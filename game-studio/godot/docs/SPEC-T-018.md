# Spec T-018: Tầng thế giới (tin tức, kiểm chứng, báo cáo, sự nghiệp)

Owner: Codex. Người review: Claude. Nhánh nền: `v2`. Nguồn: `docs/GDD-v2-concept.md`, `docs/CONTENT-BIBLE-v2.md`, `data/news.json`, lõi mô phỏng công ty `scripts/sim/` (đã có, 2.608 kiểm tra).

## Mục tiêu

Làm tầng logic (không giao diện) cho game v2: một kịch bản thế giới ẩn theo seed, bộ phát sinh tin tức (đúng, sai, cũ, nhiễu), công cụ kiểm chứng, báo cáo cho sếp có chấm điểm, và sự nghiệp (Tin tưởng, thăng chức, giáng chức, đuổi việc), gắn vào mô phỏng công ty hiện có. Kèm mô phỏng cân bằng chạy không giao diện.

Một **ngày** trong game v2 = một bước mô phỏng của công ty (`begin_week` rồi `finish_week`). Giao diện sẽ gọi là "ngày"; mã nội bộ giữ nguyên tên cũ của lõi.

## Nguyên tắc bất biến

1. **Không lộ sự thật ẩn.** API công khai của tầng thế giới không bao giờ trả về nhãn `truth`, `kind`, biến trạng thái ẩn, lịch cú sốc chưa xảy ra hay đáp án câu hỏi, cho tới khi gọi hàm xem lại cuối ngày (`review()`), và chỉ cho ngày đã qua. Có kiểm thử tự động rà từng khóa của mọi Dictionary trả về.
2. **Tái lập theo seed:** cùng seed và cùng chuỗi hành động cho kết quả y hệt.
3. **Không đổi hành vi lõi mô phỏng v1:** `test_sim.gd` (2.608) và `test_ui.gd` (134) phải qua, `balance_sim.gd` in kết quả giống hệt trước.
4. Tên, số liệu, tổ chức đều hư cấu (xem CONTENT-BIBLE mục 11).

## Cấu trúc file

```
scripts/world/world_scenario.gd   # kịch bản thế giới ẩn theo seed
scripts/world/news_engine.gd      # phát sinh tin theo luật hợp lệ
scripts/world/verifier.gd         # công cụ kiểm chứng
scripts/world/report.gd           # báo cáo và chấm điểm
scripts/world/career.gd           # Tin tưởng, chức vụ, thưởng phạt
scripts/world/world_game.gd       # lớp điều phối công khai
data/world.json                   # hệ số, bảng chức, tham số Tin tưởng, tỷ lệ tin
data/questions.json               # câu hỏi trong ngày và luật đáp án
tests/test_world.gd               # kiểm thử đơn vị và hợp đồng dữ liệu
tests/balance_world.gd            # mô phỏng cân bằng bằng bot
```

Tất cả class kế thừa `RefCounted`, không dùng Node. Mọi hệ số nằm trong `data/*.json`, không viết cứng.

## 1. Kịch bản thế giới (`world_scenario.gd`)

Với `seed` và số ngày `horizon` (demo 10, full 30), sinh một lần lúc khởi tạo:

- **Sáu biến trạng thái ẩn** theo ngày, mỗi biến một hướng trong `tang | giam | ngang` kèm độ lớn: `lai_suat`, `ty_gia`, `nguyen_lieu`, `suc_mua`, `chung_khoan`, `tin_dung`. Dùng chuỗi Markov đơn giản có quán tính (xác suất giữ hướng cũ cao hơn đổi hướng), tham số trong `world.json`. Ngữ nghĩa hướng xem trường `schema_note` trong `data/news.json` (ví dụ `ty_gia` tăng là bất lợi cho công ty nhập khẩu).
- **Lịch cú sốc:** 8 sự kiện đã có trong `data/events.json` (`app_bug`, `competitor_discount`, `logging_error`, `checkout_outage`, `server_outage`, `trend_shift`, `bad_traffic`, `price_fatigue`) xếp vào các ngày. Demo: tối đa 4 cú sốc, không hai cú trong cùng một ngày; full: tối đa 12. Một số cú sốc có "tiền thân vĩ mô" (ví dụ `competitor_discount` thường theo sau `ty_gia` tăng, `price_fatigue` theo sau `nguyen_lieu` tăng) để người chơi có thể suy ra nguyên nhân từ tin; tham số trong `world.json`.
- **Đáp án câu hỏi trong ngày** (mục 5) được tính sẵn từ kịch bản.

