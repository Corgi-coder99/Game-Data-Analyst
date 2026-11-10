# Spec T-019a: Nền mỹ thuật pixel và cảnh văn phòng (v2)

Owner: Codex. Người review: Claude. Nhánh nền: `v2`. Nguồn: `shared/style-bible/pixel-office-v2.md` (đọc kỹ), `shared/style-bible/palette-v2.json`, `docs/GDD-v2-concept.md` mục 8, `docs/CONTENT-BIBLE-v2.md` mục 3. Đây là phần đầu của giao diện v2 (T-019 chia thành a, b, c, d; a làm trước).

## Mục tiêu

1. Đường ống tạo và kiểm tra sprite **hoàn toàn bằng GDScript** (Python có thể bị chặn trong sandbox của Codex): sprite được định nghĩa dưới dạng "ảnh chữ" (mỗi ký tự là một chỉ số màu trong bảng 32 màu), một script chạy `--headless` sinh ra PNG, một script khác kiểm tra mọi PNG chỉ dùng đúng 32 màu.
2. Một **cảnh văn phòng** 640x360 hoàn chỉnh bằng các sprite đó: nhân vật đi vào, ngồi vào bàn, đồng nghiệp hoạt động, cửa sổ đổi ánh sáng theo thời điểm trong ngày, hộp thoại.

Chưa làm màn hình máy tính, báo cáo hay vòng chơi (T-019b, c).

## 1. Đường ống sprite

Thư mục (trong `game-studio/godot/`):

```
tools/sprites/*.gd          # định nghĩa sprite dạng ảnh chữ (const), mỗi file một nhóm
tools/gen_sprites.gd        # SceneTree script: đọc định nghĩa, ghi PNG vào assets/v2/
tools/check_palette.gd      # SceneTree script: kiểm tra mọi PNG trong assets/v2/
data/palette_v2.json        # bản sao của shared/style-bible/palette-v2.json
scripts/v2/palette.gd       # nạp bảng màu, cung cấp Color theo chỉ số 1..32
scripts/v2/sprite_lib.gd    # nạp texture (filter nearest), cắt khung hoạt ảnh
assets/v2/*.png             # kết quả sinh ra (commit vào git)
```

- **Định nghĩa sprite:** mảng chuỗi, mỗi ký tự thuộc bảng ánh xạ `0-9a-v` cho chỉ số màu 1 đến 32 theo thứ tự trong `palette-v2.json` (chỉ định ánh xạ rõ trong `palette.gd`), và `.` cho pixel trong suốt hoàn toàn. Ví dụ một nhân vật 16x24 là 24 chuỗi dài 16 ký tự. Nhiều khung hoạt ảnh của một sprite là nhiều mảng, ghép thành một dải ngang trong PNG.
- `gen_sprites.gd` tạo PNG bằng `Image.create`, `set_pixel`; xuất xác định (cùng đầu vào cho cùng byte), tên file ổn định. Chạy lại không đổi file nếu không đổi định nghĩa.
- `check_palette.gd` đọc mọi PNG trong `assets/v2/`; FAIL (thoát mã khác 0, in tên file và tọa độ pixel đầu tiên sai) nếu có pixel không thuộc 32 màu hoặc có alpha khác 0 hoặc 255. Kiểm tra bản sao `data/palette_v2.json` khớp `shared/style-bible/palette-v2.json` (đọc bằng đường dẫn hệ điều hành `res://../../shared/style-bible/palette-v2.json` qua `ProjectSettings.globalize_path`).
- Chạy: `Godot_console --headless --path game-studio/godot -s res://tools/gen_sprites.gd` rồi `... -s res://tools/check_palette.gd`.

## 2. Danh sách sprite (kích thước theo style bible mục 4)

| Sprite | Kích thước (px) | Khung |
|---|---|---|
| Nhân vật người chơi, 3 đồng nghiệp (Anh Khôi, Bé Mai, Chú Tư), sếp (Chị Hạnh) | 16x24 | đứng 2 khung (chớp mắt), đi 4 khung, gõ phím 2 khung (không cần cho sếp) |
| Bàn làm việc kèm màn hình | 48x24 | 1 (màn hình tắt), 1 (màn hình sáng) |
| Ghế | 16x24 | 1 |
| Cây chậu | 16x24 | 2 biến thể |
| Tủ hồ sơ | 24x32 | 1 |
| Cửa sổ tường | 32x32 | 3 (sáng, hoàng hôn, nhiều mây) |
| Cửa phòng sếp | 24x40 | 2 (đóng, mở) |
| Ô tường và sàn | 16x16 | sàn gỗ 1, tường 1, chân tường 1 |
| Đồng hồ treo tường | 16x16 | 1 (kim vẽ bằng mã trong cảnh) |
| Biểu tượng UI (cho T-019b dùng sẵn) | 8x8 | mũi tên lên, xuống, ngang; dấu kiểm; dấu X; dấu hỏi; khóa; khiên; tờ báo; bong bóng thoại; cờ |

