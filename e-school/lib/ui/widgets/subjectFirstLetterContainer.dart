import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/material.dart';

class SubjectFirstLetterContainer extends StatelessWidget {
  final String subjectName;
  const SubjectFirstLetterContainer({super.key, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(
      subjectName[0],
      style: TextStyle(
          fontSize: UiUtils.subjectFirstLetterFontSize,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).scaffoldBackgroundColor,),
    ),);
  }
}
