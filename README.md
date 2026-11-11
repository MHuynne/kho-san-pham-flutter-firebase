# Kho Sản Phẩm

Ứng dụng quản trị danh mục và tồn kho bằng Flutter Web và Android. Firebase Authentication xác thực tài khoản email/mật khẩu. Cloud Firestore lưu và đồng bộ danh mục sản phẩm.

- [Mã nguồn GitHub](https://github.com/MHuynne/kho-san-pham-flutter-firebase)
- [Video demo và APK Android](https://github.com/MHuynne/kho-san-pham-flutter-firebase/releases/tag/v1.0.0)
- [Báo cáo Word](nop-bai/bao-cao.docx)
- [Tệp cơ sở dữ liệu JSON](nop-bai/products.json)

## Chạy thử với Firebase Emulator

Cần Flutter 3.44 / Dart 3.12, Node.js, Java 21, Chrome và Android SDK nếu chạy Android. Trên Windows, dùng đường dẫn ASCII, ví dụ `D:\dev\kho-san-pham`, để Gradle và Firestore Emulator đọc đúng tên thư mục.

```sh
flutter pub get
npm install -g firebase-tools
firebase emulators:start --project demo-kho-san-pham --only auth,firestore
```

Giữ terminal trên mở. Mở terminal thứ hai từ cùng thư mục để nạp dữ liệu và chạy web.

```sh
node scripts/seed.mjs
flutter run -d chrome --web-port 5173
```

Ở màn hình đăng nhập, chọn **Điền tài khoản demo** rồi chọn **Đăng nhập**. Tài khoản emulator là `admin@kho.local` với mật khẩu `KhoDemo2026!`. Firebase Emulator UI ở [cổng 4000](http://127.0.0.1:4000/firestore/default/data/products). Dữ liệu mặc định nằm trong phiên emulator. Có thể lưu giữa các lần chạy bằng `--import=./emulator-data --export-on-exit` sau khi đã tạo bản xuất ban đầu bằng `firebase emulators:export ./emulator-data --project demo-kho-san-pham`.

Khởi động Android Emulator trong Android Studio rồi chọn thiết bị từ `flutter devices`.

```sh
flutter run -d emulator-5554
flutter build apk --debug
```

APK demo truy cập Firebase Emulator trên máy tính qua `10.0.2.2`. Với máy Android thật nối USB, có thể ánh xạ hai cổng bằng `adb reverse tcp:9099 tcp:9099` và `adb reverse tcp:8080 tcp:8080`, rồi chạy hoặc build debug với `--dart-define=EMULATOR_HOST=127.0.0.1`. Bản Android có thể chọn ảnh từ thư viện hoặc chụp bằng camera.

## Chức năng và dữ liệu

- Đăng nhập và đăng xuất bằng Firebase Authentication. Màn hình quản trị và các thao tác Firestore yêu cầu claim `admin: true`.
- Thêm, hiển thị, sửa và xóa sản phẩm với xác nhận. Danh mục tự cập nhật từ Firestore.
- Tìm theo tên, lọc theo tồn kho, sắp xếp theo tên, giá hoặc số lượng.
- Xem trước ảnh khi thêm hoặc sửa. Ảnh JPG, PNG hoặc WebP được nén thành JPEG trước khi ghi.
- **Xuất JSON** đọc toàn bộ danh mục hiện hành từ Firestore. Trên web nút này tải `products.json`. Trên Android nút sao chép JSON.

Mỗi tài liệu trong collection `products` chứa đúng bốn trường.

| Trường | Kiểu Firestore | Nội dung |
|---|---|---|
| `name` | string | Tên từ 1 đến 120 ký tự |
| `price` | integer | Giá nguyên theo VND |
| `soluong` | integer | Số lượng tồn |
| `image` | string | JPEG dưới dạng URI dữ liệu Base64 |

ID nằm trong đường dẫn tài liệu. Tệp JSON có thể mang theo ảnh khi mở ở môi trường khác. Ứng dụng thu ảnh về cạnh dài tối đa 960 px và chặn URI dài hơn 700.000 ký tự. Firestore Rules kiểm tra quyền và các trường phía máy chủ. Firestore Indexes tắt lập chỉ mục cho nội dung ảnh.

## Kết nối Firebase Cloud

1. Tạo dự án Firebase và đăng ký ứng dụng web và ứng dụng Android `vn.edu.demo.kho_san_pham`. Bật Email/Password trong Authentication, tạo tài khoản quản trị và tạo Cloud Firestore.
2. Dùng thông tin SDK của từng ứng dụng để tạo `firebase.env.web.json` và `firebase.env.android.json` theo mẫu `firebase.env.example.json`. Mỗi nền tảng dùng App ID của ứng dụng tương ứng.
3. Đăng nhập Firebase CLI và triển khai quy tắc, chỉ mục. Dùng Google Application Default Credentials của người có quyền quản lý người dùng Firebase Authentication để chạy tập lệnh cấp claim. Tài khoản đăng nhập lại sau khi được cấp quyền.

```sh
firebase login
firebase deploy --only firestore --project YOUR_PROJECT_ID
npm install --prefix scripts
gcloud auth application-default login
node scripts/grant-admin.mjs YOUR_PROJECT_ID admin@example.com
```

4. Chạy thử và build bằng cấu hình của nền tảng tương ứng. Nếu dùng Firebase Hosting, triển khai từ bản build web dùng cấu hình cloud.

```sh
flutter run -d chrome --dart-define-from-file=firebase.env.web.json
flutter build web --dart-define-from-file=firebase.env.web.json
firebase deploy --only hosting --project YOUR_PROJECT_ID
flutter build apk --dart-define-from-file=firebase.env.android.json
```

## Kiểm tra dự án

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Các thư viện chính được cài bằng `flutter pub add firebase_core firebase_auth cloud_firestore image_picker image web`. Phiên bản đã giải quyết nằm trong `pubspec.lock`.

Tài liệu kỹ thuật [FlutterFire](https://firebase.google.com/docs/flutter/setup), [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure), [Firebase custom claims](https://firebase.google.com/docs/auth/admin/custom-claims) và [giới hạn Cloud Firestore](https://firebase.google.com/docs/firestore/quotas).

Ảnh minh họa từ Unsplash: [bàn phím](https://images.unsplash.com/photo-1541140532154-b024d705b90a), [chuột](https://images.unsplash.com/photo-1527814050087-3793815479db), [đồng hồ](https://images.unsplash.com/photo-1523275335684-37898b6baf30), [loa](https://images.unsplash.com/photo-1608043152269-423dbba4e7e1), [máy ảnh](https://images.unsplash.com/photo-1516035069371-29a1b244cc32) và [tai nghe](https://images.unsplash.com/photo-1505740420928-5e560c06d30e). Phông Inter dùng [SIL Open Font License](assets/fonts/OFL.txt).