Nhân vật khác nhau bằng màu tóc, màu áo (chọn từ bảng) và một phụ kiện nhỏ 1 đến 2 pixel (ví dụ kính, cà vạt). Không vẽ giống người thật. Chất lượng yêu cầu: dễ nhận ra ở scale 1x và 2x, theo ánh sáng từ trên trái (điểm sáng phía trên trái, bóng phía dưới phải bằng màu 3), không viền anti-alias.

## 3. Cảnh văn phòng (`scenes/v2/office.tscn`, `scripts/v2/office.gd`)

- Bố cục 640x360, nhìn ngang: tường phía trên (khoảng 128px) có cửa sổ ở bên trái, đồng hồ, cửa phòng sếp ở bên phải; sàn gỗ bên dưới. Bốn bàn làm việc xếp hàng; bàn của người chơi nổi bật hơn (màn hình sáng, viền sáng 1 pixel màu 21 theo style bible mục 3). Hai cây, một tủ hồ sơ. Phòng sếp nằm ngoài khung nhìn, sếp xuất hiện ở cửa khi cần.
- **Hoạt ảnh:** đồng nghiệp lặp chớp mắt và gõ phím (thời lượng từng khung chỉnh riêng, mặc định 120 ms theo style bible mục 6; khung chạm đất lâu hơn); người chơi đi vào từ cửa trái đến bàn bằng chu kỳ đi 4 khung rồi ngồi xuống.
- **API của `office.gd`:**
  - `set_phase(phase: String)` với `"sang" | "trua" | "chieu"`: đổi khung cửa sổ và mảng sáng trên sàn (chỉ dùng màu trong bảng).
  - `set_clock(hour: int, minute: int)`: kim đồng hồ.
  - `play_arrival()` rồi phát tín hiệu `seated`.
  - `play_boss_appears(line: String)`: sếp xuất hiện ở cửa, hiện hộp thoại, tín hiệu `dialog_closed` khi người chơi bấm hoặc nhấn phím xác nhận.
  - `show_dialog(speaker: String, text: String)` và `hide_dialog()`: hộp thoại code-vẽ (nền màu 2, viền màu 5, chữ màu 8 hoặc 7), ngắt dòng tự động, không tràn khung.
  - Tín hiệu `desk_clicked` khi bấm vào bàn người chơi (hoặc Enter).
- Chữ: dùng font mặc định của Godot với kích thước cơ sở 8 và 12 (chưa có font pixel được duyệt; **không tải font ngoài**). Tiếng Việt phải đúng dấu.
- Mọi hình đều từ `assets/v2/` (sinh bằng mục 1) hoặc vẽ bằng màu trong bảng. Không dùng màu ngoài bảng, không gradient.

## 4. Kiểm thử

`tests/test_v2_assets.gd` (chạy `--headless`):

- `gen_sprites` chạy được và xuất xác định (chạy hai lần cho cùng hash từng file).
- `check_palette`: mọi PNG chỉ dùng 32 màu và alpha 0 hoặc 255; bản sao palette khớp bản ở `shared/`.
- Kích thước từng sprite khớp bảng mục 2 (nhân vật 16x24 mỗi khung, bàn 48x24, v.v.) và dải khung đúng số lượng.
- Cảnh `office.tscn` nạp không lỗi; mọi texture dùng filter nearest; mọi vị trí vẽ là số nguyên.
- Mô phỏng khung hình bằng cách gọi hàm cập nhật: `play_arrival()` kết thúc và phát `seated` trong số khung hợp lý (dưới 600 khung ở 60 FPS); `play_boss_appears` phát `dialog_closed` khi giả lập xác nhận; `set_phase` với ba giá trị không lỗi; giá trị sai bị từ chối.
- Hộp thoại không tràn: với chuỗi dài 300 ký tự tiếng Việt, mọi điều khiển nằm trong 640x360.

Giữ nguyên: `test_sim` (2.623), `test_ui` (134), `test_world`, và `balance_sim` giống hệt trước.

## Ràng buộc

- Không dùng asset, font, âm thanh hay mã tải từ bên ngoài; không gọi mạng. Không logo, thương hiệu, hình người thật.
- Không sửa `scripts/sim/`, `scripts/world/`, `scripts/ui/` (UI v1), `scenes/*.tscn` hiện có, `data/*.json` hiện có (chỉ thêm `data/palette_v2.json`), `shared/`, `docs/`, `media-marketing/`. Không đổi `project.godot` (giữ `run/main_scene` hiện tại).
- Không có Python bắt buộc; mọi công cụ bằng GDScript.

## File được sửa

`game-studio/godot/tools/*`, `game-studio/godot/scripts/v2/*`, `game-studio/godot/scenes/v2/*`, `game-studio/godot/assets/v2/*`, `game-studio/godot/data/palette_v2.json`, `game-studio/godot/tests/test_v2_assets.gd`.

## Bàn giao

Trong `TASKS.md`: file đổi, cách chạy `gen_sprites` và `check_palette`, kết quả kiểm thử, các chỗ tự quyết (ví dụ cách bố trí cảnh, thiết kế nhân vật), và các hạn chế đã biết. Claude sẽ tự chạy cảnh và chụp màn hình để duyệt mỹ thuật; nếu chưa đạt sẽ trả lại kèm nhận xét cụ thể.
