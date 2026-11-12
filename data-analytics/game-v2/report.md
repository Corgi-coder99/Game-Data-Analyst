# Case study 1: Data Corp v2 — phễu, chiến lược và độ khó (dữ liệu bot)

Dữ liệu: 720 run (12 bot x 60 seed, 10 ngày), 33.063 sự kiện, validator 0 lỗi. Nguồn là **bot**, không phải người chơi; mọi kết luận chỉ nói về cân bằng game, không nói về hành vi người (giả định A-004). Tái tạo: `tests/telemetry_bots.gd --games=60`, rồi `analyze_playlog.py`.

## Chất lượng dữ liệu
Không run trùng, không run thiếu `run_end`, `acc` trong [0,1], mỗi ngày đủ day_start/day_end/report_submit/wait. 127 run có ít hơn 10 `day_start` — không phải lỗi: đó là run bị sa thải (ending `fired`), xem phễu.

## Kết quả
1. **Phễu theo ngày.** 587/720 run sống sót đến hết (133 bị sa thải, trong đó 127 bị sa thải trước ngày 10). Mất run tập trung ở chiến lược kém: rumor_follower sa thải 44/60, random_reporter 36/60, official_only 12/60, analyst_slow 16/60; careful_hedger 0/60. Analyst sạch chỉ 1/60. Tỉ lệ thắng (`won`) tách rất rõ: analyst 90%, verifier 50%, official_only 22%, rumor 8%. → Game phân biệt tốt giữa chơi kỹ và chơi ẩu.
2. **Verify-first vs submit-early.** Kết quả **giống hệt** (acc 0.858, win 90%, chênh lệch ghép cặp = 0 trên 60 seed). Nguyên nhân: cả hai bot đều đi qua cùng bước phân tích sạch; verify thêm của "verify-first" (750 so với 375 lần) không đổi kết quả. Kết luận đúng: **thí nghiệm này không kiểm chứng được giá trị của verify**; cần bot đối chứng "không verify" thật. Đề xuất, chưa làm.
3. **Áp lực thời gian.** 83% báo cáo đúng hạn, 17% muộn, 0 bị lỡ; tỉ lệ này phẳng theo ngày (16,4–17%). Phẳng nghĩa là độ căng thời gian không tăng theo rank/ngày trong bot — nhưng phần "muộn" chủ yếu do bot chủ ý (late_verifier) nên chưa kết luận được đồng hồ có quá chặt với người.
4. **Độ khó câu hỏi.** acc trung bình 0,65–0,75 với 18/20 câu; **q5 (0,87) và q9 (0,90) dễ rõ rệt**, q1/q6/q8 khó nhất (0,65–0,67). Chênh lệch giữa câu khó nhất và trung vị chỉ ~0,06, nên chưa có câu nào "bất công". q5/q9 là ứng viên làm khó hơn hoặc kiểm tra lại đáp án (kiểu T-038). Lưu ý acc của bot trộn nhiều chiến lược, chưa tách theo bot.
5. **Retention D1/D7:** chưa làm được — bot không có ngày lịch thật. Cần người chơi thật.

## Giả định và giới hạn
- Bot không đại diện cho người; tỉ lệ thắng/bị sa thải là thước đo cân bằng, không phải hành vi.
- Số seed 60/bot, không có khoảng tin cậy cho so sánh giữa bot (chỉ mô tả).
- Mỗi bot dùng một chiến lược cố định, nên "chiến lược nào tốt" là định nghĩa của bot, không phải khám phá.
- Chưa tách độ khó câu hỏi theo bot hay theo rank.

## Bước tiếp theo
Thêm bot đối chứng "không verify" để trả lời câu 2, rồi tách độ khó theo bot (câu 4). Sau khi có người chơi thật (T-042) mới làm retention.
