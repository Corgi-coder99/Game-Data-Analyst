# Bảng công việc (Claude Code và Codex)

Quy tắc: xem docs/collaboration.md. Mỗi việc có đúng một owner. Nhận việc xong mới được sửa file.

Trạng thái: Backlog -> In progress -> Review -> Done. Bị chặn thì chuyển sang mục Blocked.

## Backlog

| ID | Việc | Owner | Nhánh | File được sửa | Tiêu chí hoàn thành |
|---|---|---|---|---|---|
| T-001 (ví dụ) | Viết spec tính năng X | Claude | claude/T-001 | docs/spec-x.md | Spec có mô tả, đầu vào, đầu ra, ví dụ |
| T-002 (ví dụ) | Cài đặt tính năng X theo spec T-001 | Codex | codex/T-002 | src/x.py, tests/test_x.py | Kiểm thử qua, đúng spec |
| T-008 | check_web.py: ép stdout UTF-8 để không lỗi UnicodeEncodeError trên console Windows mặc định | Codex | codex/T-008 | media-marketing/web/check_web.py | Chạy `python -I check_web.py` (không cần -X utf8) qua 6 mục |
| T-010 | Kịch bản và video quảng cáo 30 giây (làm sau T-011 để quảng cáo đúng với cơ chế cuối) | Claude/Codex | chưa chốt | media-marketing/video/* | Chưa có spec |

## In progress

| ID | Việc | Owner | Nhánh | File được sửa | Tiêu chí hoàn thành |
|---|---|---|---|---|---|
| T-011 | Phân tích phải có lợi (thẻ xử lý chỉ gỡ sự kiện khi nguyên nhân đã lộ) và sửa ván 30 tuần. VU đã duyệt spec | Codex | codex/T-011 | game-studio/godot/scripts/sim/*, data/cards.json, events.json, config.json, tests/balance_sim.gd, tests/test_sim.gd | Xem game-studio/godot/docs/SPEC-T-011.md |

## Review

(chưa có)

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
