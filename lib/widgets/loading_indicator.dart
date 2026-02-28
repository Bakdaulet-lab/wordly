import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Loading content, please wait',
        child: const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
