import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'catalog.dart';

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, required this.catalog, this.product});
  final Catalog catalog;
  final Product? product;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late final _quantity = TextEditingController(
    text: widget.product?.quantity.toString(),
  );
  late String? _image = widget.product?.image;
  bool _saving = false;
  bool _picking = false;
  String? _imageError;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _picking = true;
      _imageError = null;
    });
    try {
      final photo = await ImagePicker().pickImage(source: source);
      if (photo == null) return;
      if (await photo.length() > 12 * 1024 * 1024) {
        throw const FormatException('Ảnh nguồn tối đa 12 MB.');
      }
      final uri = await compute(prepareImage, await photo.readAsBytes());
      if (mounted) setState(() => _image = uri);
    } on FormatException catch (error) {
      if (mounted) setState(() => _imageError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _imageError =
              'Không thể mở ảnh. Hãy chọn ảnh JPG, PNG hoặc WebP.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _validateNumber(String? value, int maximum) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 0 || parsed > maximum
        ? 'Nhập số nguyên từ 0 đến ${number(maximum)}.'
        : null;
  }

  Future<void> _save() async {
    final fieldsValid = _form.currentState!.validate();
    final image = _image;
    if (image == null) setState(() => _imageError = 'Hãy chọn ảnh sản phẩm.');
    if (!fieldsValid || image == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.catalog.save(
        Product(
          widget.product?.id ?? '',
          _name.text.trim(),
          int.parse(_price.text),
          int.parse(_quantity.text),
          image,
        ),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Không thể lưu vào Firestore. Hãy kiểm tra kết nối và quyền quản trị.';
      });
    }
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    int maximum,
  ) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) => _validateNumber(value, maximum),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _picking;
    final hasCamera =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
        content: SizedBox(
          width: 430,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final name = (value ?? '').trim();
                      if (name.isEmpty) return 'Nhập tên sản phẩm.';
                      return name.length > 120 ? 'Tên tối đa 120 ký tự.' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _numberField(_price, 'Giá (₫)', maxPrice),
                  const SizedBox(height: 12),
                  _numberField(_quantity, 'Số lượng', maxQuantity),
                  const SizedBox(height: 16),
                  const Text(
                    'Hình ảnh sản phẩm',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_image != null)
                    SizedBox(
                      height: 125,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ProductPhoto(_image!),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(_picking ? 'Đang xử lý…' : 'Chọn ảnh'),
                      ),
                      if (hasCamera)
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => _pick(ImageSource.camera),
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                          ),
                          label: const Text('Chụp ảnh'),
                        ),
                    ],
                  ),
                  if (_imageError != null)
                    Text(
                      _imageError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_saveError != null)
                    Text(
                      _saveError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(_saving ? 'Đang lưu…' : 'Lưu sản phẩm'),
          ),
        ],
      ),
    );
  }
}
