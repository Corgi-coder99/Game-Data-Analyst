# Spec T-019b: Màn hình máy tính (v2): tin tức, công ty, công cụ kiểm chứng

Owner: Codex. Người review: Claude. Nhánh nền: `v2` (đã có T-018, T-018b, T-019a). Nguồn: `shared/style-bible/pixel-office-v2.md` mục 5 (giao diện máy tính), `docs/GDD-v2-concept.md` mục 3, `docs/CONTENT-BIBLE-v2.md`, `scripts/world/world_game.gd` (API công khai), `scripts/v2/*` và `assets/v2/*` của T-019a.

## Mục tiêu

Làm màn hình máy tính giả lập mà người chơi dùng cả ngày: đọc tin, kiểm chứng tin bằng công cụ, xem dashboard công ty, ghim tối đa 3 tin làm bằng chứng. Chưa làm soạn báo cáo và họp cuối ngày (T-019c). Màn hình này chạy trên một đối tượng `WorldGame` (đã có), không tự sinh dữ liệu.

## Bố cục (640x360, nền desktop màu 17)

```
+------------------------------------------------------------------+
| Câu hỏi của sếp: <question_today().text> (một dòng, cuộn nếu dài)  |  <- dải trên, cao 14px
+------------------------------+-----------------------------------+
| [Cửa sổ TIN TỨC]             | [Cửa sổ CÔNG TY]                  |
|  danh sách tin               |  Cash, 7 chỉ số, mũi tên          |
|  (cuộn)                      |  Tin tưởng, chức vụ, ngày         |
|                              +-----------------------------------+
|                              | [Cửa sổ CÔNG CỤ]                  |
|                              |  4 công cụ, Energy, kết quả       |
+------------------------------+-----------------------------------+
| Thanh tác vụ (16px): [Tin tức][Công ty][Công cụ]   Ngày N/H  ●●○ |
+------------------------------------------------------------------+
```

Cửa sổ Tin tức khoảng 392x300, Công ty khoảng 240x140, Công cụ khoảng 240x156 (Codex tinh chỉnh cho vừa chữ, không tràn). Ba cửa sổ cùng hiện, không chồng. Nút trên thanh tác vụ thu nhỏ hoặc phục hồi từng cửa sổ (cửa sổ thu nhỏ ẩn đi, cửa sổ khác không đổi chỗ). Cửa sổ kéo thả để bản sau (không bắt buộc).

Phong cách theo style bible mục 5: viền cửa sổ 1px màu 5, thanh tiêu đề cao 12px màu 18 với chữ màu 22, nút thu nhỏ 8x8, thanh tác vụ cao 16px màu 2 có đồng hồ ngày. Tạo `Theme` bằng mã trong `scripts/v2/theme_v2.gd` chỉ dùng màu trong bảng 32 màu (không gradient, không bóng mờ, không bo tròn).

## Cửa sổ Tin tức

- Danh sách các tin từ `news_today()` (gồm cả tin các ngày trước còn hiệu lực), mới nhất ở trên, cuộn được. Mỗi dòng gồm:
  - **Chip nguồn** theo loại (`source_tier`): `chinh_thuc` màu xanh dương với biểu tượng khiên; `bao_chi` xám xanh với tờ báo; `mang_xa_hoi` tím với bong bóng thoại; `noi_bo` vàng với khóa (theo style bible mục 5). Tên nguồn bên cạnh.
  - Tiêu đề tin (ngắt dòng, tối đa 2 dòng, đủ nội dung ở tooltip).
  - Ngày đăng (`day`).
  - **Nhãn kiểm chứng** theo `verification`: `chua_kiem_chung` không có nhãn; `xac_nhan` dấu kiểm xanh lá; `bac_bo` dấu X đỏ; `chua_du_can_cu` dấu hỏi vàng; `cu` nhãn "Đã cũ" màu 6 kèm biểu tượng.
  - Nút ghim (cờ): bật thì tin vào danh sách bằng chứng. **Tối đa 3 tin được ghim**; bấm khi đã đủ 3 thì không ghim thêm và hiện thông báo ngắn. Tin ghim có viền sáng.
