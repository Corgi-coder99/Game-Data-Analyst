# Cách chơi bản demo v2 (nhánh `v2`)

Tình trạng: demo 10 ngày chơi được từ màn tiêu đề đến kết thúc. Mỹ thuật là sprite viết bằng mã (đơn giản), font mặc định của Godot. Số liệu và tên trong game đều hư cấu.

## Chạy

Cần Godot 4.7. Từ thư mục dự án:

```bash
D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe --path D:\Dev\ai-company\game-studio\godot res://scenes/v2/main_v2.tscn
```

Thêm `-- --seed=7` để cố định kịch bản. Cũng có thể mở thư mục `game-studio/godot` bằng editor Godot rồi chạy cảnh `scenes/v2/main_v2.tscn`. (Bản dashboard cũ vẫn là cảnh mặc định của dự án, gắn tag `demo-dashboard-v1` trên `master`.)

Nhánh git: `v2`. Chưa merge vào `master`.

## Cách chơi

1. **Mỗi ngày** sếp (chị Hạnh) hỏi một câu, ví dụ giá nguyên liệu sẽ tăng, giảm hay đi ngang.
2. **Màn hình máy tính:**
   - Cửa sổ **Tin tức**: đọc tin. Màu chip cho biết loại nguồn (chính thức, báo chí, mạng xã hội, nội bộ). Nguồn nào cũng có thể đúng hoặc sai.
   - Cửa sổ **Công cụ kiểm chứng**: chọn một tin rồi bấm "Dùng". Mỗi ngày có 3 Energy phân tích, mỗi lần tốn 1, nên không kiểm chứng được hết. Kết quả: xác nhận, bác bỏ, chưa đủ căn cứ, hoặc tin đã cũ.
   - Bấm cờ để **ghim tối đa 3 tin** làm bằng chứng.
   - Cửa sổ **Công ty**: Cash và 7 chỉ số (có thể bị nhiễu khi dữ liệu bẩn).
   - Tab **Báo cáo**: chọn dự báo, mức tự tin, hành động đề xuất (tối đa theo chức vụ), rồi Nộp.
3. **Họp cuối ngày:** sự thật được công bố: tin nào đúng, sai, cũ, nhiễu, nguyên nhân thật của cú sốc, sếp có làm theo đề xuất không, thưởng, thăng chức, cảnh cáo, giáng chức hoặc đuổi việc.
4. Kết thúc sau 10 ngày, hoặc sớm hơn nếu bị đuổi hoặc công ty hết tiền.

Mẹo: tự tin cao mà sai bị phạt nặng; tự tin thấp mà đúng thưởng ít. Dẫn tin chưa kiểm chứng hoặc đã bị bác bỏ làm bằng chứng sẽ bị trừ điểm.

## Phím

- Chuột là chính. **Enter hoặc Space** qua bước ở hộp thoại, họp cuối ngày, tiêu đề; **Esc** bỏ qua hoạt ảnh; **mũi tên lên xuống** chọn tin, Enter chọn.

## Kiểm thử

```bash
D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\Dev\ai-company\game-studio\godot -s res://tests/test_v2_flow.gd
D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --path D:\Dev\ai-company\game-studio\godot -s res://tests/test_v2_screens_render.gd
```

(Bộ kiểm thử bố cục `*_render` chạy **không** headless vì cần đo kích thước thật.)

## Chưa có

Âm thanh, font pixel, nhiều công ty, ván 30 ngày trong giao diện (lõi đã hỗ trợ), lưu tiến trình, bảng xếp hạng, hiệu ứng nâng cao (T-019d).
