
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.work,
                    size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 20),
                Icon(Icons.home,
                    size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 20),
                Icon(Icons.beach_access,
                    size: 40, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Loading Calendar...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
