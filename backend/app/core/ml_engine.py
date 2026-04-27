from datetime import datetime, timedelta
import random

class CognitiveLoadModel:
    """
    A simulated Machine Learning engine for determining optimal study schedules.
    In a real-world scenario, this would load a trained model (like FSRS or a custom PyTorch model)
    and use historical user session data to predict cognitive decay.
    """
    
    def __init__(self):
        # Simulated model weights
        self.base_focus_minutes = 25
        self.max_focus_minutes = 90
        self.time_of_day_weights = {
            "morning": 1.2,   # Morning tends to allow longer focus
            "afternoon": 0.9,
            "evening": 0.8,
            "night": 0.6
        }

    def _get_time_of_day(self):
        hour = datetime.now().hour
        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    def predict_optimal_duration(self, user_id: str, current_streak: int = 0):
        """
        Simulate an inference call to suggest focus duration.
        """
        time_period = self._get_time_of_day()
        weight = self.time_of_day_weights.get(time_period, 1.0)
        
        # Simulated calculation: base * time_weight + streak_bonus
        # Streak gives a slight boost to focus stamina
        streak_bonus = min(current_streak, 10) * 1.5 
        
        suggested_focus = int((self.base_focus_minutes * weight) + streak_bonus)
        
        # Add some random variance to simulate a model output
        suggested_focus += random.choice([-5, 0, 5])
        
        # Clamp bounds
        suggested_focus = max(15, min(suggested_focus, self.max_focus_minutes))
        
        # Determine optimal break
        suggested_break = 5 if suggested_focus < 40 else 10
        if suggested_focus >= 60:
            suggested_break = 15

        return {
            "suggested_focus_minutes": suggested_focus,
            "suggested_break_minutes": suggested_break,
            "cognitive_load_estimate": round(random.uniform(0.3, 0.8), 2),
            "reasoning": f"Based on your {current_streak}-day streak and current time ({time_period})."
        }

# Global singleton
ml_engine = CognitiveLoadModel()
