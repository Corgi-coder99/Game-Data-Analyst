# Spec T-009: Cân bằng lại để kỹ năng phân tích có ý nghĩa

Owner: Codex. Người review: Claude. Nguồn: `docs/GDD.md` mục 4 đến 8 và 10, `scripts/sim/simulation.gd`, `data/*.json`, `tests/balance_sim.gd`.

## Vấn đề (đã đo bằng 1.000 ván mỗi dòng, seed 104 trở đi)

| Chiến lược | Thắng ở 10 tuần (bản demo) | Thắng ở 30 tuần | Retention trung vị cuối ván | LTV/CAC trung vị cuối ván |
|---|---:|---:|---:|---:|
| ngẫu nhiên | 37,7% | 23,7% | 98% | 50 |
| chỉ quảng cáo | **52,9%** | 0% | 40% | 2,8 |
| chỉ tối ưu | 90,1% | 29,6% | 98% | 93 |
| cân bằng | 62,8% | 42,0% | 98% | 85 |

Hai lỗi thiết kế:

1. **Bản demo (10 tuần) quá dễ và không thưởng cho kỹ năng.** `balance_sim.gd` hiện chỉ chạy 30 tuần (`Sim.new` mặc định `weeks.full`), nên T-004 báo cân bằng đạt trong khi bản demo thật (10 tuần) chưa được đo. Ở demo, "chỉ quảng cáo" thắng hơn một nửa số ván, vì thắng chỉ cần sống sót đến tuần 10 với Cash dương.
2. **Thẻ nâng cấp cộng dồn vĩnh viễn.** Onboarding (+25 điểm % Retention), Fix Checkout (+4,2 điểm % Conversion), Support Automation (-100 chi phí cố định), SEO Content (-0,8 CAC) đều chơi lại được nhiều tuần. Hai lần Onboarding đã đẩy Retention từ 40% lên 90%, ba lần thì chạm trần 98%. Kết quả: Retention 98%, Conversion 14 đến 23%, LTV/CAC 50 đến 100 ở ván thắng. Những số này vô lý với người chơi hiểu SaaS (LTV/CAC thực tế thường 3 đến 8).

## Mục tiêu cân bằng (đo ở bản demo 10 tuần, 2.000 ván mỗi chiến lược, seed 104 trở đi)

| Chiến lược | Tỷ lệ thắng mục tiêu |
|---|---|
| chỉ quảng cáo | 10% hoặc thấp hơn |
| ngẫu nhiên | 20% hoặc thấp hơn |
| chỉ tối ưu | 25% đến 45% |
| cân bằng | 40% đến 60% |
| **phân tích** (chiến lược mới, mục dưới) | cao hơn "cân bằng" ít nhất 10 điểm %, và không quá 85% |

Chỉ số cuối ván của các ván **thắng** (trung vị): Retention không quá 75%, Conversion không quá 8%, LTV/CAC từ 2 đến 8.

Ở bản 30 tuần (phụ, chỉ đo để không hỏng): "chỉ quảng cáo" vẫn 0%, "cân bằng" từ 30% đến 55%.

## Chiến lược mới "phân tích" (bắt buộc, để đo đúng luận điểm của game)

Thêm chiến lược `analyst` vào `tests/balance_sim.gd` và `balance.priorities` (hoặc logic riêng): mỗi tuần, nếu có sự kiện đang hoạt động mà chưa lộ nguyên nhân và trong tay có thẻ làm lộ nó (`revealed_by` của sự kiện, xem `data/events.json`) thì chơi thẻ lộ trước; sau khi nguyên nhân lộ, nếu trong tay có thẻ xử lý (`resolved_by`) thì chơi thẻ xử lý; còn Energy và Budget thì chơi như chiến lược "cân bằng". Chiến lược này chỉ được dùng thông tin mà người chơi có thể thấy (`event_reports()` và `report()`), không đọc `state.base`.

## Công cụ được phép dùng (Codex chọn, ghi lý do)

