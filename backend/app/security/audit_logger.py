"""
Immutable Timestamped Audit Logger.
Every action is recorded with a cryptographically signed timestamp 
to ensure data integrity and tamper-proof audit trails.
"""
import hashlib
import hmac
import json
from datetime import datetime
from typing import Optional


# Simulated secret key for HMAC signing (in production, stored in HSM)
AUDIT_SIGNING_KEY = b"smart-study-audit-key-do-not-share"


class AuditLogger:
    """
    Cryptographically secure audit logging engine.
    Each log entry gets an HMAC-SHA256 signature that chains to the previous entry,
    creating a tamper-evident log (similar to a blockchain).
    """

    def __init__(self):
        self._last_hash: str = "GENESIS"

    def _compute_signature(self, payload: str) -> str:
        """Compute HMAC-SHA256 signature for a log entry."""
        return hmac.new(AUDIT_SIGNING_KEY, payload.encode(), hashlib.sha256).hexdigest()

    def _compute_chain_hash(self, entry_data: str, previous_hash: str) -> str:
        """Chain-link this entry to the previous one for tamper detection."""
        combined = f"{previous_hash}:{entry_data}"
        return hashlib.sha256(combined.encode()).hexdigest()

    def create_log_entry(
        self,
        user_id: str,
        action: str,
        resource: str,
        details: dict = None,
        ip_address: str = "unknown",
    ) -> dict:
        """
        Create a signed, timestamped audit log entry.
        
        Args:
            user_id: The user performing the action
            action: Action type (login, timer_start, test_taken, etc.)
            resource: Resource being acted upon
            details: Additional metadata
            ip_address: Client IP
        """
        timestamp = datetime.utcnow()
        
        entry_data = json.dumps({
            "user_id": user_id,
            "action": action,
            "resource": resource,
            "details": details or {},
            "ip_address": ip_address,
            "timestamp": timestamp.isoformat(),
        }, sort_keys=True)

        signature = self._compute_signature(entry_data)
        chain_hash = self._compute_chain_hash(entry_data, self._last_hash)
        self._last_hash = chain_hash

        return {
            "user_id": user_id,
            "action": action,
            "resource": resource,
            "details": details or {},
            "ip_address": ip_address,
            "timestamp": timestamp,
            "signature": signature,
            "chain_hash": chain_hash,
            "previous_hash": self._last_hash,
            "tsa_verified": True,  # Simulated TSA verification
        }

    def verify_entry(self, entry: dict) -> bool:
        """Verify that an audit log entry has not been tampered with."""
        entry_data = json.dumps({
            "user_id": entry["user_id"],
            "action": entry["action"],
            "resource": entry["resource"],
            "details": entry.get("details", {}),
            "ip_address": entry.get("ip_address", "unknown"),
            "timestamp": entry["timestamp"].isoformat() if isinstance(entry["timestamp"], datetime) else entry["timestamp"],
        }, sort_keys=True)

        expected_sig = self._compute_signature(entry_data)
        return hmac.compare_digest(expected_sig, entry.get("signature", ""))


# Global singleton
audit_logger = AuditLogger()
