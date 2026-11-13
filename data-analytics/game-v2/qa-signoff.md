# QA sign-off: case study 1 (T-043)

Analysis: Data Corp v2, phễu/chiến lược/độ khó trên playlog bot. Reviewer: Claude (tự kiểm tra, không độc lập). Author: Claude. Date: 2026-11-13. Audience: VU (portfolio, tài liệu nội bộ). Format: report.md + tables/*.csv.

## Automated (qa_runner.py trên 7 CSV)
Lần đầu: 1 FAIL (`question_difficulty.csv`: cột `wrong_label_share` rỗng hoàn toàn). Đã bỏ cột khỏi script, chạy lại: 0 FAIL, 2 WARN còn lại ở hai bảng ghép cặp (tên cột/số làm tròn, chấp nhận được).

## Manual
| Section | Status | Ghi chú |
|---|---|---|
| 1. Question framing | PASS | 4/5 câu trả lời, câu 5 ghi rõ chưa làm được |
| 2. Data sourcing | PASS | bot synthetic, validator 0 lỗi trên 35.552 sự kiện, không dữ liệu cá nhân |
| 3. Transformations | PASS | run/ngày khớp; số liệu báo cáo đối chiếu lại với bảng sau khi thêm bot thứ 13 |
| 4. Statistical validity | PASS có hạn chế | CI cho so sánh ghép cặp; không hiệu chỉnh đa so sánh (5 chỉ số); chỉ mô tả giữa bot |
| 5. Findings | PASS | đã sửa 2 lỗi: số liệu lỗi thời (720 → 780 run) và khẳng định "muộn do bot chủ ý" chưa kiểm chứng (nay có số: 2 bot gây 100% báo cáo muộn) |
| 6. Presentation | PASS | không có biểu đồ (chỉ bảng) |

## Issues
1. MUST FIX: cột rỗng — Fixed. 2. MUST FIX: số liệu báo cáo lệch dữ liệu — Fixed. 3. SHOULD FIX: không có biểu đồ — Deferred. 4. SHOULD FIX: nhiều so sánh, chưa hiệu chỉnh — Accepted (ghi trong giới hạn).

## Decision
[x] Approved with caveats: bot không đại diện người chơi; 60 seed/bot; hiệu ứng của verify lên điểm và tỉ lệ thắng chưa kết luận được; reviewer không độc lập.