Cú sốc được áp dụng vào công ty bằng `Simulation.apply_event()` đúng ngày; **không** dùng cơ chế sự kiện ngẫu nhiên của lõi (gọi `begin_week(false)`).

**Tác động vĩ mô lên công ty:** mỗi ngày, biến trạng thái ẩn thêm các hiệu chỉnh ngắn hạn qua `Simulation.apply_effect()` (modifier 1 ngày), theo bảng hệ số trong `world.json`:

| Biến | Tác động khi `tang` | Tác động khi `giam` |
|---|---|---|
| `lai_suat` | `fixed_cost` tăng | `fixed_cost` giảm nhẹ |
| `ty_gia` | `cac` tăng | `cac` giảm nhẹ |
| `nguyen_lieu` | `fixed_cost` tăng (giá vốn) | `fixed_cost` giảm nhẹ |
| `suc_mua` | `conversion` và `retention` tăng | `conversion` và `retention` giảm |
| `tin_dung` | không tác động trực tiếp (chỉ ảnh hưởng chi phí vay qua `lai_suat`) | `fixed_cost` tăng nhẹ |
| `chung_khoan` | không tác động (chỉ là chỉ báo tâm lý) | không tác động |

Độ lớn từng hệ số do bạn chỉnh bằng mô phỏng (xem mục Cân bằng); khởi điểm nên nhỏ (khoảng 2 đến 5% giá trị gốc) để không làm hỏng cân bằng kinh tế đã có.

## 2. Phát sinh tin tức (`news_engine.gd`)

Dùng `data/news.json` (41 mẫu). Mỗi ngày sinh `news_per_day` tin (demo 6, full 7; trong `world.json`).

**Quy tắc hợp lệ theo `kind`** (gọi `d` là hướng thật hôm nay của biến trạng thái mà mẫu tham chiếu; mẫu có `link: "state:<biến>"`, trường `state_direction`):

| kind | Điều kiện phát sinh |
|---|---|
| `signal` (state) | `state_direction == d` |
| `signal` (event) | cú sốc `event:<id>` đang diễn ra hoặc vừa xảy ra trong 2 ngày qua |
| `partial` | `state_direction == d`, nhưng độ lớn trong tiêu đề lệch (dùng cỡ `high` hoặc `low` ngược thực tế) |
| `trap` | `state_direction != d`, **hoặc** mẫu có `exaggerates: true` |
| `stale` | luôn hợp lệ; nội dung gắn nhãn "đã cũ" (ví dụ dùng số của kỳ trước); không được coi là bằng chứng cho hôm nay |
| `noise` | luôn hợp lệ |

**Trễ theo nguồn:** tin về một thay đổi thật chỉ xuất hiện sau `delay_days` của nguồn (xem `sources` trong `news.json`). Tin `chinh_thuc` về một cú sốc muộn hơn tin mạng xã hội; đó là nguồn của cảm giác "tin nhanh thì nhiễu, tin chắc thì trễ".

**Tỷ lệ mỗi ngày** (khởi điểm, chỉnh được): signal 45%, trap 17%, partial 10%, stale 10%, noise 15%, nhưng mỗi ván phải đủ cả năm `kind` ít nhất một lần trong demo (kiểm thử khẳng định). Không phát cùng một mẫu quá một lần trong 3 ngày. Điền `{pct}` bằng `magnitude_pct` theo độ lớn thật (hoặc lệch cho `partial`).

Mỗi tin phát sinh là một **thể hiện** với `uid` duy nhất, `template_id`, `day`, `source_id`, `source_tier`, `headline` đã điền, và (ẩn) `truth`, `kind`, `link`.

**Dữ liệu công khai của một tin** (hàm công khai chỉ trả đúng các khóa này): `uid`, `day`, `source_id`, `source_tier`, `source_name`, `headline`, `topic`, `verification` (`chua_kiem_chung | xac_nhan | bac_bo | chua_du_can_cu | cu`), `verified_by` (mảng id công cụ đã dùng).

## 3. Công cụ kiểm chứng (`verifier.gd`)

