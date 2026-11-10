# Spec T-018c: Khan hiếm cho việc kiểm chứng (Energy phân tích riêng)

Owner: Codex. Người review: Claude. Nhánh nền: `v2` (đã có T-018, T-018b, T-019a, T-019b). Đọc `docs/SPEC-T-018.md` mục 3 (kiểm chứng), `docs/SPEC-T-018b.md`, và ghi chú bàn giao T-018b, T-019b.

## Vấn đề

GDD v2 mục 3 nói mỗi ngày người chơi có **3 Energy** để dùng công cụ phân tích, nên phải chọn tin nào đáng kiểm chứng. Thực tế không như vậy:

- Ba công cụ đầu (`truy_van_lich_su`, `kiem_dinh_gia_thuyet`, `doi_chieu_nguon`) dùng thẻ `sql_deep_dive`, `ab_test`, `funnel_report`, mà `data/cards.json` đặt **Energy 0** (do cân bằng game v1 ở T-011/T-012). `lam_sach_du_lieu` (thẻ `clean_data`) có Energy 1.
- Chi phí còn lại chỉ là `tool_budget` (40 đến 100 mỗi lần, trên 18.000 Cash), quá nhỏ để gây áp lực.
- Hệ quả: người chơi có thể kiểm chứng **mọi tin mỗi ngày** gần như miễn phí; ảnh chụp giao diện v2 cũng cho thấy "0 NL" ở ba công cụ. Mất cảm giác chọn lọc, đây là lõi ý tưởng của game.

Lưu ý thêm: nếu chỉ đặt Energy cho thẻ trong `use_tool` thì sẽ lẫn với Energy của hành động công ty (`Simulation.play()` trong `end_day`), làm hành động đề xuất bị từ chối vì hết Energy. Vì vậy cần **một kho Energy phân tích riêng**.

## Mục tiêu

1. Tầng thế giới có kho **Energy phân tích** riêng: `analysis_energy` mỗi ngày (khởi điểm 3, đặt lại đầu ngày), tách khỏi Energy của mô phỏng công ty.
2. Mỗi công cụ tốn một lượng Energy phân tích riêng trong `world.json` (khóa mới `tool_energy`, khởi điểm: `doi_chieu_nguon` 1, `truy_van_lich_su` 1, `kiem_dinh_gia_thuyet` 1, `lam_sach_du_lieu` 1; Codex có thể đề xuất khác nếu cân bằng cần, ví dụ kiểm định giả thuyết 2).
3. `status()` trả `energy` và `energy_max` phản ánh **kho Energy phân tích** (hai khóa này đã được T-019b thêm; đổi ý nghĩa của chúng cho khớp, cập nhật kiểm thử). `tools()` trả `energy` là `tool_energy` của tầng thế giới (không phải Energy của thẻ trong `cards.json`).
4. Kiểm chứng tốn Energy phân tích; hết thì từ chối với mã lỗi `no_analysis_energy` (mã mới, giao diện sẽ hiện chuỗi tiếng Việt: cần thêm vào `data/strings_v2.json`). Kiểm chứng lặp cùng tin cùng công cụ vẫn miễn phí (cache như hiện nay).
5. `use_tool` trong lõi mô phỏng chỉ còn trừ **Budget** (qua tham số ghi đè đã có) và áp hiệu ứng; không trừ Energy của mô phỏng khi gọi từ tầng thế giới (thêm tham số tùy chọn hoặc cờ, giữ nguyên hành vi mặc định cho mã v1 và các kiểm thử cũ).
6. Bot cân bằng phải chịu cùng giới hạn: `verifier` và `careful_hedger` chỉ kiểm chứng tối đa số lần cho phép mỗi ngày và phải **ưu tiên** (tin mới nhất và tin liên quan câu hỏi, theo thông tin công khai).

## Mục tiêu cân bằng (giữ như T-018b, đo lại với Energy mới)

