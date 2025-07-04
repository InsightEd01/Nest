import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomSheetTextFieldContainer extends StatelessWidget {
  final String hintText;
  final TextEditingController textEditingController;
  final AlignmentGeometry? contentAlignment;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;
  final int? maxLines;
  final List<TextInputFormatter>? textInputFormatter;
  final TextInputType? keyboardType;
  final EdgeInsetsGeometry? margin;
  final bool? hideText;
  final Widget? suffix;
  final int? maxlength;
  final bool disabled;

  const BottomSheetTextFieldContainer({
    super.key,
    required this.hintText,
    required this.maxLines,
    required this.textEditingController,
    this.height,
    this.textInputFormatter,
    this.suffix,
    this.maxlength,
    this.hideText,
    this.keyboardType,
    this.margin,
    this.contentAlignment,
    this.contentPadding,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      alignment: contentAlignment ?? Alignment.center,
      padding: contentPadding ?? const EdgeInsetsDirectional.only(start: 20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      width: MediaQuery.of(context).size.width,
      height: height,
      child: TextField(
        enabled: !disabled,
        obscureText: hideText ?? false,
        keyboardType: keyboardType,
        controller: textEditingController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: UiUtils.textFieldFontSize,
        ),
        maxLines: maxLines,
        inputFormatters: textInputFormatter,
        decoration: InputDecoration(
          suffixIcon: suffix,
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintTextColor,
            fontSize: UiUtils.textFieldFontSize,
          ),
          border: InputBorder.none,
        ),
        maxLength: maxlength,
      ),
    );
  }
}