Bốn công cụ trùng với bốn thẻ phân tích hiện có (ánh xạ trong CONTENT-BIBLE mục 8): `truy_van_lich_su` = `sql_deep_dive`, `kiem_dinh_gia_thuyet` = `ab_test`, `doi_chieu_nguon` = `funnel_report`, `lam_sach_du_lieu` = `clean_data`. Công cụ luôn sẵn có trên máy (không phụ thuộc bài trong tay).

**Thay đổi duy nhất được phép trong `scripts/sim/simulation.gd`:** thêm hàm `use_tool(card_id: String) -> bool`: giống phần trừ Energy, trừ Budget, áp hiệu ứng và lộ nguyên nhân sự kiện (`revealed_by`) của `play()`, nhưng lấy thẻ từ danh sách toàn bộ `cards` thay vì tay, **không** xóa thẻ khỏi tay và chỉ chấp nhận thẻ có `category == "analysis"`. `play()` giữ nguyên hành vi. Thêm kiểm thử riêng trong `test_sim.gd`.

Quy tắc kiểm chứng một tin bằng một công cụ (hàm `verify(uid, tool_id)`):

- Trừ Energy và Budget của thẻ tương ứng qua `use_tool`. Hết Energy hoặc Budget thì từ chối, không đổi trạng thái.
- Công cụ phải nằm trong `verify_with` của mẫu tin mới cho kết quả dứt khoát; ngược lại kết quả là `chua_du_can_cu`.
- Kết quả dứt khoát theo `truth`: `dung` hoặc `mot_phan` cho `xac_nhan`; `sai` cho `bac_bo`; `cu` cho `cu` (tin đúng nhưng đã cũ); `khong_lien_quan` cho `chua_du_can_cu`.
- Dữ liệu bẩn làm nhiễu: với xác suất `(1 - integrity/100) * noise_factor` (đọc Data Integrity qua đường công khai, hệ số trong `world.json`), kết quả dứt khoát bị đổi thành `chua_du_can_cu`. Không bao giờ đổi `xac_nhan` thành `bac_bo` hoặc ngược lại (kiểm chứng không được tạo thông tin sai chủ động).
- Kiểm chứng cùng một tin hai lần bằng cùng một công cụ trả kết quả đã có, không tốn tài nguyên.
- Kiểm chứng đồng thời có thể lộ nguyên nhân sự kiện theo cơ chế hiện có của `use_tool`.

## 4. Báo cáo và chấm điểm (`report.gd`)

Mỗi ngày có đúng một **câu hỏi** (mục 5). Báo cáo là một Dictionary:

```
{ "question_id": String,
  "forecast": "tang" | "giam" | "ngang",
  "confidence": "thap" | "vua" | "cao",
  "evidence": [uid, ...],           # tối đa 3 tin
  "actions": [card_id, ...] }       # chỉ thẻ đang có trong tay, tối đa theo chức vụ
```

`submit_report(report)` kiểm tra hợp lệ (thẻ phải nằm trong tay, số tin và hành động không vượt giới hạn, câu hỏi khớp ngày) và trả lỗi có mã cụ thể nếu sai, không đổi trạng thái.

**Chấm điểm** (hệ số trong `world.json`, khởi điểm theo bảng):

| Thành phần | Quy tắc |
|---|---|
| Độ chính xác `acc` | dự báo trùng đáp án: 1,0; lệch một bậc (`ngang` so với `tang`/`giam`): 0,4; ngược hướng: 0 |
| Hệ số tự tin `c` | `thap` 0,5; `vua` 1,0; `cao` 1,5 |
| Điểm gốc | `acc >= 1`: `+base * c`; `0 < acc < 1`: `+base * c * 0,3`; `acc == 0`: `-base * c` (base khởi điểm 10) |
| Chất lượng bằng chứng `ev` trong [-1, 1] | mỗi tin dẫn: `xac_nhan` +1, `chua_du_can_cu` 0, `bac_bo` -1 (bạn dẫn tin đã bị bác bỏ), `cu` -1, chưa kiểm chứng và là `sai` hoặc `cu` -1, chưa kiểm chứng và `dung` +0,25; `ev` là trung bình (0 nếu không dẫn tin nào) |
| Điểm cuối ngày | `delta = điểm gốc * (1 + 0,25 * ev)`, làm tròn 1 chữ số |

