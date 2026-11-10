# Spec T-018b: Siết thưởng phạt và sửa ván 30 ngày

Owner: Codex. Người review: Claude. Nhánh nền: `v2` (đã có T-018). Đọc `docs/SPEC-T-018.md` và ghi chú bàn giao T-018 trong `TASKS.md`. Mã liên quan: `scripts/world/report.gd` (hàm `grade`), `scripts/world/career.gd`, `data/world.json` (mục `grading`, `career`, `ranks`, `score`), `scripts/sim/simulation.gd` (`use_tool`).

## Vấn đề (đo trên `v2`, demo 10 ngày, 2.000 ván mỗi bot)

Ý chính của game là **báo cáo sai thì bị phạt, giáng chức, đuổi việc**. Hiện không xảy ra:

| Bot (10 ngày) | Thắng | Bị đuổi | Sống sót | Tin tưởng trung vị cuối ván |
|---|---:|---:|---:|---:|
| ngẫu nhiên | 7,8% | 1,6% | 98,4% | 55,5 (khởi điểm 42) |
| nghe tin đồn | 13,85% | 1,4% | 98,6% | 56,4 |
| chỉ tin nguồn chính thức | 33,85% | 0% | 100% | 61,3 |
| kiểm chứng | 69,5% | 0,1% | 99,9% | 63,0 |

Bot báo cáo bừa kết thúc ván với Tin tưởng **cao hơn** lúc đầu. Nguyên nhân trong `report.gd`: dự báo "lệch một bậc" (`adjacent` 0,4) được cộng điểm (`partial_reward` 0,3 x điểm gốc), và dự báo sai chỉ trừ bằng đúng mức cộng của dự báo đúng. Đoán bừa vì thế có kỳ vọng tăng điểm. Kèm theo, giáng chức chỉ xảy ra khi Tin tưởng xuống dưới 25 và đúng báo cáo sai ngày đó, nên gần như không bao giờ được kích hoạt trong 10 ngày.

Bản 30 ngày (không bắt buộc ở T-018, nhưng cần sửa để có bản đầy đủ):

| Bot (30 ngày) | Thắng | Phá sản |
|---|---:|---:|
| ngẫu nhiên | 63,95% | 0,65% |
| chỉ tin nguồn chính thức | 98,5% | 0,05% |
| kiểm chứng | 62,35% | **36,85%** |
| thận trọng | 41,35% | **58%** |

Người kiểm chứng giỏi lại phá sản nhiều nhất vì mỗi lần kiểm chứng trừ Budget của thẻ phân tích (khoảng 500 mỗi lần trong `cards.json`) từ Cash của công ty, và 3 Energy mỗi ngày cho phép kiểm chứng 3 lần, cộng dồn qua 30 ngày. Còn điều kiện thắng v2 chỉ cần chức không thấp hơn `chuyen_vien`, nên ván dài ai cũng thắng.

## Mục tiêu

### A. Báo cáo bừa phải bị phạt (demo 10 ngày, 2.000 ván mỗi bot, seed 104 trở đi)

Thêm vào `balance_world.gd` các cột: **tỷ lệ ván có ít nhất một lần giáng chức** (`demoted %`), **tỷ lệ ván có cảnh cáo** (`warned %`), **Tin tưởng cuối ván** p25 / trung vị / p75. "Bị phạt nặng" = bị đuổi hoặc bị giáng chức ít nhất một lần.

| Bot | Bị phạt nặng (đuổi hoặc giáng) | Tin tưởng trung vị cuối ván | Thắng |
|---|---|---|---|
| `random_reporter` | từ 50% trở lên, trong đó bị đuổi từ 15% trở lên | dưới mức khởi điểm | tối đa 10% |
| `rumor_follower` | từ 35% trở lên | dưới hoặc bằng mức khởi điểm | tối đa 15% |
| `official_only` | tối đa 20%, đuổi tối đa 5% | tăng so với khởi điểm | 30% đến 55% |
| `careful_hedger` | tối đa 8%, đuổi tối đa 2% | tăng so với khởi điểm | 25% đến 60%, thấp hơn `verifier` |
| `verifier` | tối đa 5%, đuổi tối đa 1% | từ 60 trở lên | cao hơn `official_only` ít nhất 15 điểm %, tối đa 85% |

Ý nghĩa: người làm việc cẩn thận gần như không bị phạt oan; người đoán bừa hoặc tin đồn bị phạt rõ rệt; người chỉ tin nguồn chính thức thì ở giữa.

### B. Bản 30 ngày dùng được (2.000 ván mỗi bot)

| Bot (30 ngày) | Mục tiêu |
|---|---|
| `random_reporter` | thắng tối đa 20%, bị phạt nặng từ 70% trở lên |
| `rumor_follower` | thắng tối đa 25%, bị phạt nặng từ 55% trở lên |
| `official_only` | thắng từ 25% đến 55%, phá sản tối đa 5% |
| `careful_hedger` | thắng 30% đến 60%, phá sản tối đa 5% |
| `verifier` | thắng cao hơn `official_only` ít nhất 10 điểm %, tối đa 85%, phá sản tối đa 5% |

