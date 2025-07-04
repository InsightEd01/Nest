import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: [
        CupertinoButton(
          child: Text(UiUtils.getTranslatedLabel(context, yesKey), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        CupertinoButton(
          child: Text(UiUtils.getTranslatedLabel(context, noKey), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      backgroundColor: Colors.white,
      content: Text(UiUtils.getTranslatedLabel(context, deleteDialogMessageKey)),
      title: Text(UiUtils.getTranslatedLabel(context, deleteDialogTitleKey)),
    );
  }
}
