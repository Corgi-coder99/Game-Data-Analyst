# Style bible: Data Corp v2 (văn phòng pixel)

Phiên bản 0.1, 2026-11-10. Owner: Claude. Áp dụng cho game Data Corp v2 (`game-studio/godot`, nhánh `v2`). Đây là style bible riêng của game này: bảng màu 32 màu không dùng chung với bảng 47 màu "Hoàng kim chiến quốc" nhắc trong CLAUDE.md mục 4 (xem "Lưu ý về CLAUDE.md" cuối file).

Nguyên tắc nguồn: mọi sprite do ta tạo bằng mã (script sinh ảnh hoặc vẽ trong Godot), không dùng asset ngoài. Vì vậy mọi hình phải đơn giản, theo khối, dựng được bằng chữ nhật, đường thẳng và vài pixel chi tiết.

## 1. Màn hình và lưới

- Viewport 640x360, scale nguyên (đã cấu hình), nearest filter, không làm mờ, không xoay hình bằng góc lẻ.
- Lưới cơ sở 8x8 pixel. Mọi vật thể căn theo lưới 8 (chi tiết nhỏ được lệch 1 pixel).
- Tọa độ vẽ luôn là số nguyên. Cấm animation vị trí dưới pixel.

## 2. Bảng màu khóa (32 màu)

Mọi pixel trong asset phải thuộc bảng này. Có kiểm tra tự động (mục 8).

| # | Hex | Dùng cho |
|---|---|---|
| 1 | `#12161d` | nền tối nhất, viền ngoài |
| 2 | `#1b222c` | nền cửa sổ, tường tối |
| 3 | `#28313e` | bóng đổ, mặt bàn tối |
| 4 | `#3a4658` | khung UI, đồ vật tối |
| 5 | `#566377` | viền UI, kim loại |
| 6 | `#7d8a9c` | chữ phụ, đường kẻ |
| 7 | `#a9b4c2` | chữ thường, đồ vật sáng |
| 8 | `#e8edf2` | chữ nhấn, điểm sáng |
| 9 | `#3b2a22` | gỗ tối |
| 10 | `#5c4033` | gỗ vừa |
| 11 | `#8a6446` | gỗ sáng, sàn |
| 12 | `#b58b5e` | bàn, ghế |
| 13 | `#d9b98a` | sàn sáng, giấy |
| 14 | `#efe0c0` | tờ giấy, ánh nắng |
| 15 | `#6f7f5c` | cây xanh tối |
| 16 | `#9db27a` | cây xanh sáng |
| 17 | `#0f2a44` | nền màn hình máy tính |
| 18 | `#1d4f7a` | thanh tiêu đề cửa sổ |
| 19 | `#2f7bb5` | nút, liên kết |
| 20 | `#5aa9e0` | đường biểu đồ, tiêu điểm |
| 21 | `#9bd3f2` | nhấn sáng của màn hình |
| 22 | `#d4f0fb` | chữ trên màn hình tối |
| 23 | `#2e8b57` | tăng, tốt (tối) |
| 24 | `#57c27a` | tăng, tốt (sáng) |
| 25 | `#a63a3a` | giảm, xấu (tối) |
| 26 | `#e05d5d` | giảm, xấu (sáng) |
| 27 | `#c58a1c` | cảnh báo (tối) |
| 28 | `#f0b84a` | cảnh báo (sáng) |
| 29 | `#6a4c93` | tin đồn, mạng xã hội (tối) |
| 30 | `#a07fd1` | tin đồn, mạng xã hội (sáng) |
| 31 | `#c98b6b` | da (tối) |
| 32 | `#f1c4a1` | da (sáng) |

Ý nghĩa màu cố định (không dùng sai mục đích): xanh lá = tăng/tốt, đỏ = giảm/xấu, vàng = cảnh báo/chưa chắc, tím = nguồn tin đồn hoặc chưa kiểm chứng, xanh dương = thông tin trung tính/chính thức. Không bao giờ chỉ dùng màu để truyền nghĩa: luôn kèm biểu tượng hoặc chữ (mũi tên lên/xuống, nhãn nguồn).

## 3. Ánh sáng

- Nguồn sáng chính từ trên trái (cửa sổ văn phòng ở tường trái). Bóng đổ rơi xuống dưới phải, dùng màu 3 (`#28313e`) trên nền sàn, không dùng đen thuần.
- Màn hình máy tính tự phát sáng: viền sáng màu 21 quanh mép màn hình lên mặt bàn và tay nhân vật (1 pixel).
- Buổi sáng, trưa, chiều đổi bằng cách thay mảng sáng ở cửa sổ giữa ba tông cố định (màu 14, 28, 20 cho sáng/hoàng hôn/trời nhiều mây), không đổi bảng màu toàn cảnh.

## 4. Kích thước sprite chuẩn

| Vật thể | Kích thước (px) | Ghi chú |
|---|---|---|
| Nhân vật | 16x24 | đầu 8x8, thân 8x12, chân 8x4; 4 hướng không cần, chỉ nhìn ngang trái/phải |
| Bàn làm việc | 48x24 | kèm màn hình 16x16 trên bàn |
| Ghế | 16x24 | |
| Cây chậu | 16x24 | 2 biến thể |
| Tủ hồ sơ | 24x32 | |
| Cửa sổ tường | 32x32 | khung với 3 trạng thái ánh sáng (mục 3) |
| Tường, sàn | ô 16x16 lặp | sàn gỗ, tường tối |
| Biểu tượng UI | 8x8 hoặc 16x16 | mũi tên, nguồn tin, khóa, cờ, dấu kiểm, dấu hỏi |

