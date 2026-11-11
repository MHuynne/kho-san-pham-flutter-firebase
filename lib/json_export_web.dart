import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> deliverJson(String json) async {
  final blob = web.Blob(
    [json.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = 'products.json';
  web.document.body?.append(link);
  link.click();
  link.remove();
  Future<void>.delayed(
    const Duration(seconds: 1),
    () => web.URL.revokeObjectURL(url),
  );
  return 'Đã xuất products.json.';
}
