import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DigitalBalanceTracker extends StatelessWidget {
  final double screenTime;
  final ValueChanged<double> onChanged;

  const DigitalBalanceTracker({
    super.key,
    required this.screenTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(screenTime);
    final emoji = _getStatusEmoji(screenTime);
    final message = _getStatusMessage(screenTime);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: CircularProgressIndicator(
                value: (screenTime / 12).clamp(0.0, 1.0),
                strokeWidth: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                Text(
                  "${screenTime.toStringAsFixed(1)}h",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: screenTime,
          min: 0,
          max: 12, // Cap at 12 for UI, but could go higher
          divisions: 24, // 0.5 hour increments
          label: "${screenTime.toStringAsFixed(1)}h",
          activeColor: color,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            onChanged(value);
          },
        ),
      ],
    );
  }

  Color _getStatusColor(double hours) {
    if (hours <= 2) return Colors.green;
    if (hours <= 5) return Colors.blue;
    if (hours <= 8) return Colors.orange;
    return Colors.red;
  }

  String _getStatusEmoji(double hours) {
    if (hours <= 2) return '😌';
    if (hours <= 5) return '🙂';
    if (hours <= 8) return '😐';
    return '😟';
  }

  String _getStatusMessage(double hours) {
    if (hours <= 2) return "Healthy digital balance!";
    if (hours <= 5) return "Moderate usage.";
    if (hours <= 8) return "Try reducing a bit.";
    return "High screen time detected.";
  }
}
