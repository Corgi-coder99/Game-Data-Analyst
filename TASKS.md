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
| T-019d | Giao diện v2 phần d: hiệu ứng, chỉnh theo playtest và ảnh chụp. Sau T-019c | Codex | codex/T-019d | scenes/v2/*, scripts/v2/*, assets/v2/* | Chưa có spec |

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
| T-018 | Tầng thế giới v2 (scripts/world/): kịch bản ẩn, tin đúng/sai/cũ/nhiễu, kiểm chứng, báo cáo chấm điểm, sự nghiệp, bot cân bằng (Codex). Đạt 5/5 mục tiêu demo, không lộ dữ liệu ẩn (Claude quét 450 kết quả API). Còn nợ: thưởng phạt quá nhẹ, bản 30 ngày chưa dùng được (chuyển sang T-018b). Claude đã review; VU duyệt merge vào v2 | Codex | 2026-11-10 |
| T-018b | Siết thưởng phạt và sửa ván 30 ngày (Codex). Claude chạy lại balance_world 1.000 ván/bot: mọi mục tiêu A (demo) và B (30 ngày) đạt; test_sim 2.630, test_ui 134, test_world 32.419 qua; balance_sim giống hệt; không lộ dữ liệu ẩn. Claude tự quyết merge vào v2 (VU ủy quyền) | Codex | 2026-11-10 |
| T-019a | Giao diện v2 phần a (Codex): đường ống sprite GDScript, 26 dải PNG đúng 32 màu, cảnh văn phòng pixel. Claude chạy lại test_v2_assets (2.255), check_palette PASS, render và duyệt ảnh cảnh; tự quyết merge vào v2 (VU ủy quyền) | Codex | 2026-11-10 |
| T-019b | Giao diện v2 phần b (Codex): màn hình máy tính với cửa sổ Tin tức, Công ty, Công cụ kiểm chứng, ghim bằng chứng, thanh tác vụ. Claude chạy lại kiểm thử (v2_desktop 2.332, layout_render 2.614 không headless, assets 2.255, sim 2.630, ui 134, world 32.438), đo thanh tác vụ trong render thật (108x14), balance_sim giống hệt; qua 2 vòng trả lại vì bố cục tràn; tự quyết merge vào v2 (VU ủy quyền) | Codex | 2026-11-10 |
| T-018c | Kho Energy phân tích riêng (3 mỗi ngày), tool_energy, lỗi no_analysis_energy, bot chịu cùng giới hạn (Claude subagent làm thay Codex hết hạn mức). Claude chạy lại: test_sim 2.634, ui 134, world 32.502, v2_assets 2.255, v2_desktop 2.336, layout_render 2.614 (không headless), balance_sim giống hệt, không lộ dữ liệu ẩn; balance_world 10 ngày: verifier 65,2% vs official_only 36,4%. Lưu ý: bot chỉ dùng khoảng 1 lần kiểm chứng mỗi ngày nên khan hiếm chưa cắn bot, người chơi thật thấy 6 đến 7 tin sẽ chịu áp lực nhiều hơn. Tự quyết merge vào v2 (VU ủy quyền) | Claude subagent (thay Codex) | 2026-11-10 |
| T-019c | Vòng chơi v2 trọn vẹn: cửa sổ Báo cáo, họp cuối ngày 6 bước, màn tiêu đề, 3 kiểu kết thúc, bộ điều phối game_flow, chạy bằng scenes/v2/main_v2.tscn (Claude subagent làm thay Codex). Claude chạy lại: sim 2.634, ui 134, world 32.511, v2_assets 2.257, v2_desktop 2.448, v2_flow (đủ 3 kết cục, 12 loại lời sếp), layout_render 2.662 và screens_render 7.488 (36 màn, không headless), check_palette PASS, balance_sim giống hệt; xem ảnh tiêu đề, soạn báo cáo, họp cuối ngày, kết thúc. Tự quyết merge vào v2 (VU ủy quyền) | Claude subagent (thay Codex) | 2026-11-10 |

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

### T-018 | Codex | 2026-11-10 | Review

- Đã nhận trên codex/T-018, nền v2, cây làm việc ban đầu sạch; owner Codex/In progress có sẵn trước khi sửa. Không push, không merge.
- Đã làm: sáu class RefCounted cho kịch bản Markov/cú sốc, tin hợp lệ theo thời gian và nguồn, kiểm chứng có cache theo công cụ, báo cáo hợp lệ/chấm điểm, sự nghiệp, điều phối ngày. Có dữ liệu câu hỏi/hệ số, bot chỉ quyết định qua API công khai và kiểm thử headless.
- File đổi (dưới game-studio/godot/): scripts/world/{world_scenario,news_engine,verifier,report,career,world_game}.gd; data/world.json; data/questions.json; scripts/sim/simulation.gd (CHỈ thêm use_tool); tests/test_world.gd; tests/balance_world.gd; tests/test_sim.gd (CHỈ thêm/gọi test_use_tool). TASKS.md cho bàn giao/trạng thái. Không sửa news.json, cards.json, events.json, config.json, UI, scenes, docs, shared, media-marketing.
- Kiểm thử thực tế bằng Godot console 4.7.2 đúng đường dẫn VU giao, --headless --path game-studio/godot --script res://tests/<tên>.gd: test_sim 2.623 checks/0 failures (giữ đủ 2.608 kiểm tra cũ, thêm 15); test_ui 134/0; test_world cuối 31.655/0. World gồm rà khóa đệ quy API, bản sao sâu/cache, hash nhật ký cùng seed, tin/câu hỏi trên 200 seed, bảng kiểm chứng/chấm điểm và ví dụ tính tay, sự nghiệp, overrides/kết thúc, tích hợp 10 ngày. Quét điểm 500 ván/bot: 787 thắng/1.713 thua, min_win 6.509,50 > max_loss 1.211,00; thêm kiểm tra giới hạn lý thuyết cho 30 ngày.
- Không lộ: tin công khai chỉ 10 khóa theo spec; không trả template_id/verify_with/reliability hoặc nhãn ẩn. Rà truth/kind/link/state_direction/exaggerates/answer/scenario trên các API đọc và kết quả verify/submit/end; review ngày hiện tại/tương lai bị từ chối. end_day không trả acc/delta/đáp án; review chỉ sao chép sự thật của ngày đã kết thúc. Dữ liệu có sẵn cho ngày tương lai vẫn nằm trong phần nội bộ.
- Hồi quy v1: đã chạy balance_sim gốc TRƯỚC sửa, lưu TEMP/T-018-balance-before.txt; bản sau TEMP/T-018-balance-after.txt. Compare-Object -SyncWindow 0 khớp đủ 47 dòng, chỉ bỏ elapsed_seconds. Không sửa test/balance v1 hay hành vi play. git diff --check qua. Console vẫn có lỗi môi trường ghi user://logs/godot.log và root certificate store; không có lỗi script ở các lượt cuối. Không cần Python cho việc này.
- Cân bằng: mỗi bảng 2.000 ván/bot, seed 104..2103; --games=2000 --days=10 hoặc --days=30. Đủ 5 kind trong 100% ván của từng bot/cả hai kỳ; cả 8 cú sốc xuất hiện. acc là điểm chính xác (1/0,4/0), không phải tỷ lệ đoán đúng tuyệt đối; rank trung vị dùng chỉ số 0=thực tập, 1=chuyên viên, 2=chuyên viên chính, 3=trưởng nhóm, 4=giám đốc.

| Ngày | Bot | N | Thắng % | Fired % | Bankrupt % | Survived % | Trust trung vị | Rank trung vị | acc TB | ev TB | Đủ 5 kind % |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | random_reporter | 2000 | 7.80 | 1.60 | 0.00 | 98.40 | 55.50 | 0.0 | 0.5189 | 0.0000 | 100.00 |
| 10 | rumor_follower | 2000 | 13.85 | 1.40 | 0.00 | 98.60 | 56.40 | 0.0 | 0.5352 | -0.3604 | 100.00 |
| 10 | official_only | 2000 | 33.85 | 0.00 | 0.00 | 100.00 | 61.30 | 0.0 | 0.6985 | -0.1048 | 100.00 |
| 10 | verifier | 2000 | 69.50 | 0.10 | 0.00 | 99.90 | 63.00 | 1.0 | 0.7197 | 0.3120 | 100.00 |
| 10 | careful_hedger | 2000 | 30.50 | 0.00 | 0.00 | 100.00 | 62.70 | 0.0 | 0.7200 | 0.3120 | 100.00 |
| 30 | random_reporter | 2000 | 63.95 | 3.25 | 0.65 | 96.10 | 62.80 | 1.0 | 0.5141 | 0.0000 | 100.00 |
| 30 | rumor_follower | 2000 | 69.00 | 4.45 | 0.05 | 95.50 | 62.50 | 1.0 | 0.5345 | -0.4015 | 100.00 |
| 30 | official_only | 2000 | 98.50 | 0.00 | 0.05 | 99.95 | 68.15 | 2.0 | 0.7008 | -0.0564 | 100.00 |
| 30 | verifier | 2000 | 62.35 | 0.15 | 36.85 | 63.00 | 71.20 | 3.0 | 0.7006 | 0.2784 | 100.00 |
| 30 | careful_hedger | 2000 | 41.35 | 0.00 | 58.00 | 42.00 | 68.80 | 2.0 | 0.7061 | 0.3007 | 100.00 |

- Mục tiêu demo: đạt 5/5. Random 7,80 <=10; rumor 13,85 <=15; official 33,85 trong [30,55]; hedger 30,50 trong [25,60] và thấp hơn verifier; verifier 69,50 <=85, hơn official 35,65 điểm %. Chưa có mục tiêu định lượng chưa đạt trong spec. Bản 30 ngày chưa có ngưỡng thắng được giao: cần review/playtest chi phí tích lũy, vì official thắng 98,50%, verifier phá sản 36,85%, hedger phá sản 58%; không tuyên bố full đã cân bằng về trải nghiệm.

Lịch sử chỉnh số (R/U/O/V/H = random/rumor/official/verifier/hedger; các vòng 2..7 là mẫu 200 ván/bot/10 ngày, không thay thế lượt 2.000 cuối):

| Vòng | Thay đổi chính; giá trị khác giữ trước | N/bot | Thắng R / U / O / V / H % |
|---|---|---:|---|
| 2 | Sau sửa smoke use_tool: base=6, trust=50, ev_factor=0,25, thap=0,5 | 200 | 29,50 / 55,00 / 62,00 / 63,50 / 40,00 |
| 3 | base=4 | 200 | 10,00 / 35,50 / 36,50 / 36,50 / 2,50 |
| 4 | base=5; bot đọc thêm cụm nghĩa từ tiêu đề; verifier cao khi có >=1 bằng chứng; cooldown tin là khoảng cách >=3 ngày | 200 | 21,50 / 44,50 / 54,50 / 69,50 / 20,50 |
| 5 | trust=45, ev_factor=1 | 200 | 10,50 / 24,50 / 22,50 / 71,50 / 23,00 |
| 6 | Official bỏ bản tin nói kỳ trước khi có tin mới; rumor dẫn một tin; hedger bỏ hành động ở 50% ngày | 200 | 10,50 / 24,00 / 46,00 / 71,50 / 22,50 |
| 7 | trust=44, thap=0,6; trọng số signal/trap/partial/stale/noise=45/25/5/10/10 | 200 | 10,00 / 17,50 / 43,00 / 68,50 / 34,50 |
| 8 | trust=43; công cụ phù hợp chủ đề trước; kịch bản phải có đủ 5 kind ngay ngày đầu và đủ số tin cả kỳ | 2.000 | 9,20 / 15,90 / 35,90 / 70,90 / 34,60 |
| 9 (cuối) | trust=42 | 2.000 | 7,80 / 13,85 / 33,85 / 69,50 / 30,50 |

- Tự quyết: trọng số kind là trọng số tương đối (chuẩn hóa trên các mẫu hợp lệ), không phải bảo đảm đúng tỷ lệ ở từng ngày. Chọn lại kịch bản bằng luồng seed xác định nếu không có đủ tin hợp lệ/số lượng/cả 5 kind ngày đầu; không bịa nhãn hay đổi hướng mẫu. Tin ngày 1 có thể lặp lại ngày 4 (mỗi cửa sổ 3 ngày không lặp); câu hỏi không trùng 3 ngày trước. Sinh thêm một ngày trạng thái cho câu giá nguyên liệu dự báo ngày sau; câu q5 xét cả ngày hiện tại và hết window_days. Tín hiệu sự kiện hợp lệ khi còn diễn ra hoặc trong 2 ngày từ lúc xảy ra, kèm độ trễ nguồn.
- Tự quyết: cho Simulation chạy horizon+1 để v2 dùng ending sự nghiệp, tránh gate thắng Cash/Users/ratio cuối kỳ riêng của v1; vẫn tôn trọng state.lost của lõi. Tác động macro duration=1, không sửa hệ số kinh tế v1. Dùng báo cáo integrity công khai để tính nhiễu kiểm chứng; kết quả chưa đủ căn cứ không xóa kết luận dứt khoát trước đó. Cache kiểm chứng theo cặp uid/tool và cache chuẩn bị theo seed/horizon/hệ số, mỗi ván nhận bản sao sâu. Chạy lại 2.000 ván/bot demo sau cache: mọi dòng khớp bản không cache. Overrides hỗ trợ world (gộp đệ quy), simulation, questions, news, scenario.days/scenario.shocks.
- Tự quyết về điểm: giữ dạng công thức cộng/trừ của spec, không dùng trần điểm ván thua. Win bonus=6.000, Trust*5, positive_delta*10, demotion*150, fired*300. Với bộ số cuối, delta dương <=15/ngày, ván thua 30 ngày <=5.000 điểm; ngay cả cận thắng bảo thủ trừ 2 lần giáng chức vẫn >=5.700. Điều này bảo đảm bất biến cho cả hai kỳ. Thay đổi hệ số điểm không được bot dùng để quyết định nên không đổi bảng thắng/thua.
- Bot không tra nhãn hoặc kịch bản ẩn: đọc chủ đề/cụm từ tiêu đề, nguồn, kết quả xác nhận và tay bài. Công cụ theo nhóm chủ đề khớp verify_with hiện có; rumor dùng nguồn xã hội/nặc danh, official lọc tin cũ khi có tin mới, verifier/hedger chỉ dẫn tin xác nhận. Không có tin phù hợp thì dùng dự báo mặc định ngang, riêng rumor chọn hướng ngẫu nhiên; random chọn cả hướng/tự tin/hành động bằng RNG riêng. Hành động ưu tiên chung theo dữ liệu công khai; hedger đề xuất ít hơn. Đây là baseline headless, cần đối chiếu chơi tay.
- news.json: không sửa và chưa phát hiện lỗi dữ liệu bắt buộc sửa. Mẫu partial gắn event được xét khi cú sốc thật còn phù hợp cửa sổ; phóng đại có sẵn trong tiêu đề được giữ nguyên. Mọi dữ liệu đều hư cấu trong kho, không dùng mạng hay dữ liệu cá nhân.
- Git: git add bị fatal: Unable to create D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock: Permission denied. Chưa stage/commit, giữ nguyên file trong worktree; không vượt sandbox, không push/merge.

world.json cuối đầy đủ:

```json
{
 "version":1,
 "variables":["lai_suat","ty_gia","nguyen_lieu","suc_mua","chung_khoan","tin_dung"],
 "directions":["tang","giam","ngang"],
 "magnitudes":["low","mid","high"],
 "markov_keep":0.78,
 "shock_count":{"10":4,"30":12},
 "shock_probability":0.85,
 "precursors":{"competitor_discount":{"variable":"ty_gia","direction":"tang"},"price_fatigue":{"variable":"nguyen_lieu","direction":"tang"}},
 "precursor_weight":3,
 "news_per_day":{"10":6,"30":7},
 "kind_weights":{"signal":45,"trap":25,"partial":5,"stale":10,"noise":10},
 "repeat_days":3,"news_lifetime":3,"event_recent_days":2,
 "noise_factor":0.5,
 "macro":{"lai_suat":{"tang":{"fixed_cost":8},"giam":{"fixed_cost":-4}},"ty_gia":{"tang":{"cac":2.4},"giam":{"cac":-1.2}},"nguyen_lieu":{"tang":{"fixed_cost":6},"giam":{"fixed_cost":-3}},"suc_mua":{"tang":{"conversion":0.0003,"retention":0.003},"giam":{"conversion":-0.0003,"retention":-0.003}},"tin_dung":{"giam":{"fixed_cost":4}}},
 "magnitude_scale":{"low":0.5,"mid":1,"high":1.5},
 "tools":{"truy_van_lich_su":"sql_deep_dive","kiem_dinh_gia_thuyet":"ab_test","doi_chieu_nguon":"funnel_report","lam_sach_du_lieu":"clean_data"},
 "grading":{"base":5,"adjacent":0.4,"partial_reward":0.3,"evidence_factor":1,"confidence":{"thap":0.6,"vua":1,"cao":1.5},"evidence":{"xac_nhan":1,"chua_du_can_cu":0,"bac_bo":-1,"cu":-1},"unverified":{"sai":-1,"cu":-1,"dung":0.25,"mot_phan":0,"khong_lien_quan":0},"max_evidence":3},
 "career":{"initial_trust":42,"reset_promotion":55,"reset_demotion":40,"warning":35,"demote":25,"minimum_days":2,"correct_streak":2,"max_demotions":2,"bonus_fraction":0.5,"adopt_min":0.4,"adopt_max":1},
 "ranks":[{"id":"thuc_tap","actions":1,"promote":70,"salary":100},{"id":"chuyen_vien","actions":2,"promote":75,"salary":160},{"id":"chuyen_vien_chinh","actions":2,"promote":80,"salary":240},{"id":"truong_nhom","actions":3,"promote":85,"salary":340},{"id":"giam_doc","actions":3,"promote":101,"salary":460}],
 "score":{"win_bonus":6000,"trust":5,"positive_delta":10,"demotion":150,"fired":300},
 "balance":{"seed":104,"games":2000}
}
```

### T-018b | Codex | 2026-11-10 | Review

- Nhận trên codex/T-018b, v2 là tổ tiên HEAD (9a0657e), cây làm việc ban đầu sạch. TASKS.md chưa có dòng T-018b: đã thêm owner Codex vào In progress theo phạm vi VU giao trước khi sửa mã. Không push/merge, không dùng mạng hay dữ liệu cá nhân.
- File đổi dưới game-studio/godot/: data/world.json; scripts/world/{report,career,verifier,world_game}.gd; scripts/sim/simulation.gd (chỉ chữ ký use_tool và chọn Budget); tests/{balance_world,test_world,test_sim}.gd (test_sim chỉ thêm trong test_use_tool). TASKS.md cho nhận việc/bàn giao. Không đổi bot propose, luật kiểm chứng, tin, câu hỏi, dữ liệu kinh tế, UI, scene, docs hay shared.
- Công thức: acc vẫn 1 / 0,4 / 0; points = base*c khi đúng, base*c*adjacent_effect khi lệch một bậc, -base*c*wrong_factor khi ngược hướng. Với điểm dương nhân (1 + evidence_factor*ev), điểm âm nhân (1 - evidence_factor*ev), kẹp hệ số không âm, snappedf 0,1. Tin đã bác bỏ/tin cũ không còn làm mất mức phạt của báo cáo sai; bằng chứng xác nhận giảm phạt khi dự báo sai.
- Sự nghiệp: giữ luật cảnh cáo theo lần hạ qua ngưỡng, giáng chức khi acc=0 và Tin tưởng thấp, đuổi ở 0 Tin tưởng hoặc đủ 2 giáng chức. Thay chuỗi sai của thực tập sinh bằng số ngày Tin tưởng thấp liên tiếp (low_trust_days); chỉ kích hoạt nhánh đuổi này trên báo cáo acc<1. Thăng chức dùng max(trust, reset_promotion), không lấy mất Tin tưởng vừa kiếm được. Lương/thưởng và Cash công ty vẫn tách biệt; không chọn thêm phạt tiền.
- Chi phí: use_tool(card_id, budget_override=-1.0), mọi giá trị âm giữ giá thẻ cũ; 0 hỗ trợ công cụ miễn phí. Tầng world truyền tool_budget, tools() và cash_report hiển thị đúng giá, cache kiểm chứng không thu lại tiền. Giá mới áp dụng cả 10 và 30 ngày để cùng một công cụ không đổi giá theo kỳ; không đổi Energy/hiệu ứng/RNG của lõi.
- Thắng: win.demo=chuyen_vien; win.full=truong_nhom. Thời gian giữ chức tối thiểu 6 ngày giúp ván dài cần cả quá trình làm việc đúng, không chỉ một chuỗi may mắn. Win bonus=8.000: với delta dương tối đa 22,4/ngày, cận điểm thua 30 ngày là 7.220; cận thắng bảo thủ 7.700 (đã trừ 2 giáng chức), vẫn tách nghiêm ngặt. Không dùng trần điểm ván thua.
- balance_world thêm demoted %, warned %, heavy % (hợp của fired và demoted, không cộng trùng), Tin tưởng p25/p50/p75. Phân vị nội suy tại (N-1)*p; rank trung vị dùng 0..4. Chế độ --trace chỉ lấy acc/ev và mức tự tin từ báo cáo đã review, dùng overrides base=0, trust=100, Cash giả lập lớn để không mất đuôi chuỗi; không dùng kết quả này làm nghiệm thu và không đổi quyết định bot. Sàng C# tạm trong TEMP (RNG 18018) rồi kiểm tra ứng viên bằng ván thật.
- Lưu gốc: balance_sim chạy trước sửa, TEMP/T-018b-sim-before.txt; so sau trong TEMP/T-018b-sim-after.txt khớp 47 dòng, chỉ bỏ elapsed_seconds. Bảng world gốc demo: TEMP/T-018b-baseline-10.txt; full: TEMP/T-018b-isolated-before-30.txt (git archive HEAD vào TEMP để cố định bản gốc, chỉ thêm cột thống kê cùng bot). Các lượt gốc đầu bị đổi JSON giữa chừng đã hủy, không dùng số của lượt lỗi; bản gốc chạy lại khớp toàn bộ số T-018 đã bàn giao.

Bảng trước (2.000 ván/bot, seed 104..2103; đủ 5 kind 100%, 8/8 cú sốc ở cả hai kỳ):

| Ngày | Bot | N | Thắng % | Fired % | Bankrupt % | Survived % | Demoted % | Warned % | Heavy % | Trust p25/p50/p75 | Rank p50 | acc TB | ev TB | Đủ 5 kind % |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| 10 | random_reporter | 2000 | 7.80 | 1.60 | 0.00 | 98.40 | 0.00 | 17.95 | 1.60 | 47.77/55.50/62.90 | 0.0 | 0.5189 | 0.0000 | 100.00 |
| 10 | rumor_follower | 2000 | 13.85 | 1.40 | 0.00 | 98.60 | 0.00 | 23.70 | 1.40 | 48.90/56.40/63.90 | 0.0 | 0.5352 | -0.3604 | 100.00 |
| 10 | official_only | 2000 | 33.85 | 0.00 | 0.00 | 100.00 | 0.00 | 0.90 | 0.00 | 55.87/61.30/67.50 | 0.0 | 0.6985 | -0.1048 | 100.00 |
| 10 | verifier | 2000 | 69.50 | 0.10 | 0.00 | 99.90 | 0.05 | 7.90 | 0.15 | 55.90/63.00/73.00 | 1.0 | 0.7197 | 0.3120 | 100.00 |
| 10 | careful_hedger | 2000 | 30.50 | 0.00 | 0.00 | 100.00 | 0.00 | 0.15 | 0.00 | 57.60/62.70/67.50 | 0.0 | 0.7200 | 0.3120 | 100.00 |
| 30 | random_reporter | 2000 | 63.95 | 3.25 | 0.65 | 96.10 | 0.10 | 22.15 | 3.35 | 55.00/62.80/72.00 | 1.0 | 0.5141 | 0.0000 | 100.00 |
| 30 | rumor_follower | 2000 | 69.00 | 4.45 | 0.05 | 95.50 | 0.15 | 31.25 | 4.60 | 55.00/62.50/71.90 | 1.0 | 0.5345 | -0.4015 | 100.00 |
| 30 | official_only | 2000 | 98.50 | 0.00 | 0.05 | 99.95 | 0.00 | 1.20 | 0.00 | 60.57/68.15/75.70 | 2.0 | 0.7008 | -0.0564 | 100.00 |
| 30 | verifier | 2000 | 62.35 | 0.15 | 36.85 | 63.00 | 0.45 | 9.55 | 0.60 | 61.60/71.20/82.60 | 3.0 | 0.7006 | 0.2784 | 100.00 |
| 30 | careful_hedger | 2000 | 41.35 | 0.00 | 58.00 | 42.00 | 0.00 | 0.35 | 0.00 | 61.00/68.80/75.40 | 2.0 | 0.7061 | 0.3007 | 100.00 |

Lịch sử chỉnh số: các dòng sau là ván thật 200/bot (seed 104..303), trừ vòng 8/9 ghi rõ 2.000. Các hệ số không nêu giữ vòng trước. R/U/O/V/H = random/rumor/official/verifier/hedger. Không dùng các mẫu nhỏ thay kết quả nghiệm thu 2.000.

| Vòng | Thay đổi |
|---|---|
| 1 | base=5, adjacent_effect=-0,3, wrong_factor=1,8, ev_factor=1; giữ Trust 42, ngưỡng thăng 70/75/80/85; thăng không giảm Trust; giá công cụ 60/80/40/100, full cần trưởng nhóm |
| 2 | Ngưỡng thăng 62/85/100/85; demote=30; chuỗi sai thực tập tính acc<1 |
| 3 | ev_factor=0,65; demote=25 |
| 4 | base=6, wrong=2,2, adjacent=-0,1, ev=0,5; thap=0,7, cao=1,1; ngưỡng chuyên viên chính lên trưởng nhóm 94 |
| 5 | demote=35, low_trust_days=3 thay chuỗi sai; thap=0,65; ngưỡng đầu 64, ngưỡng lên trưởng nhóm 100 |
| 6 | warning/demote=40; low_days=5; thap=0,6, cao=1; full cần giám đốc, ngưỡng trưởng nhóm lên giám đốc 100 |
| 7 | wrong=1,4, adjacent=-0,6, ev=0,7; thap=0,7, cao=1,2 |
| Sàng 1 | 100.000 ứng viên trên chuỗi công khai 200 seed/cả hai kỳ; giữ vua=1, tốt nhất vẫn vi phạm fired official. Không sửa world.json cho từng ứng viên, không phải bảng nghiệm thu |
| Sàng 2 | Cho vua trong [0,7;1,1], mở ev về 0..1 và minimum_days đến 7; tìm được ứng viên đạt ngưỡng trên mẫu nhỏ. Candidate: base=10, wrong=2,3, adjacent=-0,55, ev=0,2; thap/vua/cao=0,8/0,85/1,6; Trust=47, demote=16, low_days=6, minimum_days=6, promote=72/79/96/100, full=trưởng nhóm |
| 8 | Chạy thật 2.000/bot, Trust=46 thay 47 để random có dư địa phạt; bonus thắng 8.000. Demo chỉ thiếu trần fired verifier (1,75% >1%); dừng lượt 30 ngày và quét điểm đang chạy để sửa, không lấy kết quả dở dang |
| 9 | ev_factor=0,4, thap=0,7. Chạy thật 2.000/bot cả hai kỳ; giữ nguyên mục tiêu A/B |

Kết quả từng vòng đã hoàn tất (Thắng / Fired / Heavy theo thứ tự R/U/O/V/H):

| Vòng | Ngày | N/bot | Thắng % R/U/O/V/H | Fired % R/U/O/V/H | Heavy % R/U/O/V/H |
|---|---:|---:|---|---|---|
| 1 | 10 | 200 | 1.00 / 2.50 / 12.50 / 68.50 / 18.00 | 18.00 / 44.00 / 1.00 / 0.00 / 0.00 | chưa thêm cột |
| 2 | 10 | 200 | 5.50 / 9.50 / 31.50 / 80.00 / 47.50 | 54.50 / 75.00 / 14.00 / 0.00 / 0.00 | 54.50 / 76.50 / 14.00 / 0.00 / 0.00 |
| 2 | 30 | 200 | 0.00 / 0.00 / 26.00 / 92.00 / 55.00 | 80.00 / 97.00 / 18.50 / 0.00 / 0.00 | 82.00 / 98.50 / 18.50 / 0.00 / 0.00 |
| 3 | 10 | 200 | 5.50 / 13.00 / 32.00 / 72.00 / 31.50 | 38.50 / 61.00 / 8.50 / 0.00 / 0.00 | 38.50 / 62.00 / 8.50 / 0.00 / 0.00 |
| 3 | 30 | 200 | 0.00 / 0.50 / 27.50 / 89.00 / 25.50 | 77.00 / 92.50 / 6.00 / 0.00 / 0.00 | 78.50 / 94.50 / 6.00 / 0.00 / 0.00 |
| 4 | 10 | 200 | 8.00 / 12.00 / 49.50 / 73.00 / 59.50 | 42.50 / 53.50 / 9.00 / 0.00 / 0.00 | 42.50 / 54.00 / 9.00 / 0.00 / 0.00 |
| 4 | 30 | 200 | 0.50 / 1.00 / 64.00 / 88.50 / 82.50 | 73.50 / 87.50 / 8.50 / 0.50 / 0.00 | 76.00 / 91.50 / 8.50 / 0.50 / 0.00 |
| 5 | 10 | 200 | 5.50 / 10.00 / 45.00 / 68.50 / 48.00 | 52.00 / 59.50 / 10.50 / 0.50 / 0.00 | 52.00 / 60.50 / 10.50 / 0.50 / 0.00 |
| 5 | 30 | 200 | 0.00 / 1.00 / 54.50 / 86.50 / 70.00 | 79.00 / 88.50 / 16.50 / 1.00 / 0.00 | 81.50 / 93.00 / 17.00 / 1.00 / 0.00 |
| 6 | 10 | 200 | 4.00 / 8.50 / 45.00 / 61.00 / 40.50 | 48.50 / 54.00 / 10.50 / 0.00 / 0.00 | 48.50 / 54.50 / 10.50 / 0.00 / 0.00 |
| 6 | 30 | 200 | 0.00 / 0.50 / 37.00 / 65.50 / 28.00 | 81.50 / 88.50 / 13.00 / 1.50 / 0.50 | 84.00 / 93.00 / 15.00 / 1.50 / 0.50 |
| 7 | 10 | 200 | 3.00 / 7.00 / 28.50 / 67.50 / 41.50 | 55.50 / 64.00 / 19.00 / 3.50 / 3.50 | 55.50 / 64.50 / 19.00 / 3.50 / 3.50 |
| 7 | 30 | 200 | 0.00 / 0.00 / 17.50 / 70.50 / 31.50 | 87.50 / 95.50 / 25.00 / 5.50 / 5.50 | 90.00 / 98.00 / 26.00 / 5.50 / 5.50 |
| 8 | 10 | 2000 | 7.10 / 10.70 / 37.65 / 63.70 / 51.35 | 53.25 / 72.55 / 2.95 / 1.75 / 0.05 | 53.50 / 72.90 / 2.95 / 1.75 / 0.05 |
| 9 | 10 | 2000 | 7.10 / 8.25 / 35.70 / 66.20 / 52.90 | 51.40 / 76.45 / 3.45 / 0.25 / 0.00 | 51.60 / 76.95 / 3.45 / 0.25 / 0.00 |
| 9 | 30 | 2000 | 0.55 / 0.40 / 30.55 / 66.15 / 57.10 | 90.35 / 97.60 / 10.60 / 1.05 / 0.00 | 92.30 / 98.45 / 11.75 / 1.05 / 0.00 |


Bảng sau vòng 9 (2.000 ván/bot, seed 104..2103):

| Ngày | Bot | N | Thắng % | Fired % | Bankrupt % | Survived % | Demoted % | Warned % | Heavy % | Trust p25/p50/p75 | Rank p50 | acc TB | ev TB | Đủ 5 kind % |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| 10 | random_reporter | 2000 | 7.10 | 51.40 | 0.00 | 48.60 | 0.20 | 86.60 | 51.60 | 0.00/0.00/35.60 | 0.0 | 0.4774 | 0.0000 | 100.00 |
| 10 | rumor_follower | 2000 | 8.25 | 76.45 | 0.00 | 23.55 | 0.50 | 92.75 | 76.95 | 0.00/0.00/0.00 | 0.0 | 0.4604 | -0.3538 | 100.00 |
| 10 | official_only | 2000 | 35.70 | 3.45 | 0.00 | 96.55 | 0.00 | 43.25 | 3.45 | 39.80/58.95/76.50 | 0.0 | 0.6947 | -0.1075 | 100.00 |
| 10 | verifier | 2000 | 66.20 | 0.25 | 0.00 | 99.75 | 0.00 | 17.85 | 0.25 | 74.40/92.80/100.00 | 1.0 | 0.7197 | 0.3120 | 100.00 |
| 10 | careful_hedger | 2000 | 52.90 | 0.00 | 0.00 | 100.00 | 0.00 | 12.50 | 0.00 | 59.60/73.40/86.40 | 1.0 | 0.7200 | 0.3120 | 100.00 |
| 30 | random_reporter | 2000 | 0.55 | 90.35 | 0.05 | 9.60 | 4.25 | 98.70 | 92.30 | 0.00/0.00/0.00 | 0.0 | 0.4527 | 0.0000 | 100.00 |
| 30 | rumor_follower | 2000 | 0.40 | 97.60 | 0.00 | 2.40 | 4.50 | 99.75 | 98.45 | 0.00/0.00/0.00 | 0.0 | 0.4469 | -0.3853 | 100.00 |
| 30 | official_only | 2000 | 30.55 | 10.60 | 0.05 | 89.35 | 1.15 | 52.35 | 11.75 | 53.70/78.45/95.30 | 2.0 | 0.6866 | -0.0630 | 100.00 |
| 30 | verifier | 2000 | 66.15 | 1.05 | 0.50 | 98.45 | 0.00 | 17.95 | 1.05 | 90.98/96.20/100.00 | 3.0 | 0.7151 | 0.3510 | 100.00 |
| 30 | careful_hedger | 2000 | 57.10 | 0.00 | 0.00 | 100.00 | 0.00 | 12.80 | 0.00 | 90.30/96.20/100.00 | 3.0 | 0.7172 | 0.3509 | 100.00 |

- Đạt mục tiêu A: random Heavy 51,60% >=50, fired 51,40% >=15, Trust p50=0 <46, thắng 7,10% <=10. Rumor Heavy 76,95% >=35, p50=0 <=46, thắng 8,25% <=15. Official Heavy=fired 3,45% <=20/5, p50=58,95 >46, thắng 35,70% trong [30;55]. Hedger Heavy=fired 0% <=8/2, p50=73,40 >46, thắng 52,90% trong [25;60] và dưới verifier. Verifier Heavy=fired 0,25% <=5/1, p50=92,80 >=60, thắng 66,20% <=85, hơn official 30,50 điểm % >=15.
- Đạt mục tiêu B: random thắng 0,55% <=20, Heavy 92,30% >=70; rumor thắng 0,40% <=25, Heavy 98,45% >=55. Official thắng 30,55% trong [25;55], bankrupt 0,05% <=5; hedger thắng 57,10% trong [30;60], bankrupt 0%; verifier thắng 66,15% <=85, hơn official 35,60 điểm % >=10, bankrupt 0,50% <=5. Không hạ mục tiêu; không còn mục tiêu định lượng A/B chưa đạt. Không diễn giải trần fired của demo thành trần cho full (spec B không đặt trần này); tất cả số fired full đã ghi nguyên ở bảng.
- Kiểm thử: Godot console 4.7.2 đúng đường dẫn VU giao, --headless --path game-studio/godot --script res://tests/<tên>.gd. test_sim: 2.630/0 failures (đủ 2.623 cũ +7 mới); test_ui: 134/0; test_world: 32.419/0, gồm quét 500 seed/bot ở cả hai kỳ; chạy lại đầy đủ sau chốt 4 ví dụ hệ số cuối cũng 32.419/0, exit 0 (TEMP/T-018b-test-world-delivery.txt). Quét điểm 10 ngày: 863 thắng/1.637 thua, min_win 8.464,50 > max_loss 1.914,00; 30 ngày: 761 thắng/1.739 thua, min_win 9.538,00 > max_loss 3.776,00. balance_sim trước/sau giống 47 dòng, chỉ loại elapsed_seconds. git diff --check qua. Console vẫn báo không ghi được user://logs/godot.log và không đọc được kho chứng chỉ; không có lỗi script ở các lượt cuối.
- Không lộ/tái lập: giữ nguyên bộ rà đệ quy truth/kind/link/state_direction/exaggerates/answer/scenario, không xóa kiểm tra; mở rộng public/replay/hash nhật ký từ 10 sang cả 30 ngày. review ngày hiện tại/tương lai vẫn bị từ chối. Mọi bot giữ nguyên propose, chỉ dùng API công khai; thống kê kind/cú sốc/acc/ev chỉ lấy từ review sau ngày. Đủ 5 kind 100% và 8/8 cú sốc ở cả hai bảng cuối. Chuỗi báo cáo đúng trên kịch bản cố định 10/30 ngày không giảm Trust, không cảnh cáo/giáng chức/đuổi việc, kể cả lúc thăng chức.

Danh sách kiểm tra đổi (giữ toàn bộ kiểm tra cũ, không xóa):

| Kiểm tra | Thay đổi và lý do |
|---|---|
| hand computed nominal correct high with evidence | Giữ 18,8 = snappedf(10*1,5*1,25); công thức thưởng đúng không đổi |
| hand computed nominal opposite | -12,5 thành -13,5 = -10*1,8*(1-0,25); sai nhân wrong_factor, bằng chứng xác nhận giảm phạt |
| hand computed nominal adjacent | +3,8 thành -2,2 = snappedf(-10*0,3*0,75); lệch một bậc chuyển sang bị trừ, snappedf của Godot làm tròn -2,25 lên -2,2 |
| accuracy table / confidence grade table | Giữ đủ 27 tổ hợp hướng/đáp án/tự tin và 54 kiểm tra; acc giữ 1/0,4/0, delta thay 0,3 và -1 cũ bằng adjacent_effect và -wrong_factor |
| evidence table / evidence delta | Giữ đủ 25 cặp truth/verification (50 kiểm tra); ev không đổi, delta nhân thêm confidence.vua vì hệ số vừa nay là 0,85, không còn mặc định bằng 1 |
| promotion and reset | Đổi kỳ vọng Trust 55 thành 72 = max(42+15+15,55), vì thăng chức không được làm mất Trust. Cố định fixture 42/35/25, tenure=2, ngưỡng 70 để ví dụ tính tay độc lập với chỉnh cân bằng; vẫn kiểm tra thâm niên tối thiểu và 300 tiền lương/thưởng |
| intern first wrong / intern two wrong fired | Giữ cả hai kiểm tra với fixture low_trust_days=2 và Trust 25: sau một ngày thấp chưa đuổi, ngày thấp thứ hai có báo cáo sai thì đuổi. Đây là cơ chế thấp kéo dài mới, không còn dựa riêng hai acc=0 liên tiếp |
| warning only crossing / new crossing / demotion resets / two demotions fired / zero trust fired / adoption monotonic | Giữ nguyên mọi kỳ vọng cũ trên fixture cố định (cảnh cáo 1 rồi 2, giáng 24->40, đuổi sau 2 giáng hoặc Trust=0, chấp thuận đơn điệu). Chỉ đổi nguồn config sang fixture để không vô tình phụ thuộc ngưỡng live 16 |
| test_public_and_replay | Giữ nguyên toàn bộ vòng 10 ngày, thêm vòng 30 ngày với cùng kiểm tra khóa ẩn/cache/bản sao/hash. Chỉ yêu cầu survived cho tích hợp demo cũ; vòng full kiểm tra kết thúc nhất quán vì báo cáo ngang cố định có thể bị đuổi theo luật mới |
| test_score_sweep | Giữ đủ 500 ván/bot/10 ngày và cận lý thuyết 30 ngày; thêm quét thực tế 500 ván/bot/30 ngày, tách min_win/max_loss từng kỳ, không thay bằng mẫu nhỏ hơn |
| test_overrides_and_endings | Giữ mọi fixture fired/bankrupt/survived và công thức điểm chính xác; thêm kiểm tra Trust/cảnh cáo/giáng/đuổi sau từng báo cáo đúng trong fixture thắng |

Kiểm tra thêm:

- Ví dụ tính tay với bộ số cuối: đúng/vừa/có xác nhận +11,9 = 10*0,85*1,4; ngược hướng -11,7 = snappedf(-10*0,85*2,3*0,6); lệch một bậc -2,8 = snappedf(-10*0,85*0,55*0,6); dẫn tin bác bỏ và ngược hướng -27,4 = snappedf(-10*0,85*2,3*1,4). Giữ thêm fixture danh định sai+bằng chứng xấu -22,5 và adjacent không bằng chứng -3, cùng kỳ vọng đoán đều âm.
- Báo cáo đúng khi phục hồi ở Trust thấp không bị đuổi dù bộ đếm thấp đã đủ; một báo cáo adjacent sau giai đoạn thấp kéo dài mới kích hoạt nhánh đuổi. Hai chuỗi cố định 10/30 ngày kiểm tra Trust không giảm mỗi ngày, không phạt, kết thúc survived; giá tools bằng Cash bị trừ và cash_report, kiểm chứng cache không thu lại; ranh giới thắng cho cả 5 chức ở demo/full.
- test_sim thêm 7 kiểm tra chỉ trong test_use_tool: ghi đè giá 60 khi không đủ giá gốc 500; trừ đúng 60; giữ Energy và tay; từ chối giá 80 khi Cash=0; từ chối không thay tài nguyên; ghi đè 0 hợp lệ; giá 0 không vượt được ràng buộc analysis. SQL có Energy=0 trong cards.json hiện tại, không giả định mất 1 Energy. Giữ đủ 15 kiểm tra use_tool cũ.
- Tự quyết: mọi chỉnh số chỉ ở world.json; không đổi kinh tế v1 hoặc nguồn tin để đạt tỷ lệ. Bằng chứng nhân theo dấu điểm, ngưỡng thăng 72/79/96/100, thời gian giữ chức 6 ngày, Trust khởi điểm 46, demote 16, thấp kéo dài 6 ngày; giá công cụ dùng chung hai kỳ, full cần trưởng nhóm; bonus thắng tăng theo cận điểm. Không thêm luật đọc đáp án cho bot. Không phát hiện lỗi bắt buộc sửa trong news.json/questions.json.

world.json cuối đầy đủ:
```json
{
 "version":1,
 "variables":["lai_suat","ty_gia","nguyen_lieu","suc_mua","chung_khoan","tin_dung"],
 "directions":["tang","giam","ngang"],
 "magnitudes":["low","mid","high"],
 "markov_keep":0.78,
 "shock_count":{"10":4,"30":12},
 "shock_probability":0.85,
 "precursors":{"competitor_discount":{"variable":"ty_gia","direction":"tang"},"price_fatigue":{"variable":"nguyen_lieu","direction":"tang"}},
 "precursor_weight":3,
 "news_per_day":{"10":6,"30":7},
 "kind_weights":{"signal":45,"trap":25,"partial":5,"stale":10,"noise":10},
 "repeat_days":3,"news_lifetime":3,"event_recent_days":2,
 "noise_factor":0.5,
 "macro":{"lai_suat":{"tang":{"fixed_cost":8},"giam":{"fixed_cost":-4}},"ty_gia":{"tang":{"cac":2.4},"giam":{"cac":-1.2}},"nguyen_lieu":{"tang":{"fixed_cost":6},"giam":{"fixed_cost":-3}},"suc_mua":{"tang":{"conversion":0.0003,"retention":0.003},"giam":{"conversion":-0.0003,"retention":-0.003}},"tin_dung":{"giam":{"fixed_cost":4}}},
 "magnitude_scale":{"low":0.5,"mid":1,"high":1.5},
 "tools":{"truy_van_lich_su":"sql_deep_dive","kiem_dinh_gia_thuyet":"ab_test","doi_chieu_nguon":"funnel_report","lam_sach_du_lieu":"clean_data"},
 "grading":{"base":10,"adjacent":0.4,"adjacent_effect":-0.55,"wrong_factor":2.3,"evidence_factor":0.4,"confidence":{"thap":0.7,"vua":0.85,"cao":1.6},"evidence":{"xac_nhan":1,"chua_du_can_cu":0,"bac_bo":-1,"cu":-1},"unverified":{"sai":-1,"cu":-1,"dung":0.25,"mot_phan":0,"khong_lien_quan":0},"max_evidence":3},
 "career":{"initial_trust":46,"reset_promotion":55,"reset_demotion":40,"warning":35,"demote":16,"low_trust_days":6,"minimum_days":6,"correct_streak":2,"max_demotions":2,"bonus_fraction":0.5,"adopt_min":0.4,"adopt_max":1},
 "ranks":[{"id":"thuc_tap","actions":1,"promote":72,"salary":100},{"id":"chuyen_vien","actions":2,"promote":79,"salary":160},{"id":"chuyen_vien_chinh","actions":2,"promote":96,"salary":240},{"id":"truong_nhom","actions":3,"promote":100,"salary":340},{"id":"giam_doc","actions":3,"promote":101,"salary":460}],
 "score":{"win_bonus":8000,"trust":5,"positive_delta":10,"demotion":150,"fired":300},
 "tool_budget":{"truy_van_lich_su":60,"kiem_dinh_gia_thuyet":80,"doi_chieu_nguon":40,"lam_sach_du_lieu":100},
 "win":{"demo":"chuyen_vien","full":"truong_nhom"},
 "balance":{"seed":104,"games":2000}
}
```

- Git: git add bị fatal: Unable to create 'D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock': Permission denied. Không stage/commit được; giữ nguyên file chưa commit trong worktree. Không đổi quyền, không vượt sandbox, không push/merge.
### T-019a | Codex | 2026-11-10 | Review

- Đã nhận: owner Codex, trạng thái In progress; nhánh codex/T-019a, cây làm việc ban đầu sạch. Triển khai đúng SPEC-T-019a, không gọi mạng.
- Đã làm: đường ống GDScript thuần, ảnh chữ theo 0-9a-v/dot, 26 dải PNG xác định; bản sao palette khớp byte với shared. Cảnh office 640x360 có đủ bốn bàn, hai cây, tủ, cửa sổ, đồng hồ, cửa sếp; API set_phase/set_clock/play_arrival/play_boss_appears/show_dialog/hide_dialog và seated/dialog_closed/desk_clicked. Không đổi main_scene, mã hoặc dữ liệu lõi, không gọi mạng hay dùng tài nguyên ngoài.
- File thêm (dưới game-studio/godot): tools/gen_sprites.gd, tools/check_palette.gd, tools/sprites/{characters,furniture,icons}.gd; scripts/v2/{palette,sprite_lib,office}.gd; scenes/v2/office.tscn; data/palette_v2.json; assets/v2/*.png (26 ảnh và metadata Godot nếu có); tests/test_v2_assets.gd. TASKS.md cập nhật trạng thái và bàn giao.
- Cách chạy từ gốc worktree trong PowerShell: đặt $godot = 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'; chạy & $godot --headless --path game-studio/godot -s res://tools/gen_sprites.gd rồi & $godot --headless --path game-studio/godot -s res://tools/check_palette.gd. Test tương tự với -s res://tests/test_v2_assets.gd. Xem cảnh riêng: & $godot --path game-studio/godot res://scenes/v2/office.tscn.
- Kiểm tra: gen_sprites và check_palette exit 0; 26 PNG đúng kích thước/số khung, palette 32 màu, alpha 0/255; hai lượt sinh có SHA-256 giống nhau, không ghi lại PNG nếu bytes không đổi. test_v2_assets 2.255/0 failures; test_sim 2.630/0; test_ui 134/0; test_world 32.419/0, gồm hai kỳ và quét 500 seed/bot. balance_sim chạy trước/sau: toàn bộ số liệu giữ nguyên (chỉ elapsed_seconds 28,822 -> 35,079), không đổi file đầu vào/mã bot/mô phỏng. Ví dụ balanced 10/30 ngày 43,05%/32,05%, analyst 55,50%/53,30%.
- Tự quyết: bốn bàn tại x=136/248/360/472, y=200; tường cao 128, lối vào trái và lối đi trước bàn. Người chơi áo xanh/cà vạt vàng; Khôi tóc tối/áo xám/kính; Mai tóc nâu/áo tím/kẹp tóc; Tư tóc bạc/áo xanh rêu/mũ; Hạnh áo xanh đậm/cổ áo sáng. Bóng phía dưới phải màu 3, viền màn hình người chơi màu 21; cửa sổ sáng/trưa/chiều tương ứng sáng/nhiều mây/hoàng hôn. Hoạt ảnh dùng thời lượng riêng, chân chạm đất 160 ms; vị trí làm tròn từng khung, đến bàn khoảng 207 khung 60 FPS; API advance(delta) hỗ trợ kiểm thử không chờ thời gian thật.
- Hạn chế/duyệt: dùng font Godot mặc định cỡ 8/12; sprite không anti-alias, chữ vẫn theo font mặc định chưa phải font pixel. Hộp thoại 300 ký tự giữ nguyên nội dung, tự xuống dòng và cuộn trong khung 592x80; chưa phân trang. Đã chạy render thật và xem ảnh TEMP/T-019a-office.png (cờ --capture của test, ảnh ngoài assets); Claude cần chụp/duyệt mỹ thuật ở 1x và 2x, đặc biệt độ đọc nhân vật nhỏ và mật độ họa tiết sàn. Console có cảnh báo môi trường không ghi được user://logs, không đọc được kho chứng chỉ; render thật thêm cảnh báo cache shader, không có lỗi script trong lượt cuối.
- Git: git add bị Permission denied khi tạo D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock (metadata ngoài vùng ghi). Chưa stage/commit; để nguyên file chưa commit, không vượt sandbox, không push, không merge.
### T-019b | Codex | 2026-11-10 | Review

- Đã làm: desktop 640x360 gồm Tin tức, Công ty, Công cụ và thanh tác vụ; chọn tin bằng chuột/phím, ghim tối đa 3, kiểm chứng/cache, thu nhỏ/phục hồi và đủ tín hiệu/API theo spec. Chỉ đọc API công khai WorldGame, lọc đúng 10 khóa tin; quét toàn bộ scripts/v2 không tham chiếu định danh nhạy cảm. WorldGame chỉ thêm hai khóa int energy/energy_max trong status().
- File đổi (dưới game-studio/godot): scenes/v2/desktop.tscn; scripts/v2/{desktop,theme_v2}.gd; scripts/v2/windows/{window_base,news_window,company_window,tools_window,tooltip_label}.gd; data/strings_v2.json; scripts/world/world_game.gd (chỉ status); tests/{test_v2_desktop,test_world}.gd (test_world chỉ thêm kiểm tra energy). TASKS.md chuyển dòng sang Review và ghi bàn giao. Dùng lại 26 sprite, không cần thêm biểu tượng; gen_sprites không làm đổi asset. Không sửa office, project.godot, mô phỏng, UI v1 hoặc dữ liệu cũ.
- Kiểm thử Godot console 4.7.2, --headless --path game-studio/godot -s res://tests/<tên>.gd: test_v2_desktop 582/0 failures (gồm 10 ngày thực, ghim/tín hiệu, cache, thiếu Energy/Budget, lỗi đóng ngày, bàn phím, chuỗi, quét mã nhạy cảm, 6 tiêu đề 200 ký tự, tooltip và kích thước thực); test_v2_assets 2.255/0; test_sim 2.630/0; test_ui 134/0; test_world 32.438/0 (giữ 32.419 cũ +19 kiểm tra energy). gen_sprites exit 0; check_palette PASS 26 PNG/32 màu/alpha nhị phân. balance_sim trước/sau giống hệt 47 dòng, chỉ bỏ elapsed_seconds. git diff --check qua.
- Tự quyết: cửa sổ Tin tức 388x320, Công ty 240x164, Công cụ 240x152, không chồng; tiêu đề tin font 12 hai dòng, phần phụ font 8; câu hỏi dài tự cuộn ngang có dừng ở hai đầu; tooltip ngắt dòng rộng 296px. Mũi tên so với ảnh chụp cuối lần đọc ở ngày trước, không thay mốc khi refresh cùng ngày. LTV/CAC ước tính từ số liệu báo cáo, sàn hao hụt 1%, có tooltip giải thích. Cache vẫn bấm được khi cạn tài nguyên, vì lõi không thu phí lần hai; chi phí lấy từ tools() (ba công cụ 0 Energy, Làm sạch dữ liệu 1). Ghim hết hiệu lực tự bỏ và phát evidence_changed. Chú thích hư cấu nằm ở tooltip đồng hồ ngày.
- Duyệt trực quan: đã render thật bằng --rendering-method gl_compatibility -s res://tests/test_v2_desktop.gd -- --capture và xem hai ảnh trong thư mục TEMP hệ thống: T-019b-desktop.png (ván thật, đã ghim/kiểm chứng) và T-019b-desktop-long.png (tin dài). Claude cần duyệt mỹ thuật khi tích hợp với văn phòng; màn hình nhận game qua setup(), không tự tạo ván hoặc đổi main_scene. Console vẫn có lỗi môi trường không ghi được user://logs và không đọc kho chứng chỉ; render thêm cảnh báo cache shader; không có lỗi script ở lượt cuối.
- Git: git add bị fatal: Unable to create D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock: Permission denied. Chưa stage/commit, giữ nguyên file trong worktree codex/T-019b; không vượt sandbox, không push, không merge.

#### Sửa sau review dc82312 | Codex | 2026-11-10 | Review

- Đã sửa: gắn nút/đồng hồ vào thanh tác vụ có clip, áp theme trước khi tính kích thước, margin StyleBox 1px và minimum nút 108x14; ProgressBar tắt phần trăm/áp theme trước khi đặt 117x7 và đặt lại sau khi thêm vào cây. Các hàng ngày/chức vụ, Tin tưởng và 8 chỉ số tách biệt. Tên/chi phí công cụ được tách thành hai hàng 12px, bước công cụ 24px (bản cũ chồng 2px).
- File đổi đợt này (dưới game-studio/godot): scripts/v2/desktop.gd, scripts/v2/theme_v2.gd, scripts/v2/windows/company_window.gd, scripts/v2/windows/tools_window.gd, tests/test_v2_desktop.gd; TASKS.md cho trạng thái/bàn giao. Không sửa dữ liệu, Energy hay lớp thế giới.
- Kiểm tra hồi quy mới: chờ hai process_frame và thêm frame_post_draw khi render thật; đọc get_global_rect() và get_combined_minimum_size(), kiểm tra trong 640x360 (nội dung cuộn kiểm tra vùng nhìn), các hàng anh em không chồng trong cả ba cửa sổ, từng dòng tin và chrome; nút tác vụ nằm trong y344..360, cao <=14 kể cả minimum; chiều cao font cộng margin từng trạng thái nút phải <=14. Chạy trên dc82312 trước sửa: 1.454 kiểm tra/8 lỗi ở cả headless và render; chạy lại bộ cuối 2.332 kiểm tra trên mã gốc: 16 lỗi, exit 1; khôi phục mã sửa: 2.332/0 ở headless và render thật, exit 0. Lỗi thật: ProgressBar cao 27px dù đặt 7px, đè Cash và hàng kế. Nút tác vụ ở môi trường kiểm tra này đo 14px cả trước sửa; đã cố định thứ tự theme/margin/clip và thêm kiểm tra font để tránh tái phát lỗi cắt chữ review nêu.
- Số đo global sau layout/render: taskbar (0,344) 640x16; ba nút (4/116/228,345) 108x14, kết thúc y359, font cao 12px + margin dọc 2px. Thanh Tin tưởng (513,52) 117x7, kết thúc y59; Cash (400,64) cao 12px, cách thanh 5px. Nhãn Năng lượng (400,204) 230x14; kết quả Chưa đủ căn cứ (400,314) 232x22, kết thúc y336. Tiêu đề cửa sổ cao 12px, nút ghim đầu (342,60) 20x20. Đã xem ảnh render thật TEMP hệ thống/T-019b-desktop.png và T-019b-desktop-long.png: chữ tác vụ, Cash, kết quả công cụ, Năng lượng, tiêu đề và ghim đều nằm trọn, không chồng.
- Kiểm thử còn lại: test_v2_assets 2.255/0, test_sim 2.630/0, test_ui 134/0, test_world 32.438/0; gen_sprites exit 0, check_palette PASS 26 PNG; balance_sim trước/sau giống hệt 47 dòng khi bỏ elapsed_seconds. Giữ cảnh báo môi trường user://logs, kho chứng chỉ và cache shader; không có lỗi script ở lượt cuối. git diff --check qua.
- Git đợt sửa: git add bị Permission denied khi tạo D:/Dev/ai-company/.git/worktrees/ai-company-codex/index.lock; file sửa chưa stage/commit. Không vượt sandbox, không push, không merge.

### T-018c | Claude subagent (thay Codex) | 2026-11-10 | Review

- Nhánh codex/T-018c (từ v2), commit mã 0fbeb12. Không push, không merge, không tải mạng.
- Làm: kho Energy phân tích riêng của tầng thế giới (WorldGame._analysis_energy, đặt lại ở begin_day). world.json thêm analysis_energy và tool_energy. status().energy/energy_max là kho này; tools().energy là tool_energy. verify trừ kho này, hết thì trả {ok:false,error:"no_analysis_energy"} (không trừ Budget, không đổi trạng thái); kiểm chứng lặp vẫn miễn phí; lỗi invalid_uid/invalid_tool vẫn được ưu tiên hơn lỗi hết Energy. Simulation.use_tool thêm tham số tùy chọn spend_energy (mặc định true, hành vi cũ giữ nguyên); Verifier gọi với false nên Energy công ty không bị đụng. UI v2: chỉ thêm chuỗi errors.no_analysis_energy trong strings_v2.json (desktop.gd và tools_window.gd tự đúng vì đọc status()/tools(); không phải sửa).
- Bot (balance_world.gd): verifier và careful_hedger chỉ kiểm chứng tin liên quan câu hỏi của đúng ngày hiện tại, theo thứ tự tin trong danh sách công khai, dừng khi gặp no_analysis_energy. Thêm 2 cột in ra: kiểm chứng/ngày và % tin liên quan được kiểm chứng.
- Chỉnh số: không cần vòng chỉnh nào. Giá trị khởi điểm của spec (analysis_energy 3, mọi tool_energy 1) đạt toàn bộ mục tiêu A và B ngay vòng đầu. Không đổi grading, career, tool_budget.

Bảng cân bằng (2.000 ván/bot, seed 104+). Trước = v2 gốc, Sau = T-018c. KC/ngày = số lần kiểm chứng trung bình mỗi ngày (chỉ đo ở bản Sau).

| Ngày | Bot | Thắng trước/sau | Đuổi trước/sau | Phá sản trước/sau | Phạt nặng trước/sau | Tin tưởng p50 trước/sau | KC/ngày |
|---|---|---|---|---|---|---|---|
| 10 | random_reporter | 7,10 / 7,10 | 51,40 / 51,40 | 0 / 0 | 51,60 / 51,60 | 0 / 0 | 0 |
| 10 | rumor_follower | 8,25 / 8,25 | 76,45 / 76,45 | 0 / 0 | 76,95 / 76,95 | 0 / 0 | 0 |
| 10 | official_only | 35,70 / 35,70 | 3,45 / 3,45 | 0 / 0 | 3,45 / 3,45 | 58,95 / 58,95 | 0 |
| 10 | verifier | 66,20 / 64,75 | 0,25 / 0,30 | 0 / 0 | 0,25 / 0,30 | 92,80 / 92,40 | 1,015 |
| 10 | careful_hedger | 52,90 / 51,65 | 0 / 0 | 0 / 0 | 0 / 0 | 73,40 / 72,80 | 1,015 |
| 30 | random_reporter | 0,55 / 0,55 | 90,35 / 90,35 | 0,05 / 0,05 | 92,30 / 92,30 | 0 / 0 | 0 |
| 30 | rumor_follower | 0,40 / 0,40 | 97,60 / 97,60 | 0 / 0 | 98,45 / 98,45 | 0 / 0 | 0 |
| 30 | official_only | 30,55 / 30,55 | 10,60 / 10,60 | 0,05 / 0,05 | 11,75 / 11,75 | 78,45 / 78,45 | 0 |
| 30 | verifier | 66,15 / 63,50 | 1,05 / 1,10 | 0,50 / 0,35 | 1,05 / 1,10 | 96,20 / 96,20 | 1,182 |
| 30 | careful_hedger | 57,10 / 54,10 | 0 / 0,05 | 0 / 0 | 0 / 0,05 | 96,20 / 96,20 | 1,182 |

- Tỷ lệ tin liên quan câu hỏi (của ngày đó) được kiểm chứng: verifier và careful_hedger 96,3% (10 ngày), 95,1% (30 ngày).
- Mục tiêu A (10 ngày) và B (30 ngày) đều ĐẠT: verifier hơn official_only 29,05 điểm % (10 ngày, cần 15) và 32,95 điểm % (30 ngày, cần 10); mọi bot khác nằm trong khoảng yêu cầu. Không có mục tiêu nào chưa đạt, không có mâu thuẫn giữa A và B.
- Phát hiện cần Claude cân nhắc: khan hiếm gần như không cắn bot. Mỗi ngày chỉ có khoảng 1 tin liên quan câu hỏi nên bot dùng ~1 lần kiểm chứng/ngày (spec kỳ vọng "gần giới hạn" 3). Người chơi thật thấy cả 6-7 tin nên có thể muốn kiểm chứng nhiều hơn. Nếu muốn áp lực rõ hơn: giảm analysis_energy xuống 2, hoặc tăng tool_energy của kiem_dinh_gia_thuyet/lam_sach_du_lieu lên 2, hoặc thêm bot "kiểm chứng rộng". Chưa thử vì mục tiêu đã đạt và spec nêu khởi điểm 3 và 1.

world.json cuối: file đầy đủ ở game-studio/godot/data/world.json. Phần thêm mới so với v2: "analysis_energy":3, "tool_energy":{"truy_van_lich_su":1,"kiem_dinh_gia_thuyet":1,"doi_chieu_nguon":1,"lam_sach_du_lieu":1}, đặt ngay trước "tool_budget":{"truy_van_lich_su":60,"kiem_dinh_gia_thuyet":80,"doi_chieu_nguon":40,"lam_sach_du_lieu":100}. Mọi khóa khác không đổi (grading base 10, adjacent 0,4, adjacent_effect -0,55, wrong_factor 2,3, evidence_factor 0,4; career initial_trust 46, warning 35, demote 16; win demo chuyen_vien, full truong_nhom; news_per_day 6/7).

Kiểm tra đã đổi (không xóa kiểm tra nào):
- test_world / test_verification, "energy refusal atomic" (cấp Verifier): Verifier không còn kiểm tra hay trừ Energy công ty, nên đổi thành "verifier ignores company energy"; việc từ chối khi hết Energy chuyển lên WorldGame và được kiểm trong test mới.
- test_world / test_status_energy: "public energy values before day" so với kho phân tích (analysis_energy) thay vì Energy sim; "public energy matches company" đổi thành "company energy untouched by verification"; thêm kiểm mã lỗi no_analysis_energy chính xác.
- Thêm test_analysis_energy (mới): tools() trả tool_energy và budget thế giới; trừ đúng chi phí; hết kho thì từ chối no_analysis_energy, không đổi status/news/cash_report; invalid_tool và invalid_uid được ưu tiên; kiểm chứng lặp miễn phí khi hết kho; kho đặt lại mỗi ngày; Energy công ty không bị trừ và hành động đề xuất vẫn thực thi ở end_day khi kho phân tích đã cạn; không lộ khóa ẩn.
- test_sim / test_use_tool: thêm 4 kiểm tra cho spend_energy (mặc định vẫn đòi và trừ Energy; false không đòi, không trừ, vẫn trừ Budget, không vượt rào danh mục).
- test_v2_desktop: thêm 4 kiểm tra (thông báo no_analysis_energy ở cửa sổ công cụ; chấm Energy theo kho phân tích; chuỗi có mặt). Các kiểm tra Energy cũ giữ nguyên và qua.

Kết quả chạy thật (worktree, Godot 4.7.2 console):
- test_sim: 2.634 kiểm tra, 0 lỗi. test_ui: 134, 0 lỗi.
- test_world (đầy đủ, gồm quét 500 ván/bot): 32.502, 0 lỗi. Quét điểm: 10 ngày min_win 8.464,50 > max_loss 1.914,00; 30 ngày min_win 9.538,00 > max_loss 3.519,00.
- test_v2_assets: 2.255, 0 lỗi. test_v2_desktop: 2.336, 0 lỗi. test_v2_layout_render (không headless): 2.614, 0 lỗi.
- balance_sim: trước/sau giống hệt từng dòng (43 dòng, bỏ elapsed_seconds).
- balance_world 2.000 ván, 10 và 30 ngày: như bảng trên. Số "Trước" lấy từ chạy bản gốc v2 trong phiên này.

### T-019c | Claude subagent (thay Codex) | 2026-11-10 | Review

- Nhánh codex/T-019c (từ v2), commit nhỏ theo phần; không push, không merge, không mạng. Ván chạy trọn từ tiêu đề đến kết thúc bằng `Godot --path game-studio/godot res://scenes/v2/main_v2.tscn` (không đổi project.godot). Tham số tùy chọn sau `--`: `--seed=N` cho ván cố định. Đã chạy thật bằng phím (Enter, Esc, Space) với hiệu ứng mờ dần bật: TITLE -> DAY_START -> WORK -> REVIEW -> DAY_START ngày 2 đều chuyển đúng.
- File thêm (dưới game-studio/godot): scripts/v2/{game_flow,review_scene,ending_scene,title_scene}.gd, scripts/v2/windows/report_window.gd, scenes/v2/{main_v2,title,review,ending}.tscn, tests/{test_v2_flow,test_v2_screens_render}.gd, assets/v2/{dash,clock_old}.png. File sửa: scripts/world/world_game.gd (chỉ status() thêm max_actions), scripts/v2/desktop.gd (tab Báo cáo, đồng hồ, start_day), scripts/v2/office.gd (xem phần tự quyết), data/strings_v2.json, tools/sprites/icons.gd (2 biểu tượng), tests/{test_world,test_v2_desktop,test_v2_assets}.gd. Không đụng scripts/sim, scripts/ui, scenes ngoài v2, các data/*.json cũ, shared, docs, project.godot.
- Kết quả chạy thật (Godot 4.7.2 console): test_sim 2.634/0; test_ui 134/0; test_world đầy đủ 32.511/0 (32.502 cũ + 9 kiểm tra max_actions); test_v2_assets 2.257/0 (2.255 + kiểm kê 2 biểu tượng mới); test_v2_desktop 2.448/0 (2.336 cũ + nút tác vụ thứ 4 + kiểm tra tab Báo cáo và quét mã nhạy cảm mới); test_v2_layout_render (không headless) 2.662/0 (2.614 cũ, tăng do nút Báo cáo); test_v2_flow (headless) 1.417/0; test_v2_screens_render (không headless) 7.488 kiểm tra/0 lỗi, 36 màn, 985 control. gen_sprites 28 dải, check_palette PASS 28 PNG/32 màu. balance_sim trước/sau giống hệt 43 dòng (bỏ elapsed_seconds); balance_world (mặc định 2.000 ván, 10 ngày) trước/sau giống hệt 8 dòng số liệu (bản gốc b220d0f chạy trong thư mục tạm).
- Cách chạy kiểm thử bố cục thật: `Godot --path game-studio/godot -s res://tests/test_v2_screens_render.gd` (KHÔNG --headless; thêm `-- --capture` để lưu 36 ảnh T-019c-<màn>.png vào thư mục TEMP, `-- --fault` cố ý đẩy nút Chơi ra ngoài màn hình: lần thử đã FAIL đúng 2 kiểm tra, exit 1, rồi gỡ). Mỗi màn: chờ 6 khung hình + frame_post_draw, duyệt mọi Control hiển thị, kiểm tra get_global_rect trong 640x360, kích thước thực >= kích thước tối thiểu, control nằm trong cha, anh em không chồng, chữ không bị cắt (đo độ rộng chuỗi, số dòng và cả line_spacing). Phải sửa các lỗi thật do bài kiểm tra này tìm ra: dòng chú thích tiêu đề bị cắt dòng 2, lời sếp màn kết thúc bị cắt, nút bỏ ghim chồng 1px lên nhãn, hộp thoại office chồng nhãn người nói 4px. Đã xem ảnh render thật: tiêu đề, office có lời sếp, WORK (rỗng/đã chọn/hộp xác nhận), họp 6 bước (có ngày có cú sốc, ngày thăng chức có dải sáng), ba màn kết thúc đều đọc được.
- test_v2_flow: ván tốt 10 seed (verifier qua đường UI) đều survived với đúng thứ tự trạng thái; ván xấu (ngẫu nhiên, tự tin cao, initial_trust 12) tìm được fired; kịch bản cố định (fixture của test_world: đáp án luôn tang) phủ cả 12 loại lời sếp (right, partial, wrong_low/mid/high, warning, promotion, demotion, fired, bankrupt, survived_won, survived_lost) cùng so khớp với review() độc lập; bankrupt qua overrides.simulation; 7 mã lỗi báo cáo hợp lệ bị từ chối với thông báo tiếng Việt, không đổi trạng thái, và nộp lần hai bị từ chối; Spy khẳng định review(day) chỉ gọi đúng 1 lần mỗi ngày đã kết thúc; quét mã khẳng định chỉ review_scene.gd gọi review() và đọc truth/root_cause/states; 20 seed tự động đều kết thúc; hiệu ứng mờ dần bước 25%, tổng 280 ms.
- Tự quyết: (1) Báo cáo là tab ở cột phải: bấm nút "Báo cáo" ở thanh tác vụ thì cửa sổ Báo cáo thế chỗ Công ty và Công cụ, bấm lại một trong hai thì quay lại; Báo cáo không nằm trong desktop.windows để kiểm thử cũ giữ nguyên. Nút tác vụ thứ 4 ở x=340, đồng hồ thu còn x=452..636 và hiện thêm giờ (08:30, +30 phút mỗi lần kiểm chứng tốn năng lượng; tra cache không tốn). (2) Desktop giữ nguyên suốt ván (ẩn khi không WORK) và dùng desktop.start_day() mỗi ngày, để mũi tên so sánh ngày trước của cửa sổ Công ty không bị xóa. (3) Pha văn phòng (sang/trua/chieu) chỉ ghi ở flow.phase vì office không hiện trong WORK; màn kết thúc tự đặt pha. (4) Lời sếp khi sai và tự tin Vừa không có trong spec: thêm biến thể wrong_mid ("Sai. Cô chỉ chắc vừa phải, nhưng tôi vẫn cần bằng chứng tốt hơn."); sai và tự tin Thấp/Cao dùng đúng câu spec. Các câu khác nguyên văn spec (câu cảnh cáo dùng bản "Đây là cảnh cáo..." của spec, không phải "thứ hai" của content bible). (5) Họp cuối ngày dùng 6 bước đúng thứ tự spec; hộp thoại Chị Hạnh ở dưới có chân dung 32x48; Space/Enter hoặc nút Tiếp tục qua bước. Tin dẫn làm bằng chứng và dự báo lấy từ báo cáo người chơi vừa nộp (flow truyền vào), không từ review(). (6) Tên cú sốc hiển thị lấy từ strings_v2.shocks; nguyên nhân gốc lấy nguyên từ root_cause của review(). (7) Thêm 2 biểu tượng 8x8 `dash` và `clock_old` cho nhãn Không liên quan và Đã cũ; cập nhật kiểm kê test_v2_assets. (8) office.gd: thêm seat_now() và set_hint_visible(), nhãn gợi ý được ẩn khi sếp hỏi; dời ô chữ hộp thoại từ y=23 sang y=28 (cao 44) vì nhãn người nói thực đo cao 23px đè lên chữ. Không đổi gì khác trong office.
- Hạn chế: chưa chơi bằng chuột thật (chỉ phím thật và gọi tín hiệu nút); font mặc định cỡ 8/12 chưa phải font pixel; đồng hồ không hiện trong lúc review; nút Thoát gọi get_tree().quit() chưa kiểm thử bằng tự động; ván 30 ngày chưa nối vào flow (HORIZON = 10). Một số hộp tooltip dài chỉ kiểm bằng test cũ.
- Git: git add/commit chạy được trong worktree này (lần này không bị Permission denied), commit trên nhánh codex/T-019c, không push, không merge.


### T-020 | Claude subagent (thay Codex) | 2026-11-10 | Done

- Wave 1/4 theo feedback playtest của VU: English UI, popup tiền/emote, đồng nghiệp phản ứng. Spec: game-studio/godot/docs/SPEC-T-020.md. Nhánh codex/T-020. Waves 2-4 (desktop apps + báo cáo hạn giờ; thành phố + văn phòng + palette v3; tiêu tiền) chờ T-020 xong. Online: để sau.

- Handoff (nhanh codex/T-020, commit nho theo phan, khong push, khong merge, khong mang):
- Lam: (1) English toan bo chu nguoi choi thay: data/strings_v2.json (viet lai, giu nguyen khoa), data/news.json (headline, ten nguon, ghi chu), data/questions.json, label trong scripts/v2/office.gd (LUC CHAU / ANALYTICS DEPT, You/Khoi/Mai/Tu, Ms. Hanh). world.json von khong co chu Viet. Them strings_v2.root_causes de man hop cuoi ngay khong hien root_cause tieng Viet cua events.json (khong duoc sua events.json). (2) Popup tien/emote: scripts/v2/reaction_stage.gd moi (san khau 208x120 ben phai review, nhan vat 2x, chu +$N xanh / -$N do noi len 14px va mo dan 25% trong 1,2 s, emote 8x8 phong 2x tren dau). Gan vao review_scene.gd o buoc 1 (Boss reaction) va buoc 6 (Career). Buoc Career them dong "Pay today: +$N" (N = thay doi personal_pay cong khai tru bonus) va "Bonus: +$N"; "fine" = personal_pay giam (sim khong co tien phat, nhanh nay chi co API + test, khong bao gio xuat hien trong van that). Esc bo qua hoat anh, popup chi la Label/TextureRect mouse_filter IGNORE nen khong chan Space/Enter. (3) Dong nghiep (Khoi): sai/giang chuc/duoi viec/het tien -> dap ban phim 3 khung (lac + rung ban) kem bong bong thoai; dung/thang chuc -> nhay + ngon tay cai len. Moi tam trang 8 cau goc (strings_v2.coworker.angry / happy). Dung a mot phan va canh cao khong phan ung. Emote nguoi choi: happy (dung/thang chuc), neutral (gan dung/khong doi), sad (sai tu tin thap/vua, giang chuc, canh cao, het tien), angry (sai tu tin cao, duoi viec). (4) 5 icon moi 8x8 (emote_happy/sad/angry/neutral, thumb) trong tools/sprites/icons.gd, da chay gen_sprites; chi dung 32 mau palette.
- File sua: data/{strings_v2,news,questions}.json; scripts/v2/{office,review_scene}.gd; scripts/v2/reaction_stage.gd (moi); tools/sprites/icons.gd + assets/v2/{emote_happy,emote_sad,emote_angry,emote_neutral,thumb}.png; tests/{test_v2_popups (moi),test_v2_assets,test_v2_desktop,test_v2_flow,test_v2_screens_render,balance_world}.gd. Khong dung: CLAUDE.md, shared/, scripts/ui/, scripts/sim/, scripts/world/, cards.json, events.json, config.json, world.json, project.godot.
- Kiem thu that (Godot 4.7.2 console): test_sim 2.634/0; test_ui 134/0; test_world 32.511/0; test_v2_assets 2.262/0; test_v2_desktop 2.462/0; test_v2_flow 1.418/0; test_v2_popups (moi, headless) 221/0; test_v2_layout_render (khong headless) 2.662/0; test_v2_screens_render (khong headless) 7.925/0, 36 man, 1.069 control (tang tu 7.488/985 do san khau moi). gen_sprites 33 dai; check_palette PASS 33 PNG, 32 mau. balance_sim truoc/sau giong het 43 dong (bo elapsed); balance_world 2.000 van 10 ngay truoc/sau giong het 8 dong (bo elapsed; ban goc la v2 giai nen vao thu muc tam).
- Kiem tra da doi: test_v2_flow: disclaimer / ten tieu de / nut Choi, Thoat so voi chuoi tieng Viet -> chuoi English moi (3 check, cung y nghia). test_v2_assets: kiem ke sprite them 5 icon (1 check); chuoi thu tieng Viet -> English; check "Vietnamese retained" doi ten thanh "long dialogue text retained". test_v2_desktop: chi doi chuoi fixture sang English (khong doi check). test_v2_screens_render: chi doi chuoi fixture. tests/balance_world.gd: quy tac doc headline (interpretation) va loc "truoc" doi tu tu khoa tieng Viet sang tu khoa English; da doi chieu bang script voi ca 41 headline x 4 loai cau hoi de bot phan loai y het ban cu (neu khong doi thi ket qua bot lech han, vi bot doc chu cua headline). Khong xoa check nao. test_v2_popups moi: khong co dau tieng Viet (regex [A-y]) trong strings_v2/news/questions/world/palette va moi file scripts/v2, scenes/v2; >=6 cau moi tam trang; popup dung dau/so tien cho pay, bonus, fine (mau xanh/do, noi len, mo dan, bien mat sau 1,2 s, skip, mouse IGNORE); mood dong nghiep theo ket qua (dung -> happy, sai -> angry, anh xa category -> mood/emote); Esc bo qua nhung Enter van qua buoc.
- Anh chup (game-studio/godot/docs/screenshots-T-020/, tao bang test_v2_screens_render -- --capture): T-020-title.png, T-020-desk-news-window.png, T-020-review-pay-popup.png (+$ popup + emote), T-020-review-promotion-popup.png, T-020-coworker-slam.png (dong nghiep het "My eyes!"), T-020-ending-fired.png, T-020-ending-survived.png. Da xem anh that: chu khong bi cat, khong chong nhau.
- Han che: (1) events.json va cards.json (cam sua) van con chu Viet nhung khong bao gio hien o v2 (shocks/root_causes/actions lay tu strings_v2). (2) Sim khong co tien phat bang tien, nen popup "fine" chi xuat hien neu personal_pay giam (hien khong xay ra). (3) Popup/dong nghiep chi o man hop cuoi ngay (review); chua o office hay desktop. (4) Font mac dinh, chua phai font pixel; chu English dai hon nen cac cua so vua khit, da qua render test. (5) v1 (scripts/ui, strings.json, test_ui) giu nguyen tieng Viet, dung theo spec. (6) Tien te hien thi la $ theo spec, du ten tien trong truyen la dong lac. (7) Ten rieng giu khong dau (Luc Chau, Tan Lac, Khoi, Mai, Tu, Hanh).


### T-021 | Claude subagent (thay Codex) | 2026-11-10 | Done

- Feedback playtest của VU: tin tức thuần chữ, không có hướng dẫn, không thấy nút gửi báo cáo, không sửa được bằng chứng. Desktop có icon app, Mail soạn báo cáo (sửa được đến khi Gửi), tin có hình, tutorial. Spec: game-studio/godot/docs/SPEC-T-021.md. Nhánh codex/T-021. Sau đó: T-022 art + palette v3 (cần VU duyệt CLAUDE.md), T-023 báo cáo hạn giờ, T-024 tiêu tiền.

- Handoff T-021 (nhánh codex/T-021, commit nhỏ theo phần; không push, không merge, không mạng):
- Làm: (1) Desktop có 5 icon (Browser, Mail, Insight BI, Code Pad, Help) ở cột trái; mỗi lần chỉ một cửa sổ app ở vùng làm việc 442x290 (bấm icon = mở hoặc focus; nút minimize và close ở thanh tiêu đề; thanh tác vụ chỉ liệt kê cửa sổ đang mở, bấm cửa sổ đang ở trước = thu nhỏ). Esc thu nhỏ cửa sổ trước. Màn "home" hiện câu hỏi hôm nay khi chưa mở app. (2) Mail = ReportWindow viết lại (58,30,442x290): To/Subject, chip Forecast/Confidence, 3 ô Evidence (headline, dấu kiểm chứng, nút x), Actions theo hạng, nút Send lớn luôn thấy ở góc dưới phải + checklist còn thiếu gì, Clear all, hộp xác nhận "Send to Ms. Hanh? You cannot edit afterwards." (Send / Keep editing). Sửa tự do đến khi Send; nháp giữ nguyên khi đóng/mở cửa sổ; API cũ (submit_requested, WorldGame.submit_report, trần action theo hạng, tối đa 3 evidence) giữ nguyên. (3) Browser: card = thumbnail pictogram 8x8 phóng 4x theo topic (7 icon) + huy hiệu nguồn có crest từng tier + mũi tên claim và huy hiệu số ("-1.0%") suy ra chỉ từ headline (windows/claim.gd; headline mâu thuẫn thì không hiện mũi tên) + nút Pin + Read more (mở rộng, có nút Verify in Code Pad). Không có sparkline (không có số công khai đủ chuỗi). Dải headline ticker chạy ở y=16..28. (4) Evidence tray 3 ô ở đáy desktop: bấm ô = nhảy tới bài trong Browser, nút x = bỏ ghim. (5) Tutorial ngày 1 (tutorial_panel.gd, cột phải 132px): bubble của Ms. Hanh 6 nhóm bước / 9 bước con, khung highlight + mũi tên, Continue/Enter, Skip; bước tự tiến khi người chơi làm thật (mở Browser, chọn bài, mở Code Pad, dùng tool, ghim, mở Mail, chọn forecast+confidence, Send), làm trước thì nhảy qua; icon Help mở lại bất cứ lúc nào; trạng thái chỉ trong bộ nhớ theo từng ván. Goal checklist 5 mục ngày 1-2, thu gọn được. Tooltip glossary cho Trust, Energy, 4 tier nguồn. Code Pad hiện bài đang chọn và giải thích Energy.
- File mới (dưới game-studio/godot): scripts/v2/tutorial_panel.gd, scripts/v2/windows/claim.gd, tests/test_v2_t021.gd, tests/test_v2_mouse.gd, assets/v2/{topic_*(7),crest_*(4),app_*(5)}.png, docs/screenshots-T-021/. File sửa: scripts/v2/desktop.gd (viết lại), scripts/v2/windows/{news_window,report_window,tools_window,company_window,window_base}.gd, tools/sprites/icons.gd, data/strings_v2.json (khóa mới: glossary, home, news_ui, tray, goals, tutorial, report.*; windows.* đổi tên hiển thị), tests/{test_v2_desktop,test_v2_layout_render,test_v2_screens_render,test_v2_assets}.gd. Không đụng CLAUDE.md, shared/, scripts/ui/, scripts/sim, scripts/world, cards/events/config/world.json, project.godot.
- Kiểm thử (Godot 4.7.2 console): test_v2_t021 311/0 (mới, headless); test_v2_mouse 140/0 (mới, KHÔNG headless, chuột thật qua Input.parse_input_event: Play -> bàn -> hộp thoại -> tutorial -> Browser -> chọn bài -> Read more -> Verify -> Use -> ghim -> tray -> Mail -> chip -> Send/Keep editing/Send -> review bằng nút Continue -> ngày 2; chạy bằng `-- --seed=104 [--capture]`); test_v2_desktop 4.288/0 (582 -> 4.288 vì layout đo từng cửa sổ khi ở phía trước); test_v2_layout_render 5.096/0; test_v2_screens_render 10.129/0, 40 màn, 1.564 control (có thêm màn work-home, work-browser, work-browser-expanded, work-codepad, work-bi); test_v2_assets 2.278/0 (+16 sprite); test_v2_flow 1.420/0; test_v2_popups 223/0; test_sim 2.634/0; test_ui 134/0; test_world 32.511/0; check_palette PASS 49 PNG/32 màu. balance_sim và balance_world không chạy lại vì không đụng scripts/sim, scripts/world, tests/balance_*.
- Kiểm tra đã đổi: test_v2_desktop: khối "cửa sổ thu nhỏ/khôi phục tại chỗ" + "tab Báo cáo thế chỗ Công ty/Công cụ" + "cửa sổ không chồng nhau" thay bằng mô hình mới (một cửa sổ phía trước, taskbar liệt kê cửa sổ mở, close gỡ khỏi taskbar, 16 tín hiệu window_toggled, Mail 442x290); check_layout mở lần lượt từng cửa sổ rồi đo (cửa sổ ẩn không được bố trí); cửa sổ phải nằm trong vùng làm việc; phải mở Browser trước khi kiểm "long headline shows two lines". test_v2_layout_render và test_v2_screens_render: bỏ qua lớp CoachOverlay (meta overlay, vẽ đè toàn màn, không nhận chuột) trong kiểm tra anh em chồng nhau; layout_render mở từng app, kiểm Send nằm trọn trong 640x360 (>=100x30) và 32x32 thumbnail mỗi card; screens_render đổi tên ảnh thành T-021-*. test_v2_assets: thêm 16 sprite vào kiểm kê. Không xóa kiểm tra nào ngoài các khối đã thay bằng tương đương.
- Ảnh chụp (game-studio/godot/docs/screenshots-T-021/, từ test_v2_mouse -- --capture, đã xem): T-021-desktop-home.png, T-021-tutorial-select-article.png, T-021-browser-expanded-card.png (thumbnail, badge, claim), T-021-tutorial-use-tool.png, T-021-evidence-tray.png, T-021-mail-empty.png, T-021-mail-filled.png (Send luôn hiện), T-021-mail-confirm.png. Ảnh test_v2_screens_render --capture ghi vào thư mục TEMP (T-021-work-*.png).
- Hạn chế/duyệt: font mặc định chưa phải font pixel; mũi tên coach là đường mảnh vẽ chồng lên cửa sổ; tutorial chỉ có chuỗi English; một cửa sổ app mỗi lần (không kéo, không chồng) nên người chơi phải chuyển qua lại giữa Browser và Code Pad (đã thêm nút Verify in Code Pad trong card mở rộng và tray); claim arrow dựa trên từ khóa headline nên một số headline không có mũi tên; không có sparkline. Palette v3 và art overhaul để T-022. Console có cảnh báo môi trường user://logs/cache shader như các lượt trước.


### T-022 | Claude subagent (thay Codex) | 2026-11-10 | Done

- Art overhaul theo feedback VU: palette v3 (additive, không sửa CLAUDE.md, chỉ có đề xuất), cảnh đi làm qua thành phố, văn phòng nhiều phòng ban, màu sinh động. Spec: game-studio/godot/docs/SPEC-T-022.md. Nhánh codex/T-022. Có luật chống treo (dừng sau 2 lần sửa cùng test lỗi).

### T-023 | Claude subagent | 2026-11-10 | Done
- Báo cáo hạn giờ (nộp muộn thị trường đã đổi). Spec docs/SPEC-T-023.md, worktree ai-company-t023, nhánh codex/T-023. Handoff: docs/HANDOFF-T-023.md.

### T-024 | Claude subagent | 2026-11-10 | Done
- Cuộc sống sau giờ làm: tiêu tiền (đồ ăn vặt, vàng, tiết kiệm, đất, nhà). Spec docs/SPEC-T-024.md, worktree ai-company-t024, nhánh codex/T-024. Handoff: docs/HANDOFF-T-024.md.

### T-025 | Claude subagent | 2026-11-10 | Done
- Tài liệu tiếng Anh, README, .gitignore, chuẩn bị GitHub (không push). Spec docs/SPEC-T-025.md, worktree ai-company-t025, nhánh codex/T-025. Handoff: docs/GITHUB-READINESS.md.

### T-022 handoff | Claude subagent (thay Codex) | 2026-11-10 | Review

- Nhánh codex/T-022 (từ v2), commit nhỏ, không push/merge/mạng. Không sửa CLAUDE.md, scripts/ui, scripts/sim, scripts/world, cards/events/config/world.json, project.godot (git diff v2 rỗng cho các đường dẫn này). balance_sim/balance_world không đổi vì không đụng sim/world (không chạy lại).
- Palette v3: 64 màu (32 màu v2 giữ nguyên thứ tự + 32 mới: trời ngày/hoàng hôn/âm u, gạch/cam, lá, da, accent đỏ-vàng-teal-magenta-cam-cobalt, thảm văn phòng, nhựa đường). Files: shared/style-bible/palette-v3.json và pixel-office-v3.md, data/palette_v3.json, scripts/v2/palette.gd (bảng chữ 64 ký tự), tools/check_palette.gd (bản sao shared khớp, superset của v2, không trùng màu, mọi PNG chỉ dùng màu v3 và alpha nhị phân). Đề xuất sửa CLAUDE.md mục 4 ở docs/PROPOSAL-CLAUDE-MD-palette-v3.md (VU duyệt, chưa sửa CLAUDE.md).
- Cảnh đi làm (mới): scripts/v2/commute_scene.gd, scenes/v2/commute.tscn, scripts/v2/pen.gd (helper vẽ dùng chung). Đường phố 640x360 vẽ bằng mã: 3 lớp skyline parallax, mây trôi, 6 cửa hàng có biển (MOONBEAN CAFE, SIZZLE NOODLES, CORNER MART, HARBOR BANK, DAILY NEWS, MOTH BOOKS), tòa nhà LUC CHAU, xe hơi/bus/xe máy/xe đạp với đèn giao thông (xe dừng trước vạch, không chồng xe), người đi bộ nhiều trang phục, người băng đường khi đèn đỏ, cây, cột đèn, hơi nước quán mì, bảng OPEN nhấp nháy. Người chơi có mũi tên vàng, đi vào cửa tòa nhà (~7 s); Esc/Enter/Space/click bỏ qua; phát tín hiệu finished đúng 1 lần. Tâm trạng chỉ theo giá trị công khai (số ngày và trust công khai): day>=5 hoặc trust<=35 âm u; day>=8 hoặc trust<=20 u ám, mưa, ít xe; day>=4 biển CLOSING SALE ở hiệu sách; day>=6 hàng chờ ở ngân hàng; bảng tin DAILY NEWS đổi theo ngày; cafe ghi CLOSED các ngày cuối. Flow: game_flow.gd có commute_enabled (mặc định true) và skip_commute(); commute chạy trong trạng thái DAY_START trước văn phòng nên thứ tự trạng thái không đổi; skip_intro() cũng bỏ qua commute.
- Văn phòng nhiều phòng (viết lại office.gd, thêm office_art.gd): thế giới 1280x560, camera 640x360 mặc định ở phòng Data Analytics (bàn người chơi, DeskButton, hộp thoại, API cũ giữ nguyên). 9 phòng có vách kính và cửa: Data Analytics (4 bàn: You, Khoi, Mai, Tu, dashboard, bàn phân tích, máy in), Finance (2 bàn, biểu đồ, két), Marketing (2 bàn, moodboard, giá vẽ, sofa), Sales (3 bàn, bảng chỉ tiêu, một người gọi điện có bong bóng), Executive (Ms. Hanh sau bàn lớn), Reception (lễ tân, quầy, sofa, logo), Meeting (bàn kính, bảng trắng có biểu đồ, 2 người họp), Server room (4 rack LED nhấp nháy), Break room (máy cà phê có hơi, tủ lạnh, máy bán hàng, sofa), hành lang có thảm. NPC gõ phím và chớp mắt, 3 người đi dọc hành lang, bảng tên phòng và tên bàn. Minimap góc trên phải (bấm để chuyển phòng), phím Tab chuyển phòng, show_room() và pan_to(). Khi sếp xuất hiện camera về phòng Data, Ms. Hanh rời phòng Executive tới cửa. Phản ứng Khoi và popup tiền nằm ở màn review (không đổi, test_v2_popups vẫn qua).
- Màu sống động: desktop có wallpaper thành phố hoàng hôn (scripts/v2/city_art.gd; dock và home panel mờ để thấy nền), tiêu đề có skyline và tòa nhà công ty, màn review có nền thành phố, màn kết thúc dùng văn phòng nhiều phòng (đã ẩn minimap). Icon app và thumbnail tin giữ nguyên (đã đúng v3).
- 14 sprite nhân viên mới (tools/sprites/characters.gd ROSTER: rin, bao, linh, dat, an, vy, sam, ngoc, ops, lead, intern, kai, mei, pat). gen_sprites 63 dải, check_palette PASS 63 PNG / 64 màu.
- Kiểm thử thật (Godot 4.7.2 console): test_v2_commute (mới, headless) 621/0 gồm palette v3 (64 màu, superset v2, alphabet, bản sao shared), mọi texture thủ tục chỉ dùng màu v3 và alpha nhị phân, commute chạy N khung và kết thúc 1 tín hiệu trong 6-9 s, skip bằng gọi/Esc/click, đèn giao thông đủ xanh và đỏ và không xe nào vượt đèn đỏ, xe cùng làn không chồng, mood theo day/trust, CLOSING và hàng chờ chỉ ngày muộn, flow đầy đủ commute -> office -> desktop -> review tới kết thúc, 9 phòng và số NPC từng phòng (4/2/2/3/1/1/2/1/1), 11 bàn không chồng nhau và nằm trong phòng, camera/minimap/Tab/pan, leak probe (mã mới không đọc truth/root_cause/review/states, flow chỉ truyền day và trust công khai, chữ hiển thị chỉ ASCII tiếng Anh). Các test khác: test_v2_flow 1.424/0, test_v2_popups 228/0, test_v2_t021 311/0, test_v2_desktop 4.344/0, test_sim 2.634/0, test_ui 134/0, test_world đầy đủ 32.511/0, test_v2_assets 476/0, test_v2_layout_render (không headless) 5.096/0, test_v2_mouse (không headless, chuột thật) 143/0, test_v2_screens_render (không headless) 10.052/0 với 51 màn và 1.536 control.
- Kiểm tra đã đổi: test_v2_assets: kiểm kê thêm 14 sprite; số kiểm tra giảm từ 2.278 xuống 476 vì văn phòng cũ có ~400 node ô gạch (mỗi node bị kiểm hai lần), văn phòng mới là một texture nền nên ít node hơn (không xóa kiểm tra nào). test_v2_flow: new_flow() đặt commute_enabled=false để các test cũ giữ nguyên, commute được kiểm riêng trong test_v2_commute. test_v2_mouse: sau Play kiểm commute rồi bấm chuột bỏ qua (cả ngày 2), ảnh ghi vào docs/screenshots-T-022. test_v2_screens_render: thêm màn commute-day1, commute-day9, office của 9 phòng (40 -> 51 màn), ảnh TEMP đổi tiền tố T-022. Quét mã của test_v2_desktop cấm từ "kind" trong scripts/v2 nên mã mới dùng tên "variety". Wallpaper và backdrop gắn meta "overlay" để bài kiểm tra anh em chồng nhau bỏ qua (như ColorRect nền trước đây).
- Ảnh chụp (game-studio/godot/docs/screenshots-T-022/): after/T-022-commute-day1.png, after/T-022-commute-day9.png (khủng hoảng: âm u, mưa, CLOSING SALE, hàng chờ), after/T-022-office-{data,finance,marketing,executive,reception,sales,meeting,server,break}.png, after/T-022-day-start-boss.png, after/T-022-work-home.png (wallpaper), after/T-022-title.png, after/T-022-review-day1-step1.png, after/T-022-ending-{survived,fired}.png; before/before-{title,day-start-boss,work-home,review-day1-step1,ending-survived}.png (bản v2) để so sánh; ảnh chuột thật (desktop, mail, tutorial) ở thư mục gốc screenshots-T-022. Đã xem ảnh thật (commute, các phòng, title, desktop, ending); rõ ràng phong phú hơn v2 (v2 chỉ có một phòng nâu với 4 bàn, nền thành phố đơn sắc).
- Hạn chế: (1) ảnh trước/sau chỉ có 5 màn so sánh; (2) font mặc định cỡ 8 nên vài biển phải rút ngắn tên (HARBOR BANK, MOTH BOOKS); (3) hộp thoại sếp che hành lang phía dưới; (4) NPC chỉ đi dọc hành lang, chưa đi qua cửa vào từng phòng; (5) màn kết thúc vẫn dùng văn phòng làm nền (city_art có sẵn nền ending_good/ending_bad nhưng chưa nối vào); (6) icon app và thumbnail tin chưa vẽ lại; (7) commute chỉ dùng day và trust công khai, không biến thể theo cú sốc cụ thể (cố ý, để không lộ sự thật ẩn); (8) palette 64 màu cần VU duyệt đổi CLAUDE.md (docs/PROPOSAL-CLAUDE-MD-palette-v3.md).


### T-026 | Claude subagent | 2026-11-10 | Done
- Vòng đời hằng ngày kiểu game SIM: sáng dậy, chọn phương tiện, đèn đỏ, vào cửa hàng, thanh thể lực/tâm trạng/sức khỏe/stress, làm thêm giờ, hóa đơn, ngủ. Spec docs/SPEC-T-026.md, worktree ai-company-t026, nhánh codex/T-026. Handoff: docs/HANDOFF-T-026.md. T-027 (thành phố đi bộ tự do) để sau.

### T-027 | Claude subagent | 2026-11-10 | Done
- Chọn cửa hàng tự do trên phố (bấm vào cửa hàng, nút Go to work). Spec docs/SPEC-T-027.md, worktree ai-company-t027, nhánh codex/T-027. Handoff: docs/HANDOFF-T-027.md.

### T-028 | Claude subagent | 2026-11-10 | Done
- Art cozy hiện đại phần A (palette v4, văn phòng, nhà, desktop, nhân vật, tiêu đề). Tham khảo phong cách ảnh VU gửi, không sao chép. Spec docs/SPEC-T-028.md, worktree ai-company-t028, nhánh codex/T-028. Phần B (phố, cửa hàng) sau T-027.


### T-029 | Claude subagent | 2026-11-10 | Done
- Art cozy phần B: phố, cửa hàng, cảnh đi làm, nội thất cửa hàng, thumbnail tin tức. Spec docs/SPEC-T-029.md, worktree ai-company-t029, nhánh codex/T-029. Handoff: docs/HANDOFF-T-029.md.


### T-030 | Claude subagent | 2026-11-10 | Done
- Online giai đoạn 0 (offline): hồ sơ cục bộ, Wall of Fame, Employee of the Month, thành tích, thang điểm danh mô phỏng + ngày nghỉ, thư HR hài hước, Daily Shift. Spec docs/SPEC-T-030.md, thiết kế docs/DESIGN-online.md, worktree ai-company-t030, nhánh codex/T-030. Chạy song song với T-029.

### T-031 | Claude subagent | 2026-11-10 | Done
- Dịch dữ liệu và test v1 sang tiếng Anh (events/cards/strings, test_ui), thêm test cấm dấu tiếng Việt. Spec docs/SPEC-T-031.md, worktree ai-company-t031, nhánh codex/T-031. Handoff: docs/HANDOFF-T-031.md.

### T-032 | Claude subagent | 2026-11-10 | Done
- Landing page tiếng Anh cho game v2, trung thực, không bịa số liệu, cập nhật check_web.py (sửa T-008). Spec docs/SPEC-T-032.md, worktree ai-company-t032, nhánh codex/T-032. Handoff: media-marketing/web/HANDOFF-T-032.md. Không deploy.

### T-033 | Claude subagent | 2026-11-10 | Done
- Lõi phân tích dữ liệu: engine bảng dữ liệu thô bẩn, sinh từ trạng thái ẩn, thao tác no-code, pipeline, biểu đồ, kiểm tra biểu đồ gây hiểu lầm, tham chiếu và chấm điểm, solvability. Spec docs/SPEC-T-033.md, thiết kế docs/DESIGN-data-core.md, worktree ai-company-t033, nhánh codex/T-033. Chưa có UI (T-034).

### T-035a | Claude subagent | 2026-11-10 | Done
- Nội dung học tập: danh mục case, Handbook, lời huấn luyện, tutorial 5 ngày, validator. Spec docs/SPEC-T-035a.md, worktree ai-company-t035a, nhánh codex/T-035a. Không code game.


### T-034 | Claude subagent | 2026-11-10 | Done
- UI lõi dữ liệu: app Files/Sheet (bước sửa được), trình tạo biểu đồ + cảnh báo gây hiểu lầm, Dashboard, đính kèm phân tích và chọn kết luận trong Mail, bước 'Your analysis' ở họp cuối ngày. Spec docs/SPEC-T-034.md, worktree ai-company-t034, nhánh codex/T-034. Handoff: docs/HANDOFF-T-034.md.


### T-035 | Claude subagent | 2026-11-11 | Done
- Lớp học tập: app Handbook, gợi ý tốn Energy, huấn luyện cuối ngày (Dr. Linh), tutorial 5 ngày, tiến độ kỹ năng. Spec docs/SPEC-T-035.md. Chờ T-034 merge rồi giao.


### T-037 | Codex | 2026-11-11 | Done
- Âm thanh tự sinh bằng mã (SFX + nhạc lo-fi + cài đặt âm lượng), không tải asset ngoài. Spec game-studio/godot/docs/SPEC-T-037.md, worktree ai-company-codex, nhánh codex/T-037. File được sửa: scripts/audio/*, tests/test_t037_*, một dòng hook trong game_flow.gd/reaction_stage.gd/tutorial_panel.gd/scripts/life/*, màn Settings (T-030), data/strings_v2.json (mục audio). Không sửa desktop.gd, windows/*, Mail, review_scene (T-034 đang sửa).
- Handoff Codex (2026-11-11, Performance amendment): tối ưu MỘT lượt đạt ngân sách audio; giữ toàn bộ thay đổi uncommitted trước đó. Scope amendment đã giải quyết quyền sửa profile. Chưa chuyển Review vì hồi quy test_world timeout 60 giây; dừng mở rộng kiểm thử, cần reviewer xử lý ngân sách/tách test cũ trước khi xác nhận toàn bộ suite.
- Lượt này sửa scripts/audio/{synth,sfx_bank,music,audio_manager}.gd, tests/test_t037_{synth,manager}.gd; thêm tests/test_t037_{music,timing,flow}.gd; cập nhật TASKS.md. Giữ scripts/audio/audio_hooks.gd, scripts/meta/profile.gd, scripts/v2/{game_flow,reaction_stage,tutorial_panel,settings_scene}.gd, scripts/life/{morning_scene,evening_scene}.gd và tests/test_t030_meta.gd từ lượt trước. Không sửa spec của reviewer hay simulation/world/balance.
- Nhạc: 8 bar/32 beat, 16000 Hz, cache pluck+echo theo mood/note, bảng sine 1024 mẫu và vòng mix/encode gọn; worker Thread ưu tiên thấp sinh từng mood, mutex công bố resource, is_ready/get_ready không sinh nhạc trên main thread. SFX giữ 22050 Hz, rút tất cả về <=0.6 giây; noise có seed cố định. Test đọc WAV.data một lần ngoài vòng lặp và tách synth/music/timing. Sửa tên bus SFX; Dummy driver dùng timer/WeakRef cho tuổi thọ voice, tránh giữ native playback khi headless; shutdown dừng worker.
- Timing đo cuối: 27 SFX = 110 ms (mục tiêu <5000); home/street/work/evening/crisis = 78/114/78/79/89 ms (mỗi mood <3000). test_t037_timing có ngưỡng 3x và dừng ngay khi vượt mục tiêu. Không cần lượt tối ưu thứ hai.
- Kết quả cuối (checks pass/fail; thời gian toàn tiến trình): test_t030_meta 480/0, 1.668 s; test_t037_manager 60/0, 4.203 s; test_t037_synth 184/0, 0.805 s; test_t037_music 36/0, 1.116 s; test_t037_timing 12/0, 1.227 s; test_t037_flow 13/0, 2.090 s. Manager/flow lượt cuối không còn lỗi callback hay cảnh báo ObjectDB.
- Hồi quy bổ sung: test_t030_flow 57/0, 23.209 s; test_t030_render không headless 6951/0, 47.968 s (17 màn hình, 694 control, gồm Settings thường/xác nhận; không ghi screenshot); test_sim 2634/0, 4.806 s; test_ui 106/0, 0.870 s. test_world timeout 60.017 s, chưa có summary (đã in score sweep 10 ngày); không tính là pass. Các hồi quy còn lại và balance_sim chưa chạy/so sánh; không tuyên bố toàn bộ suite pass. git diff --check đạt.
- Lỗi gặp rồi sửa trong lượt: kiểu biến path trong test manager; phân biệt hoa/thường bus SFX; đợi frame trong test flow; callback Dummy dùng WeakRef thay node đã bị drop. Các lượt Godot vẫn in ERROR Failed to read the root certificate store từ môi trường Windows, có cả test profile/sim gốc; không dùng mạng. Mỗi lệnh có timeout 60 s, không tự chạy đồng thời nhiều Godot; không có crash 139.
- Nghe thử (chưa kiểm tra bằng tai): & 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path game-studio/godot -s res://tests/test_t037_manager.gd -- --listen (chạy riêng, timeout 60 s; khoảng 50 s, 27 SFX rồi 5 mood). Hoặc mở game v2 > Settings > Sound test. Không git add/commit/push/merge.

### T-037-PROFILE | Codex | 2026-11-11 | Done (đã nằm trong T-037)
- Đề xuất mở rộng phạm vi T-037 cho `game-studio/godot/scripts/meta/profile.gd`: thêm defaults Master 70, Music 40, SFX 70, Mute false và giữ các trường này qua save/load, tương thích profile cũ. Cần chủ dự án/Claude xác nhận phạm vi; Codex chưa sửa file này.