1. Thêm cờ `once: true` cho thẻ nâng cấp vĩnh viễn: sau khi chơi, thẻ rời khỏi bộ bài cho đến hết ván.
2. Hiệu quả giảm dần: mỗi lần chơi lại cùng một thẻ nâng cấp, tác dụng giảm một nửa.
3. Hạ trần `limits` (ví dụ Retention tối đa 0,85) và chỉnh giá trị thẻ, sự kiện, chi phí cố định, ARPU, số tuần trong `data/`.
4. Thêm điều kiện thắng cho bản demo (khóa tùy chọn trong `config.json`, ví dụ `win.min_cash` hoặc `win.min_ratio`), để thắng không chỉ là sống sót. Điều kiện mới phải đặt trong `data/config.json`, không viết cứng.

Nếu cần công cụ ngoài danh sách (ví dụ đổi cơ chế rút bài), dừng lại và hỏi Claude trong ghi chú bàn giao, không tự làm.

## Ràng buộc (không được phá)

- Giữ nguyên **12 thẻ, 8 sự kiện, 7 chỉ số, 10 tuần demo**: trang landing page (`media-marketing/web/check_web.py`) đang đối chiếu các con số này. Nếu bắt buộc đổi, nêu rõ trong bàn giao, Claude sẽ sửa trang web.
- Công thức điểm T-006 vẫn đúng: mọi ván thua có điểm thấp hơn mọi ván thắng (`test_sim.gd` đang kiểm tra bất biến này).
- Giao diện vẫn chạy: `test_ui.gd` (106 kiểm tra) phải qua. Nếu bộ bài ít thẻ hơn số thẻ rút (4), phải xử lý không lỗi.
- Giao diện không đọc số thật trong ván: không đổi nguyên tắc dữ liệu.
- Mô phỏng vẫn tái lập được theo seed.

## Việc cần làm

1. Chạy đo hiện trạng bằng `balance_sim.gd` có tham số tuần (xem mục sau) để xác nhận bảng "Vấn đề".
2. Thêm tham số `--weeks=10` hoặc `--weeks=30` vào `balance_sim.gd` (mặc định in cả hai) và thêm chiến lược `analyst`. In thêm cho mỗi dòng: Retention, Conversion, LTV/CAC trung vị cuối ván của ván thắng.
3. Chỉnh cân bằng bằng các công cụ trên cho đến khi đạt mục tiêu. Ghi lại từng vòng chỉnh (giá trị đổi, kết quả) vào ghi chú bàn giao.
4. Cập nhật `tests/test_sim.gd`: kiểm tra tính chất của thẻ `once` (nếu dùng), trần chỉ số, và các bất biến của điểm. Không xóa kiểm tra cũ trừ khi nó kiểm tra đúng hành vi đã đổi (ghi rõ kiểm tra nào đổi và lý do).

## File được sửa

`game-studio/godot/scripts/sim/*`, `game-studio/godot/data/cards.json`, `data/events.json`, `data/config.json`, `game-studio/godot/tests/balance_sim.gd`, `game-studio/godot/tests/test_sim.gd`. Chỉ sửa `tests/test_ui.gd` nếu kiểm tra nào đó phụ thuộc giá trị cân bằng cũ, và phải ghi rõ trong bàn giao. Không sửa `scripts/ui/`, `scenes/`, `media-marketing/`.

## Tiêu chí hoàn thành

- `balance_sim.gd` in bảng cho cả 10 và 30 tuần, bao gồm chiến lược `analyst`, và các tỷ lệ thắng nằm trong mục tiêu ở trên.
- Chỉ số cuối ván thắng (trung vị) nằm trong khoảng cho phép.
- `test_sim.gd`, `test_ui.gd` qua. `check_web.py` (chạy với `-X utf8 -I`) vẫn qua 6 mục.
- Ghi chú bàn giao trong TASKS.md: bảng kết quả trước và sau, lịch sử chỉnh số, các công cụ đã dùng và lý do.
