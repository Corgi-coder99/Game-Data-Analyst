# Spec T-012: Chữa gốc kinh tế (người dùng không được co về gần 0)

Owner: Codex. Người review: Claude. Tiếp nối T-009 và T-011 (đã merge). Đọc `docs/SPEC-T-009.md`, `docs/SPEC-T-011.md` và ghi chú bàn giao của hai việc đó trong `TASKS.md`.

## Vấn đề gốc

Mô hình tuần (GDD mục 4) là `Users' = Users - Users x (1 - Retention) + ad_spend / CAC`. Với giá trị khởi điểm Retention = 40% mỗi **tuần**, 60% người dùng rời đi mỗi tuần, còn quảng cáo mua về khoảng 47 người mỗi tuần (700 / 15). Trạng thái cân bằng của số người dùng là `người_mới / churn`, khoảng 47 / 0,6 = 78 người, bất kể người chơi làm gì ở mức khởi điểm. Hệ quả đã đo (T-011, demo 10 tuần):

| Chiến lược | Số ván thắng | Users cuối ván thắng (p10 / trung vị / p90), bắt đầu 1.000 |
|---|---:|---|
| cân bằng | 389 / 1.000 | 5 / 24 / 68 |
| chỉ tối ưu | 269 / 1.000 | 0,3 / 4,9 / 23 |

Người chơi "thắng" khi công ty gần như mất hết khách, vì điều kiện thắng demo (`win.demo.min_users = 0,1`) không chặn gì. Doanh thu cũng không có ý nghĩa: 78 người x 2% x 25 = khoảng 39 mỗi tuần, so với chi phí cố định 450. Cả câu chuyện "cứu startup" của game vì vậy không đúng với dashboard mà người chơi thấy. Đây cũng là lý do T-011 phải chỉnh gượng ván 30 tuần (hệ số chi phí `full_cost_multiplier = 0,1`, `full_card_cost_multiplier = 0,05` từ tuần 11, xác suất sự kiện hạ còn 0,2), trái GDD mục 8 (độ khó tăng dần).

## Hướng giải (Claude chọn, Codex chỉnh số)

Giữ nguyên công thức tuần. Sửa **quy mô** để tăng trưởng và suy giảm đều có thể xảy ra:

1. Đổi ý nghĩa Retention khởi điểm cho hợp lý với chu kỳ tuần: Retention khởi điểm trong khoảng 75% đến 85% (churn 15 đến 25% mỗi tuần), trần Retention khoảng 92% đến 95%. Thẻ Retention (Onboarding, Loyalty, Influencer) chỉnh lại để các bước cộng hợp lý với thang mới.
2. Chỉnh quy mô quảng cáo, CAC, Users khởi điểm, ARPU, Conversion và chi phí cố định để: ở mức khởi điểm công ty **đang lỗ nhẹ và co lại chậm**, và chơi tốt thì có thể đưa công ty tới tăng trưởng.
3. Điều kiện thắng mới (đặt trong `config.json`, mục `win`, tách demo/full như hiện tại): sống sót **và** giữ được công ty. Cụ thể: `min_cash`, `min_ratio` giữ ý nghĩa, và đổi `min_users` thành một giá trị tuyệt đối có nghĩa (khoảng 70% đến 80% số Users khởi điểm cho demo).
4. Hoàn nguyên các chỉnh gượng ở ván 30 tuần: xóa `full_cost_multiplier`, `full_card_cost_multiplier` khỏi `config.json` và `simulation.gd`; đặt lại xác suất và số sự kiện mỗi pha cho **tăng dần** (gợi ý khởi điểm: 0,3 / 0,5 / 0,7, pha cuối 1 đến 2 sự kiện), theo GDD mục 8. Nếu ván 30 tuần không khả thi sau khi sửa quy mô, chỉnh bằng các hệ số kinh tế chung hoặc `win.full`, không dùng hệ số chỉ áp dụng từ tuần 11.

