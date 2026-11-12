# Analysis assumptions log: Data Corp v2 playlog

Dùng cho dự án case study Game Data Analyst (T-040 đến T-043). Mỗi mục: giả định, lý do, ảnh hưởng nếu sai, cách kiểm tra.

| ID | Ngày | Giả định | Lý do | Rủi ro nếu sai | Cách kiểm |
|---|---|---|---|---|---|
| A-001 | 2026-11-12 | Telemetry là opt-in, mặc định tắt, không có mạng ở bản đầu | Giảm rủi ro GDPR; không cần server | Ít dữ liệu người chơi thật | Đếm số run xuất được sau khi phát hành |
| A-002 | 2026-11-12 | `player_pid` ngẫu nhiên là dữ liệu giả danh (pseudonymous), xóa khi rút đồng ý | Cần nối phiên để tính retention | Có thể bị coi là dữ liệu cá nhân | VU kiểm tra lại câu chữ đồng ý với trường hoặc hướng dẫn CNIL trước khi đăng; đây không phải tư vấn pháp lý |
| A-003 | 2026-11-12 | Game dành cho người chơi 16 tuổi trở lên, không hỏi tuổi | Tránh thu dữ liệu trẻ em | Người chơi nhỏ tuổi vẫn có thể tải | Ghi rõ trên trang cửa hàng |
| A-004 | 2026-11-12 | Dữ liệu bot (`src="bot"`) dùng để dựng pipeline, KHÔNG dùng để kết luận về hành vi người | Bot không phản ánh người | Kết luận sai nếu trộn | Luôn lọc theo `src`; báo cáo ghi rõ nguồn |
| A-005 | 2026-11-12 | So sánh tutorial và không tutorial chỉ là quan sát, không ngẫu nhiên | Người chọn tutorial khác nhóm còn lại | Nhầm tương quan thành nhân quả | Ghi giới hạn trong báo cáo; không dùng từ "gây ra" |
| A-006 | 2026-11-12 | Mẫu người chơi nhỏ (bạn bè, cộng đồng) và lệch | Không có kênh phân phối lớn | Khoảng tin cậy rộng, thiên lệch chọn mẫu | Báo cáo kích thước mẫu và khoảng tin cậy; không khái quát hóa |
