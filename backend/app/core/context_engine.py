from datetime import datetime
import random


class ContextEngine:
    """
    Predictive context engine that classifies user state based on 
    GPS/accelerometer data and suggests appropriate study actions.
    
    In production, this would use a trained classifier on sensor data.
    """

    LOCATION_ACTIONS = {
        "commuting": "audio_flashcards",
        "library": "study_session",
        "home_desk": "study_session",
        "bed": "sleep_review",
        "gym": "break",
        "unknown": "none",
    }

    def _get_time_context(self) -> str:
        hour = datetime.now().hour
        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    def classify_context(self, user_id: str, gps_lat: float = 0.0, gps_lon: float = 0.0,
                         accel_magnitude: float = 0.0) -> dict:
        """Classify user context from sensor data (simulated)."""
        # Simulated classification based on accelerometer magnitude
        if accel_magnitude > 5.0:
            location_state = "commuting"
            activity = "driving"
        elif accel_magnitude > 2.0:
            location_state = "gym"
            activity = "walking"
        elif accel_magnitude < 0.5:
            time_ctx = self._get_time_context()
            if time_ctx == "night":
                location_state = "bed"
                activity = "lying_down"
            else:
                location_state = "home_desk"
                activity = "sitting"
        else:
            location_state = "library"
            activity = "sitting"

        suggested_action = self.LOCATION_ACTIONS.get(location_state, "none")
        time_context = self._get_time_context()

        # Override for night time
        if time_context == "night" and location_state == "bed":
            suggested_action = "sleep_review"

        return {
            "user_id": user_id,
            "location_state": location_state,
            "activity_type": activity,
            "time_context": time_context,
            "suggested_action": suggested_action,
            "confidence": round(random.uniform(0.7, 0.95), 2),
            "computed_at": datetime.utcnow(),
        }

    def generate_iot_commands(self, protocol_config: dict) -> list:
        """Generate simulated IoT device commands for Focus Protocol."""
        commands = []
        commands.append({
            "device_type": "light",
            "action": "set_color_temp",
            "value": protocol_config.get("light_color_temp", 5000),
            "brightness": protocol_config.get("light_brightness", 80),
            "status": "sent",
        })
        commands.append({
            "device_type": "thermostat",
            "action": "set_temperature",
            "value": protocol_config.get("target_temp_celsius", 20.0),
            "status": "sent",
        })
        if protocol_config.get("lock_phone", True):
            commands.append({
                "device_type": "phone",
                "action": "enable_dnd",
                "status": "sent",
            })
        if protocol_config.get("mute_notifications", True):
            commands.append({
                "device_type": "speaker",
                "action": "mute",
                "status": "sent",
            })
        return commands


# Global singleton
context_engine = ContextEngine()
