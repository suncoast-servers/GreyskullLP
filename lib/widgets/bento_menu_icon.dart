import 'package:flutter/material.dart';

/// 2×3 bento grid — main menu affordance (not a back arrow).
class BentoMenuIcon extends StatelessWidget {
  const BentoMenuIcon({super.key, this.size = 22, this.gap = 2.5});

  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final cell = (size - gap) / 2;
    final color = IconTheme.of(context).color ?? Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (_) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(2, (_) {
              return Container(
                width: cell,
                height: (size - gap * 2) / 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
