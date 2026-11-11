import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'catalog.dart';
import 'firebase_config.dart';
import 'json_export.dart';
import 'app_theme.dart';
import 'product_editor.dart';

enum StockFilter { all, inStock, outOfStock }

enum ProductSort { name, priceAscending, priceDescending, quantity }

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.email});
  final String email;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _catalog = Catalog();
  final _search = TextEditingController();
  late Stream<List<Product>> _stream = _catalog.watch();
  String _query = '';
  StockFilter _filter = StockFilter.all;
  ProductSort _sort = ProductSort.name;
  bool _exporting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _edit([Product? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductEditor(catalog: _catalog, product: product),
    );
    if (saved == true) {
      _notify(product == null ? 'Đã thêm sản phẩm.' : 'Đã cập nhật sản phẩm.');
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có muốn xóa “${product.name}” khỏi kho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa sản phẩm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _catalog.delete(product.id);
      _notify('Đã xóa sản phẩm.');
    } catch (_) {
      _notify('Không thể xóa sản phẩm. Vui lòng thử lại.');
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      _notify(await deliverJson(await _catalog.exportJson()));
    } catch (_) {
      _notify('Không thể xuất dữ liệu từ Firestore. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      _notify('Không thể đăng xuất. Vui lòng thử lại.');
    }
  }

  List<Product> _visible(List<Product> products) {
    final result = products.where((product) {
      final matchesFilter = switch (_filter) {
        StockFilter.all => true,
        StockFilter.inStock => product.quantity > 0,
        StockFilter.outOfStock => product.quantity == 0,
      };
      return matchesFilter && product.name.toLowerCase().contains(_query);
    }).toList();
    result.sort((a, b) {
      final comparison = switch (_sort) {
        ProductSort.name => 0,
        ProductSort.priceAscending => a.price.compareTo(b.price),
        ProductSort.priceDescending => b.price.compareTo(a.price),
        ProductSort.quantity => b.quantity.compareTo(a.quantity),
      };
      return comparison == 0
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : comparison;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              title: const Brand(),
              actions: [
                IconButton(
                  tooltip: 'Đăng xuất',
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                ),
                const SizedBox(width: 6),
              ],
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide) _sidebar(),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _status(
                      Icons.cloud_off_outlined,
                      'Không thể tải danh mục',
                      'Kiểm tra kết nối Firestore và quyền của tài khoản.',
                      FilledButton(
                        onPressed: () =>
                            setState(() => _stream = _catalog.watch()),
                        child: const Text('Thử lại'),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _catalogView(snapshot.data!, wide);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar() => Container(
    width: 224,
    color: ink,
    padding: const EdgeInsets.fromLTRB(18, 27, 18, 19),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: Brand(light: true),
        ),
        const SizedBox(height: 42),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff304b3f),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 18, color: Color(0xffd7f38c)),
              SizedBox(width: 11),
              Text(
                'Sản phẩm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Divider(color: Color(0xff405b51)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xffd7f38c),
            child: Icon(Icons.person_outline, size: 19, color: ink),
          ),
          title: const Text(
            'Quản trị viên',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          subtitle: Text(
            widget.email,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xffbad1c7), fontSize: 11),
          ),
        ),
        TextButton.icon(
          onPressed: _signOut,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xffd4e4dd),
            alignment: Alignment.centerLeft,
          ),
          icon: const Icon(Icons.logout, size: 17),
          label: const Text('Đăng xuất'),
        ),
      ],
    ),
  );

  Widget _catalogView(List<Product> products, bool wide) {
    final available = products.where((product) => product.quantity > 0).length;
    final quantity = products.fold<int>(
      0,
      (total, product) => total + product.quantity,
    );
    final filtered = _visible(products);
    final stats = [
      _Metric(
        label: 'Sản phẩm',
        value: products.length,
        icon: Icons.inventory_2_outlined,
      ),
      _Metric(
        label: 'Đơn vị tồn kho',
        value: quantity,
        icon: Icons.layers_outlined,
      ),
      _Metric(
        label: 'Hết hàng',
        value: products.length - available,
        icon: Icons.remove_shopping_cart_outlined,
      ),
    ];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            wide ? 36 : 16,
            wide ? 30 : 20,
            wide ? 36 : 16,
            16,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, size) {
                    final heading = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sản phẩm',
                          style: TextStyle(
                            fontSize: wide ? 37 : 30,
                            fontWeight: FontWeight.w800,
                            color: ink,
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Theo dõi danh mục và số lượng tồn kho.'),
                      ],
                    );
                    final actions = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _exporting ? null : _export,
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 19,
                          ),
                          label: Text(_exporting ? 'Đang xuất…' : 'Xuất JSON'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 43),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _edit,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Thêm sản phẩm'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 43),
                          ),
                        ),
                      ],
                    );
                    if (size.maxWidth < 670) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heading,
                          const SizedBox(height: 16),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [heading, actions],
                    );
                  },
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, size) {
                    final compact = size.maxWidth < 640;
                    return Row(
                      children: [
                        for (var i = 0; i < stats.length; i++) ...[
                          if (i != 0) SizedBox(width: compact ? 7 : 14),
                          Expanded(child: stats[i].build(compact)),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 25),
                _filters(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Danh mục sản phẩm',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ),
                    Text(
                      '${filtered.length} sản phẩm',
                      style: const TextStyle(color: Color(0xff536861)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(wide ? 36 : 16, 0, wide ? 36 : 16, 28),
          sliver: filtered.isEmpty
              ? SliverToBoxAdapter(
                  child: _status(
                    Icons.inventory_2_outlined,
                    products.isEmpty
                        ? 'Kho chưa có sản phẩm'
                        : 'Không tìm thấy sản phẩm',
                    products.isEmpty
                        ? 'Thêm sản phẩm đầu tiên vào danh mục.'
                        : 'Hãy đổi từ khóa hoặc bộ lọc.',
                    null,
                  ),
                )
              : SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 265,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _ProductCard(
                      key: ValueKey(product.id),
                      product: product,
                      edit: () => _edit(product),
                      delete: () => _delete(product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filters() => LayoutBuilder(
    builder: (context, size) {
      final search = TextField(
        controller: _search,
        decoration: InputDecoration(
          hintText: 'Tìm theo tên sản phẩm',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa từ khóa',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
        onChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
      );
      final selectors = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PopupMenuButton<StockFilter>(
            tooltip: 'Lọc tồn kho',
            initialValue: _filter,
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (_) => [
              for (final item in StockFilter.values)
                PopupMenuItem(value: item, child: Text(_stockLabel(item))),
            ],
            child: _filterControl(Icons.filter_list, _stockLabel(_filter)),
          ),
          PopupMenuButton<ProductSort>(
            tooltip: 'Sắp xếp',
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ProductSort.name, child: Text('Tên A–Z')),
              PopupMenuItem(
                value: ProductSort.priceAscending,
                child: Text('Giá tăng dần'),
              ),
              PopupMenuItem(
                value: ProductSort.priceDescending,
                child: Text('Giá giảm dần'),
              ),
              PopupMenuItem(
                value: ProductSort.quantity,
                child: Text('Tồn kho giảm dần'),
              ),
            ],
            child: _filterControl(Icons.swap_vert, switch (_sort) {
              ProductSort.name => 'Tên A–Z',
              ProductSort.priceAscending => 'Giá tăng',
              ProductSort.priceDescending => 'Giá giảm',
              ProductSort.quantity => 'Tồn kho giảm',
            }),
          ),
        ],
      );
      if (size.maxWidth < 650) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [search, const SizedBox(height: 10), selectors],
        );
      }
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          selectors,
        ],
      );
    },
  );

  String _stockLabel(StockFilter filter) => switch (filter) {
    StockFilter.all => 'Tất cả tồn kho',
    StockFilter.inStock => 'Còn hàng',
    StockFilter.outOfStock => 'Hết hàng',
  };

  Widget _filterControl(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xffd4dfd8)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 7),
        Text(label),
        const SizedBox(width: 4),
        const Icon(Icons.expand_more, size: 16),
      ],
    ),
  );

  Widget _status(IconData icon, String title, String message, Widget? action) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: accent),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              if (action != null)
                Padding(padding: const EdgeInsets.only(top: 16), child: action),
              if (useEmulators && action != null)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Firestore Emulator · cổng 8080'),
                ),
            ],
          ),
        ),
      );
}

