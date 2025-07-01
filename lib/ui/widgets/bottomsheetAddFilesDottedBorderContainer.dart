import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class BottomsheetAddFilesDottedBorderContainer extends StatelessWidget {
  final String title;
  final Function onTap;
  const BottomsheetAddFilesDottedBorderContainer({
    super.key,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: DottedBorder(
        borderType: BorderType.RRect,
        dashPattern: const [10, 10],
        radius: const Radius.circular(10.0),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        child: Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height * (0.075),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 15,
                      offset: const Offset(0, 2.0),
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.25),
                    ),
                  ],
                ),
                width: 30,
                height: 30,
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * (0.05),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
