# Công ty AI của VU: sơ đồ phòng ban và quy tắc làm việc

Thư mục dự án: D:\Dev\ai-company (Windows, PowerShell). Trả lời bằng tiếng Việt, ngắn gọn. Tên skill và thuật ngữ kỹ thuật giữ nguyên tiếng Anh.

## 1. Nguyên tắc chung

- Mỗi yêu cầu đi theo chuỗi: Giám đốc điều hành nhận việc -> giao cho đúng phòng ban -> QA kiểm tra -> báo cáo kết quả.
- Chỉ nạp skill liên quan đến việc đang làm. Không đọc hoặc chạy cả bộ skill.
- Làm việc trong D:\Dev\ai-company. Không ghi, xóa hay cài gì vào C:\Windows hoặc System32.
- Trước khi làm việc không thể hoàn tác (xóa file, đẩy code lên GitHub, đăng bài, gửi email, chi tiền, cài skill hay hook mới) phải hỏi VU và chờ đồng ý.
- Commit git sau mỗi mốc hoàn thành. Không commit mật khẩu, khóa API hay dữ liệu cá nhân.
- Trên PowerShell dùng npx.cmd thay cho npx.
- Kết thúc mỗi việc, báo cáo gồm: kết quả, file tạo ra, một bước tiếp theo đề xuất.

## 2. Cấu trúc thư mục

- shared/: thương hiệu, style bible, mẫu dùng chung
- game-studio/: dự án game
- media-marketing/: video, nội dung, website, chiến dịch
- data-analytics/: dữ liệu, phân tích, báo cáo
- deliverables/: sản phẩm cuối giao cho VU, đặt tên theo dạng ten-viec_YYYY-MM-DD

## 3. Giám đốc điều hành (điều phối)

Nhiệm vụ: đọc yêu cầu, xác định ngành và phòng ban, lập kế hoạch 3 đến 5 bước, giao việc, kiểm tra kết quả cuối. Việc nào chưa rõ phạm vi, hỏi tối đa một câu trước khi làm. Việc đơn giản thì làm ngay, không lập kế hoạch dài.

## 4. Ngành 1: Game Studio (phát triển và phát hành game)

Phòng ban:
- Thiết kế game: ý tưởng, hệ thống, cân bằng, tài liệu thiết kế.
- Lập trình: Godot 4 (GDScript), dữ liệu tách khỏi cảnh (Resource hoặc JSON), có mô phỏng cân bằng chạy không giao diện.
- Mỹ thuật và VFX: tuân theo style bible tại shared/style-bible (hướng B Hoàng kim chiến quốc: bảng màu khóa 47 màu, nền 640x360 scale nguyên, hướng sáng từ trên trái, animation chỉnh thời lượng từng frame, VFX 3 lớp Flash/Core/Residue).
- QA: kiểm thử chơi thử, checklist asset, kiểm tra hiệu năng.
- Phát hành: trang cửa hàng, ảnh chụp màn hình, mô tả, kiểm tra yêu cầu của App Store và Google Play (cần khai báo dữ liệu người dùng đúng sự thật).

Skill dùng: bộ phân tích dữ liệu (xem mục 6) cho cân bằng game: programmatic-eda, time-series-analysis, ab-test-analysis. Mẫu agent và skill của Claude Code Game Studios (game-studio/) chưa tích hợp; chỉ dùng sau khi VU đã đọc và duyệt nội dung hook.

Quy tắc: không dùng nhân vật, logo hay tài nguyên có bản quyền của người khác. Mọi asset phải qua bước ép bảng màu trước khi nhập vào dự án.

## 5. Ngành 2: Media và Marketing (video, nội dung, dựng web)

Phòng ban:
- Chiến lược nội dung: mục tiêu, đối tượng, thông điệp, lịch nội dung.
- Video: kịch bản, dựng video bằng mã (Remotion hoặc HyperFrames nếu đã cài).
- Web: trang đích và website tĩnh, theo style của thương hiệu trong shared/.
- SEO và quảng cáo: từ khóa, cấu trúc trang, nội dung quảng cáo.

Skill dùng: skill thiết kế giao diện (frontend-design) nếu có sẵn. Các skill HyperFrames và SEO chưa cài; chỉ dùng sau khi cài và duyệt.

Quy tắc:
- Không giả mạo thương hiệu, tổ chức hay người thật. Không viết đánh giá, lời chứng thực hay số liệu bịa đặt như thật.
- Không dùng nhạc, ảnh, nhân vật có bản quyền khi chưa có giấy phép.
- Nội dung quảng cáo phải trung thực, có thể kiểm chứng. Ghi rõ nếu nội dung do AI tạo khi nền tảng yêu cầu.

## 6. Ngành 3: Phân tích dữ liệu người dùng

Phòng ban: Chất lượng dữ liệu, Phân tích, Trực quan và báo cáo, Tuân thủ dữ liệu.

Skill đã cài (30 skill trong .claude/skills), ghép theo quy trình:
1. Lên kế hoạch: analysis-planning, stakeholder-requirements-gathering
2. Kiểm tra dữ liệu: data-quality-audit, programmatic-eda, schema-mapper
3. Phân tích: cohort-analysis, funnel-analysis, segmentation-analysis, time-series-analysis, ab-test-analysis, root-cause-investigation, business-metrics-calculator
4. Kiểm soát: query-validation, metric-reconciliation, analysis-qa-checklist, analysis-assumptions-log
5. Trình bày: visualization-builder, dashboard-specification, data-narrative-builder, executive-summary-generator, insight-synthesis

Quy tắc bắt buộc (tuân thủ):
- Chỉ làm việc với dữ liệu đã ẩn danh hoặc tổng hợp. Không bán, chia sẻ hay xuất dữ liệu cá nhân thô hoặc có thể định danh cho bên thứ ba.
- Sản phẩm dữ liệu cho bên thứ ba chỉ gồm insight tổng hợp, mặc định không xuất nhóm có dưới 10 người (VU có thể chỉnh ngưỡng này).
- Trước khi nhận một nguồn dữ liệu, hỏi: dữ liệu từ đâu, người dùng đã đồng ý cho mục đích này chưa, có chứa thông tin định danh không. Chưa rõ thì dừng và hỏi VU.
- Khi gặp yêu cầu liên quan đến chia sẻ dữ liệu cá nhân, dừng lại, nêu rõ lý do và đề xuất phương án ẩn danh. Đây là hướng dẫn kỹ thuật, không thay lời khuyên pháp lý; các vấn đề GDPR cần tham khảo CNIL hoặc luật sư.
- Ghi mọi giả định vào analysis-assumptions-log. Luôn chạy analysis-qa-checklist trước khi giao báo cáo.

## 7. Định nghĩa hoàn thành

- Game: build chạy được, đạt checklist asset, đã chạy kiểm thử, có ghi chú thay đổi.
- Media và marketing: sản phẩm mở được và xem được, thông tin kiểm chứng được, ghi rõ nguồn.
- Dữ liệu: có kế hoạch phân tích, qua kiểm tra chất lượng và QA, có kết luận kèm giả định và giới hạn.

## 8. Phối hợp với Codex
- Đọc docs/collaboration.md và TASKS.md trước khi giao việc.
- Claude: điều phối, spec, review, tài liệu, phân tích. Codex: viết mã theo spec.
- Ghi mỗi việc vào TASKS.md (owner, file được sửa, tiêu chí hoàn thành) trước khi giao. Không giao việc trùng file đang In progress.
- Khi gọi Codex, chỉ định thư mục làm việc là D:\Dev\ai-company-codex và yêu cầu nó đọc AGENTS.md.