`delta` là độ đổi của Tin tưởng. Hàm trả về Dictionary kết quả công khai chỉ sau khi `review()` (độ chính xác, delta, nhãn thưởng/phạt), không phải ngay lúc nộp (để giao diện tạo họp cuối ngày).

## 5. Câu hỏi trong ngày (`data/questions.json`)

Codex viết file này từ CONTENT-BIBLE mục 9 và quy tắc dưới. Mỗi câu: `id`, `text` (tiếng Việt như trong CONTENT-BIBLE), `variable`, `window_days`, `answer_rule`. Demo dùng các câu có đáp án tính được:

| Câu (mục 9) | Đáp án |
|---|---|
| 1. Giá nguyên liệu | hướng thật `nguyen_lieu` trong `window_days` (ngày kế tiếp) |
| 3. Lãi suất | hướng thật `lai_suat` |
| 4. Sức mua | hướng thật `suc_mua` |
| 5. Đối thủ giảm giá | `tang` nếu cú sốc `competitor_discount` đang diễn ra trong cửa sổ, ngược lại `ngang` |
| 6. Ngân hàng đối tác | hướng thật `tin_dung` |
| 8. Số liệu báo cáo tuần | `giam` (không đáng tin) nếu `logging_error` đang diễn ra, ngược lại `tang` |
| 9. Tin đồn ngân hàng sụp | `ngang` (không cần hành động) nếu chỉ có tin `trap` về chủ đề này, `giam` nếu có tín hiệu thật (`tin_dung` giảm mạnh) |

Câu 2, 7, 10 để bản sau. Mỗi ngày chọn một câu mà kịch bản có thể trả lời, không lặp trong 3 ngày. Có kiểm thử: đáp án của mọi câu khớp với kịch bản và với luật.

## 6. Sự nghiệp (`career.gd`)

Thang chức: `thuc_tap`, `chuyen_vien`, `chuyen_vien_chinh`, `truong_nhom`, `giam_doc`. Tham số khởi điểm trong `world.json`:

| Chức | Số hành động tối đa mỗi báo cáo | Ngưỡng Tin tưởng để thăng | Lương mỗi ngày |
|---|---:|---:|---:|
| thuc_tap | 1 | 70 | 100 |
| chuyen_vien | 2 | 75 | 160 |
| chuyen_vien_chinh | 2 | 80 | 240 |
| truong_nhom | 3 | 85 | 340 |
| giam_doc | 3 | không có | 460 |

- Tin tưởng 0 đến 100, khởi điểm 50. Mỗi ngày `trust += delta`, kẹp trong [0, 100].
- **Thăng chức:** khi `trust >=` ngưỡng của chức hiện tại, hai báo cáo gần nhất đều có `acc >= 1`, và đã ở chức đó ít nhất 2 ngày. Sau khi thăng, `trust` đặt lại 55.
- **Cảnh cáo:** khi `trust <= 35`, tăng bộ đếm cảnh cáo một lần mỗi lần hạ qua ngưỡng (không đếm lặp khi đứng yên dưới ngưỡng).
- **Giáng chức:** khi `trust <= 25` và báo cáo ngày đó có `acc == 0`: xuống một chức (không dưới `thuc_tap`), `trust` đặt 40, tăng bộ đếm giáng chức.
- **Đuổi việc:** khi `trust <= 0`, hoặc bộ đếm giáng chức đạt 2, hoặc `trust <= 25` và đang ở `thuc_tap` với báo cáo `acc == 0` hai ngày liên tiếp.
- **Thưởng tiền:** báo cáo có `acc >= 1` và `ev >= 0,5` nhận thưởng ngày bằng 50% lương ngày. Thưởng chỉ ghi vào sổ cá nhân của người chơi (số liệu cho màn kết thúc), không vào Cash công ty.
- **Mức chấp thuận của sếp:** mỗi hành động trong báo cáo được sếp thực hiện với xác suất `adopt = adopt_min + (adopt_max - adopt_min) * trust / 100` (khởi điểm 0,4 đến 1,0), rút bằng RNG riêng theo seed. Hành động được chấp thuận thực thi bằng `Simulation.play()`. Nếu không đủ Budget hoặc Energy lúc thực thi thì bỏ qua và ghi nhận "không thực hiện được".

## 7. Lớp điều phối công khai (`world_game.gd`)

