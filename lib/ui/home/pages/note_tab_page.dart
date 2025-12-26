import 'package:flutter/material.dart';
import '../widgets/gradient_page.dart';
import '../widgets/recordings_list.dart';

class NoteTabPage extends StatelessWidget {
  const NoteTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Text(
                    '記録',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: RecordingsList()),
          ],
        ),
      ),
    );
  }
}