class _Metric {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  Widget build(bool compact) => Container(
    height: compact ? 100 : 104,
    padding: EdgeInsets.all(compact ? 9 : 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffdee8e0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            if (!compact) Icon(icon, size: 19, color: accent),
            if (!compact) const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  color: const Color(0xff516860),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            number(value),
            style: TextStyle(
              fontSize: compact ? 24 : 31,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    super.key,
    required this.product,
    required this.edit,
    required this.delete,
  });
  final Product product;
  final VoidCallback edit;
  final VoidCallback delete;

  @override
  Widget build(BuildContext context) {
    final available = product.quantity > 0;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xffdee8e0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductPhoto(product.image),
                Positioned(
                  top: 11,
                  left: 11,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: available
                          ? const Color(0xffe3f5e9)
                          : const Color(0xffffeadf),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        available ? 'Còn hàng' : 'Hết hàng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: available
                              ? const Color(0xff19583e)
                              : const Color(0xff87452f),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${number(product.price)} ₫',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: accent,
                              ),
                            ),
                          ),
                          Text(
                            'Tồn ${number(product.quantity)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff536861),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sửa ${product.name}',
                      visualDensity: VisualDensity.compact,
                      onPressed: edit,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                    IconButton(
                      tooltip: 'Xóa ${product.name}',
                      visualDensity: VisualDensity.compact,
                      onPressed: delete,
                      icon: const Icon(Icons.delete_outline, size: 19),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