## Công cụ được phép (Codex chọn, ghi lý do)

1. **Công thức chấm** (`grade` và `world.json` mục `grading`): đổi `partial_reward` về 0 hoặc thành giá trị âm nhỏ (khóa mới `adjacent_effect`, ví dụ -0,15 lần điểm gốc), thêm `wrong_factor` nhân điểm phạt khi sai (khởi điểm gợi ý 1,5), chỉnh hệ số tự tin và `evidence_factor`.
2. **Sự nghiệp** (`career.gd`, mục `career`): hạ `initial_trust`, đổi `warning` và `demote`, thêm điều kiện giáng chức theo số cảnh cáo (ví dụ đủ 2 cảnh cáo thì giáng chức), cho phép giáng chức không đòi báo cáo ngày đó có `acc == 0` khi Tin tưởng thấp kéo dài, thêm **phạt tiền** vào sổ cá nhân khi báo cáo sai (khóa mới `fine_fraction`, chỉ là số liệu cho màn kết thúc, không vào Cash công ty). Không làm cho người báo cáo đúng bị phạt oan.
3. **Chi phí kiểm chứng ở bản 30 ngày:** cho phép đặt chi phí công cụ riêng cho tầng thế giới trong `world.json` (khóa `tool_budget` theo từng công cụ, ví dụ 40 đến 120 mỗi lần, và/hoặc hạn mức phân tích riêng mỗi ngày thay vì trừ thẳng từ Cash). Thay đổi tương ứng trong `Simulation.use_tool`: thêm tham số tùy chọn ghi đè Budget, giữ nguyên hành vi mặc định nếu không truyền (bộ kiểm thử v1 giữ nguyên).
4. **Điều kiện thắng theo độ dài ván:** tách `win` trong `world.json` thành `win.demo` và `win.full` với chức tối thiểu khác nhau (khởi điểm: demo `chuyen_vien`, full `chuyen_vien_chinh` hoặc `truong_nhom`).
5. Mọi hệ số khác trong `world.json` (ngưỡng thăng chức, `adopt_min`, `adopt_max`, tỷ lệ kind tin, số tin mỗi ngày, độ lớn tác động vĩ mô). Cần công cụ ngoài danh sách (đổi cấu trúc báo cáo, đổi luật kiểm chứng, thêm loại tin) thì dừng và hỏi Claude.

Nếu hai mục tiêu mâu thuẫn nhau, **dừng và báo rõ** thay vì tự hạ mục tiêu.

## Ràng buộc (không được phá)

- API công khai vẫn không lộ nhãn ẩn (kiểm thử rà khóa ở `test_world.gd` giữ nguyên và qua).
- Tái lập theo seed; không đổi hành vi lõi v1: `test_sim.gd` (2.623 kiểm tra), `test_ui.gd` (134), `balance_sim.gd` giống hệt trước (so từng dòng).
- Bất biến điểm v2: mọi ván `fired` hoặc `bankrupt` có điểm thấp hơn mọi ván thắng, ở cả 10 và 30 ngày (kiểm thử quét 500 ván mỗi bot như ở T-018 giữ nguyên).
- Người báo cáo đúng không bị phạt: với ván mẫu cố định, một chuỗi báo cáo đúng liên tiếp không bao giờ làm giảm Tin tưởng (kiểm thử riêng).
- Bot chỉ dùng API công khai (không đọc `truth`).
- `test_world.gd` có các ví dụ tính tay cho bảng chấm điểm và sự nghiệp; khi đổi công thức phải **cập nhật các ví dụ đó theo công thức mới** và ghi rõ trong bàn giao từng kiểm tra nào đã đổi và vì sao, không xóa kiểm tra.

## File được sửa

`game-studio/godot/data/world.json`, `game-studio/godot/scripts/world/*`, `game-studio/godot/scripts/sim/simulation.gd` (chỉ `use_tool` và tham số ghi đè chi phí), `game-studio/godot/tests/test_world.gd`, `game-studio/godot/tests/balance_world.gd`, `game-studio/godot/tests/test_sim.gd` (chỉ phần `use_tool`). Không sửa `news.json`, `questions.json` (nếu thấy lỗi thì ghi vào bàn giao), `cards.json`, `events.json`, `config.json`, `scripts/ui`, `scenes`, `docs`, `shared`.

## Tiêu chí hoàn thành

- `balance_world.gd` in bảng cho 10 và 30 ngày (có `demoted %`, `warned %`, Tin tưởng p25/p50/p75) và mọi bot nằm trong mục tiêu A và B.
- `test_world.gd`, `test_sim.gd`, `test_ui.gd`, `balance_sim.gd` đạt như ràng buộc.
- Bàn giao trong `TASKS.md`: bảng trước/sau (10 và 30 ngày), lịch sử chỉnh số từng vòng, `world.json` cuối đầy đủ, danh sách kiểm tra đã đổi, mục tiêu nào chưa đạt và vì sao.
