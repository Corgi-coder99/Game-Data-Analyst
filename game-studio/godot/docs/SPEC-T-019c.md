# Spec T-019c: Vòng chơi v2 trọn vẹn (báo cáo, họp cuối ngày, tiêu đề, kết thúc)

Người làm: Claude subagent (thay Codex hết hạn mức đến 15/11/2026). Người review: Claude điều phối. Nhánh nền: `v2` (đã có T-018, T-018b, T-018c, T-019a, T-019b). Đọc: `docs/GDD-v2-concept.md` mục 3, 6, 7, `docs/CONTENT-BIBLE-v2.md` (đặc biệt mục 8, 10, 12), `shared/style-bible/pixel-office-v2.md`, `docs/SPEC-T-019a.md`, `docs/SPEC-T-019b.md`, `scripts/world/world_game.gd`, `scripts/v2/*`.

## Mục tiêu

Ghép các phần đã có (văn phòng, màn hình máy tính, tầng thế giới) thành **một ván 10 ngày chơi được từ màn tiêu đề đến màn kết thúc**, chỉ bằng chuột và phím. Thêm: cửa sổ soạn báo cáo, họp cuối ngày (sự thật được công bố), màn kết thúc theo từng kiểu kết cục, màn tiêu đề, bộ điều phối vòng chơi.

Chạy được bằng: `Godot --path game-studio/godot res://scenes/v2/main_v2.tscn` (bản v1 vẫn là `run/main_scene`, **không đổi `project.godot`**).

## 1. Luồng trạng thái (`scripts/v2/game_flow.gd`, `scenes/v2/main_v2.tscn`)

```
TITLE -> NEW_GAME -> DAY_START -> WORK (màn hình máy tính) -> SUBMITTED -> REVIEW -> (DAY_START ngày kế | ENDING) -> END_SCREEN -> (NEW_GAME | TITLE)
```

- **TITLE:** `scenes/v2/title.tscn`: cảnh văn phòng mờ làm nền (dùng sprite của T-019a), chữ "Data Corp (tên tạm)", nút Chơi và Thoát, và dòng chú thích bắt buộc nguyên văn ở CONTENT-BIBLE mục 12 ở đáy màn hình ("Dữ liệu và tên trong game là hư cấu, do mô phỏng sinh ra. Không phải dữ liệu thị trường thật và không phải lời khuyên đầu tư. Một phần nội dung và mã được tạo với hỗ trợ của AI.").
- **NEW_GAME:** tạo `WorldGame(seed, 10)`; seed lấy theo thời gian (có tham số cố định cho kiểm thử).
- **DAY_START:** `begin_day()`; cảnh văn phòng với đặt pha sáng (`set_phase("sang")`, `set_clock(8, 30)`); ngày đầu người chơi đi vào bàn (`play_arrival()`), các ngày sau đã ngồi sẵn; sếp xuất hiện (`play_boss_appears`) với câu hỏi trong ngày (`question_today().text`); khi `dialog_closed` hoặc người chơi bấm bàn, chuyển sang WORK. Có phím Esc/Space để bỏ qua hoạt ảnh.
- **WORK:** màn hình máy tính (T-019b) cộng cửa sổ Báo cáo (mục 2). Đồng hồ trên thanh tác vụ tăng 30 phút mỗi lần dùng công cụ; pha cửa sổ văn phòng đổi `trua` sau lần dùng công cụ đầu tiên hoặc khi đồng hồ qua 12:00; không bắt buộc hiển thị cảnh văn phòng trong lúc WORK.
- **SUBMITTED:** sau khi nộp báo cáo, khóa mọi chỉnh sửa; gọi `end_day()`; đặt pha `chieu`.
- **REVIEW (họp cuối ngày):** mục 3.
- **Sau REVIEW:** nếu `status().finished` thì `ENDING`; ngược lại `begin_day()` ngày kế (chuyển cảnh mờ dần ≤ 300 ms, bằng lớp màu 1 với độ trong suốt bước 25%).
- **ENDING và END_SCREEN:** mục 4.
- Chuyển cảnh bằng mờ dần; không có rung màn hình.

`game_flow.gd` chỉ dùng API công khai của `WorldGame`. Mọi chuỗi hiển thị ở `data/strings_v2.json`.

## 2. Cửa sổ Báo cáo (`scripts/v2/windows/report_window.gd`, thêm vào màn hình máy tính)

Cùng phong cách cửa sổ T-019b (viền màu 5, thanh tiêu đề màu 18). Bố cục thêm vào desktop: nếu cần chỗ, thu cửa sổ Công ty và Công cụ lại và đặt Báo cáo vào cùng ô (tab hoặc nút thanh tác vụ "Báo cáo" bật/tắt), miễn không tràn 640x360 và các hàng không chồng nhau trong render thật.