```
func _init(seed: int, horizon: int, overrides: Dictionary = {}) -> void
func begin_day() -> void              # gọi begin_week(false), áp cú sốc và tác động vĩ mô, sinh tin và câu hỏi
func news_today() -> Array            # tin công khai (mục 2), gồm cả tin chưa kiểm chứng của các ngày trước còn hiệu lực
func question_today() -> Dictionary   # {id, text}
func tools() -> Array                 # [{id, name_key, energy, budget}]
func verify(uid: String, tool_id: String) -> Dictionary   # {ok, result, energy_left} hoặc {ok:false, error}
func hand() -> Array                  # các thẻ hành động hiện có (từ Simulation.hand)
func submit_report(report: Dictionary) -> Dictionary      # {ok} hoặc {ok:false, error}
func end_day() -> Dictionary          # chạy chấp thuận, finish_week, chấm điểm, cập nhật sự nghiệp; trả kết quả công khai ngày
func review(day: int) -> Dictionary   # sự thật của ngày đã qua: nhãn từng tin, nguyên nhân cú sốc, đáp án, độ chính xác, delta
func status() -> Dictionary           # {day, horizon, rank, trust, warnings, demotions, personal_pay, cash_report, finished, ending}
func report_snapshot() -> Dictionary  # tái dùng Simulation.report() (số có nhiễu) cho dashboard
```

`ending`: `""` khi chưa xong, `fired`, `bankrupt` (công ty hết tiền theo `Simulation.state.lost`), hoặc `survived` (qua đủ ngày, công ty còn sống, chưa bị đuổi). Điều kiện thắng v2: `survived` và chức không thấp hơn `chuyen_vien` (demo). Điểm v2 = `1000` nếu thắng cộng `Trust * 5` cộng `10 * tổng_delta_dương` trừ `150 * giáng_chức` trừ `300 * đuổi_việc` (đặt các hệ số trong `world.json`, kiểm thử bất biến: mọi ván `fired` hoặc `bankrupt` có điểm thấp hơn mọi ván `survived` thắng).

`overrides` cho phép kiểm thử nạp dữ liệu giả (kịch bản cố định, tin cố định, hệ số) mà không đổi file.

## 8. Cân bằng (`tests/balance_world.gd`)

Chạy `--headless` N ván (mặc định 2.000, tham số `--games=`, `--days=10|30`) cho các bot, chỉ dùng API công khai, không đọc trạng thái ẩn:

| Bot | Hành vi |
|---|---|
| `random_reporter` | dự báo và độ tự tin ngẫu nhiên, không kiểm chứng, đề xuất hành động ngẫu nhiên trong tay |
| `rumor_follower` | tin tin mạng xã hội và tin nội bộ nặc danh nhất, độ tự tin cao, không kiểm chứng |
| `official_only` | chỉ tin nguồn chính thức và báo chí, bỏ qua tin trễ nếu có xung đột, độ tự tin vừa, không kiểm chứng |
| `verifier` | mỗi ngày kiểm chứng tối đa các tin liên quan câu hỏi bằng công cụ đúng (theo `verify_with`), chỉ dẫn tin đã `xac_nhan`, chỉnh độ tự tin theo số bằng chứng |
| `careful_hedger` | luôn chọn độ tự tin `thap`, dẫn tin xác nhận nếu có, hành động ít |

Mục tiêu demo (10 ngày, 2.000 ván mỗi bot, seed 104 trở đi), tỷ lệ **thắng** (`survived` và chức không thấp hơn `chuyen_vien`):

| Bot | Tỷ lệ thắng mục tiêu |
|---|---|
| `random_reporter` | tối đa 10% |
| `rumor_follower` | tối đa 15% |
| `official_only` | 30% đến 55% |
| `careful_hedger` | 25% đến 60%, thấp hơn `verifier` |
| `verifier` | cao hơn `official_only` ít nhất 15 điểm %, tối đa 85% |

Ngoài tỷ lệ thắng, in cho mỗi bot: tỷ lệ `fired`, `bankrupt`, `survived`; Tin tưởng cuối ván trung vị; chức cuối trung vị; độ chính xác dự báo trung bình; chất lượng bằng chứng trung bình `ev`. Chỉ số kiểm tra phụ: trong demo, với mỗi ván, đủ cả năm `kind` tin đã được phát sinh; cả 8 cú sốc đều có thể xuất hiện qua các seed khác nhau.

