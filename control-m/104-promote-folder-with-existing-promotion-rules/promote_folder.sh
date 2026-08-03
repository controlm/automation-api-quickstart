#!/usr/bin/env bash
#
# promote_folder.sh
# -----------------------------------------------------------------------------
# Promote a Control-M Folder from DEV to PROD with existing promotion rules
#
# Example: promote a Control-M folder from a DEV environment to a PROD
# environment using the Control-M Automation API CLI (ctm).
#
# What it does, end to end:
#   1. Registers the DEV and PROD environments with the ctm CLI.
#   2. Exports the folder (jobs) definition from DEV.
#   3. Retrieves the DEV-to-PROD promotion rule (deploy descriptor).
#   4. Transforms the DEV definition using the promotion rule so it is
#      valid for PROD (server names, host groups, etc. get remapped).
#   5. Validates the transformed definition against PROD (ctm build).
#   6. Deploys the transformed definition to PROD (ctm deploy).
#
# NOTE: This is a demo. Credentials are placeholders in the CONFIG section
# below. For anything beyond a quick demo, read them from a secrets manager /
# environment variables instead of committing them to a repo.
# -----------------------------------------------------------------------------

set -euo pipefail

# =============================================================================
# CONFIG - edit these values to match your sites
# =============================================================================

# --- DEV environment (source) ---
DEV_NAME="DEV"
DEV_ENDPOINT="https://<DEV endpoint server>:8443/automation-api"
DEV_USER="<DEV EM USER>"
DEV_PASSWORD="<DEV EM PASS>"

# --- PROD environment (target) ---
PROD_NAME="PROD"
PROD_ENDPOINT="https://<PROD endpoint server>:8443/automation-api"
PROD_USER="<PROD EM USER>"
PROD_PASSWORD="<PROD EM PASS>"

# --- What to promote ---
DEV_SERVER="<DEV_SERVER>"   # Control-M/Server that holds the folder in DEV
FOLDER_NAME="Folder_1"         # Folder to promote
PROMOTION_RULE="DEV-TO-PROD"   # Promotion rule name defined in Control-M

# --- Working files (created in the current directory) ---
DATA_FILE="data.json"                 # Raw folder definition exported from DEV
DESCRIPTOR_FILE="deploy_descriptor.json"  # Promotion rule / deploy descriptor
PROD_DATA_FILE="prod_data.json"       # Transformed definition ready for PROD

# =============================================================================
# Promotion flow
# =============================================================================

# 1. Register the DEV and PROD environments with the ctm CLI.
echo "==> Registering DEV environment ($DEV_NAME)"
ctm env add "$DEV_NAME" "$DEV_ENDPOINT" "$DEV_USER" "$DEV_PASSWORD"

echo "==> Registering PROD environment ($PROD_NAME)"
ctm env add "$PROD_NAME" "$PROD_ENDPOINT" "$PROD_USER" "$PROD_PASSWORD"

# 2. Export the folder (jobs) definition from DEV.
echo "==> Exporting folder '$FOLDER_NAME' from DEV server '$DEV_SERVER'"
ctm env set "$DEV_NAME"
ctm deploy jobs::get -s "server=${DEV_SERVER}&folder=${FOLDER_NAME}" > "$DATA_FILE"

# 3. Retrieve the promotion rule (deploy descriptor).
echo "==> Available promotion rules:"
ctm deploy promotionrules::get

echo "==> Fetching deploy descriptor for promotion rule '$PROMOTION_RULE'"
ctm deploy promotionrules:rule::get "$PROMOTION_RULE" > "$DESCRIPTOR_FILE"

# 4. Transform the DEV definition into a PROD-ready definition.
echo "==> Transforming DEV definition into PROD-ready definition"
ctm deploy transform "$DATA_FILE" "$DESCRIPTOR_FILE" > "$PROD_DATA_FILE"

# 5. Validate the transformed definition against PROD (dry run).
echo "==> Validating transformed definition against PROD (build)"
ctm build "$PROD_DATA_FILE" -e "$PROD_NAME"

# 6. Deploy the transformed definition to PROD.
echo "==> Deploying transformed definition to PROD"
ctm deploy "$PROD_DATA_FILE" -e "$PROD_NAME"

echo "==> Done. Folder '$FOLDER_NAME' promoted from $DEV_NAME to $PROD_NAME."
