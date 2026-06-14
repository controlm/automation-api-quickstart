"""Remedy ITSM client – authentication and change-request creation."""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import requests

ITSM_CONFIG_FILE = Path(__file__).parent / "itsm_config.json"

logger = logging.getLogger("remedy_client")


def load_itsm_config() -> dict:
    if not ITSM_CONFIG_FILE.exists():
        logger.error("ITSM config not found: %s", ITSM_CONFIG_FILE)
        sys.exit(1)
    with open(ITSM_CONFIG_FILE, encoding="utf-8") as f:
        return json.load(f)


def get_auth_token(base_url: str, username: str, password: str, verify_ssl: bool) -> str:
    """Authenticate against Remedy and return a JWT token."""
    auth_url = f"{base_url.rsplit('/api', 1)[0]}/api/jwt/login"
    resp = requests.post(
        auth_url,
        data={"username": username, "password": password},
        verify=verify_ssl,
        timeout=30,
    )
    resp.raise_for_status()
    return resp.text


def create_change_request(config: dict, alert: dict) -> str | None:
    """Create a Remedy change request and return its ID."""
    base_url = config["remedy_base_url"]
    verify_ssl = config.get("verify_ssl", True)
    form = config.get("remedy_form", "CHG:ChangeInterface_Create")

    token = get_auth_token(
        base_url, config["username"], config["password"], verify_ssl
    )

    defaults = dict(config.get("ticket_defaults", {}))

    description = f"Control-M Request {alert.get('name', '')} by {alert.get('endUser', '')}"
    defaults["Description"] = description

    payload = {"values": defaults}

    url = f"{base_url}/entry/{form}"
    headers = {
        "Authorization": f"AR-JWT {token}",
        "Content-Type": "application/json",
    }

    logger.info("Creating Remedy change request for workspace '%s'", alert.get("name"))
    logger.info("Payload: %s", json.dumps(payload, indent=2))
    resp = requests.post(
        url, headers=headers, json=payload, verify=verify_ssl, timeout=30
    )
    if not resp.ok:
        logger.error("Remedy response [%d]: %s", resp.status_code, resp.text)
    resp.raise_for_status()

    location = resp.headers.get("Location", "")
    ticket_id = location.rsplit("/", 1)[-1] if location else None
    logger.info("Remedy change request created: %s", ticket_id or "(see response)")
    return ticket_id


def release_token(base_url: str, token: str, verify_ssl: bool):
    """Log out / release the JWT token."""
    logout_url = f"{base_url.rsplit('/api', 1)[0]}/api/jwt/logout"
    try:
        requests.post(
            logout_url,
            headers={"Authorization": f"AR-JWT {token}"},
            verify=verify_ssl,
            timeout=10,
        )
    except Exception:
        logger.debug("Token logout failed (non-critical)")
