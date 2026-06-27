#!/usr/bin/env python3
"""
register_appliances.py

Registers Backup and DR appliances into the global management server after a
terraform apply. Deliberate post-apply step: the management server's Actifio API
authenticates against its own DATABASE user list. The TFC runner service account
is NOT an Actifio DB user (gets 401); only a console-registered USER identity can
register an appliance. So this runs with your gcloud user credentials.

Prerequisites:
  - You have logged into the Backup and DR console at least once (creates your
    Actifio DB user).
  - gcloud is authenticated as that same user.
  - Run from environments/sandbox (so 'terraform state pull' works), or pass
    --state-file pointing at a pulled state json.

Usage:
  cd environments/sandbox
  python3 ../../scripts/register_appliances.py
"""
import argparse
import json
import subprocess
import sys

PROJECT = "backup-and-dr-dev-0"
MGMT_LOCATION = "us-central1"
MGMT_NAME = "backup-dr-management-server"


def run(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def pull_state(state_file):
    if state_file:
        with open(state_file) as f:
            return json.load(f)
    r = run(["terraform", "state", "pull"])
    if r.returncode != 0 or not r.stdout.strip():
        sys.exit("ERROR: 'terraform state pull' failed. Run from the env dir after 'terraform init'.\n" + r.stderr)
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        sys.exit("ERROR: state pull did not return valid JSON. First 200 chars:\n" + r.stdout[:200])


def resolve_endpoint():
    r = run(["gcloud", "backup-dr", "management-servers", "describe", MGMT_NAME,
             "--project", PROJECT, "--location", MGMT_LOCATION,
             "--format", "value(managementUri.api)"])
    base = r.stdout.strip()
    if not base:
        sys.exit("ERROR: could not resolve management server api URI.\n" + r.stderr)
    return base


def get_token():
    r = run(["gcloud", "auth", "print-access-token"])
    tok = r.stdout.strip()
    if not tok:
        sys.exit("ERROR: could not get access token. Run 'gcloud auth login'.\n" + r.stderr)
    return tok


def extract_appliances(state):
    acc = {}
    for r in state.get("resources", []):
        mod = r.get("module", "")
        if ".module.backup_dr_appliance" not in mod:
            continue
        region = mod.split('region["')[1].split('"]')[0] if 'region["' in mod else "unknown"
        entry = acc.setdefault(region, {})
        t, n = r.get("type"), r.get("name")
        insts = r.get("instances", [])
        if not insts:
            continue
        attrs = insts[0]["attributes"]
        if t == "random_string" and n == "shared_secret":
            entry["secret"] = attrs["result"]
        elif t == "time_static" and n == "activation_date":
            entry["unix"] = attrs["unix"]
        elif t == "google_service_account" and n == "ba_service_account":
            entry["sa"] = attrs["email"]
    return acc


def get_ips():
    r = run(["gcloud", "compute", "instances", "list", "--project", PROJECT,
             "--filter", "name~bkp-dr",
             "--format", "value(name,networkInterfaces[0].networkIP)"])
    ips = {}
    for line in r.stdout.strip().splitlines():
        parts = line.split()
        if len(parts) >= 2:
            ips[parts[0]] = parts[1]
    return ips


def session(base, token):
    r = run(["curl", "-sS", "-X", "POST", f"{base}/session",
             "-H", f"Authorization: Bearer {token}", "--max-time", "30"])
    return json.loads(r.stdout)["session_id"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state-file", default=None, help="path to a pulled tfstate json (optional)")
    args = ap.parse_args()

    print("==> Pulling Terraform state")
    state = pull_state(args.state_file)
    print("==> Resolving management server api endpoint")
    base = resolve_endpoint()
    print(f"    BASE={base}")
    print("==> Acquiring user access token")
    token = get_token()

    print("==> Extracting appliance details from state")
    appliances = extract_appliances(state)
    if not appliances:
        sys.exit("ERROR: no appliance resources found in state.")
    ips = get_ips()

    for region, e in sorted(appliances.items()):
        secret_result = e.get("secret")
        unix = e.get("unix")
        sa = e.get("sa")
        vm = sa.split("@")[0] if sa else None
        ip = ips.get(vm) if vm else None
        if not (secret_result and unix and ip and sa):
            print(f"[{region}] SKIP - missing data (secret={bool(secret_result)} ip={ip} sa={sa})")
            continue
        full_secret = f"{secret_result}00000000{format(int(unix) + 86400, 'x')}"
        sid = session(base, token)
        body = json.dumps({
            "ipaddress": ip,
            "shared_secret": full_secret,
            "deployBaWithoutPsa": True,
            "serviceaccount": sa,
        })
        r = run(["curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}",
                 "-X", "POST", f"{base}/cluster/register",
                 "-H", f"Authorization: Bearer {token}",
                 "-H", f"backupdr-management-session: Actifio {sid}",
                 "-H", "Content-Type: application/json",
                 "-d", body, "--max-time", "180"])
        code = r.stdout.strip()
        note = "OK" if code == "204" else ("server-side may still complete" if code == "000" else "")
        print(f"[{region}] {vm} ({ip}) register HTTP {code} {note}")

    # verify
    sid = session(base, token)
    r = run(["curl", "-sS", f"{base}/cluster",
             "-H", f"Authorization: Bearer {token}",
             "-H", f"backupdr-management-session: Actifio {sid}", "--max-time", "30"])
    try:
        count = json.loads(r.stdout).get("count", 0)
        print(f"\n==> Management server now reports {count} registered appliance(s).")
    except Exception:
        print(f"\n==> Could not parse cluster count: {r.stdout[:200]}")
    print("==> Done. Verify all appliances show CONNECTED in the console.")


if __name__ == "__main__":
    main()
