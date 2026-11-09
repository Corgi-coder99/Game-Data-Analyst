# Spec T-006: Sửa công thức điểm

Owner: Codex. Người review: Claude. Nguồn: `docs/GDD.md` mục 7 (điểm tính từ Cash cuối, LTV/CAC, số sự kiện xử lý đúng) và `scripts/sim/simulation.gd` hàm `score()`.

## Vấn đề

`score()` hiện là `cash x 1 + LTV/CAC x 100 + resolved x 500`, LTV/CAC không bị giới hạn. Khi Retention chạm trần 98% thì `churn_floor` làm LTV/CAC lên tới khoảng 70. Kết quả quan sát được: một ván **thua** với Cash -444 được 6.598 điểm. Điểm của ván thua phải thấp hơn mọi ván thắng.

## Quy tắc điểm mới

1. **Ván thắng:** `win_bonus + max(0, cash) x w_cash + min(ratio, ratio_cap) x w_ratio + resolved x w_resolved`.
2. **Ván thua:** `min(loss_cap, week x w_week + resolved x w_resolved_loss)`. Không tính Cash và LTV/CAC.
3. **Ván chưa kết thúc** (cả `won` và `lost` đều sai): giữ hành vi cũ không bị lỗi, tính như ván thắng nhưng không cộng `win_bonus`. Không dùng ở giao diện.
4. Ràng buộc bất biến: `loss_cap < win_bonus`, nên mọi ván thua có điểm thấp hơn mọi ván thắng.

Giá trị khởi điểm (đặt trong `data/config.json`, mục `score`, không viết cứng trong mã):

| Khóa | Giá trị |
|---|---:|
| `win_bonus` | 1000 |
| `cash` (w_cash) | 0.1 |
| `ratio` (w_ratio) | 100 |
| `ratio_cap` | 5 |
| `resolved` (w_resolved) | 100 |
| `week` (w_week) | 40 |
| `resolved_loss` (w_resolved_loss) | 50 |
| `loss_cap` | 900 |

Giữ khóa `score.cash`, `score.ratio`, `score.resolved` để không phá chỗ đang đọc. Thêm khóa mới. Đổi giá trị các khóa cũ theo bảng. Nếu đổi tên khóa nào, báo trong bàn giao.

## Việc cần làm

1. Sửa `score()` theo quy tắc trên.
2. Cập nhật `data/config.json` (mục `score`).
3. Thêm kiểm thử vào `tests/test_sim.gd`:
   - Ván thua với Cash âm và LTV/CAC rất cao: điểm không vượt `loss_cap`.
   - Ván thắng có Cash nhỏ dương, không sự kiện nào xử lý: điểm lớn hơn `loss_cap`.
   - LTV/CAC bị giới hạn: tăng ratio từ 5 lên 70 không đổi điểm.
   - Cùng seed cho cùng điểm.
   - Quét ít nhất 500 ván mỗi chiến lược: không có ván thua nào có điểm lớn hơn ván thắng có điểm nhỏ nhất.
4. (Tùy chọn, không bắt buộc) `tests/balance_sim.gd` in thêm điểm trung bình của ván thắng và ván thua cho mỗi chiến lược. Không được làm đổi tỷ lệ thắng hay bất kỳ số liệu hiện có.

## Ràng buộc

- Chỉ đổi cách tính điểm. Không đổi logic mô phỏng tuần, thẻ, sự kiện hay điều kiện thắng thua.
- `balance_sim` phải cho đúng các kết quả thắng/thua cũ (balanced thắng 40,85%, ads_only 0%, optimization_only 29,25%, random 23,15%).
- `test_sim.gd` hiện 118 kiểm tra phải còn qua, cộng thêm kiểm tra mới. `test_ui.gd` (106 kiểm tra) phải còn qua: nó so điểm hiển thị với `simulation.score()` nên không cần sửa.

## File được sửa

`game-studio/godot/scripts/sim/simulation.gd` (chỉ hàm `score()` và các biến cần cho nó), `game-studio/godot/data/config.json` (chỉ mục `score`), `game-studio/godot/tests/test_sim.gd`, `game-studio/godot/tests/balance_sim.gd` (chỉ nếu làm mục tùy chọn).

## Tiêu chí hoàn thành

- Ba lệnh headless `test_sim.gd`, `test_ui.gd`, `balance_sim.gd` chạy xong, không lỗi, số thắng/thua không đổi.
- Ván minh họa trước đây (thua, Cash -444) giờ có điểm không quá 900.
- Ghi chú bàn giao trong TASKS.md theo mẫu, nêu rõ giá trị điểm cuối của vài ván mẫu.
