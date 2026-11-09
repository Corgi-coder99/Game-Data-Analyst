# Spec T-004: Lõi mô phỏng Data Corp và mô phỏng cân bằng headless

Owner: Codex. Người review: Claude. Nguồn thiết kế: `game-studio/godot/docs/GDD.md` (đọc kỹ mục 3 đến 8 và 10).

## Phạm vi

Chỉ lõi logic và dữ liệu. Không làm giao diện, cảnh, âm thanh hay đồ họa.

## Việc cần làm

1. `data/config.json`: giá trị khởi điểm (GDD mục 3), chi phí cố định 800, hệ số hiệu suất giảm dần quảng cáo 0.1 mỗi 1,000, số tuần mặc định (10 cho demo, 30 cho bản đầy đủ), điều kiện thắng thua (GDD mục 7).
2. `data/cards.json`: 12 thẻ theo GDD mục 5. Mỗi thẻ có `id`, `name`, `category`, `budget`, `energy`, `effects` (thay đổi chỉ số, có thể kèm điều kiện hoặc thời hạn). Giá trị do bạn đề xuất hợp lý, ghi vào ghi chú bàn giao để Claude duyệt.
3. `data/events.json`: 8 sự kiện theo GDD mục 6. Mỗi sự kiện có `id`, `symptom` (chỉ số bị tác động hiển thị), `root_cause` (ẩn), và thẻ nào làm lộ hoặc xử lý đúng nguyên nhân.
4. `scripts/sim/`: các lớp thuần logic (kế thừa `RefCounted`, không dùng Node), gồm trạng thái công ty, bước mô phỏng một tuần theo công thức GDD mục 4, rút thẻ, áp dụng sự kiện, nhiễu theo Data Integrity.
5. `tests/balance_sim.gd`: chạy N ván (mặc định 2,000) cho 4 chiến lược: ngẫu nhiên, chỉ chi quảng cáo, chỉ tối ưu, cân bằng. In tỷ lệ thắng, tuần thua trung vị và phân bố Cash cuối ván.
6. `tests/test_sim.gd`: kiểm thử đơn vị cho công thức (ví dụ một tuần với số cho trước ra đúng kết quả tính tay, Cash không âm khi chưa thua, cùng seed cho cùng kết quả).

## Ràng buộc

- GDScript, Godot 4.7. Mọi hệ số đọc từ `data/`, không viết cứng trong mã.
- Bộ sinh số ngẫu nhiên nhận seed để chạy lặp lại được.
- Chạy được không giao diện bằng:
  `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path <worktree>\game-studio\godot -s res://tests/balance_sim.gd`
- Một lượt `balance_sim` 2,000 ván xong dưới 60 giây.
- Không sửa `project.godot`, `docs/`, hay file ngoài danh sách dưới đây.

## File được sửa

`game-studio/godot/data/*.json`, `game-studio/godot/scripts/sim/*`, `game-studio/godot/tests/*`. Được sửa `game-studio/godot/scripts/data.gd` nếu cần thêm hàm đọc dữ liệu (ghi rõ trong ghi chú bàn giao).

## Tiêu chí hoàn thành

- Hai lệnh `test_sim.gd` và `balance_sim.gd` chạy xong, không lỗi.
- Mục tiêu cân bằng GDD mục 10: chiến lược "chỉ chi quảng cáo" thua trước tuần 15 ở phần lớn ván; chiến lược "cân bằng" thắng khoảng 40 đến 60%. Chưa đạt thì chỉnh số trong `data/` và ghi lại kết quả từng lần chỉnh.
- Ghi chú bàn giao trong TASKS.md theo mẫu, kèm bảng kết quả `balance_sim`.