Nếu hai mục tiêu mâu thuẫn nhau, **dừng và báo** thay vì tự hạ mục tiêu. Công cụ cân bằng được phép: mọi hệ số trong `world.json`, tỷ lệ kind, độ trễ, số tin mỗi ngày, độ lớn tác động vĩ mô, hệ số chấm điểm. Cần công cụ khác (đổi luật kiểm chứng, đổi cấu trúc báo cáo) thì hỏi Claude.

## 9. Kiểm thử (`tests/test_world.gd`)

- **Tái lập:** cùng seed và cùng hành động cho cùng kết quả (hash toàn bộ nhật ký).
- **Không lộ:** rà đệ quy mọi Dictionary và Array công khai (`news_today`, `question_today`, `tools`, `hand`, `status`, kết quả `verify`, `submit_report`, `end_day` của ngày đang chơi): không có khóa `truth`, `kind`, `link`, `state_direction`, `exaggerates`, `answer`, `scenario`; `review(day)` trả lỗi nếu `day` chưa qua.
- **Luật hợp lệ của tin:** với mỗi kind, mọi tin phát sinh qua 200 seed thỏa điều kiện ở mục 2.
- **Trễ theo nguồn:** tin về thay đổi thật xuất hiện không sớm hơn `delay_days` của nguồn.
- **Kiểm chứng:** bảng kết quả theo `truth`; công cụ sai `verify_with` cho `chua_du_can_cu`; không đổi `xac_nhan` thành `bac_bo`; hết Energy thì từ chối và không đổi trạng thái; kiểm chứng lặp không tốn thêm.
- **Chấm điểm:** từng dòng của bảng mục 4 bằng ví dụ tính tay.
- **Sự nghiệp:** thăng chức, cảnh cáo (đếm một lần), giáng chức, đuổi việc theo từng điều kiện, thưởng tiền, xác suất chấp thuận đơn điệu theo `trust`.
- **Câu hỏi:** đáp án của mọi câu khớp kịch bản; không lặp trong 3 ngày.
- **Bất biến điểm v2:** quét 500 ván mỗi bot: mọi ván thua điểm thấp hơn mọi ván thắng.
- **Tích hợp:** chạy trọn một ván 10 ngày bằng API công khai (như giao diện sẽ làm) không lỗi; `Simulation.state` nhất quán.
- `test_sim.gd` có kiểm thử cho `use_tool` (không xóa thẻ khỏi tay, từ chối thẻ không phải `analysis`).

## Ràng buộc

- Không sửa `scripts/ui/`, `scenes/`, `data/cards.json`, `data/events.json`, `data/config.json`, `data/news.json` (nếu thấy lỗi trong `news.json` thì ghi vào bàn giao để Claude sửa), `media-marketing/`, `docs/`, `shared/`.
- Không sửa `scripts/sim/` ngoài hàm `use_tool` (và nếu bắt buộc, một vài dòng phụ trợ cho nó; ghi rõ).
- `test_sim.gd` (2.608 kiểm tra), `test_ui.gd` (134 kiểm tra) giữ nguyên và qua; `balance_sim.gd` in kết quả giống hệt `master`/`v2` hiện tại (so từng dòng, bỏ `elapsed_seconds`).
- Chuỗi hiển thị tiếng Việt nằm ở các file dữ liệu (`questions.json`, `news.json`); tầng này không tự sinh chữ ngoài các mã lỗi và nhãn kỹ thuật.
- Không đọc hoặc sinh dữ liệu cá nhân, không gọi mạng.

## File được sửa

`game-studio/godot/scripts/world/*`, `game-studio/godot/data/world.json`, `game-studio/godot/data/questions.json`, `game-studio/godot/scripts/sim/simulation.gd` (chỉ `use_tool`), `game-studio/godot/tests/test_world.gd`, `game-studio/godot/tests/balance_world.gd`, `game-studio/godot/tests/test_sim.gd` (chỉ thêm kiểm thử `use_tool`).

## Bàn giao

Trong `TASKS.md`: file đổi, bảng cân bằng bot (10 ngày và 30 ngày), lịch sử các vòng chỉnh số, `world.json` cuối đầy đủ, xác nhận không lộ sự thật ẩn (kết quả kiểm thử rà khóa), các chỗ tự quyết, mục tiêu nào chưa đạt và vì sao.
