# Bảng công việc (Claude Code và Codex)

Quy tắc: xem docs/collaboration.md. Mỗi việc có đúng một owner. Nhận việc xong mới được sửa file.

Trạng thái: Backlog -> In progress -> Review -> Done. Bị chặn thì chuyển sang mục Blocked.

## Backlog

| ID | Việc | Owner | Nhánh | File được sửa | Tiêu chí hoàn thành |
|---|---|---|---|---|---|
| T-001 (ví dụ) | Viết spec tính năng X | Claude | claude/T-001 | docs/spec-x.md | Spec có mô tả, đầu vào, đầu ra, ví dụ |
| T-002 (ví dụ) | Cài đặt tính năng X theo spec T-001 | Codex | codex/T-002 | src/x.py, tests/test_x.py | Kiểm thử qua, đúng spec |
| T-005b | Giao diện: dashboard đầy đủ (T-005a đã xong, sẵn sàng giao) | Codex | codex/T-005b | game-studio/godot/scenes/game.tscn, scripts/ui/*, data/strings.json, tests/test_ui.gd | Xem game-studio/godot/docs/SPEC-T-005-split.md |
| T-005c | Giao diện: màn kết thúc, hoàn thiện (chỉ giao sau khi T-005b xong) | Codex | codex/T-005c | game-studio/godot/scenes/end.tscn, scenes/game.tscn, scripts/ui/*, data/strings.json, assets/CREDITS.md, tests/test_ui.gd | Xem game-studio/godot/docs/SPEC-T-005-split.md |

## In progress

(chưa có)

## Review

(chưa có)

## Done

| ID | Việc | Owner | Ngày |
|---|---|---|---|
| T-003 | Viết GDD Data Corp (game-studio/godot/docs/GDD.md), VU đã duyệt | Claude | 2026-11-09 |
| T-004 | Lõi mô phỏng Data Corp + balance_sim headless (Codex). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-09 |
| T-005a | Giao diện: khung và vòng tuần (Codex). Claude đã review, VU duyệt merge vào master | Codex | 2026-11-09 |

## Blocked

(chưa có)

## Ghi chú bàn giao

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
