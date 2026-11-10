# Bảng công việc (Claude Code và Codex)

Quy tắc: xem docs/collaboration.md. Mỗi việc có đúng một owner. Nhận việc xong mới được sửa file.

Trạng thái: Backlog -> In progress -> Review -> Done. Bị chặn thì chuyển sang mục Blocked.

## Backlog

| ID | Việc | Owner | Nhánh | File được sửa | Tiêu chí hoàn thành |
|---|---|---|---|---|---|
| T-001 (ví dụ) | Viết spec tính năng X | Claude | claude/T-001 | docs/spec-x.md | Spec có mô tả, đầu vào, đầu ra, ví dụ |
| T-002 (ví dụ) | Cài đặt tính năng X theo spec T-001 | Codex | codex/T-002 | src/x.py, tests/test_x.py | Kiểm thử qua, đúng spec |
| T-008 | check_web.py: ép stdout UTF-8 để không lỗi UnicodeEncodeError trên console Windows mặc định | Codex | codex/T-008 | media-marketing/web/check_web.py | Chạy `python -I check_web.py` (không cần -X utf8) qua 6 mục |
| T-010 | Kịch bản và video quảng cáo 30 giây (làm sau T-012 để cảnh quay không hiện công ty gần hết người dùng) | Claude/Codex | chưa chốt | media-marketing/video/* | Chưa có spec |
| T-018 | Tầng thế giới (scripts/world/): kịch bản ẩn theo seed, phát sinh tin (đúng, sai, cũ, nhiễu), công cụ kiểm chứng, báo cáo chấm điểm, sự nghiệp, bot cân bằng. Spec xong, chờ VU duyệt để giao | Codex | codex/T-018 | game-studio/godot/scripts/world/*, data/world.json, data/questions.json, scripts/sim/simulation.gd (chỉ use_tool), tests/test_world.gd, tests/balance_world.gd, tests/test_sim.gd (chỉ use_tool) | Xem game-studio/godot/docs/SPEC-T-018.md |
| T-019 | Giao diện v2: cảnh văn phòng, màn hình máy tính và các cửa sổ, luồng báo cáo, họp cuối ngày. Chờ T-016, T-018 | Codex | codex/T-019 | scenes/*, scripts/ui/*, assets/* | Chưa có spec |

## In progress

(chưa có)

## Review

| ID | Việc | Owner | Nhánh | File được sửa | Tiêu chí hoàn thành |
|---|---|---|---|---|---|
| T-016 | Style bible pixel mới: bảng màu 32 màu, kích thước sprite, ánh sáng, giao diện máy tính, hoạt ảnh, kiểm tra tự động. Chờ VU xem | Claude | v2 | shared/style-bible/pixel-office-v2.md, palette-v2.json | VU duyệt style bible; quyết định có sửa CLAUDE.md mục 4 không |
| T-017 | Content bible v2 (thế giới hư cấu Tân Lạc, công ty Lục Châu, nhân vật, 10 nguồn tin, ánh xạ 8 cú sốc) và data/news.json (41 mẫu tin, đã kiểm hợp lệ). Chờ VU xem | Claude | v2 | game-studio/godot/docs/CONTENT-BIBLE-v2.md, data/news.json | VU duyệt nội dung |

## Done

| ID | Việc | Owner | Ngày |
|---|---|---|---|
| T-003 | Viết GDD Data Corp (game-studio/godot/docs/GDD.md), VU đã duyệt | Claude | 2026-11-09 |
| T-004 | Lõi mô phỏng Data Corp + balance_sim headless (Codex). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-09 |
| T-005a | Giao diện: khung và vòng tuần (Codex). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-09 |
| T-005b | Giao diện: dashboard đầy đủ (Codex). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-09 |
| T-005c | Giao diện: màn kết thúc, nhãn trục biểu đồ (Codex). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-09 |
| T-006 | Sửa công thức điểm: giới hạn LTV/CAC, ván thua tối đa 900 điểm (Codex). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-10 |
| T-007 | Landing page trung thực (media-marketing/web). Claude đã chạy check_web.py (6/6 PASS khi dùng UTF-8) và kiểm tra trình duyệt 360px/1280px; VU duyệt merge vào master | Codex | 2026-11-10 |
| T-009 | Cân bằng lại bản demo 10 tuần (Codex). Đạt 4/5 mục tiêu demo; chưa đạt: analyst không hơn balanced, 30 tuần quá khó (chuyển sang T-011). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-10 |
| T-011 | Thẻ xử lý chỉ gỡ sự kiện khi đã lộ nguyên nhân; analyst hơn balanced 11,55 điểm % ở demo; 30 tuần khả thi về thống kê (Codex). Còn nợ kinh tế chuyển sang T-012. Claude đã review, VU duyệt merge vào master | Codex | 2026-11-10 |
| T-012 | Chữa gốc kinh tế (Codex): Retention 85%, Cash 18.000, người thắng demo giữ khoảng 147% Users khởi điểm; bỏ hệ số chỉnh gượng ván 30 tuần; sửa 1 dòng fixture test_ui.gd (dòng 29) theo spec. GDD đã cập nhật lên 0.2. Claude đã review và chạy check_web.py, VU duyệt merge vào master | Codex | 2026-11-10 |
| T-013 | Giao diện: gợi ý thẻ xử lý khi nguyên nhân đã lộ (Codex); event_reports() thêm remedies chỉ khi đã lộ, balance_sim giống hệt master. Claude đã review, chụp màn hình và chạy check_web.py; VU duyệt merge vào master | Codex | 2026-11-10 |
| T-014 | Thay ảnh gameplay trên landing page bằng ảnh chụp từ ván chơi tự nhiên của bản mới (tuần 3/10, có sự kiện đã lộ và gợi ý thẻ xử lý); cập nhật alt. check_web.py 6/6 | Claude | 2026-11-10 |
| T-015 | Concept GDD v2 (game-studio/godot/docs/GDD-v2-concept.md). VU duyệt hướng v2; nguồn pixel art chốt: sprite viết bằng mã; bản v1 gắn tag demo-dashboard-v1, v2 phát triển trên nhánh v2 | Claude | 2026-11-10 |
| T-015 | Concept GDD v2 (game-studio/godot/docs/GDD-v2-concept.md). VU duyệt hướng v2; nguồn pixel art chốt: sprite viết bằng mã; bản v1 gắn tag demo-dashboard-v1, v2 phát triển trên nhánh v2 | Claude | 2026-11-10 |

## Blocked

(chưa có)

## Ghi chú bàn giao

### T-007 | Codex | 2026-11-10 | Review

- Đã nhận: owner Codex/In progress có sẵn, nhánh codex/T-007, master là tổ tiên HEAD; cây làm việc ban đầu sạch.
- Đã làm: landing page HTML/CSS thuần với đủ 9 mục, nội dung nguyên văn theo spec, metadata, liên kết neo, font hệ thống, responsive, focus bàn phím và reduced motion. Không form, JavaScript hay tài nguyên ngoài; không sửa assets. Script kiểm tra 6 mục bằng thư viện chuẩn, đối chiếu số liệu từ nguồn game và thoát khác 0 khi FAIL.
- File đổi: media-marketing/web/index.html, media-marketing/web/style.css, media-marketing/web/check_web.py; TASKS.md cho bàn giao/trạng thái.
- Kiểm tra: git diff --check qua. PNG đọc header được 640x360; CSS giới hạn 1280px và pixelated. Chưa kiểm tra bằng trình duyệt, không chụp ảnh; Claude cần xem 360px/1280px và console khi review.
- Chưa có kết quả PASS/FAIL thực tế của check_web.py: cả 6 mục (tài nguyên, 9 mục, ảnh/alt, số liệu, nội dung cấm/form, metadata) chưa chạy được. Worktree không có .venv. Đã thử `& D:\Dev\ai-company\.venv\Scripts\python.exe media-marketing\web\check_web.py`, báo Access is denied; Python gốc ghi trong pyvenv.cfg cũng bị Access is denied. Không thay quyền hay vượt sandbox. Chạy lại lệnh trên khi môi trường cho phép; chưa xác nhận tiêu chí toàn PASS.
- Tự quyết: bố cục tối, màu nhấn phụ #a9dec9, ảnh giữ tỷ lệ gốc, các khối chuyển cột theo chiều rộng. Nhãn mục lấy từ spec; alt mô tả tuần 4/10, nguyên nhân đã lộ, biểu đồ Users. Spec vừa cấm “bảng xếp hạng” vừa bắt buộc liệt kê trong “Chưa có”: giữ đúng nội dung bắt buộc, checker chỉ miễn trừ đúng dòng li này trong #not-yet; mọi ngữ cảnh khác vẫn cấm. Không thêm tuyên bố mới.
- Git: git add bị `fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied`. Để nguyên file chưa commit trong worktree; không vượt sandbox, không push, không merge.

### T-005c | Codex | 2026-11-09 | Review

- Đã nhận: owner Codex/In progress có sẵn khi bắt đầu; nhánh codex/T-005c cùng HEAD master (6d1699c), cây làm việc ban đầu sạch.
- Đã làm: màn kết thúc riêng thắng/thua, điểm, số sự kiện xử lý đúng, bảng 8 chỉ số thực/đã thấy, nút Chơi lại/Về tiêu đề; chỉ end_screen đọc chỉ số thực. Biểu đồ có min/max, nhãn tuần, đơn vị phần trăm, một điểm kèm nhãn; giữ mọi report và tránh nhãn tuần chồng nhau.
- File đổi (dưới game-studio/godot/): scenes/end.tscn (mới), scenes/game.tscn (bỏ nhãn kết thúc tạm), scripts/ui/end_screen.gd (mới), scripts/ui/game_controller.gd, scripts/ui/metric_chart.gd, data/strings.json, tests/test_ui.gd; TASKS.md cho bàn giao. Không sửa sim hoặc ba JSON lõi.
- Kiểm tra thực tế: Godot console 4.7.2, --headless --path game-studio/godot --script res://tests/<script>. test_ui.gd: 106 checks, 0 failures (thắng/thua, điểm, bảng thật/báo cáo, replay, về tiêu đề, kích thước bảng và glyph tiếng Việt); test_sim.gd: 118 checks, 0 failures; balance_sim.gd: 2.000 ván/chiến lược, balanced 40,85%, các baseline khác giữ nguyên; cả ba exit 0. git diff --check qua. Console vẫn báo Failed to open log file for writing và Failed to read the root certificate store; không lỗi script. Không chụp ảnh; chưa review trực quan bằng mắt, Claude cần xem khi review.
- Tự quyết: so số thực sau tuần kết thúc với report cuối người chơi đã thấy trước khi kết thúc tuần, ghi rõ chênh lệch gồm nhiễu và diễn biến tuần cuối; không gọi report mới khi kết thúc. Dùng font mặc định Godot, không thêm font ngoài nên không cần CREDITS.md. Nhánh thua dùng fixture tiền âm qua apply_effect() công khai vì seed 105 không hành động vẫn thắng; không đổi dữ liệu mô phỏng.
- Git: git add bị `fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied`. Chưa commit; để nguyên file trong worktree, không vượt sandbox, không push, không merge.

Mỗi việc xong thì thêm một mục theo mẫu:

- T-xxx | Bên làm | Ngày
  - Đã làm:
  - File đổi:
  - Cách kiểm tra:
  - Việc cần bên kia xem:

### T-004 | Codex | 2026-11-09 | Review

- Đã làm: lõi RefCounted theo seed, kinh tế tuần, rút 4 thẻ không lặp trong tay, giới hạn Budget/Energy, hiệu ứng trễ/có hạn, sự kiện chồng nhau, lộ và xử lý nguyên nhân, nhiễu chỉ trên báo cáo; thắng/thua demo và đầy đủ, điểm số. RNG báo cáo riêng để việc đọc dashboard không đổi diễn biến ván.
- File đổi: `data/config.json`, `data/cards.json`, `data/events.json`, `scripts/sim/company.gd`, `scripts/sim/simulation.gd`, `tests/test_sim.gd`, `tests/balance_sim.gd` (đường dẫn dưới `game-studio/godot/`); `TASKS.md` cho bàn giao. Không sửa `scripts/data.gd`.
- Cách kiểm tra: đã chạy đúng hai lệnh headless trong yêu cầu bằng Godot 4.7.2. `test_sim.gd`: 118 checks, 0 failures, exit 0. `balance_sim.gd`: 2.000 ván **mỗi chiến lược** (8.000 tổng), seed 104..2103, exit 0, 6,369 giây. Không có lỗi script ở lượt cuối. Môi trường vẫn in `Failed to open log file for writing: user://logs/godot.log` và `Failed to read the root certificate store`; không khẳng định console hoàn toàn không lỗi. Lượt có thêm `--log-file` trong phạm vi tests loại bỏ lỗi log, vẫn có lỗi kho chứng chỉ.
- Git: đang ở `codex/T-004`, ban đầu cây làm việc sạch. Chưa commit được: `git add` và `git commit` bị `Permission denied` khi tạo `D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock` (metadata Git nằm ngoài vùng được ghi). Không push, không merge. Cần chạy commit khi môi trường cho phép ghi metadata Git.

Kết quả cuối (Cash gồm cả ván thắng và thua; Cash âm là số dư tại tuần đã thua, không ép về 0):

| Chiến lược | Thắng | Tuần thua trung vị | Thua trước tuần 15 | Cash min / p25 / p50 / p75 / max |
|---|---:|---:|---:|---|
| Ngẫu nhiên | 23,15% | 9 | 73,55% | -947,73 / -421,42 / -182,67 / -8,51 / 204.972,41 |
| Chỉ quảng cáo | 0% | 11 | 100% | -799,99 / -633,88 / -522,40 / -387,24 / -1,12 |
| Chỉ tối ưu | 29,25% | 12 | 50% | -932,26 / -302,33 / -102,02 / 2.779,41 / 92.561,36 |
| Cân bằng | 40,85% | 10 | 52,25% | -890,19 / -252,41 / -46,18 / 32.620,15 / 172.047,71 |

Lịch sử chỉnh số (2.000 ván/chiến lược mỗi lần; các giá trị khác giữ nguyên):

| Lần | Onboarding ΔRetention | Fix Checkout ΔConversion | Thắng ngẫu nhiên / quảng cáo / tối ưu / cân bằng | Thời gian |
|---|---:|---:|---|---:|
| 1 | +18 điểm % | +2,5 điểm % | 4,25% / 0% / 8,75% / 11,40% | 8,138 giây |
| 2 | +25 điểm % | +4 điểm % | 22,05% / 0% / 28,55% / 39,10% | 10,137 giây |
| 3 (cuối) | +25 điểm % | +4,2 điểm % | 23,15% / 0% / 29,25% / 40,85% | 6,369 giây |

Giá trị thẻ đề xuất cần Claude duyệt (Budget/Energy; hiệu ứng cộng dồn, mặc định lâu dài nếu không ghi hạn):

| Thẻ | Budget / Energy | Hiệu ứng |
|---|---|---|
| SQL Deep-Dive | 50 / 1 | Lộ app_bug, competitor_discount, logging_error, bad_traffic |
| A/B Test | 100 / 1 | Sai số preview còn 10% đến hành động kế tiếp; lộ trend_shift, price_fatigue |
| Funnel Report | 50 / 1 | Lộ checkout_outage, server_outage |
| Clean Data | 100 / 1 | Integrity +25; xử lý logging_error |
| Fix Checkout Bug | 250 / 1 | Conversion +4,2 điểm %; xử lý checkout_outage |
| Onboarding Redesign | 300 / 1 | Retention +25 điểm %, bật cờ onboarding; xử lý app_bug, bad_traffic |
| Support Automation | 250 / 1 | Chi phí cố định -100/tuần; xử lý server_outage |
| Ads Campaign | 700 / 1 | Chi quảng cáo 700, trừ Budget đúng một lần |
| Influencer Campaign | 1.000 / 2 | Users +200; Retention -12 điểm % trong 3 tuần nếu chưa onboarding |
| Loyalty Program | 150 / 1 | Retention +8 điểm %, chi phí +80/tuần trong 4 tuần; xử lý competitor_discount, price_fatigue |
| SEO Content | 150 / 1 | CAC -0,8 sau 2 tuần, giữ đến hết ván; xử lý trend_shift |
| Giảm giá | 0 / 1 | Conversion +1,5 điểm %, ARPU -5 trong 3 tuần; xử lý competitor_discount, price_fatigue |

Giá trị sự kiện đề xuất cần Claude duyệt (hiệu ứng áp dụng ngay; thẻ xử lý gỡ các modifier còn hiệu lực, không hoàn tác user đã mất):

| ID / nguyên nhân | Triệu chứng và tác động | Hạn | Thẻ lộ → thẻ xử lý |
|---|---|---|---|
| app_bug / lỗi khởi động app | Retention -15 điểm % | 3 tuần | SQL → Onboarding |
| competitor_discount / đối thủ giảm giá | Retention -10 điểm % | 3 tuần | SQL → Loyalty hoặc Giảm giá |
| logging_error / log trùng | Integrity -30, báo cáo Retention -20 điểm %, Retention thực không đổi | 4 tuần | SQL → Clean Data |
| checkout_outage / lỗi thanh toán | Conversion -2,5 điểm % | 3 tuần | Funnel → Fix Checkout |
| server_outage / máy chủ quá tải | Users -100 một lần (sàn 0), Conversion -1,5 điểm % | 2 tuần | Funnel → Support |
| trend_shift / đổi xu hướng | CAC +5 | 4 tuần | A/B → SEO |
| bad_traffic / sai đối tượng | Retention -12 điểm % | 4 tuần | SQL → Onboarding |
| price_fatigue / phản ứng giá | Conversion -2 điểm % | 4 tuần | A/B → Giảm giá hoặc Loyalty |

- Hệ số phụ cần Claude duyệt: chi phí biến đổi 0,05 × Users sau churn/mua mới; sàn chi phí cố định 100, CAC 1; trần Retention 98%, Conversion 100%, Integrity 100; nhiễu tương đối tối đa ±50% × (1 - Integrity/100). Pha tuần 1–10 / 11–20 / 21–30: xác suất sự kiện 30% / 60% / 80%, số lượt lấy mẫu 1 / 1 / 2, Integrity giảm 0 / 1 / 2 mỗi tuần. Điểm = Cash + 100 × LTV/CAC + 500 × số sự kiện xử lý đúng.
- Cần review: GDD chỉ mô tả ví dụ sự kiện, nên cả tám nguyên nhân và số liệu trên là đề xuất. Bot cân bằng ưu tiên Onboarding → Checkout → Ads → Support → SEO → Loyalty → Clean → SQL → Funnel → A/B → Giảm giá → Influencer, thử chơi mọi thẻ trong tay theo thứ tự nếu đủ tiền/năng lượng; không dùng nguyên nhân ẩn. Kết quả là baseline cho bot này, cần playtest UI sau. Thẻ phân tích hiện cung cấp thông tin nguyên nhân và độ chính xác preview; biểu đồ cohort/funnel thuộc phần UI ngoài phạm vi.

### T-005a | Codex | 2026-11-09 | Review

- Đã nhận việc trên nhánh codex/T-005a; chỉ triển khai phần a theo SPEC-T-005-split.md.

- Đã làm: màn tiêu đề Chơi/Thoát, HUD và 7 chỉ số báo cáo, tay 4 thẻ có trạng thái mờ/khóa, vòng tuần demo 10 tuần, nhãn kết thúc Thắng/Thua và điểm. Chỉ phần a; không biểu đồ, không chụp ảnh.
- File đổi (dưới game-studio/godot/): scenes/title.tscn, scenes/game.tscn, scripts/ui/title_screen.gd, scripts/ui/game_controller.gd, scripts/ui/palette.gd, assets/theme/main_theme.tres, data/strings.json, tests/test_ui.gd; project.godot chỉ dòng run/main_scene. TASKS.md cập nhật trạng thái và bàn giao.
- Cách kiểm tra: Godot 4.7.2 console, --headless --path game-studio/godot --script res://tests/test_ui.gd (12 checks, 0 failures); test_sim.gd (118 checks, 0 failures); balance_sim.gd (2.000 ván/chiến lược, balanced 40,85%, các chiến lược khác giữ baseline). Cả ba exit 0. git diff --check qua. Không sửa sim hoặc ba JSON lõi.
- Tự quyết: seed kiểm thử thắng là 105; ván thường lấy seed theo thời gian. LTV/CAC tính từ các chỉ số report, dùng churn_floor cấu hình. Cash báo cáo quyết định mờ/khóa thẻ; lõi vẫn kiểm tra Cash thực và UI báo từ chối chung nếu số nhiễu gây lệch. Dùng font mặc định Godot, không thêm tài sản ngoài. Màn kết thúc tạm thay nội dung ngay trong scene game.
- Cần Claude xem: xác nhận cách khóa thẻ theo Cash có nhiễu; review trực quan tiếng Việt/bố cục (không chụp ảnh theo yêu cầu). Godot vẫn báo Failed to open log file for writing: user://logs/godot.log và Failed to read the root certificate store; không có lỗi script.
- Git: nhánh codex/T-005a, xác nhận master là tổ tiên HEAD. Chưa commit: git add bị lỗi nguyên văn `fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied`. Để nguyên file chưa commit, không vượt sandbox, không push, không merge.

### T-005b | Codex | 2026-11-09 | Review

- Đã nhận việc trên nhánh codex/T-005b; chỉ sửa phạm vi phần b, không chụp ảnh.

- Đã làm: 7 ô chỉ số/mũi tên theo báo cáo cuối tuần trước, bấm chọn biểu đồ `_draw()` lưu từng report kèm tuần; dấu ? với LOW_INTEGRITY_THRESHOLD = 60; triệu chứng và nguyên nhân lấy từ event_reports(); nhật ký tuần; chi tiết thẻ khi hover, màu nhóm, phím 1–4 và Enter; phản hồi HUD 0,2 giây. Giữ màn kết thúc tạm từ T-005a.
- File đổi (dưới game-studio/godot/): scenes/game.tscn, scripts/ui/game_controller.gd, scripts/ui/metric_chart.gd (mới), scripts/ui/palette.gd, data/strings.json, tests/test_ui.gd; TASKS.md cho trạng thái và bàn giao.
- Cách kiểm tra: Godot console 4.7.2, --headless --path game-studio/godot --script res://tests/{test_ui.gd,test_sim.gd,balance_sim.gd} (chạy riêng từng script). UI 32 checks, 0 failures (che/lộ nguyên nhân bằng thẻ SQL, chọn biểu đồ, lịch sử, cảnh báo, restart, tooltip, phím 1/Enter, kích thước container <=640x360); sim 118 checks, 0 failures; balance 2.000 ván/chiến lược, balanced 40,85%, giữ nguyên toàn bộ baseline. Cả ba exit 0. Không sửa sim hay JSON lõi; không chụp ảnh, không làm T-005c.
- Tự quyết/cần review: nhật ký là ước tính từ report cuối trước khi kết thúc tuần (có nhãn rõ), tính mới/mất/doanh thu/chi phí bằng công thức kinh tế và cấu hình công khai; không hiển thị số thật từ finish_week(). Mũi tên so với report cuối tuần trước, tuần đầu dùng →. Biểu đồ lưu mọi lần đọc report, kể cả sau chơi thẻ; trục dọc tự co và có min/max. Tên thẻ dài có tooltip đầy đủ; cần Claude review trực quan tiếng Việt (không chụp ảnh). Dùng bảng màu tập trung, không thêm tài sản ngoài.
- Môi trường: vẫn báo Failed to open log file for writing và Failed to read the root certificate store; không có lỗi script.

- Git: git diff --check qua. Chưa commit: git add bị lỗi Permission denied khi tạo D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock. Để file chưa commit, không vượt sandbox, không push, không merge.

### T-006 | Codex | 2026-11-09 | Review

- Đã nhận: owner Codex/In progress có sẵn; nhánh codex/T-006 đã tồn tại, đang được chọn và cùng commit master 6e0ab7c; cây làm việc ban đầu sạch.
- Đã làm: score() tách thắng/thua/chưa kết thúc đúng SPEC-T-006; cập nhật đủ tám hệ số cấu hình, giữ tên khóa cũ. Không đổi mô phỏng tuần, thẻ, sự kiện hoặc điều kiện thắng/thua.
- File đổi: game-studio/godot/scripts/sim/simulation.gd (chỉ score), game-studio/godot/data/config.json (chỉ score), game-studio/godot/tests/test_sim.gd; TASKS.md cho trạng thái/bàn giao.
- Kiểm tra: Godot console 4.7.2 --headless --path game-studio/godot --script res://tests/<script>. test_sim.gd: 2.131 checks, 0 failures (giữ 118 checks cũ, thêm 2.013); test_ui.gd: 106 checks, 0 failures; balance_sim.gd: 2.000 ván/chiến lược, random 23,15%, ads_only 0%, optimization_only 29,25%, balanced 40,85%; các số liệu khác giữ nguyên. Cả ba exit 0; git diff --check qua. Môi trường vẫn báo không ghi được user://logs/godot.log và không đọc được kho chứng chỉ; không có lỗi script.
- Điểm mẫu: fixture thua Cash -444, ratio 70, tuần 30, resolved 20 = 900; thắng Cash 1, ratio 5 hoặc 70, resolved 0 = 1.500,1. Ván thật seed 104: random thắng Cash 82.807,53, điểm 10.880,75; ads_only thua Cash -594,06, điểm 440; optimization_only thua Cash -473,06, điểm 580; balanced thua Cash -401,09, điểm 500. Quét 500 ván mỗi chiến lược: 496 thắng/1.504 thua; điểm thắng nhỏ nhất 2.008,46 > điểm thua lớn nhất 900.
- Tự quyết: dùng lại nhánh hiện có vì trùng master, không reset; không làm phần balance_sim tùy chọn; dùng fixture tổng hợp cho biên điểm và quét chung bốn chiến lược để kiểm tra bất biến giữa mọi ván thắng/thua. Không đổi tên khóa.
- Git: git add bị fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied. Để nguyên file chưa commit, không vượt sandbox, không push, không merge.

### T-009 | Codex | 2026-11-10 | Review — chưa đạt toàn bộ cân bằng

- Nhận việc: owner Codex/In progress đã có sẵn. Lệnh tạo nhánh báo đã tồn tại; đang checkout codex/T-009, HEAD = master = 5014ff8, cây làm việc ban đầu sạch. Không reset, không push, không merge.
- Đã làm: công cụ đo mặc định cả 10/30 tuần, 2.000 ván/chiến lược, seed 104..2103; hỗ trợ --weeks=10/30, --games=N, --seed=N để tái hiện fixture. In Cash quantiles, tuần thua, tỷ lệ thua sớm và trung vị Retention/Conversion/LTV-CAC của riêng ván thắng (n/a nếu không có). Analyst chỉ chọn hành động từ event_reports(), tay bài và định nghĩa sự kiện công khai; không đọc state.base/active_events. Hai sự kiện cùng triệu chứng Conversion giảm được xét như các ứng viên, không biết trước nguyên nhân ẩn. Số thật chỉ được đọc sau kết thúc để thống kê, giống các bot khác.
- Công cụ cân bằng đã chọn: hiệu ứng giảm một nửa sau mỗi lần chơi thành công cho Onboarding, Checkout, Support, SEO (kể cả SEO trễ); không dùng once để giữ khả năng xử lý sự kiện tái xuất. Giữ chi phí thẻ, cơ chế rút và khả năng xử lý nguyên nhân chưa lộ. Hạ trần Retention 75%, Conversion 8%; chỉnh giá trị/chi phí; điều kiện thắng demo cấu hình min_cash=500, min_ratio=5, min_users=12 để sống sót với công ty gần hết user không tự thắng. Điều kiện này chỉ áp dụng horizon demo, không áp dụng bản 30 tuần. Không sửa công thức điểm T-006.
- Số cuối: Cash đầu 8.000; fixed_cost 450, sàn 10; ad_diminishing 0,01. Onboarding +0,15; Checkout +0,03; Support -250; SEO -0,8 sau hai tuần (bốn nâng cấp đều giảm dần). Ads Budget=ad_spend=300, tính tiền đúng một lần. Loyalty Budget=400, fixed_cost +20 trong 4 tuần; các giá trị khác giữ gốc. Thử nghiệm tăng ad_spend vượt Budget đã loại, không có khoản quảng cáo miễn phí ở bản bàn giao.
- File đổi: game-studio/godot/scripts/sim/simulation.gd, game-studio/godot/data/cards.json, game-studio/godot/data/config.json, game-studio/godot/tests/balance_sim.gd, game-studio/godot/tests/test_sim.gd; TASKS.md cho trạng thái/bàn giao. Không sửa events.json, UI, scenes, landing page. Giữ 12 thẻ, 8 sự kiện, 7 chỉ số và demo 10 tuần.

Bảng trước/sau (2.000 ván mỗi dòng; thứ tự ba chỉ số là Retention % / Conversion % / LTV-CAC, chỉ ván thắng):

| Tuần | Chiến lược | Thắng trước | Thắng sau | Chỉ số trước | Chỉ số sau |
|---|---|---:|---:|---|---|
| 10 | random | 37,25% | 17,05% | 98 / 14,60 / 70,42 | 75 / 6,50 / 5,97 |
| 10 | ads_only | 53,30% | 0% | 40 / 2 / 2,78 | n/a |
| 10 | optimization_only | 89,80% | 27,90% | 98 / 14,60 / 93,28 | 75 / 7,25 / 7,14 |
| 10 | balanced | 61,50% | 46,45% | 98 / 18,80 / 88,03 | 75 / 7,25 / 6,84 |
| 10 | analyst | 61,10% | 45,35% | 98 / 18,80 / 88,03 | 75 / 7,25 / 6,67 |
| 30 | random | 23,15% | 0% | 98 / 33,10 / 98,04 | n/a |
| 30 | ads_only | 0% | 0% | n/a | n/a |
| 30 | optimization_only | 29,25% | 9,95% | 98 / 43,70 / 145,35 | 44,53 / 4,49 / 2,68 |
| 30 | balanced | 40,85% | 0% | 98 / 45,20 / 132,98 | n/a |
| 30 | analyst | 40,05% | 0% | 98 / 44 / 122,55 | n/a |

Lịch sử chỉnh số (mọi vòng đủ 2.000 ván mỗi chiến lược; thông số không nêu giữ từ vòng trước; R/A/O/B/P = random/ads/optimization/balanced/analyst, đơn vị %):

| Vòng | Thay đổi | Thắng demo R/A/O/B/P | Thắng 30 tuần B/P |
|---|---|---|---|
| 0 | Gốc, thêm công cụ đo và analyst | 37,25 / 53,30 / 89,80 / 61,50 / 61,10 | 40,85 / 40,05 |
| 1 | Cash 6.000, fixed 450; cap 75%/8%; Onboarding +15 điểm %, Checkout +3 điểm %; Influencer 600/+400 user. Cờ diminishing chưa được áp dụng ở lượt này, phát hiện và sửa ở vòng 2 | 11,85 / 30,05 / 47,90 / 4,70 / 5,15 | 0 / 0 |
| 2 | Bật thực thi giảm dần cả bốn nâng cấp; Cash 7.000, fixed 300; Ads spend 2.800/Budget 700; win Cash >=1.700 | 14,20 / 68,65 / 47,55 / 2,95 / 3,50 | 0 / 0 |
| 3 | Ads Budget 200, Influencer Budget 200; Loyalty fixed +20; win Cash >=2.200, ratio >=4 | 44,75 / 0 / 52,35 / 54,05 / 53,05 | 0 / 0 |
| 4 | Ads spend 5.000; Support -150; Influencer trở lại 1.000/+200; win Cash >=2.700 | 20,60 / 0 / 47,95 / 70 / 68,70 | 6,20 / 4,80 |
| 5 | Ads spend 20.000/Budget 400; win Cash >=3.000; loại phương án vì spend vượt Budget | 27,90 / 0 / 31,45 / 77,50 / 76 | 56,70 / 50,35 |
| 6 | Ads trở lại 700/700; Cash 10.000, fixed 450; ad_diminishing 0,01; win Cash >=1.800 | 25,15 / 0 / 94,30 / 48,25 / 49,20 | 0 / 0 |
| 7 | Cash 8.000; sàn fixed 10; Support -250; Ads 300/300; Loyalty Budget 400; win Cash >=1.200 | 20,75 / 0 / 85,25 / 50,25 / 50,55 | 0 / 0 |
| 8 | win Cash >=1.250, Users >=20 | 14,75 / 0 / 13,75 / 32,75 / 32,50 | 0 / 0 |
| 9 | win Users >=10 | 17,45 / 0 / 33,35 / 41,25 / 41 | 0 / 0 |
| 10 | win Cash >=500, ratio >=5, Users >=12; fixture UI seed105 đủ Cash 615,47 nên giữ kiểm thử thắng | 17,05 / 0 / 27,90 / 46,45 / 45,35 | 0 / 0 |
| 11 (cuối) | Giới hạn điều kiện win mới vào demo như spec; bản full giữ thắng bằng sống sót | 17,05 / 0 / 27,90 / 46,45 / 45,35 | 0 / 0 |

- Kiểm thử: Godot console 4.7.2 tại đường dẫn VU cung cấp, --headless --path game-studio/godot --script res://tests/<script>. test_sim.gd: 2.212 checks, 0 failures, exit 0; test_ui.gd: 106 checks, 0 failures, exit 0, không sửa test_ui. balance_sim.gd: đủ 10 dòng/20.000 ván, exit 0, 14,164 giây ở lượt cuối. Score sweep 500 ván/chiến lược có 55 thắng/1.945 thua; min điểm thắng 1.302,27 > max thua 900. git diff --check qua sau dọn whitespace.
- Test cũ không xóa: đổi số kỳ vọng kinh tế theo Cash/fixed/ad_diminishing mới, Retention sau Onboarding 0,65 -> 0,55, Budget Ads 700 -> 300. Fixture horizon demo tắt điều kiện win trong bản config riêng để chỉ kiểm tra thời lượng; bổ sung kiểm tra độc lập cả ba điều kiện thắng. Fixture score giữ cap 98% trong config riêng để tiếp tục kiểm tra ratio 5/70 nguyên gốc; không thay cap game. Thêm kiểm tra hiệu ứng giảm 1/2 kể cả SEO trễ, từ chối không tính lượt, xử lý sự kiện khi nâng cấp đã chơi nhiều lần, trần/sàn và số nội dung; giữ kiểm tra tái lập seed và bất biến điểm cũ.
- Công cụ thực thi: PowerShell/.NET để đọc/chỉnh file; Godot headless để đo/kiểm thử; Git để kiểm tra nhánh/diff và thử commit. Python .venv đã thử: `D:\Dev\ai-company\.venv\Scripts\python.exe -X utf8 -I media-marketing/web/check_web.py` bị `Access is denied` lúc tạo process. Chưa xác nhận check_web 6/6; Claude cần tự chạy. Không đổi quyền hoặc vượt sandbox. Godot vẫn báo không ghi được user://logs/godot.log và không đọc được root certificate store; không có lỗi script ở kết quả cuối.
- Chưa đạt: analyst 45,35% thấp hơn balanced 1,10 điểm %, cần >=56,45%; balanced 30 tuần 0%, yêu cầu 30–55%. Bốn baseline demo và mọi trung vị ván thắng đạt. Không coi đây là bản đủ điều kiện merge. Nguyên nhân quan sát: xử lý sự kiện không cần lộ nguyên nhân nên bot balanced vẫn sửa được lỗi; phân tích dùng thêm Energy/Budget, còn tay 4 thẻ giới hạn cặp phân tích/xử lý. Về kinh tế dài hạn, ratio hiện tại = ARPU/((1-Retention)*CAC), nhưng doanh thu còn nhân Conversion <=8%; với ratio trung vị khoảng 6–7, hoàn vốn doanh thu của mua user chỉ khoảng 0,5 lần chi phí trước fixed cost. Giảm cộng dồn đã bỏ nguồn lợi nhuận ảo cũ; các bot tiếp tục mua nâng cấp đắt dù tác dụng gần 0, dẫn đến cạn Cash. Đây là chẩn đoán từ các vòng thử, không khẳng định không tồn tại bộ số đạt trong phạm vi công cụ cho phép.
- Cần Claude/VU xem: giữ bản này làm mốc đo/demo để chỉnh tiếp hay duyệt spec bổ sung về định nghĩa LTV, vai trò bắt buộc của chẩn đoán, hoặc bot tránh mua nâng cấp gần hết tác dụng. Đây là các hướng ngoài công cụ hiện được duyệt, chưa triển khai; không tự sửa công thức kinh tế, điều kiện xử lý hay cơ chế rút bài.
- Git: git add bị `fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied`. Không thể stage/commit; để nguyên sáu file chưa commit trong worktree codex/T-009, không vượt sandbox, không push, không merge.

### T-011 | Codex | 2026-11-10 | Review

- Nhận việc: đã đọc AGENTS.md, docs/collaboration.md, TASKS.md (cả T-009), SPEC-T-011 và SPEC-T-009. Owner Codex/In progress đã có sẵn. Nhánh codex/T-011 tồn tại, đang checkout và cùng master 8d01d24 (đã có T-009), cây ban đầu sạch. Lệnh tạo nhánh báo đã tồn tại nên dùng nhánh này, không reset.
- Đã làm: play() chỉ gỡ incident khi event.revealed và thẻ thuộc resolved_by. Chơi mù vẫn tính tiền, Energy, hiệu ứng và diminishing bình thường, không cộng resolved; chẩn đoán không hồi tố lần chơi mù. Lộ rồi xử lý cùng tuần hoặc tuần sau đều được; hết hạn tự nhiên không cộng resolved. Giữ score() T-006, 12 thẻ, 8 sự kiện, 7 chỉ số, demo 10 tuần.
- File đổi: game-studio/godot/scripts/sim/simulation.gd; game-studio/godot/data/{cards,events,config}.json; game-studio/godot/tests/{balance_sim,test_sim}.gd; TASKS.md cho trạng thái/bàn giao. Không sửa UI, scenes, test_ui.gd, media-marketing.

Bảng trước/sau: trước lấy từ baseline master T-009 đã ghi trong spec/bàn giao, không coi là phép đo lại ở T-011; sau là output thật vòng 9, 2.000 ván/chiến lược, seed 104..2103. Trung vị chỉ tính ván thắng, thứ tự Retention % / Conversion % / LTV-CAC.

| Tuần | Bot | Thắng trước | Thắng sau | Trung vị trước | Trung vị sau |
|---|---|---:|---:|---|---|
| 10 | random | 17,05% | 12,50% | 75 / 6,50 / 5,97 | 70,50 / 6,50 / 4,77 |
| 10 | ads_only | 0% | 0% | n/a | n/a |
| 10 | optimization_only | 27,90% | 26,25% | 75 / 7,25 / 7,14 | 66,25 / 2,25 / 4,62 |
| 10 | balanced | 46,45% | 41,80% | 75 / 7,25 / 6,84 | 74,25 / 3,75 / 4,41 |
| 10 | analyst | 45,35% | 53,35% | 75 / 7,25 / 6,67 | 74,25 / 7,25 / 4,99 |
| 30 | random | 0% | 9,30% | n/a | 75 / 8 / 5,97 |
| 30 | ads_only | 0% | 0% | n/a | n/a |
| 30 | optimization_only | 9,95% | 0% | 44,53 / 4,49 / 2,68 | n/a |
| 30 | balanced | 0% | 34,80% | n/a | 74,25 / 7,25 / 5,45 |
| 30 | analyst | 0% | 55,00% | n/a | 75 / 8 / 5,88 |

Lịch sử chỉnh số: mọi vòng chạy đủ ba script, balance 20.000 ván/vòng; R/A/O/B/P = random/ads/optimization/balanced/analyst, đơn vị %. Giá trị không nêu giữ vòng trước. S/U là failures sim/UI; lỗi fixture được sửa ở vòng sau, không bỏ kiểm tra.

| Vòng | Thay đổi | Demo R/A/O/B/P | Full R/B/P | S/U |
|---|---|---|---|---|
| 0 | Bắt buộc revealed; bot xác định ngừng nâng cấp sau 3 lần, random giữ ngẫu nhiên | 13,65 / 0 / 18,25 / 34,50 / 37,45 | 0 / 0 / 0,05 | 0/2 |
| 1 | Cash 8.400; demo ratio 4,5; ba thẻ lộ Budget/Energy 0/0; modifier Retention/Conversion/CAC của sự kiện kéo dài 8 tuần; chi phí vận hành từ tuần 11 nhân 0,1 | 20,95 / 0 / 15,05 / 32,25 / 38 | 45 / 62,35 / 65 | 1/0 |
| 2 | Chance demo 0,6; tách win.demo=Cash 1.400/ratio 3,5/users 8, win.full=0/3/8; Budget từ tuần 11 nhân 0,1; sửa kỳ vọng Cash test theo vốn mới | 9 / 0 / 6,55 / 22,60 / 30,10 | 16,40 / 3,70 / 30,80 | 1/2 |
| 3 | Chance demo 0,3; demo gates 500/3,5/3; full Cash 1.000; penalty Retention -0,3, Conversion -0,05; fixture full horizon tắt gate riêng | 23,65 / 0 / 23,35 / 38,90 / 46,80 | 2 / 0,45 / 9,25 | 0/2 |
| 4 | Cash 9.000; demo gates 500/4/2; chance tuần 11–30 =0,3, count=1; Influencer 1.600; price_fatigue ưu tiên Loyalty trước Discount | 16,90 / 0 / 21,90 / 34,40 / 43,55 | 22,20 / 39,15 / 61,35 | 0/2 |
| 5 | Demo gates 300/3,5/2; full Cash 2.500; Budget từ tuần 11 nhân 0,05 | 23,35 / 0 / 25,60 / 41,25 / 49,90 | 16,60 / 28,85 / 51,70 | 0/0 |
| 6 | Chance demo 0,4, full 0,2; demo gates 300/3/1; full Cash 3.500; Influencer 2.400 | 13,45 / 0 / 19,95 / 33,90 / 42,80 | 7,70 / 18,25 / 33,10 | 0/0 |
| 7 | Demo users >=0,1; ba thẻ lộ Budget 50/Energy 0; analyst bỏ chẩn đoán thừa; balanced/analyst chỉ mua Influencer nếu Retention báo cáo >=70% | 10,80 / 0 / 26,20 / 40,55 / 51,30 | 5,30 / 20,85 / 40,50 | 0/2 |
| 8 | Cash 9.400, cập nhật fixture Cash; full Cash 2.500 | 12,50 / 0 / 26,25 / 41,80 / 53,35 | 11,90 / 42,05 / 61,85 | 0/0 |
| 9 (cuối) | Full Cash 3.000; thêm test cả 8 sự kiện, gate full, chi phí phase và hồi quy seed105; thu gọn định dạng JSON | 12,50 / 0 / 26,25 / 41,80 / 53,35 | 9,30 / 34,80 / 55 | 0/0 |

- Bot: random vẫn chơi mọi thẻ theo thứ tự RNG, không dùng tri thức nâng cấp. Các bot có priority bỏ nâng cấp diminishing sau 3 lần thành công (lần thứ tư còn 12,5% hiệu ứng gốc), dựa vào lịch sử hành động công khai upgrade_plays. Analyst bỏ giới hạn này khi chữa nguyên nhân đã lộ vì gỡ sự kiện vẫn đủ hiệu lực. Analyst dùng event_reports và định nghĩa công khai để lộ trước, chữa sau; xét hai ứng viên khi triệu chứng Conversion mơ hồ. Lượt dự phòng dùng priority balanced nhưng bỏ ba thẻ lộ vì đã chẩn đoán có mục tiêu đầu tuần. Balanced vẫn có thể lộ cuối priority rồi chữa tuần sau. Balanced và analyst cùng chỉ xét Influencer nếu report().retention >=0,7, dùng số nhiễu người chơi thấy. Không đọc state.base/active_events để quyết định. Report dùng RNG riêng nên không đổi RNG rút bài/sự kiện. Số thật chỉ đọc khi ván kết thúc để thống kê. Giữ bot score sweep cũ để kiểm chứng điểm cả với policy cũ.
- Tự quyết cân bằng: ba thẻ lộ tốn 50 Budget/0 Energy để không mất lượt chữa; phạt Retention -30 điểm %, Conversion -5 điểm % trong 8 tuần làm việc chữa nguyên nhân có giá trị; logging_error giữ nguyên. Influencer giá 2.400, tác dụng +200 users giữ nguyên. price_fatigue ưu tiên Loyalty khi cả hai remedy có sẵn. Giữ diminishing 1/2, caps 75%/8%, công thức LTV/CAC, doanh thu/churn.
- Tự quyết ván dài: theo quyền tách chi phí phase ở T-011, từ tuần 11 chi phí vận hành thực trả (fixed + variable) nhân 0,1; mọi Budget thực trả nhân 0,05, cho mọi chiến lược, không đổi Energy/hiệu ứng. Ads từ tuần 11 trả 15 để tạo ad_spend=300, không trừ 300 lần nữa: đây là giảm giá phase chủ ý theo config mới, không phải baseline T-009. Demo Ads vẫn trả đúng 300. Hệ số giảm chi phí khá lớn; demo min_users=0,1 chỉ chặn công ty gần như hết user, không mang nghĩa một người nguyên. Claude cần xem các lựa chọn này khi review/playtest; đạt đích thống kê không suy ra đã tối ưu trải nghiệm chơi tay.
- Test cũ đổi: Cash kỳ vọng 6.759,702970297 -> 8.159,702970297 theo vốn đầu; repeated-upgrade thêm SQL trước chữa vì cơ chế mới; gate sang win.demo. Fixture full horizon tắt win trong config bản sao để kiểm tra thời lượng; test_full_rules kiểm tra từng gate demo/full độc lập. Không xóa test cũ; giữ tái lập seed/report, diminishing và toàn bộ fixture/sweep điểm T-006. Thêm test chơi mù rồi lộ không chữa hồi tố, chữa cùng/khác tuần, đúng nguồn modifier, không đếm hai lần và hết hạn không cộng resolved cho cả cơ chế.
- Kết quả cuối thực tế: Godot 4.7.2 console đúng đường dẫn VU cung cấp, --headless --path game-studio/godot --script res://tests/<script>. test_sim.gd: 2.326 checks, 0 failures, exit 0; test_ui.gd: 106 checks, 0 failures, exit 0; balance_sim.gd: đủ 10 dòng, 2.000 ván/dòng, 31,540 giây, exit 0. Analyst hơn balanced demo 11,55 điểm %, full 20,20 điểm %. Mọi trung vị ván thắng đạt Retention <=75%, Conversion <=8%, ratio 2..8; không thắng in n/a. Score sweep policy cũ: 122 thắng/1.878 thua, min_win=1.894,31 > max_loss=900. UI seed105 thắng Cash 414,43, Users 2,06, ratio 5,32. git diff --check qua. Console vẫn báo lỗi log user://logs/godot.log và root certificate store, không lỗi script.
- check_web.py chưa xác nhận: D:\Dev\ai-company\.venv\Scripts\python.exe -X utf8 -I media-marketing/web/check_web.py báo Unable to create process ... Access is denied. Claude cần tự chạy 6 mục; không thay quyền, không vượt sandbox. Không còn mục tiêu cân bằng chưa đạt; kiểm tra web bị chặn môi trường.
- Git: git add sáu file mã/data/test bị fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied. Để cả bảy file (kể cả TASKS.md) chưa commit trên codex/T-011; không vượt sandbox, không push, không merge.

Giá trị config.json cuối đầy đủ để cập nhật GDD (hai khóa economy mới áp dụng từ tuần 11; win chọn theo horizon):

```json
{
 "version":1,
 "initial":{"cash":9400,"users":1000,"arpu":25,"conversion":0.02,"retention":0.4,"cac":15,"integrity":80,"fixed_cost":450,"ad_spend":0},
 "weeks":{"demo":10,"full":30},
 "economy":{"ad_diminishing":0.01,"ad_unit":1000,"cost_per_user":0.05,"churn_floor":0.01,"full_cost_multiplier":0.1,"full_card_cost_multiplier":0.05},
 "limits":{"retention":[0,0.75],"conversion":[0,0.08],"integrity":[0,100],"cac":[1,1000],"arpu":[0,1000],"fixed_cost":[10,100000]},
 "loss":{"cash":0,"ratio":1,"streak":4,"low_cash":2000},
 "draw":4,
 "energy":3,
 "noise_scale":0.5,
 "score":{"win_bonus":1000,"cash":0.1,"ratio":100,"ratio_cap":5,"resolved":100,"week":40,"resolved_loss":50,"loss_cap":900},
 "phases":[{"through":10,"event_chance":0.4,"event_count":1,"integrity_decay":0},{"through":20,"event_chance":0.2,"event_count":1,"integrity_decay":1},{"through":30,"event_chance":0.2,"event_count":1,"integrity_decay":2}],
 "balance":{"games":2000,"seed":104,"quantiles":[0,0.25,0.5,0.75,1],"priorities":{"ads_only":["ads_campaign"],"optimization_only":["onboarding_redesign","fix_checkout_bug","support_automation","loyalty_program","seo_content"],"balanced":["onboarding_redesign","fix_checkout_bug","ads_campaign","support_automation","seo_content","loyalty_program","clean_data","sql_deep_dive","funnel_report","ab_test","discount","influencer_campaign"]}},
 "win":{"demo":{"min_cash":300,"min_ratio":3,"min_users":0.1},"full":{"min_cash":3000,"min_ratio":3,"min_users":8}}
}
```

### T-012 | Codex | 2026-11-10 | Review

- Nhận việc: đọc AGENTS.md, docs/collaboration.md, TASKS.md (T-009/T-011), SPEC-T-009/T-011/T-012 và đính chính. Owner Codex/In progress có sẵn, nhánh codex/T-012, cây ban đầu sạch. Giữ đính chính: optimization không có nguồn Users mới, không nâng cap quá 95%.
- Đã làm: giữ công thức tuần; Retention đầu 85%, cap 95%; min_users=750 tuyệt đối trên 1.000 Users đầu cho demo/full. Xóa hai full_*_multiplier khỏi config và simulation; tuần 11 trở đi trả nguyên giá. Chance pha 0,45/0,55/0,70, mỗi pha 1 lượt lấy mẫu, decay 0/1/2. Giữ 12 thẻ, 8 sự kiện, 7 chỉ số, demo 10 tuần, diminishing 1/2, RNG tái lập, điều kiện revealed T-011 và toàn bộ hệ số/ratio_cap/score T-006.
- Quy mô đầu không hành động/không sự kiện: tuần 1 còn 850 Users, doanh thu 204, vận hành 242,50, lỗ 38,50 (0,21% vốn 18.000). Không cấp tiền/quảng cáo miễn phí hoặc trợ giá riêng ván dài.
- File đổi dưới game-studio/godot/: scripts/sim/simulation.gd; data/cards.json, events.json, config.json; tests/balance_sim.gd, test_sim.gd, test_ui.gd; TASKS.md cho bàn giao/trạng thái. Không sửa docs/, scripts/ui/, scenes/, media-marketing/.
- Claude/VU cho phép trực tiếp sửa fixture test_ui.gd ở lượt tiếp tục; không tự mở rộng danh sách file trong dòng việc. Chính xác **tests/test_ui.gd dòng 29**: thay mảng priority cũ bằng `var priority: Array = game.simulation.config.balance.priorities.balanced`. Giữ mọi assertion và đủ 106 checks. Hai assertion phụ thuộc fixture thắng: `demo win` (dòng 39), `win result and score agree with simulation` (dòng 42), không sửa hai assertion. Fixture cũ seed105 chỉ còn Users 602,99/Cash 8.017,59, thua theo gate mới; fixture hiện hành thắng Users 1.829,74/Cash 13.095,53/ratio 6,82. test_sim dùng cùng policy hiện hành cho fixture UI, đổi nhãn kiểm tra cho đúng.

Bảng trước/sau: đo thật cùng seed 104..2103, 2.000 ván/bot, trước = T-011 đo lại trước chỉnh số; sau = vòng 13 và lượt xác nhận cuối khớp nhau. Users chỉ ván thắng, n/a khi không thắng.

| Tuần | Bot | Thắng trước % | Thắng sau % | Users trung vị trước | Users sau p10 / trung vị / p90 |
|---|---|---:|---:|---:|---|
| 10 | random | 12,50 | 18,90 | 29,35 | 929,05 / 1.443,89 / 2.164,64 |
| 10 | ads_only | 0 | 0 | n/a | n/a |
| 10 | optimization_only | 26,25 | 0 | 4,92 | n/a |
| 10 | balanced | 41,80 | 43,05 | 24,01 | 914,35 / 1.470,49 / 2.392,29 |
| 10 | analyst | 53,35 | 55,50 | 27,28 | 900,62 / 1.467,14 / 2.392,01 |
| 30 | random | 9,30 | 8,90 | 128,64 | 1.385,98 / 2.022,94 / 2.778,86 |
| 30 | ads_only | 0 | 0 | n/a | n/a |
| 30 | optimization_only | 0 | 0 | n/a | n/a |
| 30 | balanced | 34,80 | 32,05 | 82,73 | 1.073,21 / 1.894,22 / 2.955,40 |
| 30 | analyst | 55 | 53,30 | 78,92 | 1.089,17 / 1.966,18 / 3.052,10 |

- Mọi mục tiêu cân bằng theo đính chính đạt: analyst hơn balanced 12,45 điểm % demo, 21,25 điểm % full. Optimization 0% thấp hơn balanced >=10 điểm % demo và thấp hơn full; không có thắng để tính Users/chỉ số. Random demo 18,90% <=20%, full 8,90% <=10%; Ads 0%. Users trung vị demo balanced 147,05%, analyst 146,71% số đầu; p10 mọi nhóm có thắng >=50%. Trung vị Retention 95%, Conversion <=8%, ratio 6,39–6,76 ở mọi nhóm có thắng (chi tiết output dưới), đạt 2..8. Ads thua demo Users tuần 1/3/5/10 = 850 / 572,17 / 367,12 / 100,18: không tăng, tuần 10 >100. Ngưỡng cuối này gần biên của bộ seed được giao, chưa thay thế playtest.

Lịch sử 13 vòng: mỗi vòng đủ 2.000 ván/bot cho cả 10/30 tuần; số không nêu giữ vòng trước. R/A/O/B/P = random/ads/optimization/balanced/analyst, đơn vị %. Kiểm thử hồi quy chạy ở các mốc và lượt cuối, không khẳng định cả ba script đã chạy mỗi vòng.

| Vòng | Thay đổi | Demo R/A/O/B/P | Full R/A/O/B/P |
|---|---|---|---|
| 1 | Bỏ trợ giá; Cash 12.000, Retention 0,82/cap 0,95, ARPU 3/CAC 10/Conversion 0,02, fixed 50; gates Cash 300/ratio 2/Users 750 cả hai horizon. Chance 0,3/0,5/0,7. Onboarding +0,08, Loyalty +0,04; Support -25; Ads 800/800; Influencer Budget 800/Energy 1/+600/penalty -0,05 trong 3 tuần; Discount ARPU -0,5. Event Retention -0,10/8 tuần. | 74.00 / 0.00 / 0.00 / 71.15 / 77.15 | 0.00 / 0.00 / 0.00 / 0.00 / 0.45 |
| 2 | ARPU 6/CAC 20/Conversion 0,04; Ads 1.500/1.500; Influencer Energy 2/Budget 1.400; Checkout +0,015; SEO -1,6. Event Retention -0,20, Conversion -0,03, 8 tuần. Xóa nốt nhánh đọc khóa trợ giá trong mã (config đã bỏ vòng 1 nên không đổi số). | 42.85 / 0.00 / 0.00 / 29.60 / 35.80 | 0.05 / 0.00 / 0.00 / 0.05 / 0.40 |
| 3 | Cash 16.000, Retention đầu 0,85; demo Cash >=5.000; Checkout/Onboarding Budget 600/600, Support 400, SEO 300; Influencer Budget 800; Ads 600/600. Event Retention -0,12, Conversion -0,04; các duration 8 thành 4 (kể cả CAC). | 71.90 / 0.00 / 0.00 / 48.30 / 49.60 | 7.65 / 0.00 / 0.00 / 28.95 / 45.25 |
| 4 | Fixed đầu 200, Support -150; demo Cash >=8.000. Influencer penalty -0,25/6 tuần; event Retention -0,20/6 tuần, Conversion -0,04/6 tuần. | 6.90 / 0.00 / 0.00 / 10.25 / 16.55 | 0.35 / 0.00 / 0.00 / 2.55 / 8.90 |
| 5 | ARPU 12/CAC 40/Conversion 0,02; demo Cash >=10.000. Checkout +0,03; Influencer +1.000; SEO -3,2. Event Retention -0,12/6 tuần, Conversion -0,06/8 tuần. | 26.70 / 0.00 / 0.00 / 24.65 / 30.60 | 36.80 / 0.00 / 0.00 / 36.65 / 64.70 |
| 6 | Demo Cash >=7.000; ba thẻ lộ Budget 300. Priority balanced/analyst đưa Influencer lên sau Checkout, trước Ads. | 29.50 / 0.00 / 0.00 / 41.90 / 65.05 | 18.80 / 0.00 / 0.00 / 26.30 / 68.85 |
| 7 | Demo Cash >=10.000, full >=6.000. Balanced chỉ phân tích cuối priority khi có triệu chứng chưa lộ phù hợp với thẻ. | 13.90 / 0.00 / 0.00 / 37.50 / 43.20 | 11.10 / 0.00 / 0.00 / 27.50 / 61.55 |
| 8 | ARPU 24/CAC 80/Conversion 0,01; demo Cash >=8.000, full >=9.000; ba thẻ lộ Budget 500; Checkout +0,035; Influencer +600; SEO -6,4. | 26.80 / 0.00 / 0.00 / 50.35 / 55.90 | 13.05 / 0.00 / 0.00 / 26.95 / 60.80 |
| 9 | Chance 0,45/0,55/0,70; demo Cash >=9.000. Event Retention -0,08/6 tuần, Conversion -0,08/8 tuần. | 18.05 / 0.00 / 0.00 / 34.85 / 42.60 | 10.10 / 0.00 / 0.00 / 23.35 / 56.70 |
| 10 | Demo Cash >=8.000, full >=10.000; Ads 1.000/1.000; Clean Budget 300. Balanced phân tích rộng cuối priority khi còn bất kỳ nguyên nhân ẩn, không ghép đúng triệu chứng như analyst. | 16.30 / 0.00 / 0.00 / 27.70 / 40.25 | 6.50 / 0.00 / 0.00 / 11.35 / 42.20 |
| 11 | Cash đầu 18.000; full Cash >=6.000; Influencer penalty -0,50/8 tuần. Balanced/analyst chỉ mua Influencer sau Onboarding và report Retention >=0,85. | 20.05 / 0.00 / 0.00 / 39.75 / 55.60 | 9.40 / 0.00 / 0.00 / 15.35 / 53.00 |
| 12 | Demo Cash >=9.000, full >=15.000; phạt Conversion sự kiện kéo dài 4 tuần. | 20.40 / 0.00 / 0.00 / 42.75 / 57.25 | 8.90 / 0.00 / 0.00 / 20.20 / 53.30 |
| 13 | Demo Cash >=9.500; balanced ưu tiên chữa nguyên nhân đã lộ từ đầu tuần, vẫn phân tích rộng cuối priority. Analyst vẫn chẩn đoán có mục tiêu trước rồi chữa ngay. | 18.90 / 0.00 / 0.00 / 43.05 / 55.50 | 8.90 / 0.00 / 0.00 / 32.05 / 53.30 |

Thay đổi bot cuối (chỉ balance_sim và priority config):

- Balanced/analyst: Onboarding, Checkout, Influencer, Ads, Support, SEO, Loyalty, Clean, SQL, Funnel, A/B, Discount. Random vẫn xáo thứ tự RNG và thử mọi thẻ đủ điều kiện, không cắt lượt. Ads-only và optimization-only không đổi bộ hành động, không thêm nguồn Users cho optimization.
- Giữ giới hạn 3 lượt nâng cấp diminishing cho bot có priority; chữa nguyên nhân đã lộ bỏ qua giới hạn. Balanced chữa nguyên nhân đã lộ đầu tuần, rồi đi priority, phân tích rộng ở cuối khi còn nguyên nhân ẩn; không chữa hồi tố sau chẩn đoán. Analyst ghép triệu chứng công khai, chẩn đoán trước, chữa ngay, fallback không mua chẩn đoán thừa. Cùng hàm chữa và quy tắc Influencer cho cả hai để so công bằng thứ tự/chọn chẩn đoán.
- Influencer chỉ được balanced/analyst mua sau Onboarding (upgrade_plays công khai) và report().retention >=0,85. Không quyết định hành động từ state.base hoặc active_events. Thống kê chụp Users thực sau mỗi finish_week vào bộ ghi riêng, chỉ phân nhóm/in sau ván; không đưa số này vào bot/UI. RNG report riêng giữ tái lập diễn biến.
- Tự quyết số: ba thẻ lộ Budget 500/Energy 0 để tránh phân tích tràn lan nhưng đủ Energy chữa; phạt Conversion -8 điểm %/4 tuần làm chẩn đoán sớm có giá trị, phạt Retention -8 điểm %/6 tuần theo thang mới. Influencer +600/Budget 800/Energy 2, phạt -50 điểm %/8 tuần nếu chưa Onboarding: rủi ro mạnh cho tăng trưởng chưa chuẩn bị; flag/luật gốc không đổi. Onboarding +8 điểm % giảm dần, Loyalty +4 điểm %, Support -150, SEO -6,4 theo CAC 80, Discount ARPU -0,5. Cần Claude review cảm giác các thẻ này khi chơi tay; không tuyên bố bộ số tối ưu trải nghiệm.

Kiểm thử cuối bằng Godot console 4.7.2 đúng đường dẫn VU giao, tham số `--headless --path game-studio/godot --script res://tests/<script>.gd`:

- test_sim.gd: **2.392 checks, 0 failures**, exit 0; giữ fixture/sweep T-006, T-011, diminishing, tái lập seed. Score sweep 500 ván/bot: 104 thắng/1.896 thua, min_win 3.327,21 > max_loss 900. Thêm kiểm tra scale, lỗ nhẹ/co chậm đầu, cap/min_users tuyệt đối, phase tăng, không trợ giá, Ads trả đủ, chỉ retention không thể thắng. Đổi kỳ vọng số kinh tế/thẻ/nhiễu theo dữ liệu mới; fixture gate độc lập dùng Users 2.000/Retention 95% để kiểm tra từng gate, không sửa gate game. Test full kiểm tra nguyên giá thay trợ giá; không bỏ assertion cũ.
- test_ui.gd: **106 checks, 0 failures**, exit 0 sau đổi đúng fixture dòng 29 đã được cho phép. Không sửa mã UI/scenes.
- balance_sim.gd: **20.000 ván, 10 dòng x 2.000**, seed 104..2103, exit 0, 32,061 giây; khớp vòng 13. In Users p10/p50/p90 ván thắng, đường Users mọi ván và riêng ván thua, tuần 1/3/5/10 (+20/30 full). Mẫu số n chỉ ván thực sự tới tuần đó, không kéo dài ván thua hoặc điền 0 giả. p10/p90 chọn phần tử round(q*(n-1)); trung vị trung bình hai phần tử giữa khi n chẵn; không thắng in n/a.
- Cả ba console còn lỗi môi trường `Failed to open log file for writing: user://logs/godot.log` và `Failed to read the root certificate store`, không có lỗi script cuối.
- Python `.venv`: `D:\Dev\ai-company\.venv\Scripts\python.exe -X utf8 -I media-marketing/web/check_web.py` báo Unable to create process / Access is denied. Chưa xác nhận check_web 6/6; Claude tự chạy như đã giao. Không thay quyền/vượt sandbox.
- Git add đã thử: `fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied`. Chưa stage/commit, giữ thay đổi trong worktree; không push/merge. git diff --check qua (chỉ cảnh báo LF->CRLF).
- Chưa đạt: không còn mục tiêu số liệu chưa đạt theo đính chính; check_web bị chặn môi trường nên chưa xác minh. Cần review/playtest; không hạ mục tiêu hoặc thêm cơ chế ngoài spec.

Config.json cuối đầy đủ để Claude cập nhật GDD:

```json
{
 "version":1,
 "initial":{"cash":18000,"users":1000,"arpu":24,"conversion":0.01,"retention":0.85,"cac":80,"integrity":80,"fixed_cost":200,"ad_spend":0},
 "weeks":{"demo":10,"full":30},
 "economy":{"ad_diminishing":0.01,"ad_unit":1000,"cost_per_user":0.05,"churn_floor":0.01},
 "limits":{"retention":[0,0.95],"conversion":[0,0.08],"integrity":[0,100],"cac":[1,1000],"arpu":[0,1000],"fixed_cost":[10,100000]},
 "loss":{"cash":0,"ratio":1,"streak":4,"low_cash":2000},
 "draw":4,
 "energy":3,
 "noise_scale":0.5,
 "score":{"win_bonus":1000,"cash":0.1,"ratio":100,"ratio_cap":5,"resolved":100,"week":40,"resolved_loss":50,"loss_cap":900},
 "phases":[{"through":10,"event_chance":0.45,"event_count":1,"integrity_decay":0},{"through":20,"event_chance":0.55,"event_count":1,"integrity_decay":1},{"through":30,"event_chance":0.7,"event_count":1,"integrity_decay":2}],
 "balance":{"games":2000,"seed":104,"quantiles":[0,0.25,0.5,0.75,1],"priorities":{"ads_only":["ads_campaign"],"optimization_only":["onboarding_redesign","fix_checkout_bug","support_automation","loyalty_program","seo_content"],"balanced":["onboarding_redesign","fix_checkout_bug","influencer_campaign","ads_campaign","support_automation","seo_content","loyalty_program","clean_data","sql_deep_dive","funnel_report","ab_test","discount"]}},
 "win":{"demo":{"min_cash":9500,"min_ratio":2,"min_users":750},"full":{"min_cash":15000,"min_ratio":2,"min_users":750}}
}
```

Output xác nhận cuối đầy đủ, gồm đường Users từng bot/cả hai horizon (dấu chấm thập phân như console):

```text
weeks | strategy | games | win % | loss median week | losses before 15 % | cash min/p25/p50/p75/max | winner retention % / conversion % / ratio
10 | random | 2000 | 18.90 | 10.00 | 81.10 | [-224.58, 1603.18, 3785.3, 8392.67, 31303.96] | 95.00 / 7.56 / 6.39
  winner Users p10/p50/p90: 929.05 / 1443.89 / 2164.64
  Users median all, observed weeks only: ["1:850.00(n=2000)", "3:645.96(n=2000)", "5:538.10(n=2000)", "10:749.71(n=1819)"]
  Users median losses, observed weeks only: ["1:850.00(n=1622)", "3:550.93(n=1622)", "5:344.42(n=1622)", "10:502.98(n=1441)"]
10 | ads_only | 2000 | 0.00 | 10.00 | 100.00 | [8111.96, 12118.78, 13196.01, 14137.42, 16745.35] | n/a / n/a / n/a
  winner Users p10/p50/p90: n/a / n/a / n/a
  Users median all, observed weeks only: ["1:850.00(n=2000)", "3:572.17(n=2000)", "5:367.12(n=2000)", "10:100.18(n=2000)"]
  Users median losses, observed weeks only: ["1:850.00(n=2000)", "3:572.17(n=2000)", "5:367.12(n=2000)", "10:100.18(n=2000)"]
10 | optimization_only | 2000 | 0.00 | 10.00 | 100.00 | [9063.8, 12498.06, 13922.93, 15587.02, 22270.99] | n/a / n/a / n/a
  winner Users p10/p50/p90: n/a / n/a / n/a
  Users median all, observed weeks only: ["1:850.00(n=2000)", "3:704.97(n=2000)", "5:588.17(n=2000)", "10:362.69(n=2000)"]
  Users median losses, observed weeks only: ["1:850.00(n=2000)", "3:704.97(n=2000)", "5:588.17(n=2000)", "10:362.69(n=2000)"]
10 | balanced | 2000 | 43.05 | 10.00 | 56.95 | [-242.89, 6575.29, 9884.98, 13847.82, 35536.34] | 95.00 / 7.13 / 6.50
  winner Users p10/p50/p90: 914.35 / 1470.49 / 2392.29
  Users median all, observed weeks only: ["1:862.38(n=2000)", "3:752.50(n=2000)", "5:768.41(n=2000)", "10:1127.98(n=1999)"]
  Users median losses, observed weeks only: ["1:862.38(n=1139)", "3:713.79(n=1139)", "5:656.02(n=1139)", "10:793.49(n=1138)"]
10 | analyst | 2000 | 55.50 | 10.00 | 44.50 | [-158.48, 8663.92, 12147.23, 16092.34, 38536.34] | 95.00 / 7.13 / 6.52
  winner Users p10/p50/p90: 900.62 / 1467.14 / 2392.01
  Users median all, observed weeks only: ["1:862.38(n=2000)", "3:761.91(n=2000)", "5:788.16(n=2000)", "10:1245.77(n=1999)"]
  Users median losses, observed weeks only: ["1:862.38(n=890)", "3:708.22(n=890)", "5:644.06(n=890)", "10:716.65(n=889)"]
30 | random | 2000 | 8.90 | 23.00 | 30.05 | [-337.14, -7.87, 219.15, 1802.67, 51151.04] | 95.00 / 3.00 / 6.51
  winner Users p10/p50/p90: 1385.98 / 2022.94 / 2778.86
  Users median all, observed weeks only: ["1:850.00(n=2000)", "3:645.96(n=2000)", "5:538.10(n=2000)", "10:749.71(n=1819)", "20:1019.28(n=1183)", "30:984.25(n=878)"]
  Users median losses, observed weeks only: ["1:850.00(n=1822)", "3:614.29(n=1822)", "5:461.74(n=1822)", "10:591.38(n=1641)", "20:772.96(n=1005)", "30:533.20(n=700)"]
30 | ads_only | 2000 | 0.00 | 30.00 | 0.00 | [-197.95, 1196.14, 2445.37, 4268.23, 10461.14] | n/a / n/a / n/a
  winner Users p10/p50/p90: n/a / n/a / n/a
  Users median all, observed weeks only: ["1:850.00(n=2000)", "3:572.17(n=2000)", "5:367.12(n=2000)", "10:100.18(n=2000)", "20:15.73(n=1999)", "30:10.62(n=1635)"]
  Users median losses, observed weeks only: ["1:850.00(n=2000)", "3:572.17(n=2000)", "5:367.12(n=2000)", "10:100.18(n=2000)", "20:15.73(n=1999)", "30:10.62(n=1635)"]
30 | optimization_only | 2000 | 0.00 | 30.00 | 0.00 | [5110.33, 9901.44, 11782.42, 14121.45, 24903.64] | n/a / n/a / n/a
  winner Users p10/p50/p90: n/a / n/a / n/a
  Users median all, observed weeks only: ["1:850.00(n=2000)", "3:704.97(n=2000)", "5:588.17(n=2000)", "10:362.69(n=2000)", "20:101.51(n=2000)", "30:0.00(n=2000)"]
  Users median losses, observed weeks only: ["1:850.00(n=2000)", "3:704.97(n=2000)", "5:588.17(n=2000)", "10:362.69(n=2000)", "20:101.51(n=2000)", "30:0.00(n=2000)"]
30 | balanced | 2000 | 32.05 | 30.00 | 3.10 | [-242.89, 135.09, 7329.44, 21325.15, 89193.69] | 95.00 / 2.56 / 6.69
  winner Users p10/p50/p90: 1073.21 / 1894.22 / 2955.40
  Users median all, observed weeks only: ["1:862.38(n=2000)", "3:752.50(n=2000)", "5:768.41(n=2000)", "10:1127.98(n=1999)", "20:1469.42(n=1835)", "30:1393.22(n=1613)"]
  Users median losses, observed weeks only: ["1:862.38(n=1359)", "3:726.65(n=1359)", "5:695.05(n=1359)", "10:929.01(n=1358)", "20:1152.04(n=1194)", "30:1000.63(n=972)"]
30 | analyst | 2000 | 53.30 | 30.00 | 0.80 | [-265.46, 7031.44, 18535.81, 32584.96, 110788.32] | 95.00 / 7.13 / 6.76
  winner Users p10/p50/p90: 1089.17 / 1966.18 / 3052.10
  Users median all, observed weeks only: ["1:862.38(n=2000)", "3:761.91(n=2000)", "5:788.16(n=2000)", "10:1245.77(n=1999)", "20:1630.33(n=1937)", "30:1641.73(n=1827)"]
  Users median losses, observed weeks only: ["1:862.38(n=934)", "3:718.67(n=934)", "5:669.51(n=934)", "10:893.20(n=933)", "20:1217.29(n=871)", "30:1159.94(n=761)"]
elapsed_seconds=32.061
```

### T-013 | Codex | 2026-11-10 | Review

- Đã làm: event_reports() chỉ thêm remedies khi đã lộ, sao chép mảng đúng thứ tự dữ liệu; UI lấy cách xử lý từ event_reports(), hiện tên thẻ/nhãn (trong tay), đánh dấu thẻ phù hợp; gợi ý mất sau xử lý hoặc hết hạn. Giữ nguyên mọi kiểm tra cũ.
- File đổi: game-studio/godot/scripts/sim/simulation.gd (chỉ thêm một dòng trong event_reports), scripts/ui/game_controller.gd, data/strings.json, tests/test_sim.gd, tests/test_ui.gd; TASKS.md cho trạng thái/bàn giao. Không sửa scene, dữ liệu lõi, media-marketing hoặc docs.
- Tự quyết: viền sáng 3px và nền sáng hơn cho thẻ xử lý, giữ mờ 0,4 khi thiếu tài nguyên; thẻ cao 110px, chữ tự xuống dòng; nhiều nguyên nhân ghi nguyên nhân đầu +N, tooltip đủ tất cả. Giữ vùng cuộn sự kiện có sẵn để đọc đủ nội dung khi ba sự kiện dài; không cắt bỏ tên nguyên nhân/thẻ. Claude cần chụp màn hình/playtest theo spec.
- Kiểm tra: Godot console 4.7.2 đúng đường dẫn VU giao, --headless --path game-studio/godot --script res://tests/<script>.gd. test_sim: 2.608 checks, 0 failures (cũ 2.392 giữ nguyên); test_ui: 134 checks, 0 failures (cũ 106 giữ nguyên), gồm bounds 640x360 và chiều cao chữ thẻ. balance_sim: exit 0, 20.000 ván, khớp nguyên 47 dòng theo thứ tự với master b7c4b94 sau khi CHỈ bỏ elapsed_seconds. Bản gốc đã chạy trước khi sửa khi HEAD trùng master; output lưu tại thư mục TEMP hệ thống, T-013-balance-master.txt và T-013-balance-result.txt. git diff --check qua. Console còn lỗi môi trường log user:// và root certificate store; không lỗi script.
- Python: D:\Dev\ai-company\.venv\Scripts\python.exe -X utf8 -I media-marketing/web/check_web.py bị Unable to create process / Access is denied trong sandbox; chưa xác nhận 6/6, Claude tự chạy lại.
- Git: nhánh codex/T-013, ban đầu sạch và HEAD trùng master; git add bị Permission denied khi tạo D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock. Để file chưa stage/commit; không vượt sandbox, không push, không merge.
