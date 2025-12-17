import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/home_provider.dart';

class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 200),
          ElevatedButton(
            onPressed: () => vm.toggleRecording(),
            child: Text(state.isRecording ? 'Stop' : 'Record'),
          ),
          TextButton(
            onPressed: state.isLoading ? null : () => vm.deleteLocalRecordings(),
            child: const Text('ローカル録音を全削除（仮）'),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (!state.isLoading && state.files.isEmpty) const Text(""),
          if (state.files.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: state.files.length,
                itemBuilder: (_, i) {
                  final file = state.files[i];
                  final name = file.path.split('/').last;
                  return ListTile(
                    title: Text(name),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