- Chọn một dòng (bấm hoặc phím mũi tên lên xuống, Enter chọn) để dùng công cụ lên tin đó.
- Không bao giờ hiển thị hay suy ra nhãn thật của tin, độ tin cậy của nguồn, hay `kind`. Chỉ hiển thị đúng các khóa công khai: `uid, day, source_id, source_tier, source_name, headline, topic, verification, verified_by`.
- Màu chỉ truyền nghĩa kèm biểu tượng hoặc chữ (style bible mục 2).

## Cửa sổ Công cụ

- Liệt kê 4 công cụ từ `tools()` (tên hiển thị tiếng Việt từ `data/strings_v2.json`: Truy vấn dữ liệu lịch sử, Kiểm định giả thuyết, Đối chiếu nguồn tin, Làm sạch dữ liệu), kèm chi phí Energy và Budget.
- Hiển thị **Energy còn lại trong ngày** (chấm tròn, tối đa 3 chấm) và dùng trên thanh tác vụ.
- Nút "Dùng" áp công cụ lên tin đang chọn (gọi `world_game.verify(uid, tool_id)`). Kết quả hiện ngay bên dưới (ví dụ "Xác nhận", "Bác bỏ", "Chưa đủ căn cứ", "Tin đã cũ") và cập nhật nhãn của tin. Lỗi từ `verify` (`day_closed`, `invalid_uid`, thiếu Energy, thiếu Budget...) hiển thị bằng thông báo tiếng Việt, không đổi trạng thái.
- Nút bị làm mờ khi chưa chọn tin, hoặc khi không đủ Energy hoặc Budget.
- Dùng cùng công cụ cho cùng tin lần hai không tốn thêm (do lõi xử lý); giao diện chỉ hiện lại kết quả.

## Cửa sổ Công ty

- Cash và 7 chỉ số của `report_snapshot()` (Users, Retention, Conversion, CAC, ARPU, LTV/CAC, Data Integrity), mũi tên lên, xuống hoặc ngang so với ảnh chụp lần trước (ngày trước), màu và biểu tượng theo style bible. Dấu "?" kèm cảnh báo màu vàng khi Data Integrity báo cáo dưới 60 (hằng số có tên).
- Ngày hiện tại và tổng số ngày, chức vụ, thanh Tin tưởng 0 đến 100 từ `status()`.
- Chỉ dùng `report_snapshot()` và `status()`. Không đọc trạng thái nội bộ của lõi mô phỏng.

## Thay đổi cho phép ở lớp thế giới

Giao diện cần biết Energy còn lại mà API công khai chưa có. **Chỉ được thêm** hai khóa số nguyên `energy` và `energy_max` vào kết quả của `WorldGame.status()` (đây là thông tin người chơi vốn biết, không phải sự thật ẩn). Không thêm gì khác vào `scripts/world/`. Cập nhật `tests/test_world.gd` để kiểm tra hai khóa này có mặt, đúng giá trị (giảm sau mỗi lần `verify` tốn Energy, đặt lại đầu ngày), và rà khóa nhạy cảm vẫn qua.

## API của màn hình (`scripts/v2/desktop.gd`)

```
func setup(game: RefCounted) -> void          # nhận WorldGame đã có
func refresh() -> void                        # đọc lại API công khai và vẽ lại
func get_pinned() -> Array                    # các uid đã ghim, tối đa 3
func clear_pins() -> void
func select_news(uid: String) -> bool
func use_tool(tool_id: String) -> Dictionary  # áp công cụ lên tin đang chọn; trả kết quả của verify
signal evidence_changed(uids: Array)
signal tool_used(uid: String, tool_id: String, result: Dictionary)
signal window_toggled(window_id: String, visible: bool)
```

## Chuỗi hiển thị và bảng màu

- Mọi chuỗi tiếng Việt nằm ở `data/strings_v2.json` (nhãn loại nguồn, nhãn chủ đề, tên công cụ, nhãn kiểm chứng, nhãn chỉ số, thông báo lỗi, tiêu đề cửa sổ). Có kiểm thử: mọi giá trị `source_tier`, `topic`, `verification`, công cụ và mã lỗi của lõi đều có chuỗi tương ứng.
- Chỉ dùng 32 màu của bảng. Nếu cần thêm biểu tượng (ví dụ nút thu nhỏ, mũi tên cuộn) thì thêm vào `tools/sprites/icons.gd` (8x8 hoặc 16x16, theo style bible mục 4), chạy lại `gen_sprites` và `check_palette` (phải PASS).
- Font mặc định của Godot, cỡ 8 và 12. Không tải font ngoài.

