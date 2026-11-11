import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'dashboard.dart';
import 'firebase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await startFirebase();
    runApp(const InventoryApp());
  } catch (error) {
    runApp(InventoryApp(startupError: error));
  }
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key, this.startupError});
  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kho Sản Phẩm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: accent, primary: accent),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffd4dfd8)),
          ),
        ),
      ),
      home: startupError != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không thể khởi tạo Firebase.\n$startupError',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        return user == null
            ? const LoginPage()
            : AdminGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class AdminGate extends StatefulWidget {
  const AdminGate({super.key, required this.user});
  final User user;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late Future<IdTokenResult> _token = widget.user.getIdTokenResult();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
      future: _token,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data?.claims?['admin'] == true) {
          return Dashboard(email: widget.user.email ?? '');
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 38),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.hasError
                        ? 'Không thể kiểm tra quyền quản trị.'
                        : 'Tài khoản chưa có quyền quản trị.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(
                      () => _token = widget.user.getIdTokenResult(true),
                    ),
                    child: const Text('Kiểm tra lại'),
                  ),
                  TextButton(
                    onPressed: FirebaseAuth.instance.signOut,
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.code) {
          'wrong-password' ||
          'user-not-found' ||
          'invalid-credential' ||
          'invalid-login-credentials' => 'Email hoặc mật khẩu chưa đúng.',
          'network-request-failed' =>
            'Không thể kết nối Firebase. Hãy kiểm tra dịch vụ và thử lại.',
          'too-many-requests' =>
            'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
          _ => 'Đăng nhập thất bại (${error.code}).',
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể đăng nhập. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: Row(
        children: [
          if (wide)
            Expanded(
              child: Container(
                color: ink,
                padding: const EdgeInsets.all(54),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Brand(light: true),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xff25463b),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xffd7f38c),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Quản lý\nsản phẩm',
                      style: TextStyle(
                        fontSize: 54,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Danh mục, hình ảnh và số lượng tồn kho',
                      style: TextStyle(color: Color(0xffbed6ca)),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: AutofillGroup(
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!wide)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Brand(),
                            ),
                          if (!wide) const SizedBox(height: 32),
                          const Text(
                            'Đăng nhập quản trị',
                            style: TextStyle(
                              fontSize: 32,
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sử dụng tài khoản quản trị để truy cập kho.',
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) =>
                                (value ?? '').trim().contains('@')
                                ? null
                                : 'Nhập email hợp lệ.',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: _hidden,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _hidden
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () =>
                                    setState(() => _hidden = !_hidden),
                                icon: Icon(
                                  _hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                (value ?? '').isEmpty ? 'Nhập mật khẩu.' : null,
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 22),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: _busy ? null : _login,
                            child: Text(
                              _busy ? 'Đang đăng nhập…' : 'Đăng nhập',
                            ),
                          ),
                          if (useEmulators) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      _email.text = 'admin@kho.local';
                                      _password.text = 'KhoDemo2026!';
                                    },
                              child: const Text('Điền tài khoản demo'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
