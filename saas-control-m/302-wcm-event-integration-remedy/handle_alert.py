"""
Alert handler – evaluates Control-M workspace state transitions and opens
ITSM change requests when appropriate.

Invoked by script.sh with key-value pairs:
    changeId: <v> ctmRequestId: <v> name: <v> newState: <v> oldState: <v> ...
"""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import requests

from remedy_client import create_change_request, load_itsm_config

CTM_CONFIG_FILE = Path(__file__).parent / "settings.json"
LOG_DIR = Path(__file__).parent / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_DIR / "handle_alert.log"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger("handle_alert")


def parse_args(argv: list[str]) -> dict[str, str]:
    """Parse ``key: value`` arguments into a dict. Each arg is ``"key: value"``."""
    pairs: dict[str, str] = {}
    for arg in argv:
        key, _, value = arg.partition(": ")
        pairs[key.strip()] = value.strip()
    return pairs


# ---------------------------------------------------------------------------
# Control-M workspace helpers
# ---------------------------------------------------------------------------
def load_ctm_config() -> dict:
    if not CTM_CONFIG_FILE.exists():
        logger.error("Control-M config not found: %s", CTM_CONFIG_FILE)
        return {}
    with open(CTM_CONFIG_FILE, encoding="utf-8") as f:
        return json.load(f)


def get_workspaces(endpoint: str, api_key: str) -> list[dict]:
    """GET /build/workspaces – return the list of workspaces."""
    url = f"{endpoint}/build/workspaces"
    headers = {"x-api-key": api_key}
    logger.info("Listing workspaces: GET %s", url)
    resp = requests.get(url, headers=headers, timeout=30)
    if not resp.ok:
        logger.error("Failed to list workspaces [%d]: %s", resp.status_code, resp.text)
    resp.raise_for_status()
    data = resp.json()
    return data.get("workspaces", [])


def find_workspace_id(workspaces: list[dict], workspace_name: str) -> str | None:
    """Find the workspace ID matching the given name."""
    for ws in workspaces:
        if ws.get("name") == workspace_name:
            return str(ws.get("id"))
    return None


def update_workspace_change_id(endpoint: str, api_key: str, workspace_id: str, change_id: str):
    """PUT /build/workspace/{workspaceId} – update the changeId."""
    url = f"{endpoint}/build/workspace/{workspace_id}"
    headers = {"x-api-key": api_key, "Content-Type": "application/json"}
    params = {"takeOwnership": "true"}
    payload = {"changeId": change_id}
    logger.info("Updating workspace '%s' with changeId='%s'", workspace_id, change_id)
    resp = requests.put(url, headers=headers, json=payload, params=params, timeout=30)
    if not resp.ok:
        logger.error("Failed to update workspace [%d]: %s", resp.status_code, resp.text)
    resp.raise_for_status()
    logger.info("Workspace '%s' updated successfully", workspace_id)


def return_workspace(endpoint: str, api_key: str, workspace_id: str, reason: str):
    """POST /build/workspace/{workspaceId}/return – return workspace to user."""
    url = f"{endpoint}/build/workspace/{workspace_id}/return"
    headers = {"x-api-key": api_key, "Content-Type": "application/json"}
    payload = {"returnReason": reason}
    logger.info("Returning workspace '%s' with reason: %s", workspace_id, reason)
    resp = requests.post(url, headers=headers, json=payload, timeout=30)
    if not resp.ok:
        logger.error("Failed to return workspace [%d]: %s", resp.status_code, resp.text)
    resp.raise_for_status()
    logger.info("Workspace '%s' returned successfully", workspace_id)


def get_ctm_context() -> tuple[str, str] | None:
    """Load Control-M endpoint and apiKey, return (endpoint, api_key) or None."""
    ctm_config = load_ctm_config()
    endpoint = ctm_config.get("endpoint", "")
    api_key = ctm_config.get("apiKey", "")
    if not endpoint or not api_key:
        logger.error("Control-M endpoint/apiKey missing in settings.json")
        return None
    return endpoint, api_key


def main():
    logger.info("sys.argv = %s", sys.argv)
    alert = parse_args(sys.argv[1:])
    logger.info("Parsed alert = %s", alert)
    old_state = alert.get("oldState", "")
    new_state = alert.get("newState", "")
    workspace_name = alert.get("name", "")

    logger.info(
        "Alert received – workspace='%s' oldState='%s' newState='%s'",
        workspace_name, old_state, new_state,
    )

    change_id = alert.get("changeId", "").strip()

    if not (
        old_state == "RequesterWorks"
        and new_state == "Submitted"
        and change_id in ("", "N/A")
    ):
        logger.info(
            "No action required for transition '%s' -> '%s'", old_state, new_state
        )
        return

    logger.info("State transition RequesterWorks -> Submitted detected")

    ctx = get_ctm_context()
    if not ctx:
        return
    endpoint, api_key = ctx

    if not workspace_name.startswith("Workspace"):
        reason = "The workspace name must start with 'Workspace'"
        logger.info("Workspace name '%s' invalid – returning workspace", workspace_name)
        try:
            workspaces = get_workspaces(endpoint, api_key)
            ws_id = find_workspace_id(workspaces, workspace_name)
            if ws_id:
                return_workspace(endpoint, api_key, ws_id, reason)
            else:
                logger.error("Workspace '%s' not found in Control-M", workspace_name)
        except requests.HTTPError as exc:
            logger.error("Failed to return workspace: %s", exc)
        except Exception:
            logger.exception("Unexpected error returning workspace")
        return

    logger.info("Opening change request for workspace '%s'", workspace_name)
    itsm_config = load_itsm_config()
    ticket_id = None
    try:
        ticket_id = create_change_request(itsm_config, alert)
    except requests.HTTPError as exc:
        logger.error("Failed to create Remedy change request: %s", exc)
    except Exception:
        logger.exception("Unexpected error creating Remedy change request")

    if ticket_id:
        try:
            workspaces = get_workspaces(endpoint, api_key)
            ws_id = find_workspace_id(workspaces, workspace_name)
            if ws_id:
                update_workspace_change_id(endpoint, api_key, ws_id, ticket_id)
            else:
                logger.error("Workspace '%s' not found in Control-M", workspace_name)
        except requests.HTTPError as exc:
            logger.error("Failed to update workspace changeId: %s", exc)
        except Exception:
            logger.exception("Unexpected error updating workspace changeId")


if __name__ == "__main__":
    main()
