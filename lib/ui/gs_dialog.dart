import 'package:flutter/material.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';

/// Alert dialog matching the prototype: surface card, 22 px radius, condensed
/// title and a compact right-aligned action row.
///
/// Drop-in replacement for [AlertDialog]; keep passing Text title/content and
/// the existing action buttons.
class GsAlertDialog extends StatelessWidget {
  const GsAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.insetPadding,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Dialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: insetPadding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: tokens.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (title != null)
                DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: GsFont.display,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: tokens.bone,
                  ),
                  child: title!,
                ),
              if (title != null && content != null) const SizedBox(height: 10),
              if (content != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxContentHeight),
                  child: SingleChildScrollView(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: GsFont.body,
                        fontSize: 13,
                        height: 1.5,
                        color: tokens.muted,
                      ),
                      child: content!,
                    ),
                  ),
                ),
              if (actions != null && actions!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple list dialog matching [GsAlertDialog].
class GsSimpleDialog extends StatelessWidget {
  const GsSimpleDialog({
    super.key,
    this.title,
    required this.children,
  });

  final Widget? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GsAlertDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Rounded option row for [GsSimpleDialog].
class GsDialogOption extends StatelessWidget {
  const GsDialogOption({
    super.key,
    this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: GsFont.body,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: tokens.bone,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
