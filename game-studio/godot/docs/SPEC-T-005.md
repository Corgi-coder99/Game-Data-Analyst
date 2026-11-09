# Spec T-005: Giao diện game Data Corp (bản demo 10 tuần)

Owner: Codex. Người review: Claude. Nguồn: `docs/GDD.md` (mục 2, 3, 9, 11) và lõi mô phỏng đã merge ở T-004 (`scripts/sim/simulation.gd`).

## Phạm vi

Giao diện chơi được trên nền lõi mô phỏng có sẵn: đọc dashboard, đọc sự kiện, chơi thẻ, kết thúc tuần, màn thắng/thua. Không đổi logic trong `scripts/sim/` (cần đổi thì tạo việc mới). Không làm lưu tiến trình, bảng xếp hạng, menu cài đặt phức tạp.

## Nguyên tắc dữ liệu (quan trọng)

Giao diện **chỉ** được lấy số từ:
- `report()`: chỉ số có nhiễu theo Data Integrity.
- `event_reports()`: triệu chứng, và `root_cause` chỉ khi đã được lộ.
- `hand`, `state.energy`, `state.week`, `state.lost`, `state.won`, `score()`.

Không được đọc `state.base` hay `state.value()` để hiển thị chỉ số trong ván, vì đó là số thật, đọc vào sẽ làm mất cơ chế "dữ liệu có thể sai". Riêng màn kết thúc được hiện số thật. Cash hiển thị lấy từ `report()` giống các chỉ số khác (cho phép hiện số nhiễu). Nếu thấy cần Cash chính xác để chơi công bằng, ghi vào ghi chú bàn giao để Claude quyết, không tự đổi.

## Màn hình và luồng

1. **Màn tiêu đề:** tên game, nút Chơi, nút Thoát.
2. **Màn chơi (một màn duy nhất, bố cục dưới đây).** Vòng mỗi tuần: `begin_week()` → người chơi chơi thẻ bằng `play(card_id)` → nút "Kết thúc tuần" gọi `finish_week()` → hiện bảng kết quả tuần → tuần kế tiếp.
3. **Màn kết thúc:** thắng hoặc thua, điểm, số sự kiện xử lý đúng, và bảng "sự thật": chỉ số thật so với chỉ số đã thấy trên dashboard. Nút Chơi lại, nút về tiêu đề.

Bản demo dùng `weeks = 10` (`config.weeks.demo`).

## Bố cục màn chơi (viewport 640x360)

```
+--------------------------------------------------------------+
| Tuần 3/10   Cash 8,420   Energy ●●○        [Kết thúc tuần]   |
+-------------------------------+------------------------------+
| Users  Retention  Conv.  CAC  |  SỰ KIỆN                     |
| ARPU   LTV/CAC    Integrity   |  - triệu chứng (mỗi sự kiện) |
|                               |  - nguyên nhân (nếu đã lộ)   |
|  [Biểu đồ đường: 1 chỉ số,    |                              |
|   chọn bằng nhãn bên trên]    |  Nhật ký tuần trước          |
+-------------------------------+------------------------------+
| [Thẻ 1] [Thẻ 2] [Thẻ 3] [Thẻ 4]                              |
+--------------------------------------------------------------+
```

- Hàng đầu: tuần, Cash, Energy (chấm tròn), nút kết thúc tuần.
- Khối trái: 7 ô chỉ số (Users, Retention, Conversion, CAC, ARPU, LTV/CAC, Data Integrity) và 1 biểu đồ đường. Bấm vào một ô chỉ số thì biểu đồ đổi sang chỉ số đó. Mỗi ô có mũi tên lên/xuống so với tuần trước.
- Khối phải: danh sách sự kiện đang hoạt động (triệu chứng luôn hiện, nguyên nhân chỉ hiện khi đã lộ) và nhật ký kết quả tuần trước (người dùng mới, mất đi, doanh thu, chi phí).
- Hàng dưới: tối đa 4 thẻ trong tay. Mỗi thẻ hiện tên, nhóm (màu viền theo nhóm), Budget, Energy, mô tả hiệu ứng ngắn. Thẻ không đủ Budget hoặc Energy thì làm mờ và không bấm được. Di chuột (hoặc chạm giữ) hiện chi tiết.
- Biểu đồ vẽ bằng `_draw()` hoặc `Line2D` trong Godot, không dùng ảnh ngoài. Không có ảnh funnel ở bản này (xem mục "Ngoài phạm vi").

