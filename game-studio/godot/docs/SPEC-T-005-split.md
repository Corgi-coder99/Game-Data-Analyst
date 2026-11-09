# T-005 chia nhỏ: a, b, c

Spec gốc: `SPEC-T-005.md` (bố cục, nguyên tắc dữ liệu, mỹ thuật, ngoài phạm vi vẫn áp dụng). File này chỉ chia việc thành 3 phần làm lần lượt. Mỗi phần giao riêng, xong và được duyệt mới giao phần sau.

Thay đổi so với spec gốc: **Codex không phải chụp ảnh màn hình.** Claude tự chụp khi review. Mục 3 trong "Kiểm thử và tiêu chí hoàn thành" của spec gốc bị bỏ.

Quy tắc chung cho cả 3 phần: giao diện chỉ hiển thị số từ `report()` và `event_reports()`; không sửa `scripts/sim/`, `data/config.json`, `data/cards.json`, `data/events.json`; mọi chuỗi hiển thị nằm trong `data/strings.json`; không push, không merge.

## T-005a: khung và vòng tuần

Mục tiêu: chơi được một ván từ đầu đến cuối bằng giao diện tối thiểu (chưa đẹp), chưa có biểu đồ.

- `scenes/title.tscn`: tên game, nút Chơi, nút Thoát.
- `scenes/game.tscn`: thanh trên cùng (tuần, Cash, Energy, nút Kết thúc tuần), hàng thẻ trong tay (tên, Budget, Energy, bấm để chơi; mờ nếu không đủ), một nhãn văn bản liệt kê 7 chỉ số từ `report()`. Chưa cần ô chỉ số hay biểu đồ.
- `scripts/ui/game_controller.gd`: điều khiển vòng `begin_week()` → `play()` → `finish_week()`, chuyển sang màn kết thúc tạm (một nhãn Thắng/Thua kèm điểm) khi `lost` hoặc `won`.
- `scripts/ui/palette.gd`, `assets/theme/main_theme.tres`, `data/strings.json`.
- Sửa đúng dòng `run/main_scene` trong `project.godot` thành `res://scenes/title.tscn`.
- `tests/test_ui.gd`: nạp scene không lỗi, tự chơi đủ 10 tuần qua hàm của controller (không cần chuột), kiểm tra chuyển được sang kết thúc.

File được sửa: `scenes/title.tscn`, `scenes/game.tscn`, `scripts/ui/*`, `assets/theme/*`, `data/strings.json`, `tests/test_ui.gd`, dòng `run/main_scene` trong `project.godot`.

Hoàn thành: `test_ui.gd` qua; `test_sim.gd` (118 kiểm tra) và `balance_sim.gd` (balanced thắng 40,85%) không đổi.

## T-005b: dashboard đầy đủ

Mục tiêu: thay nhãn văn bản bằng dashboard theo bố cục spec gốc.

- 7 ô chỉ số có mũi tên so với tuần trước; bấm ô thì biểu đồ đổi chỉ số; dấu "?" khi Integrity dưới 60 (hằng số có tên).
- Biểu đồ đường vẽ bằng `_draw()`, lưu lịch sử các lần `report()`.
- Danh sách sự kiện (triệu chứng luôn hiện, nguyên nhân chỉ khi đã lộ) và nhật ký tuần trước.
- Chi tiết thẻ khi di chuột, phím 1 đến 4 chơi thẻ, Enter kết thúc tuần.
- Mở rộng `tests/test_ui.gd` kiểm tra: nguyên nhân gốc không hiện khi chưa lộ, hiện sau khi chơi đúng thẻ lộ.

File được sửa: `scenes/game.tscn`, `scripts/ui/*`, `data/strings.json`, `tests/test_ui.gd`.

## T-005c: màn kết thúc và hoàn thiện

- `scenes/end.tscn`, `scripts/ui/end_screen.gd`: thắng/thua, điểm, số sự kiện xử lý đúng, bảng "sự thật" so chỉ số thật với chỉ số đã thấy, nút Chơi lại và Về tiêu đề.
- Chỉ màn này được đọc `state.base` / `state.value()`.
- Kiểm tra hiển thị tiếng Việt, chữ không bị cắt; bổ sung `assets/CREDITS.md` nếu dùng font ngoài.
- Mở rộng `tests/test_ui.gd` cho cả hai nhánh thắng và thua.
- Bổ sung vào biểu đồ (`scripts/ui/metric_chart.gd`): nhãn trục dọc (giá trị nhỏ nhất, lớn nhất) và nhãn trục ngang (số tuần). Khi mới có 1 điểm dữ liệu thì hiện điểm kèm nhãn, không để trống.

File được sửa: `scenes/end.tscn`, `scenes/game.tscn` (chỉ phần chuyển màn), `scripts/ui/*`, `data/strings.json`, `assets/CREDITS.md`, `tests/test_ui.gd`.