Được dùng mọi công cụ của spec T-009 và T-011. Cần công cụ ngoài danh sách (đổi công thức tuần, thêm thẻ hay sự kiện mới) thì dừng và hỏi Claude.

## Tiêu chí hoàn thành

**Tỷ lệ thắng** (2.000 ván mỗi chiến lược, seed 104 trở đi): giữ các mục tiêu của T-011.

| | Demo 10 tuần | Full 30 tuần |
|---|---|---|
| chỉ quảng cáo | tối đa 10% | 0% |
| ngẫu nhiên | tối đa 20% | tối đa 10% |
| chỉ tối ưu | 25% đến 45% | thấp hơn cân bằng |
| cân bằng | 35% đến 55% | 25% đến 55% |
| phân tích | cao hơn cân bằng ít nhất 10 điểm %, tối đa 85% | cao hơn cân bằng ít nhất 10 điểm % |

**Tiêu chí mới về chất lượng ván chơi** (chỉ tính ván thắng, demo 10 tuần):

- Users cuối ván (trung vị): cân bằng và phân tích **không thấp hơn 90%** số Users khởi điểm; chiến lược phân tích **không thấp hơn 110%**; chỉ tối ưu không thấp hơn 70%.
- Ở p10 (ván thắng tệ nhất), Users cuối ván không thấp hơn 50% số Users khởi điểm.
- Chỉ số cuối ván thắng (trung vị): Retention không quá trần mới, Conversion không quá 8%, LTV/CAC từ 2 đến 8 (như T-009).
- Ở ván thua, đường Users trung vị tuần 1, 3, 5, 10 của chiến lược "chỉ quảng cáo" phải **không tăng**, và chỉ cần co lại chậm hơn trước (không rớt về dưới 10% trong 10 tuần).

**Báo cáo bắt buộc:** `balance_sim.gd` in thêm cho mỗi chiến lược (10 và 30 tuần): Users cuối ván thắng (p10 / trung vị / p90), và đường Users trung vị tại tuần 1, 3, 5, 10 (và 20, 30 ở bản full).

## Ràng buộc (không được phá)

- Giữ nguyên **12 thẻ, 8 sự kiện, 7 chỉ số, 10 tuần demo** (landing page đối chiếu qua `check_web.py`).
- Bất biến điểm T-006: mọi ván thua điểm thấp hơn mọi ván thắng; `ratio_cap` và các hệ số điểm giữ nguyên trừ khi bất biến buộc đổi (ghi rõ nếu đổi).
- Cơ chế T-011 giữ nguyên: thẻ xử lý chỉ gỡ sự kiện khi nguyên nhân đã lộ.
- `test_ui.gd` (106 kiểm tra) phải qua. Giao diện không đọc số thật trong ván. Nếu một kiểm tra UI phụ thuộc giá trị cân bằng cũ, sửa kiểm tra đó và ghi rõ trong bàn giao.
- Mô phỏng tái lập theo seed.
- Không sửa `scripts/ui/`, `scenes/`, `media-marketing/`, `docs/`.

## File được sửa

`game-studio/godot/scripts/sim/*`, `game-studio/godot/data/cards.json`, `data/events.json`, `data/config.json`, `game-studio/godot/tests/balance_sim.gd`, `game-studio/godot/tests/test_sim.gd`; `tests/test_ui.gd` chỉ khi một kiểm tra phụ thuộc giá trị cân bằng cũ.

## Bàn giao

Trong `TASKS.md`: bảng trước/sau (tỷ lệ thắng và Users cuối ván), lịch sử chỉnh số từng vòng, `config.json` cuối cùng đầy đủ (để Claude cập nhật GDD mục 3, 4, 7, 8), danh sách thay đổi bot nếu có, và mục tiêu nào chưa đạt. Nếu một mục tiêu không đạt được cùng lúc với mục tiêu khác, nói rõ mâu thuẫn thay vì tự hạ mục tiêu.
