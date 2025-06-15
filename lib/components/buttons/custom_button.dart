import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final bool fullWidth;
  final EdgeInsets customPadding;
  final String label;
  final VoidCallback onPressedAction;
  final WidgetStateProperty<Color>? backgroundColor;

  const CustomButton({
    super.key,
    required this.fullWidth,
    required this.customPadding,
    required this.onPressedAction,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: ElevatedButton(
        onPressed: () {
          onPressedAction();
        },
        style: ButtonStyle(
          backgroundColor: backgroundColor ??
              WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          minimumSize: fullWidth
              ? WidgetStateProperty.all<Size>(
                  const Size.fromHeight(50.0),
                )
              : null,
          padding: WidgetStateProperty.all(
            customPadding,
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.apply(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
