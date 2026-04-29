"""
Hardware Security Module (HSM) Simulation.
Manages encryption keys via cloud HSMs to ensure that even database 
administrators cannot access decrypted user data.
"""
import secrets
import hashlib
from datetime import datetime, timedelta
from typing import Dict, Optional


class HSMKeyManager:
    """
    Simulated cloud HSM (Hardware Security Module) key management.
    In production, this would interface with AWS CloudHSM, Azure Dedicated HSM,
    or Google Cloud HSM for FIPS 140-2 Level 3 compliant key storage.
    """

    def __init__(self):
        # Simulated key store (in production, keys never leave the HSM)
        self._master_key = secrets.token_hex(32)
        self._key_store: Dict[str, dict] = {}
        self._key_rotation_days = 90

    def generate_data_key(self, purpose: str = "general") -> dict:
        """
        Generate a data encryption key (DEK) protected by the master key.
        The DEK is used for field-level encryption of sensitive data.
        """
        key_id = f"dek-{secrets.token_hex(8)}"
        raw_key = secrets.token_hex(32)
        
        # "Wrap" the key with the master key (simulated envelope encryption)
        wrapped_key = hashlib.sha256(
            f"{self._master_key}:{raw_key}".encode()
        ).hexdigest()

        key_entry = {
            "key_id": key_id,
            "purpose": purpose,
            "algorithm": "AES-256-GCM",
            "wrapped_key": wrapped_key,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(days=self._key_rotation_days),
            "is_active": True,
            "rotation_count": 0,
        }
        self._key_store[key_id] = key_entry
        
        return {
            "key_id": key_id,
            "plaintext_key": raw_key,  # Only returned once, for immediate use
            "algorithm": "AES-256-GCM",
            "expires_at": key_entry["expires_at"],
        }

    def rotate_key(self, key_id: str) -> Optional[dict]:
        """Rotate a data encryption key — generates a new key and retires the old one."""
        if key_id not in self._key_store:
            return None
        
        old_key = self._key_store[key_id]
        old_key["is_active"] = False
        
        new_key = self.generate_data_key(purpose=old_key["purpose"])
        new_key_entry = self._key_store[new_key["key_id"]]
        new_key_entry["rotation_count"] = old_key["rotation_count"] + 1
        
        return {
            "old_key_id": key_id,
            "new_key_id": new_key["key_id"],
            "rotation_count": new_key_entry["rotation_count"],
        }

    def generate_e2ee_keypair(self, user_id: str) -> dict:
        """
        Generate an E2EE key pair for peer-to-peer study sessions.
        Uses simulated X25519 key exchange.
        """
        private_key = secrets.token_hex(32)
        public_key = hashlib.sha256(private_key.encode()).hexdigest()

        return {
            "user_id": user_id,
            "public_key": public_key,
            "private_key_encrypted": hashlib.sha256(
                f"{self._master_key}:{private_key}".encode()
            ).hexdigest(),
            "algorithm": "X25519",
            "created_at": datetime.utcnow(),
        }

    def list_active_keys(self) -> list:
        """List all active encryption keys (metadata only, no key material)."""
        return [
            {
                "key_id": k["key_id"],
                "purpose": k["purpose"],
                "algorithm": k["algorithm"],
                "created_at": k["created_at"],
                "expires_at": k["expires_at"],
                "is_active": k["is_active"],
            }
            for k in self._key_store.values()
        ]


# Global singleton
hsm_manager = HSMKeyManager()
