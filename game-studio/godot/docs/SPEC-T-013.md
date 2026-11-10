# Spec T-013: Gợi ý thẻ xử lý khi nguyên nhân đã lộ

Owner: Codex. Người review: Claude. Nguồn: `docs/GDD.md` mục 6 (thẻ xử lý chỉ gỡ sự kiện khi nguyên nhân đã lộ), `docs/SPEC-T-005.md` (nguyên tắc dữ liệu), `docs/SPEC-T-011.md`.

## Vấn đề

Sau T-011, muốn gỡ một sự kiện người chơi phải làm hai bước: dùng thẻ phân tích để lộ nguyên nhân, rồi chơi đúng thẻ xử lý. Giao diện hiện chỉ hiện "Nguyên nhân: ..." sau khi lộ, nhưng **không nói thẻ nào xử lý được**. Người chơi mới không có cách nào học luật này ngoài đoán mò, và nếu chơi nhầm thẻ thì mất Budget mà sự kiện vẫn còn.

## Mục tiêu

Khi nguyên nhân của một sự kiện đã lộ, giao diện cho người chơi biết **thẻ nào xử lý được** và **thẻ nào trong tay xử lý được**. Khi nguyên nhân chưa lộ thì **không** hiện gì thêm (giữ nguyên câu đố triệu chứng so với nguyên nhân).

## Nguyên tắc dữ liệu (bất biến)

- Thông tin cách xử lý chỉ được lộ ra cùng lúc với `root_cause`, tức chỉ khi `event.revealed == true`. Không bao giờ có trong `event_reports()` hay giao diện trước đó.
- Giao diện vẫn chỉ dùng số từ `report()` và thông tin từ `event_reports()`, không đọc `state.base`, `state.value()` hay `active_events` trực tiếp.
- Không đổi hành vi mô phỏng: kết quả `balance_sim.gd` phải **giống hệt** trước khi làm (tỷ lệ thắng từng chiến lược, ở cả 10 và 30 tuần, đến từng chữ số in ra).

## Thay đổi mô phỏng được phép (duy nhất)

Trong `scripts/sim/simulation.gd`, hàm `event_reports()`: khi `event.revealed` là true, thêm khóa `remedies` vào phần tử trả về, là mảng `id` thẻ lấy từ `event.definition.resolved_by` (giữ đúng thứ tự trong dữ liệu). Khi chưa lộ, **không có** khóa `remedies` (không để mảng rỗng, không để `null`). Không đổi gì khác trong `scripts/sim/`. Chiến lược `analyst` và các bot khác phải cho kết quả y hệt (nếu bot đang đọc `event_reports()` thì đảm bảo khóa mới không ảnh hưởng quyết định).

## Hành vi giao diện

1. **Danh sách sự kiện (khối phải):** với sự kiện đã lộ, dòng nguyên nhân kèm dòng "Cách xử lý: <tên thẻ>, <tên thẻ>". Tên thẻ lấy từ `data/strings.json` (`cards`). Thẻ nào đang có trong tay thì thêm nhãn "(trong tay)". Sự kiện chưa lộ: chỉ hiện triệu chứng như hiện nay.
2. **Thẻ trong tay:** thẻ là cách xử lý của ít nhất một sự kiện đang hoạt động đã lộ thì có dấu hiệu phân biệt rõ (viền hoặc nền nổi hơn viền nhóm) và thêm một dòng ngắn "Xử lý: <nguyên nhân>" (nếu xử lý được nhiều sự kiện thì ghi nguyên nhân đầu tiên và thêm "+N"). Dấu hiệu này không được làm thẻ khác trông bị khóa, và không thay trạng thái mờ khi thiếu Budget hoặc Energy.
3. Thẻ xử lý đã có trong tay nhưng chưa có nguyên nhân lộ: **không** đánh dấu gì.
4. Khi sự kiện hết hạn hoặc đã được gỡ thì gợi ý biến mất ngay ở lần làm mới kế tiếp.
5. Bố cục 640x360 không được tràn hay cắt chữ khi có tới 3 sự kiện cùng lúc đã lộ (cho phép rút gọn dòng, ưu tiên hiện đủ tên nguyên nhân và ít nhất tên thẻ đầu tiên).
6. Chuỗi hiển thị mới đặt trong `data/strings.json`, tiếng Việt đúng dấu.

## Kiểm thử

`tests/test_sim.gd` (thêm):
- Trước khi lộ: phần tử của `event_reports()` có `symptom`, không có `root_cause`, không có `remedies`.
- Sau khi chơi đúng thẻ lộ: có đủ `root_cause` và `remedies`, `remedies` bằng đúng `resolved_by` của sự kiện, theo thứ tự dữ liệu.
- Quét tất cả 8 sự kiện (ép sự kiện qua API công khai hoặc fixture): mỗi cái đúng hai điều trên.
- Tái lập theo seed: cùng seed cho cùng kết quả (khóa mới không đổi diễn biến).

`tests/test_ui.gd` (thêm, giữ nguyên 106 kiểm tra cũ):
- Chưa lộ: không có chữ "Cách xử lý" trong danh sách sự kiện, không thẻ nào được đánh dấu xử lý.
- Đã lộ: danh sách hiện đúng tên thẻ xử lý; thẻ trong tay thuộc `remedies` có dấu hiệu và dòng "Xử lý: ..."; thẻ không thuộc `remedies` thì không.
- Sau khi chơi thẻ xử lý đúng: sự kiện biến mất và gợi ý biến mất.
- Ba sự kiện đã lộ cùng lúc: không có node nào tràn khỏi vùng hiển thị (kiểm tra kích thước điều khiển trong giới hạn viewport).

Chạy cả ba: `test_sim.gd`, `test_ui.gd`, `balance_sim.gd`. `balance_sim.gd` phải in kết quả giống hệt `master` (so từng dòng bảng thắng thua).

## File được sửa

`game-studio/godot/scripts/sim/simulation.gd` (chỉ `event_reports()`), `game-studio/godot/scripts/ui/*`, `game-studio/godot/scenes/game.tscn` (chỉ nếu cần thêm node), `game-studio/godot/data/strings.json`, `game-studio/godot/tests/test_sim.gd`, `game-studio/godot/tests/test_ui.gd`. Không sửa `data/cards.json`, `data/events.json`, `data/config.json`, `media-marketing/`, `docs/`.

## Tiêu chí hoàn thành

- Ba bộ kiểm thử qua; số kiểm tra cũ (`test_sim` 2.392, `test_ui` 106) không giảm; `balance_sim.gd` giống hệt trước.
- `check_web.py` (`-X utf8 -I`) vẫn qua 6 mục (nếu Python bị chặn trong sandbox thì ghi rõ, Claude sẽ tự chạy).
- Bàn giao trong TASKS.md: file đổi, chỗ nào tự quyết (cách đánh dấu thẻ), cách kiểm tra. Claude sẽ tự chụp màn hình để xem bố cục.
