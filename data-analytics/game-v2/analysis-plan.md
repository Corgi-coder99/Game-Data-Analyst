# Kế hoạch phân tích T-043: dữ liệu playlog Data Corp v2 (bot)

## Mục tiêu và quyết định phục vụ
Dùng playlog ẩn danh để trả lời 5 câu hỏi của SPEC-T-040 và quyết định: ngày nào/loại câu hỏi nào cần chỉnh cân bằng (T-038-style) trước khi phát hành.

## Nguồn dữ liệu
- `bot_playlog.jsonl` sinh bởi `tests/telemetry_bots.gd` (60 game mỗi bot, 12 bot, seed 104+, 10 ngày). `src="bot"`, `pid="bot-<tên>"`.
- Dữ liệu tổng hợp/synthetic, không có người thật: không có vấn đề định danh. Không dùng để kết luận về hành vi người chơi (A-004).
- Không đưa file thô vào git (sinh lại được bằng lệnh trong báo cáo); chỉ commit bảng tổng hợp.

## Câu hỏi và phương pháp
| # | Câu hỏi | Phương pháp (skill) | Bot dùng được? |
|---|---|---|---|
| 1 | Funnel theo ngày, nơi run kết thúc | funnel-analysis | Có (kết cục theo chiến lược) |
| 2 | Verify-first vs submit-early: acc, ev, trust, minutes | so sánh hai nhóm cùng seed (ghép cặp) | Có, đây là thí nghiệm thật vì cùng seed |
| 3 | Áp lực thời gian: on-time/late/missed theo ngày | tổng hợp theo ngày, rank | Có, nhưng phản ánh bot |
| 4 | Độ khó câu hỏi theo question_id/topic | acc theo câu hỏi | Có (độ khó khách quan của câu hỏi) |
| 5 | Retention D1/D7 | cohort-analysis | Không: bot không có `date` thật; ghi là chưa làm được |

## Kiểm tra chất lượng trước khi phân tích
Số run, số sự kiện mỗi loại, run thiếu run_end, trùng run_id, nhận biết giá trị lạ (acc ngoài [0,1]), khớp đếm với kỳ vọng (10 day_start/run).

## Tiêu chí hoàn thành
Có `report.md` với kết luận kèm giả định/giới hạn, bảng tổng hợp CSV, script chạy lại được, và checklist analysis-qa-checklist.