Nội dung:
- **Dự báo:** 3 lựa chọn một-trong-ba: Tăng, Giảm, Đi ngang (chip có biểu tượng mũi tên; không chỉ dùng màu).
- **Mức tự tin:** Thấp, Vừa, Cao.
- **Bằng chứng:** danh sách các tin đã ghim (từ cửa sổ Tin tức, tối đa 3, `desktop.get_pinned()`), mỗi dòng hiện tiêu đề rút gọn và nhãn kiểm chứng; nút bỏ ghim. Có nhắc "chưa kiểm chứng" cho tin chưa kiểm.
- **Hành động đề xuất:** lấy từ `hand()` (các thẻ hành động hôm nay, với Budget và Energy từ dữ liệu thẻ), hiển thị tên đã đổi theo ngữ cảnh (CONTENT-BIBLE mục 8: Fix Checkout Bug thành "Siết thu hồi công nợ qua cổng thanh toán", Onboarding Redesign thành "Cải tiến quy trình đặt hàng cho đại lý mới", Ads Campaign thành "Chi marketing tìm đại lý", Influencer Campaign thành "Hợp tác kênh phân phối lớn", Loyalty Program thành "Chương trình giữ chân đại lý", SEO Content thành "Nội dung và kênh bán lẻ trực tuyến", Support Automation thành "Tự động hóa kho và chăm sóc", Giảm giá thành "Khuyến mãi tạm thời"). Tối đa số hành động theo chức vụ (xem mục 5: cần thêm `max_actions` vào `status()`). Chọn hoặc bỏ chọn bằng nhấp chuột.
- Nút "Nộp báo cáo": gọi `submit_report` với `{question_id, forecast, confidence, evidence, actions}`; lỗi (mã trong `world_game.gd`/`report.gd`: `invalid_question`, `invalid_forecast`, `invalid_confidence`, `too_many_evidence`, `too_many_actions`, `invalid_evidence`, `invalid_action`, `day_closed`, `already_submitted`) hiện bằng thông báo tiếng Việt từ `strings_v2.json`, không đổi trạng thái. Nút mờ cho đến khi đã chọn dự báo và mức tự tin; có hộp xác nhận ngắn "Nộp báo cáo? Không sửa được nữa."
- Không bao giờ hiển thị nhãn thật của tin, độ tin cậy nguồn hay đáp án. Chỉ dùng API công khai.

## 3. Họp cuối ngày (`scenes/v2/review.tscn`, `scripts/v2/review_scene.gd`)

Sau `end_day()`, dùng `review(day)` của **ngày vừa kết thúc** (đây là nơi duy nhất được hiển thị sự thật, vì ngày đã đóng). Bố cục: hộp thoại của Chị Hạnh ở dưới (như office) và một bảng "Sự thật hôm nay" bên trên, hiển thị lần lượt (có nút Tiếp tục để qua bước kế, hoặc Space/Enter):

1. **Phản ứng của sếp** (lời thoại theo kết quả, mục 6) kèm độ đổi Tin tưởng `delta` (số nổi lên theo style bible: hiện số lớn 12px rồi tan 600 ms) và thanh Tin tưởng cập nhật.
2. **Đáp án và dự báo:** "Dự báo của bạn: X (mức tự tin Y). Thực tế: Z." Điểm chính xác bằng chữ (Đúng, Gần đúng, Sai).
3. **Các tin hôm nay và sự thật:** mỗi tin kèm nhãn thật: Đúng, Sai, Đúng một phần, Đã cũ, Không liên quan (chip với biểu tượng: dấu kiểm, dấu X, dấu hỏi, đồng hồ cũ, gạch ngang; màu theo style bible) và đánh dấu tin nào bạn đã dẫn làm bằng chứng. Mục sự thật của `review()` dùng các khóa mà `review(day)` trả (`news`, `shocks`, `answer`, `result`, `career`, `actions`, `states`).
4. **Cú sốc và nguyên nhân gốc:** các cú sốc xảy ra hôm nay, kèm nguyên nhân gốc (`root_cause`).
5. **Hành động:** mỗi hành động đề xuất cho biết sếp có chấp thuận không (`adopted`) và có thực hiện được không (`executed`), bằng chữ rõ ràng.
6. **Sự nghiệp:** thưởng tiền, thăng chức, cảnh cáo, giáng chức hoặc đuổi việc (từ `career` và `status()`), với hiệu ứng thăng chức bằng dải ánh sáng quét ngang 400 ms (màu 28 và 14).