Nhân vật chính và đồng nghiệp khác nhau bằng màu tóc, áo (dùng màu từ bảng) và phụ kiện nhỏ 1 đến 2 pixel. Không vẽ nhân vật giống người thật.

## 4b. Phân cảnh

- **Văn phòng chung (nền):** nhìn ngang, 4 bàn, 1 bàn người chơi nổi bật hơn (màn hình sáng). Phòng sếp bên phải qua cánh cửa. Cây, tủ hồ sơ, đồng hồ treo tường (làm đồng hồ đếm giờ trong ngày).
- **Màn hình máy tính:** phóng cảnh (zoom) vào màn hình khi người chơi ngồi vào bàn. Toàn bộ vùng nhìn là giao diện máy tính giả lập (mục 5).
- **Họp cuối ngày:** nhân vật người chơi và sếp đối diện qua bàn, hộp thoại ở dưới.

## 5. Giao diện "máy tính" (cửa sổ trong game)

- Nền desktop màu 17. Thanh tác vụ cao 16px, màu 2, đồng hồ góc phải (màu 22).
- Cửa sổ: viền 1px màu 5, thanh tiêu đề cao 12px màu 18, chữ tiêu đề màu 22. Nút đóng/thu nhỏ vuông 8x8.
- Mỗi nguồn tin có "chip" nhỏ theo loại: chính thức (xanh dương, biểu tượng khiên), báo chí (xám xanh, biểu tượng tờ báo), mạng xã hội (tím, biểu tượng bong bóng thoại), nội bộ (vàng, biểu tượng khóa). Tin đã kiểm chứng thêm dấu kiểm xanh lá; bị bác bỏ thêm dấu X đỏ; chưa đủ căn cứ thêm dấu hỏi vàng.
- Bảng giá: số tăng màu 24 kèm mũi tên lên, giảm màu 26 kèm mũi tên xuống, không đổi màu 7 kèm gạch ngang.
- Biểu đồ: đường dày 1px màu 20, lưới màu 3, trục màu 6, không có gradient. Điểm cuối nổi bật bằng ô 3x3 màu 21.
- Chữ: font pixel có giấy phép rõ (OFL) hỗ trợ tiếng Việt có dấu, cỡ cơ sở 8px và 12px, căn lưới. Chỉ dùng font ghi nguồn và giấy phép trong `assets/CREDITS.md`.

## 6. Hoạt ảnh

- Tối đa 4 khung cho chu kỳ đi bộ, 2 khung cho gõ phím, 2 khung cho chớp mắt. Thời lượng từng khung chỉnh riêng (mặc định 120ms; khung chạm đất lâu hơn).
- Hiệu ứng nhẹ: tin mới về nhấp nháy viền 2 lần; thưởng/phạt bật số nổi lên 12px rồi tan sau 600ms; thăng chức có dải ánh sáng quét ngang 400ms (màu 28 và 14). Không có rung màn hình.
- Chuyển cảnh: mờ dần bằng lớp màu 1 với độ trong suốt bước 25%, tối đa 300ms.

## 7. Cấm

- Dùng màu ngoài bảng, gradient, mờ viền (anti-alias), pixel bán trong suốt trong sprite.
- Dùng logo, thương hiệu, nhân vật hoặc biểu tượng có bản quyền. Tên và logo công ty trong game là hư cấu, tự thiết kế.
- Phông chữ chưa rõ giấy phép.

## 8. Kiểm tra tự động (việc của Codex khi làm T-019)

Công cụ `tools/check_palette.py` (chỉ thư viện chuẩn hoặc Pillow nếu đã có trong `.venv`; nếu chưa có thì viết bộ đọc PNG đơn giản): với mỗi PNG trong `assets/`, báo FAIL nếu có pixel không thuộc 32 màu trên hoặc có pixel bán trong suốt (ngoài alpha 0 hoàn toàn). Sprite sinh bằng mã phải đi qua bước này trước khi nhập vào dự án.

Bảng màu máy đọc: `shared/style-bible/palette-v2.json` (32 màu theo thứ tự trên).

## 9. Checklist asset (QA)

- [ ] Kích thước đúng bảng mục 4 và căn lưới 8.
- [ ] Chỉ dùng 32 màu, không bán trong suốt.
- [ ] Ánh sáng từ trên trái, bóng đổ màu 3.
- [ ] Đọc rõ ở scale 1x và 2x.
- [ ] Màu giữ đúng ý nghĩa (mục 2), có biểu tượng hoặc chữ đi kèm.
- [ ] Không chứa hình ảnh hoặc tên thật.

## Lưu ý về CLAUDE.md

CLAUDE.md mục 4 yêu cầu mỹ thuật game tuân theo "style bible tại shared/style-bible (hướng B Hoàng kim chiến quốc: bảng màu 47 màu, nền 640x360, ...)". Style bible đó chưa từng được tạo, và chủ đề chiến quốc không hợp game công sở này. File này giữ các nguyên tắc chung (640x360 scale nguyên, hướng sáng trên trái, thời lượng từng khung chỉnh riêng, kiểm tra bảng màu trước khi nhập) nhưng dùng bảng 32 màu riêng. Cần VU quyết định có sửa CLAUDE.md để ghi nhận ngoại lệ này không; mình chưa sửa CLAUDE.md.
