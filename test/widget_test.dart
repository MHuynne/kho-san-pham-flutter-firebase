import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kho_san_pham/main.dart';
import 'package:kho_san_pham/firebase_config.dart';

void main() {
  testWidgets('Hiển thị form đăng nhập và kiểm tra thông tin rỗng', (
    tester,
  ) async {
    await tester.pumpWidget(const InventoryLoginHarness());
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();
    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(find.text('Nhập mật khẩu.'), findsOneWidget);
  });

  testWidgets('Có thể điền tài khoản demo từ form đăng nhập', (tester) async {
    await tester.pumpWidget(const InventoryLoginHarness());
    if (useEmulators) {
      await tester.tap(find.text('Điền tài khoản demo'));
      await tester.pump();
      expect(find.text('admin@kho.local'), findsOneWidget);
    }
  });
}

class InventoryLoginHarness extends StatelessWidget {
  const InventoryLoginHarness({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: LoginPage());
}
