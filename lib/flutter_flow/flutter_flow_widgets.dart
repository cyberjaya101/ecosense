import 'package:flutter/material.dart';

class FFButtonOptions {
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry iconPadding;
  final Color? iconColor;
  final Color? color;
  final TextStyle? textStyle;
  final double elevation;
  final BorderSide? borderSide;
  final BorderRadius? borderRadius;

  const FFButtonOptions({
    this.width = 130,
    this.height = 40,
    this.padding = EdgeInsets.zero,
    this.iconPadding = EdgeInsets.zero,
    this.iconColor,
    this.color,
    this.textStyle,
    this.elevation = 2,
    this.borderSide,
    this.borderRadius,
  });
}

class FFButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Icon? icon;
  final FFButtonOptions options;

  const FFButtonWidget({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(options.width, options.height),
        padding: options.padding,
        backgroundColor: options.color,
        elevation: options.elevation,
        side: options.borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: options.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
                data: IconThemeData(color: options.iconColor), child: icon!),
            const SizedBox(width: 8),
          ],
          Text(text, style: options.textStyle),
        ],
      ),
    );
  }
}
