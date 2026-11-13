# Checklist trước khi phát hành (T-042)

- [ ] Export Web và Windows chạy được (chạy thử bản export, không chỉ trong editor).
- [ ] Web: cần cross-origin isolation? (chỉ nếu bật thread; mặc định tắt) — kiểm tra trên itch.io bật "SharedArrayBuffer" nếu cần.
- [ ] Màn đồng ý hiện ở lần chạy đầu, mặc định No; chọn No thì không có thư mục telemetry.
- [ ] Settings: Export play data / Delete my data hoạt động trong bản export (user:// trên Web là IndexedDB: kiểm tra đường dẫn hiển thị).
- [ ] Không có file test, ảnh nháp, khóa hay đường dẫn máy trong gói.
- [ ] Ảnh chụp màn hình mới từ bản build.
- [ ] Mô tả khớp tính năng thật; có ghi 16+ và nội dung AI.
- [ ] VU duyệt cuối cùng.
