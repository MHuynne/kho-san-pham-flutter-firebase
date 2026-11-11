import 'package:flutter/material.dart';

const ink = Color(0xff172e29);
const accent = Color(0xff17644d);
const background = Color(0xfff4f7f4);

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: light ? const Color(0xffd7f38c) : accent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: light ? ink : Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          'Kho Sản Phẩm',
          style: TextStyle(
            color: light ? Colors.white : ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
