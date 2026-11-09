# Spec T-011: Phân tích phải có lợi, và sửa ván 30 tuần

Owner: Codex. Người review: Claude. Tiếp nối T-009 (`docs/SPEC-T-009.md`, đã merge). Đọc bảng kết quả trong ghi chú bàn giao T-009 trong `TASKS.md`.

## Hiện trạng sau T-009 (đo ở master)

| Chiến lược | Thắng 10 tuần | Thắng 30 tuần |
|---|---:|---:|
| ngẫu nhiên | 17,05% | 0% |
| chỉ quảng cáo | 0% | 0% |
| chỉ tối ưu | 27,90% | 9,95% |
| cân bằng | 46,45% | 0% |
| phân tích | 45,35% | 0% |

Còn hai điểm chưa đạt từ T-009:

1. **Phân tích không có lợi.** Chiến lược `analyst` (lộ nguyên nhân rồi mới xử lý) thấp hơn `balanced` 1,10 điểm %. Nguyên nhân trong mã (`scripts/sim/simulation.gd`, hàm `play`): thẻ có trong `resolved_by` của sự kiện gỡ ngay sự kiện đó, **không cần** nguyên nhân đã lộ (`event.revealed`). Vì vậy người chơi chỉ việc chơi thẻ xử lý "đoán mò" mà không cần thẻ phân tích. Điều này đi ngược GDD mục 6 (phải phân biệt triệu chứng với nguyên nhân gốc).
2. **Ván 30 tuần gần như không thể thắng** (cân bằng 0%). Bản demo 10 tuần là bản chơi hiện tại nên không ảnh hưởng người chơi ngay, nhưng phải sửa để bản đầy đủ khả thi.

## Thay đổi cơ chế bắt buộc

**Thẻ xử lý chỉ gỡ sự kiện nếu nguyên nhân của sự kiện đó đã lộ** (`event.revealed == true`). Chi tiết:

- Trong `play()`: điều kiện gỡ sự kiện là `card_id in resolved_by` **và** `event.revealed`.
- Thẻ xử lý chơi khi nguyên nhân chưa lộ: hiệu ứng riêng của thẻ vẫn áp dụng (ví dụ Onboarding vẫn tăng Retention), nhưng sự kiện không bị gỡ và không tính vào `resolved`.
- Chơi thẻ lộ rồi thẻ xử lý trong cùng một tuần phải hoạt động (thứ tự chơi quyết định).
- `state.resolved` (dùng cho điểm) chỉ đếm sự kiện được gỡ theo cách trên.
- Sự kiện không được xử lý thì vẫn tự hết hạn như hiện nay.

Đây là thay đổi ngoài danh sách công cụ của T-009 và đã được Claude duyệt trong spec này.

## Mục tiêu cân bằng

**Bản demo 10 tuần (ưu tiên, 2.000 ván mỗi chiến lược, seed 104 trở đi):**

| Chiến lược | Tỷ lệ thắng |
|---|---|
| chỉ quảng cáo | 10% hoặc thấp hơn |
| ngẫu nhiên | 20% hoặc thấp hơn |
| chỉ tối ưu | 25% đến 45% |
| cân bằng | 35% đến 55% |
| phân tích | cao hơn cân bằng ít nhất 10 điểm %, tối đa 85% |

Chỉ số cuối ván thắng (trung vị) giữ như T-009: Retention không quá 75%, Conversion không quá 8%, LTV/CAC từ 2 đến 8.

**Bản 30 tuần (phụ nhưng phải khả thi):** chỉ quảng cáo 0%, ngẫu nhiên tối đa 10%, cân bằng 30% đến 55%, phân tích cao hơn cân bằng, chỉ tối ưu thấp hơn cân bằng.

## Việc cần làm

1. Sửa `play()` theo cơ chế bắt buộc.
2. Chỉnh cân bằng sao cho "phân tích có lợi": phần thưởng của việc gỡ một sự kiện (phần phạt không còn gánh) phải đủ lớn so với cái giá của thẻ lộ và thẻ xử lý. Được chỉnh mức phạt và thời hạn sự kiện trong `data/events.json`, chi phí và hiệu quả thẻ trong `data/cards.json`, và `data/config.json`. Chỉ được dùng công cụ trong spec T-009, cộng với các việc dưới đây.
3. Cho phép tách điều kiện thắng theo độ dài ván: `win.demo` và `win.full` trong `config.json` (hiện chỉ có một khối `win`), và tách các hệ số phase hoặc chi phí nếu cần để ván 30 tuần khả thi. Tên khóa mới phải đặt rõ và ghi trong bàn giao.
4. Sửa logic các chiến lược giả lập trong `tests/balance_sim.gd` cho hợp lý: bot không mua lại thẻ nâng cấp đã giảm hiệu quả gần bằng 0; chiến lược `analyst` chỉ dùng thông tin người chơi thấy (`event_reports()`, `report()`), không đọc `state.base`. Mọi thay đổi bot phải ghi trong bàn giao để Claude xem có công bằng giữa các chiến lược không.
5. Cập nhật `tests/test_sim.gd`: thẻ xử lý không gỡ sự kiện khi chưa lộ; gỡ được khi đã lộ (cùng tuần và khác tuần); `resolved` chỉ tăng khi gỡ hợp lệ; tái lập theo seed. Kiểm tra cũ nào phải đổi, ghi rõ lý do.

## Ràng buộc (không được phá)

- Giữ nguyên **12 thẻ, 8 sự kiện, 7 chỉ số, 10 tuần demo** (landing page đối chiếu các con số này qua `check_web.py`).
- Bất biến điểm T-006: mọi ván thua điểm thấp hơn mọi ván thắng.
- `test_ui.gd` (106 kiểm tra) phải qua. Giao diện không đọc số thật trong ván.
- Mô phỏng tái lập theo seed.
- Không sửa `scripts/ui/`, `scenes/`, `media-marketing/`.

## File được sửa

`game-studio/godot/scripts/sim/*`, `game-studio/godot/data/cards.json`, `data/events.json`, `data/config.json`, `game-studio/godot/tests/balance_sim.gd`, `game-studio/godot/tests/test_sim.gd`. Chỉ sửa `tests/test_ui.gd` nếu một kiểm tra phụ thuộc giá trị cân bằng cũ (ghi rõ trong bàn giao).

## Tiêu chí hoàn thành

- `balance_sim.gd` in bảng cho 10 và 30 tuần, và các tỷ lệ thắng nằm trong mục tiêu.
- `test_sim.gd`, `test_ui.gd` qua. `check_web.py` (`-X utf8 -I`) qua 6 mục (nếu Python bị chặn trong sandbox thì ghi rõ, Claude sẽ tự chạy).
- Bàn giao trong TASKS.md: bảng trước/sau, lịch sử chỉnh số từng vòng, danh sách giá trị `config.json` cuối cùng (để Claude cập nhật GDD), và mục tiêu nào chưa đạt nếu có.
