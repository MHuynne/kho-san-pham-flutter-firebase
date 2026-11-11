import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

const int maxImageLength = 700000;
const int maxPrice = 999999999999;
const int maxQuantity = 999999999;

class Product {
  const Product(this.id, this.name, this.price, this.quantity, this.image);

  factory Product.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Product(
      doc.id,
      data['name'] as String,
      data['price'] as int,
      data['soluong'] as int,
      data['image'] as String,
    );
  }

  final String id;
  final String name;
  final int price;
  final int quantity;
  final String image;

  Map<String, Object> toJson() => {
    'name': name,
    'price': price,
    'soluong': quantity,
    'image': image,
  };
}

class Catalog {
  final _products = FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> watch() => _products
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Product.fromDocument).toList());

  Future<void> save(Product product) async {
    if (product.id.isEmpty) {
      await _products.add(product.toJson());
    } else {
      await _products.doc(product.id).update(product.toJson());
    }
  }

  Future<void> delete(String id) => _products.doc(id).delete();

  Future<String> exportJson() async {
    final snapshot = await _products
        .orderBy('name')
        .get(const GetOptions(source: Source.server));
    return const JsonEncoder.withIndent('  ').convert(
      snapshot.docs.map((doc) => Product.fromDocument(doc).toJson()).toList(),
    );
  }
}

String prepareImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Định dạng ảnh không hỗ trợ.');
  }
  var resized = img.bakeOrientation(decoded);
  final side = resized.width > resized.height ? resized.width : resized.height;
  if (side > 960) {
    resized = img.copyResize(
      resized,
      width: resized.width >= resized.height ? 960 : null,
      height: resized.width < resized.height ? 960 : null,
    );
  }
  for (final quality in [82, 65, 48, 32]) {
    final uri =
        'data:image/jpeg;base64,${base64Encode(img.encodeJpg(resized, quality: quality))}';
    if (uri.length <= maxImageLength) return uri;
  }
  throw const FormatException(
    'Ảnh vượt giới hạn lưu trữ. Hãy chọn ảnh nhỏ hơn.',
  );
}

String number(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

class ProductPhoto extends StatefulWidget {
  const ProductPhoto(this.source, {super.key});
  final String source;

  @override
  State<ProductPhoto> createState() => _ProductPhotoState();
}

class _ProductPhotoState extends State<ProductPhoto> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant ProductPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _decode();
  }

  void _decode() {
    try {
      _bytes = UriData.parse(widget.source).contentAsBytes();
    } on FormatException {
      _bytes = null;
    }
  }

  Widget _placeholder() => const ColoredBox(
    color: Color(0xffe7eeea),
    child: Center(
      child: Icon(Icons.image_outlined, size: 36, color: Color(0xff507569)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return _placeholder();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }
}
