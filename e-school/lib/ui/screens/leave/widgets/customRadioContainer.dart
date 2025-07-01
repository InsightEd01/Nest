import 'package:flutter/material.dart';

class CustomRadioContainer extends StatelessWidget {
  final double size;
  final bool isSelected;
  const CustomRadioContainer(
      {super.key, this.size = 25, required this.isSelected,});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.5),
              ),
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
