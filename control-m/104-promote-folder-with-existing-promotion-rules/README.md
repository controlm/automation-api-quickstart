# Promote a Control-M Folder from DEV to PROD with existing promotion rules

This example shows how to **promote a folder (and its jobs) from a DEV
environment to a PROD environment** using the [Control-M Automation API](https://docs.bmc.com/xwiki/bin/view/IT-Operations-Management/Control-M/Control-M-Automation-API/)
command-line interface (`ctm`).

Promotion means taking a folder that was built and tested in DEV, applying a
**promotion rule** that remaps environment-specific values (Control-M/Server
names, host groups, connection profiles, etc.), and deploying the result to
PROD — without hand-editing JSON.

This example is intentionally a **bridge**: it uses existing promotion rules (`promotionrules:rule::get`) and produces a `deploy_descriptor.json` that feeds `transform` + `deploy`.

---

## Prerequisites

- The Control-M **Automation API CLI** (`ctm`) installed and on your `PATH`.
  Verify with:

```bash
ctm --version
```

- Network access from the machine running the script to both the DEV and PROD
  Automation API endpoints (default port `8443`).
- Valid credentials for both environments.
- A **promotion rule** already defined in Control-M (in this example it is
  named `DEV-TO-PROD`). Promotion rules are created in the Control-M desktop interface
  interface (Planning domain) and describe how DEV values map to PROD.

---

## Files in this example

| File                    | Purpose                                                            |
| ----------------------- | ----------------------------------------------------------------- |
| `promote_folder.sh`     | The end-to-end promotion script.                                  |
| `README.md`             | This document.                                                    |
| `data.json`             | *(generated)* Raw folder definition exported from DEV.            |
| `deploy_descriptor.json`| *(generated)* The promotion rule / deploy descriptor.            |
| `prod_data.json`        | *(generated)* Transformed definition, ready to deploy to PROD.    |

> The three generated `*.json` files are produced when you run the script and
> are ignored by git (see `.gitignore`).

---

## Quick start

1. Open `promote_folder.sh` and edit the **CONFIG** section at the top:
   - `DEV_ENDPOINT` / `PROD_ENDPOINT` — your Automation API URLs.
   - `DEV_USER` / `DEV_PASSWORD` and `PROD_USER` / `PROD_PASSWORD`.
   - `DEV_SERVER` — the Control-M/Server that holds the folder in DEV.
   - `FOLDER_NAME` — the folder you want to promote.
   - `PROMOTION_RULE` — the name of the promotion rule to apply.

2. Make it executable and run it:

```bash
chmod +x promote_folder.sh
./promote_folder.sh
```

---

## What the script does, step by step

The script automates exactly the manual commands you would run by hand.

### 1. Register the environments

```bash
ctm env add DEV  https://<DEV endpoint server>:8443/automation-api <DEV EM USER> <DEV EM PASS>
ctm env add PROD https://<PROD endpoint server>:8443/automation-api <PROD EM USER> <PROD EM PASS>
```

This tells the `ctm` CLI how to reach each Control-M environment. You only need
to do this once per machine; re-running `env add` simply updates the entry.

You can list registered environments with `ctm env::get`.

### 2. Export the folder from DEV

```bash
ctm env set DEV
ctm deploy jobs::get -s "server=<DEV_SERVER>&folder=<FOLDER_NAME>" > data.json
```

`jobs::get` returns the full JSON definition of the folder and all its jobs as
they exist in DEV. We save it to `data.json`.

### 3. Get the promotion rule (deploy descriptor)

```bash
ctm deploy promotionrules::get                 # list available rules
ctm deploy promotionrules:rule::get DEV-TO-PROD > deploy_descriptor.json
```

- `promotionrules::get` lists all promotion rules defined in Control-M.
- `promotionrules:rule::get DEV-TO-PROD` fetches the specific rule and saves it
  as the **deploy descriptor** (`deploy_descriptor.json`). This descriptor is
  what maps DEV-specific values to their PROD equivalents.

### 4. Transform the DEV definition for PROD

```bash
ctm deploy transform data.json deploy_descriptor.json > prod_data.json
```

`transform` applies the promotion rule to the DEV definition and produces a new
definition (`prod_data.json`) with all environment-specific values remapped for
PROD.

### 5. Validate against PROD (dry run)

```bash
ctm build prod_data.json -e PROD
```

`build` validates the transformed definition against the PROD environment
**without deploying**. It reports how many folders, jobs, connection profiles,
etc. would be created. Example output:

```json
[
  {
    "deploymentFile": "prod_data.json",
    "successfulFoldersCount": 0,
    "successfulSmartFoldersCount": 1,
    "successfulSubFoldersCount": 0,
    "successfulJobsCount": 2,
    "successfulConnectionProfilesCount": 0,
    "successfulDriversCount": 0,
    "isDeployDescriptorValid": false
  }
]
```

### 6. Deploy to PROD

```bash
ctm deploy prod_data.json -e PROD
```

This performs the actual deployment. On success you'll see the deployed folder
and the `ENDED_OK` status:

```json
[
  {
    "deploymentFile": "prod_data.json",
    "deploymentState": "DEPLOY FOLDERS 1/1",
    "deploymentStatus": "ENDED_OK",
    "successfulSmartFoldersCount": 1,
    "successfulJobsCount": 2,
    "deployedFolders": [
      "Folder_1"
    ]
  }
]
```

---

## Reference

- Control-M Automation API — Services (`deploy`, `build`, `env`) and Promotion
  in the official BMC documentation.