## Kiểm thử (`tests/test_v2_desktop.gd`, headless)

- Dựng `WorldGame(seed, 10)`, `begin_day()`, `desktop.setup()`; số dòng tin bằng số phần tử của `news_today()`; thứ tự mới nhất ở trên.
- Ghim: ghim tới 3 thành công, tin thứ 4 bị từ chối, bỏ ghim được; `evidence_changed` phát đúng nội dung.
- Dùng công cụ qua giao diện: nhãn kiểm chứng của dòng đổi theo kết quả; Energy giảm đúng; hết Energy thì nút mờ và `use_tool` trả lỗi, không đổi trạng thái; dùng lặp không tốn thêm.
- Không có khóa nhạy cảm trong dữ liệu đưa lên giao diện: rà tất cả Dictionary mà `desktop.gd` và các cửa sổ nhận từ `WorldGame` (hoặc đọc mã nguồn các file trong `scripts/v2/` và xác nhận không tham chiếu `truth`, `kind`, `link`, `state_direction`, `exaggerates`, `scenario`, `_scenario`, `_news`, `_reviews`, `template_id`, `verify_with`, `reliability`).
- Mọi điều khiển nằm trong 640x360 với 6 tin dài khác nhau và tiêu đề dài 200 ký tự (không tràn, không chồng).
- Thu nhỏ và phục hồi từng cửa sổ không lỗi, phát `window_toggled`.
- Chạy trọn 10 ngày bằng cách gọi API giao diện và `WorldGame` (mỗi ngày: chọn tin, dùng công cụ nếu còn Energy, ghim, nộp một báo cáo đơn giản qua `WorldGame`, `end_day`, `begin_day` ngày kế) không lỗi và `refresh()` luôn nhất quán.
- Mọi chuỗi cần có trong `strings_v2.json` (như trên).
- `tools/check_palette.gd` PASS; `test_v2_assets` (2.255 kiểm tra) giữ nguyên qua.

Giữ nguyên: `test_sim` (2.630), `test_ui` (134), `test_world` (32.419 cộng thêm kiểm tra `energy`), `balance_sim` giống hệt trước.

## Ràng buộc

- Không dùng asset, font, mã từ bên ngoài; không gọi mạng.
- Không sửa `scripts/sim/`, `scripts/ui/` (UI v1), `scenes/*.tscn` hiện có ngoài `scenes/v2/`, `data/news.json`, `data/questions.json`, `data/config.json`, `data/cards.json`, `data/events.json`, `shared/`, `docs/`, `media-marketing/`, `project.godot`. Trong `scripts/world/` chỉ thêm hai khóa vào `status()` như nêu trên.
- Không thay `scenes/v2/office.tscn` và `scripts/v2/office.gd` (T-019a), trừ khi phát hiện lỗi: khi đó ghi lỗi vào bàn giao.

## File được sửa

`game-studio/godot/scenes/v2/desktop.tscn`, `game-studio/godot/scripts/v2/desktop.gd`, `game-studio/godot/scripts/v2/windows/*`, `game-studio/godot/scripts/v2/theme_v2.gd`, `game-studio/godot/data/strings_v2.json`, `game-studio/godot/tools/sprites/icons.gd` (chỉ thêm biểu tượng), `game-studio/godot/assets/v2/*` (sinh lại), `game-studio/godot/scripts/world/world_game.gd` (chỉ `status()`), `game-studio/godot/tests/test_world.gd` (chỉ kiểm tra `energy`), `game-studio/godot/tests/test_v2_desktop.gd`.

## Bàn giao

Trong `TASKS.md`: file đổi, kết quả kiểm thử, chỗ tự quyết, hạn chế. Claude sẽ tự chạy cảnh, chụp màn hình (với ngày có đủ loại tin, có kết quả kiểm chứng, đã ghim) để duyệt, và trả lại kèm nhận xét cụ thể nếu chưa đạt.
