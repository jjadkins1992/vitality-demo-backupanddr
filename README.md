# Google Cloud Backup and DR - Terraform

This repository deploys **Google Cloud Backup and DR** using Terraform. It creates everything needed to back up your cloud workloads into immutable, ransomware-resistant storage called **backup vaults**, and it does so as code so the whole setup is repeatable and version-controlled.

This README is written for someone **new to Terraform**. It explains the concepts as it goes. Read it top to bottom the first time.

---

## Table of contents

1. [What this builds](#1-what-this-builds)
2. [Before you start (prerequisites)](#2-before-you-start)
3. [Repository layout](#3-repository-layout)
4. [Step-by-step: deploy it](#4-step-by-step-deploy-it)
5. [Step-by-step: register the appliances](#5-register-the-appliances)
6. [Step-by-step: set up a backup](#6-set-up-a-backup)
7. [How to check it worked](#7-how-to-check-it-worked)
8. [Adapting this for a new client](#8-adapting-this-for-a-new-client)
9. [Things that will trip you up](#9-things-that-will-trip-you-up)
10. [Going to production](#10-going-to-production)
11. [Glossary](#11-glossary)

---

## 1. What this builds

Four things, each built by its own Terraform **module** (a reusable block of code):

| Module | What it creates | How many |
|--------|-----------------|----------|
| `network` | A private network (VPC) for Backup and DR to live in | One |
| `management` | The central "brain" - the management server that coordinates everything | One |
| `region` | Per region: a subnet, a router, a NAT gateway, and a backup appliance | One per region |
| `vault` | One immutable backup vault (where backups are stored) | Many |

A **vault** is just storage. To actually back something up you also need a **backup plan** (a schedule) and an **association** (which links a workload to a plan). Those are covered in section 6.

---

## 2. Before you start

You need the following ready, or the deployment will fail partway:

### Accounts and tools
- A Google Cloud account with two projects:
  - a **management project** (holds the network, management server, appliances, and vaults), and
  - a **workload project** (holds the things you want to back up, e.g. VMs and databases).
- The `gcloud` command-line tool installed and logged in (`gcloud auth login`).
- Access to the Terraform Cloud organisation and workspace for this repo.

### APIs to turn on
Turn these on in the relevant projects (the deployment needs them):
- `backupdr.googleapis.com` - in **both** the management project **and** every workload project. (Forgetting the workload project is a common cause of failure.)
- `compute.googleapis.com`, `servicenetworking.googleapis.com`, and `sqladmin.googleapis.com` as needed.

### A quota check (important)
Each appliance uses 4 vCPUs. Three appliances use 12, which is exactly the default global CPU limit. That leaves **no room** for anything else in that project. So either:
- keep your workloads in a **separate** project (recommended), or
- request a CPU quota increase before deploying.

---

## 3. Repository layout

```
repo/
  modules/
    network/      the private network
    management/   the central management server
    region/       per-region subnet, router, NAT, and appliance
    vault/        one immutable backup vault
  environments/
    <client>/     this is what you edit per client:
                    main.tf       - wires the modules together with values
                    variables.tf  - the client's project IDs, retention, etc.
                    backend.tf    - points at the Terraform Cloud workspace
                    outputs.tf    - useful values printed after a build
  scripts/
    register_appliances.py   - run once after a build (see section 5)
```

**The key idea**: the `modules/` folder is the reusable engine and you rarely touch it. The `environments/<client>/` folder is where each client's specific values live. To onboard a new client, you copy the environment folder and change its values - not the modules.

---

## 4. Step-by-step: deploy it

Run these from inside `environments/<client>/`.

### 4.1 Initialise (first time only)
```bash
cd environments/<client>
terraform init
```
This connects to Terraform Cloud and downloads the needed plugins.

### 4.2 See what will be built
```bash
terraform plan
```
Read the output. The first build creates around 95+ resources. If the plan shows errors, fix them before going further (see section 9).

### 4.3 Build it
```bash
terraform apply
```
Type `yes` when prompted. The order of events:
1. The network is created.
2. The **management server** is created - this takes about **10 minutes**. The code waits on purpose so nothing races ahead of it.
3. The **appliances** are created, one per region.
4. The **vaults** are created.

When it finishes, the infrastructure exists - but the appliances are **not yet registered**. That is the next step.

---

## 5. Register the appliances

Building an appliance does not automatically connect it to the management server. You must register it, and this is a **separate step run after the build**.

### Why it is separate (the short version)
The management server only trusts identities that are already in its own internal user list. When you log into the Backup and DR console as a person, you get added to that list. The automated build identity is **not** on that list, so it cannot register the appliances itself. The registration therefore runs as **you**, using your own login.

### How to run it
```bash
# Make sure you have logged into the Backup and DR console at least once,
# and that gcloud is logged in as that same user.
cd environments/<client>
python3 ../../scripts/register_appliances.py
```
The script reads the build's state, talks to the management server as your user, and registers each appliance. Running it again is safe - an already-registered appliance is simply skipped.

### One configuration note
In the `region` module the appliance is set with `ba_registration = false`. **Leave it false.** If it is true, two bad things happen: the automated registration fails (for the reason above), and every `terraform plan` hangs for 15+ minutes because it keeps re-checking the registration. False keeps plans fast; the script handles registration instead.

---

## 6. Set up a backup

Vaults are storage. To back a workload up you need a **backup plan** and an **association**. These are currently set up with `gcloud` commands (they can be moved into Terraform later).

### 6.1 Create a backup plan
A plan lives in the **management project** and points at one vault. The backup window must be at least **6 hours**.
```bash
gcloud backup-dr backup-plans create <PLAN_NAME> \
  --project=<MGMT_PROJECT> --location=<REGION> \
  --resource-type=compute.googleapis.com/Instance \
  --backup-vault=projects/<MGMT_PROJECT>/locations/<REGION>/backupVaults/<VAULT> \
  --backup-rule=rule-id=daily-6h,recurrence=HOURLY,hourly-frequency=6,time-zone=UTC,backup-window-start=0,backup-window-end=24,retention-days=30
```
For a database, use `--resource-type=sqladmin.googleapis.com/Instance`.

### 6.2 Associate a workload to the plan
The association must be created in the **workload project** (the same project as the thing being backed up), even though it points at a plan in the management project.
```bash
gcloud backup-dr backup-plan-associations create <NAME> \
  --project=<WORKLOAD_PROJECT> --location=<REGION> \
  --backup-plan=projects/<MGMT_PROJECT>/locations/<REGION>/backupPlans/<PLAN> \
  --resource=projects/<WORKLOAD_PROJECT>/zones/<ZONE>/instances/<VM> \
  --resource-type=compute.googleapis.com/Instance
```
Resource path shapes differ:
- Compute: `projects/<p>/zones/<zone>/instances/<name>`
- Cloud SQL: `projects/<p>/instances/<name>` (no zone)

### 6.3 Run a backup now (instead of waiting for the schedule)
```bash
gcloud backup-dr backup-plan-associations trigger-backup <NAME> \
  --workload-project=<WORKLOAD_PROJECT> --location=<REGION> \
  --backup-rule-id=daily-6h
```

---

## 7. How to check it worked

**Use the right screen.** Backups made this way appear in the **Google Cloud Console** under Backup and DR > Backup vaults / Vaulted backups. They do **not** appear in the older appliance console - that one stays empty for this type of backup, which is normal.

From the command line, confirm a backup landed:
```bash
gcloud backup-dr data-sources list \
  --project=<MGMT_PROJECT> --location=<REGION> \
  --backup-vault=<VAULT> \
  --format="table(name.basename(),state,configState)"
```
A row showing `ACTIVE` means the backup is in the vault.

---

## 8. Adapting this for a new client

1. Copy `environments/<existing>/` to `environments/<new-client>/`.
2. In its `main.tf`, edit the **regions** map (region, zone, and IP range per region) and the **vaults** map (how many vaults, and their retention).
3. In its `variables.tf`, set the management and workload project IDs and the retention values.
4. In its `backend.tf`, point at the new client's Terraform Cloud workspace.
5. Run `terraform init`, `terraform plan`, `terraform apply`.
6. Run the registration script (section 5).
7. Work through the production checklist (section 10) before going live.

You should not need to change anything in `modules/`. That is the point of the structure.

---

## 9. Things that will trip you up

These are real issues you are likely to hit. Each has a simple cause.

- **Backups seem to be missing.** You are probably looking at the wrong project or the wrong console. Check the project picker, confirm you are signed into the right account, and use the Google Cloud Console (not the appliance console).
- **The appliance dashboard shows zero.** Expected. Vault backups do not show there. Use the Cloud Console.
- **Every plan takes 15+ minutes.** `ba_registration` is set to true somewhere. Set it to false.
- **"Association project should be same as resource."** You created the association in the management project. Create it in the **workload** project instead.
- **"Permission denied" when associating.** The Backup and DR service needs permission on the workload project. Importantly, **Compute and Cloud SQL use different service identities**, and each needs its own grant:
  - Compute: grant `roles/backupdr.computeEngineOperator`
  - Cloud SQL: grant `roles/backupdr.cloudSqlOperator`
  - Granting one does **not** cover the other.
- **CPU quota exceeded.** Three appliances use the whole default 12 vCPU allowance. Put workloads in another project or raise the quota.
- **A vault will not delete.** If it still holds backups that have not reached the end of their retention, it cannot be deleted - by anyone. This is the immutability protection working as designed. You wait until retention expires.

---

## 10. Going to production

Some settings are deliberately relaxed for testing and **must** be corrected before a real production deployment:

| Setting | Testing | Production |
|---------|---------|------------|
| `force_delete` on vaults | `true` (so test estates can be removed) | **`false`** - real backups must not be removable |
| Retention lock | Unlocked | **Locked** - this is what guarantees true immutability |
| Vault access restriction | `unrestricted` (test only) | **`WITHIN_ORGANIZATION`** |
| Retention period | Short, for quick test cleanup | Per the client's policy (e.g. 30 / 90 days) |

**The single most dangerous mistake** is deploying to production with the testing teardown flags left on. That would let a `terraform destroy` remove real backups, defeating the entire purpose of the solution. Always set `force_delete` to false and lock retention for production.

---

## 11. Glossary

| Term | Plain meaning |
|------|---------------|
| Management server | The central "brain" that coordinates the appliances and holds the trusted-user list. |
| Appliance | The worker that actually moves backup data. One per region here. |
| Backup vault | Immutable storage for backups. Cannot be tampered with or deleted early. |
| Backup plan | The schedule and retention for a group of workloads. |
| Association | The link between one workload and a backup plan. |
| Data source | How a protected workload appears inside a vault. |
| Retention | How long a backup is kept. Once set, it cannot be shortened. |
| Module | A reusable block of Terraform code. |
| State | Terraform's record of what it has built (stored in Terraform Cloud here). |
| GMEK | Google-Managed Encryption Key - the default encryption, no setup needed. |

---

*Adapt the example values (project IDs, regions, IP ranges, retention) to each client. The module structure stays the same; only the environment values change.*