2.000 ván mỗi bot, seed 104 trở đi, `--days=10` và `--days=30`: mọi mục tiêu A và B của `SPEC-T-018b.md` vẫn phải đạt (bị phạt nặng, Tin tưởng cuối ván, tỷ lệ thắng, phá sản). Trọng tâm: `verifier` vẫn thắng cao hơn `official_only` ít nhất 15 điểm % (demo) và 10 điểm % (30 ngày). Nếu khan hiếm làm `verifier` thấp hơn nhiều, được chỉnh `tool_energy`, `analysis_energy`, độ chính xác công cụ và hệ số chấm điểm; **không** được hạ mục tiêu. Nếu hai mục tiêu mâu thuẫn, dừng và báo.

Thêm số liệu in ra: số lần kiểm chứng trung bình mỗi ngày của từng bot (kỳ vọng `verifier` và `careful_hedger` gần giới hạn, các bot khác 0), và tỷ lệ tin liên quan câu hỏi được kiểm chứng.

## Kiểm thử

- `status().energy` bằng `energy_max` đầu ngày, giảm đúng `tool_energy` sau mỗi kiểm chứng mới, đặt lại ở `begin_day()`.
- Hết Energy thì `verify` trả `{ok:false, error:"no_analysis_energy"}`, không đổi trạng thái, không trừ Budget.
- Kiểm chứng lặp (cùng uid, cùng công cụ) không tốn Energy hay Budget.
- Energy của mô phỏng công ty không bị trừ bởi kiểm chứng: hành động đề xuất vẫn thực thi được ở `end_day` khi đã dùng hết Energy phân tích.
- `tools()` trả đúng `tool_energy`.
- Không lộ dữ liệu ẩn (kiểm thử rà khóa giữ nguyên qua).
- Giữ nguyên toàn bộ kiểm thử cũ: `test_sim` (2.630), `test_ui` (134), `test_world` (32.438 và các kiểm tra phụ thuộc Energy cũ phải cập nhật, ghi rõ từng kiểm tra đã đổi), `test_v2_assets` (2.255), `test_v2_desktop` (582, cập nhật các kiểm tra phụ thuộc Energy: ví dụ giao diện hiển thị Energy đúng và làm mờ nút khi hết), `balance_sim` giống hệt.

## Ràng buộc

- Không đổi `data/cards.json`, `events.json`, `config.json`, `news.json`, `questions.json` (game v1 giữ nguyên).
- Không sửa `scripts/ui/` (UI v1), `scenes/*.tscn` ngoài `scenes/v2/`, `scripts/v2/office.gd`, `shared/`, `docs/`.
- `Simulation` chỉ được sửa tối thiểu trong `use_tool` (tham số tùy chọn không đổi hành vi mặc định).
- Trong `scripts/v2/`: chỉ sửa phần hiển thị Energy và thông báo lỗi mới nếu cần (cập nhật `desktop.gd`, `windows/tools_window.gd`, `data/strings_v2.json`).

## File được sửa

`game-studio/godot/data/world.json`, `game-studio/godot/scripts/world/*`, `game-studio/godot/scripts/sim/simulation.gd` (chỉ `use_tool`), `game-studio/godot/scripts/v2/desktop.gd` và `scripts/v2/windows/tools_window.gd` (chỉ hiển thị Energy và lỗi mới), `game-studio/godot/data/strings_v2.json`, `game-studio/godot/tests/test_world.gd`, `game-studio/godot/tests/balance_world.gd`, `game-studio/godot/tests/test_sim.gd` (chỉ `use_tool`), `game-studio/godot/tests/test_v2_desktop.gd`.

## Bàn giao

Trong `TASKS.md`: bảng trước/sau (10 và 30 ngày, kèm số lần kiểm chứng mỗi ngày), lịch sử chỉnh số, `world.json` cuối đầy đủ, danh sách kiểm tra đã đổi và lý do, mục tiêu nào chưa đạt.
