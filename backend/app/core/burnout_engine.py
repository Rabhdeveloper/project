from datetime import datetime, timedelta
import random


class BurnoutPredictor:
    """
    Predictive engine for student burnout detection.
    Analyzes biometric data trends (HRV, stress markers, session duration)
    to intervene *before* a student reaches cognitive exhaustion.
    
    In production, this would use a trained time-series model (e.g., LSTM)
    on historical biometric + session data.
    """

    def __init__(self):
        # Thresholds for different risk levels
        self.stress_threshold_moderate = 0.5
        self.stress_threshold_high = 0.7
        self.stress_threshold_critical = 0.85
        self.max_continuous_study_minutes = 120  # 2 hours without break = concern

    def compute_cognitive_load(self, readings: list) -> dict:
        """
        Compute real-time cognitive load index from recent biometric readings.
        readings: list of dicts with keys [sensor_type, value, timestamp]
        """
        if not readings:
            return {
                "overall_load": 0.3,
                "focus_depth": 0.5,
                "stress_level": 0.2,
                "recommended_action": "continue",
            }

        # Aggregate sensor values
        hrv_values = [r["value"] for r in readings if r.get("sensor_type") == "hrv"]
        hr_values = [r["value"] for r in readings if r.get("sensor_type") == "heart_rate"]
        gsr_values = [r["value"] for r in readings if r.get("sensor_type") == "gsr"]
        eeg_values = [r["value"] for r in readings if r.get("sensor_type") == "eeg"]

        # Simulate cognitive load calculation
        # Lower HRV = higher stress; Higher GSR = higher arousal/stress
        avg_hrv = sum(hrv_values) / len(hrv_values) if hrv_values else 50.0
        avg_hr = sum(hr_values) / len(hr_values) if hr_values else 72.0
        avg_gsr = sum(gsr_values) / len(gsr_values) if gsr_values else 2.0

        # Normalize to 0-1 scale
        stress_from_hrv = max(0.0, min(1.0, 1.0 - (avg_hrv / 100.0)))  # Low HRV = high stress
        stress_from_hr = max(0.0, min(1.0, (avg_hr - 60) / 60.0))  # Higher HR = more stress
        stress_from_gsr = max(0.0, min(1.0, avg_gsr / 10.0))  # Higher GSR = more arousal

        overall_stress = (stress_from_hrv * 0.4 + stress_from_hr * 0.3 + stress_from_gsr * 0.3)
        focus_depth = max(0.0, min(1.0, 1.0 - overall_stress + random.uniform(-0.1, 0.1)))
        overall_load = max(0.0, min(1.0, overall_stress * 0.7 + (1 - focus_depth) * 0.3))

        # Determine recommended action
        if overall_stress >= self.stress_threshold_critical:
            action = "stop"
        elif overall_stress >= self.stress_threshold_high:
            action = "long_break"
        elif overall_stress >= self.stress_threshold_moderate:
            action = "short_break"
        else:
            action = "continue"

        return {
            "overall_load": round(overall_load, 3),
            "focus_depth": round(focus_depth, 3),
            "stress_level": round(overall_stress, 3),
            "recommended_action": action,
        }

    def assess_burnout_risk(self, user_id: str, recent_sessions: list, biometric_history: list) -> dict:
        """
        Assess burnout risk based on session patterns and biometric trends.
        """
        contributing_factors = []
        risk_score = 0.0

        # Factor 1: Continuous study without breaks
        total_study_minutes = sum(s.get("duration_minutes", 0) for s in recent_sessions[-5:])
        if total_study_minutes > self.max_continuous_study_minutes:
            risk_score += 0.3
            contributing_factors.append(f"prolonged_study_{total_study_minutes}min")

        # Factor 2: Elevated stress trend over recent readings
        if biometric_history:
            recent_stress = [r.get("value", 0) for r in biometric_history[-10:]
                            if r.get("sensor_type") == "hrv"]
            if recent_stress:
                avg_recent_hrv = sum(recent_stress) / len(recent_stress)
                if avg_recent_hrv < 40:  # Low HRV trend
                    risk_score += 0.25
                    contributing_factors.append("low_hrv_trend")

        # Factor 3: Late-night study sessions
        if recent_sessions:
            late_sessions = [s for s in recent_sessions
                           if isinstance(s.get("created_at"), datetime) and s["created_at"].hour >= 23]
            if len(late_sessions) >= 3:
                risk_score += 0.15
                contributing_factors.append("frequent_late_night_study")

        # Factor 4: No rest days in last 7 days (simulated)
        if len(recent_sessions) >= 7:
            risk_score += 0.15
            contributing_factors.append("no_rest_days_7d")

        # Add random variance to simulate model uncertainty
        risk_score += random.uniform(-0.05, 0.05)
        risk_score = max(0.0, min(1.0, risk_score))

        # Determine risk level and intervention
        if risk_score >= 0.75:
            risk_level = "critical"
            intervention = "force_break"
            intervention_message = "🚨 Critical burnout risk detected. Your body needs rest. Forcing a 30-minute break."
        elif risk_score >= 0.5:
            risk_level = "high"
            intervention = "suggest_meditation"
            intervention_message = "⚠️ High stress detected. Consider a 10-minute guided meditation before continuing."
        elif risk_score >= 0.3:
            risk_level = "moderate"
            intervention = "suggest_break"
            intervention_message = "💡 You've been studying hard. A short 5-minute break would help maintain focus."
        else:
            risk_level = "low"
            intervention = "none"
            intervention_message = "✅ You're doing great! Keep up the balanced study rhythm."

        return {
            "user_id": user_id,
            "risk_score": round(risk_score, 3),
            "risk_level": risk_level,
            "contributing_factors": contributing_factors,
            "intervention": intervention,
            "intervention_message": intervention_message,
            "computed_at": datetime.utcnow(),
        }


# Global singleton
burnout_engine = BurnoutPredictor()