`review_scene.gd` là **file duy nhất** trong `scripts/v2/` được phép đọc các khóa `truth`, `kind`, `root_cause`, `states`, và chỉ trên kết quả của `WorldGame.review(day)` với ngày đã qua. Kiểm thử quét mã nguồn (đã có ở T-019b) phải được cập nhật để cho phép đúng file này và vẫn cấm mọi file khác; thêm kiểm thử khẳng định `review_scene.gd` chỉ gọi `review()` với ngày đã kết thúc.

## 4. Kết thúc (`scenes/v2/ending.tscn`, `scripts/v2/ending_scene.gd`)

Theo `status().ending`: `fired`, `bankrupt`, `survived`. Mỗi kiểu có cảnh riêng ngắn: văn phòng (sếp ở cửa hoặc bàn trống khi bị đuổi), hộp thoại lời sếp (mục 6), rồi bảng tổng kết: chức vụ cuối, Tin tưởng, số ngày làm, tổng thu nhập cá nhân (`personal_pay`), điểm (`score`), và dòng "Thắng" hoặc "Thua" theo `won`. Nút "Chơi lại" (ván mới) và "Về tiêu đề". Khi `bankrupt`, thêm dòng ngắn nói công ty hết tiền.

## 5. Thay đổi nhỏ cho phép ở lớp thế giới

Giao diện cần biết số hành động tối đa của chức vụ hiện tại (người chơi vốn biết quyền hạn của mình). **Chỉ được thêm** khóa số nguyên `max_actions` vào kết quả của `WorldGame.status()`, đúng bằng `ranks[rank].actions` của `world.json`. Cập nhật `tests/test_world.gd` (đúng giá trị theo chức, đổi sau thăng hoặc giáng chức) và kiểm thử rà khóa nhạy cảm vẫn qua. Không đổi gì khác trong `scripts/world/`.

## 6. Lời thoại của sếp (Chị Hạnh), đặt trong `data/strings_v2.json` (`boss_lines`)

Dùng nguyên văn các câu dưới (có thể thêm 1 đến 2 biến thể mỗi kiểu, cùng giọng ngắn và đời thường), chọn theo kết quả:
- Đúng (`acc >= 1`): "Tốt. Lần sau cứ nói rõ mức chắc chắn như vậy."
- Sai nhưng tự tin thấp: "Sai, nhưng cô đã báo trước là chưa chắc. Tôi ghi nhận."
- Sai và tự tin cao: "Cô nói chắc chắn. Giờ công ty đang trả giá cho điều đó."
- Đúng một phần: "Cũng gần. Lần sau tôi cần thêm bằng chứng."
- Cảnh cáo: "Đây là cảnh cáo. Tôi cần thấy bằng chứng trong báo cáo, không phải cảm giác."
- Thăng chức: "Từ tuần sau cô lên chức mới. Đừng làm tôi hối hận."
- Giáng chức: "Tôi buộc phải điều cô xuống một bậc. Làm lại cho cẩn thận."
- Đuổi việc: "Tôi tiếc, nhưng công ty không đứng vững được nếu tiếp tục như vậy."
- Công ty hết tiền: "Công ty không còn tiền để hoạt động. Chuyện này không chỉ do một báo cáo."
- Sống sót đến cuối và thắng: "Công ty vẫn đứng vững. Cảm ơn cô đã ở lại."
- Sống sót nhưng chưa đủ chức để tính thắng: "Công ty vẫn còn, nhưng tôi chưa thấy cô đủ vững để giao thêm việc."
Giữ giọng điệu theo CONTENT-BIBLE mục 10. Chuỗi giao diện khác (nhãn, thông báo lỗi, tên hành động, tiêu đề) cũng nằm trong file này.

## 7. Kiểm thử

Tất cả mới, thêm vào `tests/`:
- `tests/test_v2_flow.gd` (headless): bộ điều phối chạy các kịch bản bằng API của nó mà không cần chuột:
  - **Ván tốt:** nhiều seed, mỗi ngày kiểm chứng tin liên quan, ghim, nộp báo cáo hợp lệ; ván đạt `ending == "survived"`; mọi trạng thái được đi qua đúng thứ tự.
  - **Ván xấu:** nộp báo cáo ngẫu nhiên tự tin cao; ván đạt `fired` (tìm seed hoặc ép bằng `overrides` của `WorldGame` nếu cần để kiểm thử ổn định).
  - **Phá sản:** dùng `overrides` để ép công ty hết tiền; đạt `bankrupt`.
  - Báo cáo không hợp lệ bị từ chối với thông báo tiếng Việt; không đổi trạng thái; nộp hai lần bị từ chối.
  - `review(day)` không được gọi cho ngày chưa kết thúc (khẳng định qua mock hoặc theo dõi lời gọi).
  - Thứ tự và nội dung lời thoại của sếp đúng theo kết quả (mỗi kiểu trong mục 6 được chọn trong ít nhất một kịch bản).
  - Ván 10 ngày kết thúc không lỗi script với 20 seed khác nhau chạy tự động.
