import 'package:flutter/services.dart';

Future<String> deliverJson(String json) async {
  await Clipboard.setData(ClipboardData(text: json));
  return 'Đã sao chép dữ liệu JSON.';
}
