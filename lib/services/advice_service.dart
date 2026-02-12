enum AdviceActionType { none, reflection, breathing, timer }

class AdviceItem {
  final String message;
  final String? actionLabel;
  final AdviceActionType actionType;

  AdviceItem({required this.message, this.actionLabel, this.actionType = AdviceActionType.none});
}

class AdviceService {
  AdviceItem? generateAdvice({
    required int totalDistractionMinutes,
    required String? currentMood,
    required int distractionCount,
  }) {
    // 1. Insight: High Distraction + Negative Mood
    if (totalDistractionMinutes > 45 && (currentMood == 'Stressed' || currentMood == 'Anxious' || currentMood == '😰' || currentMood == '😔')) {
      return AdviceItem(
        message: "You feel $currentMood on high distraction days. Let's pause and reflect.",
        actionLabel: "Reflect Now",
        actionType: AdviceActionType.reflection,
      );
    }

    // 2. High Distraction Time
    if (totalDistractionMinutes > 60) {
       return AdviceItem(
        message: "You've been distracted for over an hour. Consider a short walk to clear your head.",
        actionLabel: "Start Timer",
        actionType: AdviceActionType.timer, // Maybe lead to break timer? For now just timer
      );
    }

    // 3. Moderate Distraction but Frequent Interruptions
    if (distractionCount > 5) {
      return AdviceItem(
        message: "Frequent interruptions? Try turning off notifications for the next 30 minutes.",
        actionLabel: "Start Focus",
        actionType: AdviceActionType.timer,
      );
    }

    // 4. Mood-based Advice (if distraction is low but mood is off)
    if (currentMood == 'Stressed' || currentMood == '😰') {
      return AdviceItem(
        message: "Feeling overwhelmed? A quick breathing exercise might help.",
        actionLabel: "Breathe",
        actionType: AdviceActionType.breathing,
      );
    }
    
    if (currentMood == 'Tired' || currentMood == '😴') {
      return AdviceItem(
        message: "Energy low? A quick 20-minute power nap or some hydration might help.",
      );
    }

    return null; // No specific advice needed
  }
}
