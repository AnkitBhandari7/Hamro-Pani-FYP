import 'package:flutter/material.dart';

class SocialButtons extends StatelessWidget {
  final VoidCallback onGithub;
  final VoidCallback onGitlab;

  const SocialButtons({
    super.key,
    required this.onGithub,
    required this.onGitlab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGithub,
            icon: const Icon(Icons.code),
            label: const Text('GitHub'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGitlab,
            icon: const Icon(Icons.code_rounded),
            label: const Text('GitLab'),
          ),
        ),
      ],
    );
  }
}