## Hành vi cụ thể

- Chơi thẻ thành công thì thẻ biến khỏi tay, Energy và Cash cập nhật ngay, có hiệu ứng ngắn (dưới 0,3 giây).
- `play()` trả `false` thì hiện lý do (thiếu Budget hay Energy), không đổi trạng thái.
- Data Integrity thấp thì giá trị trên ô chỉ số nhấp nháy nhẹ hoặc có dấu "?" kèm cảnh báo, để người chơi biết số có thể sai. Ngưỡng hiện dấu "?" là Integrity dưới 60 (đặt trong một hằng số có tên).
- Khi `state.lost` hoặc `state.won` thì chuyển màn kết thúc.
- Hỗ trợ chuột và bàn phím (phím 1 đến 4 chơi thẻ, Enter kết thúc tuần).

## Giao diện và mỹ thuật

- Viewport 640x360, scale nguyên, nearest filter (đã có trong `project.godot`, không sửa).
- `shared/style-bible` chưa tồn tại. Tạm thời dùng một `Theme` Godot duy nhất (`assets/theme/main_theme.tres`) với bảng màu tối tối đa 16 màu, khai báo tập trung ở một file `scripts/ui/palette.gd`. Khi style bible có, chỉ cần sửa file này.
- Font: dùng font có giấy phép rõ ràng (ví dụ font OFL đi kèm Godot hoặc font tải về kèm file giấy phép trong `assets/fonts/`). Ghi nguồn và giấy phép vào `assets/CREDITS.md`.
- Không dùng hình ảnh, biểu tượng hay âm thanh có bản quyền chưa rõ. Chưa cần âm thanh ở bản này.
- Văn bản tiếng Việt, phải hiển thị đúng dấu.

## Cấu trúc mã

- `scenes/title.tscn`, `scenes/game.tscn`, `scenes/end.tscn` (cập nhật `run/main_scene` trong `project.godot` sang `title.tscn`: đây là ngoại lệ được phép sửa đúng dòng này).
- `scripts/ui/`: một script cho mỗi phần (HUD, ô chỉ số, biểu đồ, thẻ, danh sách sự kiện, màn kết thúc). Tách logic hiển thị khỏi lõi mô phỏng, giao diện chỉ gọi API công khai của `simulation.gd`.
- Chuỗi văn bản hiển thị đặt trong `data/strings.json`, không viết cứng trong mã.

## File được sửa

`game-studio/godot/scenes/*`, `game-studio/godot/scripts/ui/*`, `game-studio/godot/assets/*`, `game-studio/godot/data/strings.json`, `game-studio/godot/tests/test_ui.gd`, và một dòng `run/main_scene` trong `game-studio/godot/project.godot`. Không sửa `scripts/sim/`, `data/config.json`, `data/cards.json`, `data/events.json`.

## Kiểm thử và tiêu chí hoàn thành

1. `tests/test_ui.gd` chạy headless: nạp từng scene không lỗi, giả lập một ván 10 tuần bằng cách gọi hàm chơi thẻ và kết thúc tuần của giao diện, kiểm tra không có lỗi script và màn kết thúc hiện đúng với trạng thái thắng/thua.
2. Chạy lại `test_sim.gd` và `balance_sim.gd`, kết quả không đổi so với T-004 (118 kiểm tra qua, cân bằng giống cũ).
3. Chụp ảnh màn hình mỗi màn (tiêu đề, giữa ván, thắng, thua) lưu vào `assets/screenshots/`. Dùng skill `game-development` hoặc cờ chạy Godot có cửa sổ để chụp. Claude sẽ xem ảnh khi review.
4. Kiểm tra bằng mắt: không chữ bị cắt hay chồng, dấu tiếng Việt đúng, thẻ mờ khi không đủ tiền hoặc Energy.
5. Ghi chú bàn giao trong TASKS.md theo mẫu, nêu rõ chỗ nào đã tự quyết và chỗ nào cần Claude quyết.

## Ngoài phạm vi

Biểu đồ funnel và cohort riêng (thẻ SQL Deep-Dive và Funnel Report hiện chỉ lộ nguyên nhân bằng văn bản), âm thanh, hoạt ảnh phức tạp, lưu tiến trình, bảng xếp hạng, xuất bản web/Windows.