- `tests/test_v2_screens_render.gd` (**chạy KHÔNG headless**, bài học từ T-019b: đo kích thước thực): dựng từng màn (tiêu đề, WORK có cửa sổ Báo cáo, họp cuối ngày ở từng bước, ba kiểu kết thúc) trong cửa sổ thật, chờ vài khung hình, duyệt đệ quy mọi Control hiển thị và khẳng định `get_global_rect()` nằm trong `Rect2(0,0,640,360)` (bỏ qua nội dung bên trong `ScrollContainer`, nhưng chính ScrollContainer phải nằm trong khung), và các điều khiển anh em trong cùng một cửa sổ không chồng nhau. Phải FAIL nếu cố ý đặt một nút ra ngoài (kiểm chứng bằng cách chạy thử một lần với lỗi cố ý rồi gỡ). Ghi trong bàn giao cách chạy.
- Cập nhật `tests/test_v2_desktop.gd` và `tests/test_world.gd` cho `max_actions` và cho phép duy nhất `review_scene.gd` đọc khóa sự thật.
- Chuỗi: mọi mã lỗi, nhãn sự thật (dung, sai, mot_phan, cu, khong_lien_quan), kiểu kết thúc, và tên hành động có chuỗi tiếng Việt trong `strings_v2.json`.
- `tools/check_palette.gd` PASS (nếu thêm sprite hoặc biểu tượng: thêm vào `tools/sprites/*.gd`, chạy lại `gen_sprites`).
- Giữ nguyên và qua: `test_sim` (2.634), `test_ui` (134), `test_world` (32.502 cộng kiểm tra mới), `test_v2_assets` (2.255, cập nhật nếu thêm sprite), `test_v2_desktop` (2.336), `test_v2_layout_render` (2.614), `balance_sim` giống hệt trước, `balance_world` không đổi (không sửa thế giới ngoài `max_actions`).

## 8. Ràng buộc

- Không dùng asset, font, mã từ bên ngoài, không gọi mạng. Font mặc định Godot. Chỉ 32 màu của bảng, sprite và biểu tượng mới (nếu cần) thêm bằng ảnh chữ và sinh PNG qua `tools/gen_sprites.gd`, chạy `check_palette.gd` PASS.
- Giao diện và bộ điều phối chỉ dùng API công khai của `WorldGame`; nguyên tắc không lộ sự thật ẩn trước `review()` giữ nguyên.
- Không sửa: `scripts/sim/`, `scripts/ui/` (UI v1), `scenes/*.tscn` ngoài `scenes/v2/`, `data/cards.json`, `events.json`, `config.json`, `news.json`, `questions.json`, `shared/`, `docs/`, `media-marketing/`, `project.godot`. Trong `scripts/world/` chỉ thêm `max_actions` vào `status()`.
- Không đổi `scenes/v2/office.tscn` và `scripts/v2/office.gd` trừ khi cần sửa lỗi hoặc thêm hàm nhỏ; nếu đụng thì ghi rõ trong bàn giao.
- Mô phỏng tái lập theo seed.

## 9. File được sửa

`game-studio/godot/scenes/v2/*` (thêm `main_v2.tscn`, `title.tscn`, `review.tscn`, `ending.tscn`), `game-studio/godot/scripts/v2/*` (thêm `game_flow.gd`, `review_scene.gd`, `ending_scene.gd`, `title_scene.gd`, `windows/report_window.gd`; sửa `desktop.gd` và `theme_v2.gd` khi cần), `game-studio/godot/data/strings_v2.json`, `game-studio/godot/tools/sprites/*` và `assets/v2/*` (chỉ nếu thêm biểu tượng), `game-studio/godot/scripts/world/world_game.gd` (chỉ `status()` thêm `max_actions`), `game-studio/godot/tests/test_world.gd` (chỉ `max_actions`), `game-studio/godot/tests/test_v2_flow.gd`, `game-studio/godot/tests/test_v2_screens_render.gd`, `game-studio/godot/tests/test_v2_desktop.gd`.

## 10. Bàn giao

Trong `TASKS.md` (dưới dòng T-019c, chuyển sang Review, kiểm tra lại dòng nằm đúng mục): file đổi, kết quả thật từng lệnh kiểm thử (số kiểm tra và lỗi), cách chạy ván (`Godot --path game-studio/godot res://scenes/v2/main_v2.tscn`), cách chạy kiểm thử không headless, các chỗ tự quyết, hạn chế. Điều phối sẽ tự chạy ván bằng script, chụp ảnh từng màn và trả lại nếu bố cục hoặc nội dung chưa đạt.
