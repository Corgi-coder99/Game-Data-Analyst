# Spec T-007: Landing page trung thực cho Data Corp

Owner: Codex (viết mã). Spec, nội dung và ảnh: Claude. Review: Claude. Quy tắc nội dung: `CLAUDE.md` mục 5 (không bịa số liệu, đánh giá, lời chứng thực; không giả mạo; quảng cáo trung thực, kiểm chứng được).

## Mục tiêu

Một trang tĩnh giới thiệu game Data Corp đúng với bản demo hiện có. Mở trực tiếp bằng file (`index.html`), không cần máy chủ hay thư viện ngoài.

## Sự thật được phép nói (nguồn kiểm chứng được)

| Tuyên bố | Nguồn |
|---|---|
| Game chiến thuật nhẹ dạng thẻ bài và dashboard, người chơi là Lead Data Analyst của một startup sắp cạn tiền | `game-studio/godot/docs/GDD.md` mục 1 |
| Một ván demo dài 10 tuần | `data/config.json` (`weeks.demo`) |
| 12 thẻ quyết định, 8 sự kiện ngẫu nhiên, 7 chỉ số trên dashboard | `data/cards.json`, `data/events.json`, `game_controller.gd` |
| Số liệu trên dashboard có thể sai khi Data Integrity thấp | GDD mục 3 |
| Mỗi sự kiện có nguyên nhân gốc ẩn, phải dùng thẻ phân tích để lộ ra | GDD mục 6 |
| Màn kết thúc so số thật với số người chơi đã thấy | `end_screen.gd` |
| Đang phát triển, chưa phát hành | thực trạng |

Con số 10, 12, 8, 7 phải được `check_web.py` đối chiếu tự động với các file nguồn.

## Cấm tuyệt đối

Số người đăng ký, người chơi, lượt tải, đánh giá sao, lời chứng thực, tên người chơi, bảng xếp hạng, đồng hồ đếm ngược, cụm "đầu tiên", "hàng đầu", "số 1", "miễn phí" (chưa có bản phát hành), "chơi ngay", "tải ngay", "30+ case study", "5 công ty", "SQL thật" (chưa làm), logo hay tên thương hiệu của bên khác, `© … All rights reserved` kiểu hãng. Không có form thu email trong bản này (chưa có nơi lưu hợp pháp và thông báo quyền riêng tư).

## Cấu trúc trang (một trang, các mục theo thứ tự)

1. **Thanh đầu:** tên "Data Corp (tên tạm)", liên kết neo tới các mục.
2. **Hero:** tiêu đề do Claude viết dưới đây, một câu mô tả, nhãn trạng thái "Đang phát triển. Chưa phát hành.", nút "Xem gameplay" cuộn xuống mục 4.
3. **Vòng chơi mỗi tuần:** 4 bước ngắn (xem báo cáo, đọc sự kiện, chơi thẻ, kết thúc tuần xem kết quả).
4. **Gameplay:** ảnh `assets/gameplay-dashboard.png` (ảnh chụp thật từ bản demo) kèm chú thích "Ảnh chụp từ bản demo đang phát triển" và `alt` mô tả đúng nội dung (tuần 4/10, sự kiện có nguyên nhân đã lộ, biểu đồ Users). Hiển thị không làm mờ pixel (`image-rendering: pixelated`) và không phóng quá 2 lần kích thước gốc.
5. **Điểm khác biệt:** hai khối ngắn: "Dữ liệu có thể sai" (Data Integrity) và "Triệu chứng không phải nguyên nhân" (sự kiện, thẻ phân tích).
6. **Con số của bản demo:** dải 4 số (10 tuần, 12 thẻ, 8 sự kiện, 7 chỉ số), mỗi số có dòng "theo bản demo hiện tại".
7. **Tình trạng dự án:** hai cột "Đã có" (vòng chơi 10 tuần, dashboard, sự kiện và thẻ, màn kết thúc) và "Chưa có" (bản chơi trên web, bảng xếp hạng, nhiều công ty, phát hành). Khối này bắt buộc để quảng cáo trung thực.
8. **Theo dõi dự án:** đoạn chữ "Chưa mở đăng ký. Liên kết trang phát hành sẽ đặt ở đây khi có." Không có ô nhập.
9. **Chân trang:** "Dự án đang phát triển. Một phần nội dung và mã được tạo với hỗ trợ của AI." Không dùng ký hiệu bản quyền kiểu hãng.

## Nội dung chữ (Codex dùng nguyên văn, không sáng tác thêm tuyên bố)

- Tiêu đề: **Đọc dữ liệu. Tìm nguyên nhân. Cứu startup.**
- Mô tả: Data Corp là game chiến thuật nhẹ: bạn là Lead Data Analyst của một startup sắp cạn tiền. Mỗi tuần, bạn đọc dashboard, tìm nguyên nhân gốc của vấn đề và chọn thẻ hành động. Nhưng số liệu bạn thấy không phải lúc nào cũng đúng.
- Bốn bước vòng chơi: "Đọc báo cáo tuần: Users, Retention, Conversion, CAC, ARPU, LTV/CAC, Data Integrity." / "Xem sự kiện: bạn thấy triệu chứng, chưa chắc thấy nguyên nhân." / "Chơi thẻ: mỗi tuần có 3 Energy và tay 4 thẻ, mỗi thẻ tốn Budget." / "Kết thúc tuần: xem kết quả, rồi đối chiếu số thật ở cuối ván."
- Khối "Dữ liệu có thể sai": Khi Data Integrity giảm, các chỉ số trên dashboard bị nhiễu. Có lúc một chỉ số trông rất xấu chỉ vì dữ liệu lỗi, không phải vì công ty có vấn đề.
- Khối "Triệu chứng không phải nguyên nhân": Retention tụt có thể do lỗi ứng dụng, đối thủ giảm giá hoặc log trùng. Thẻ phân tích giúp lộ nguyên nhân, và mỗi nguyên nhân cần một cách xử lý khác nhau.

Nếu cần câu chữ khác, ghi vào bàn giao để Claude duyệt, không tự thêm tuyên bố mới.

## Kỹ thuật

- File: `media-marketing/web/index.html`, `media-marketing/web/style.css`, `media-marketing/web/check_web.py`. Ảnh đã có sẵn ở `media-marketing/web/assets/` (Claude sở hữu, Codex chỉ đọc).
- HTML và CSS thuần. Không dùng CDN, Tailwind CDN, font ngoài, ảnh ngoài, script theo dõi, `<script>` từ nguồn khác. Có thể không cần JavaScript.
- Font hệ thống (system font stack). Giao diện tối, màu lấy theo game: nền `#18202b`, chữ `#eef2f6`, nhấn `#334b62` (có thể thêm 1 đến 2 màu nhấn phụ, tương phản chữ/nền đạt WCAG AA).
- Responsive từ 360px đến 1440px, không cuộn ngang. Tôn trọng `prefers-reduced-motion`. Có `lang="vi"`, các vùng ngữ nghĩa (`header`, `main`, `section`, `footer`), tiêu đề phân cấp đúng, liên kết bàn phím truy cập được.
- Thẻ `<title>`, `meta description`, `og:title`, `og:description` (không đặt `og:image` trỏ URL ngoài).

## Kiểm thử (`check_web.py`, chỉ dùng thư viện chuẩn của Python, chạy bằng `.venv`)

Script phải kiểm tra và in từng mục PASS/FAIL, thoát mã khác 0 nếu có FAIL:
1. Không có `http://` hoặc `https://` trong `src`, `href` của tài nguyên (liên kết `#neo` nội bộ thì được).
2. Có đủ 9 mục theo cấu trúc (qua `id` hoặc tiêu đề).
3. Ảnh trong `<img>` tồn tại trên đĩa, có `alt` không rỗng.
4. Các con số 10, 12, 8, 7 khớp với: `weeks.demo` trong `config.json`, số thẻ trong `cards.json`, số sự kiện trong `events.json`, số ô chỉ số (7) trong `game_controller.gd` hoặc `strings.json`.
5. Không chứa các cụm cấm ở mục "Cấm tuyệt đối" (không phân biệt hoa thường), không có thẻ `<form>`, `<input>`.
6. Có `lang="vi"`, `<title>`, `meta description`.

## File được sửa

`media-marketing/web/index.html`, `media-marketing/web/style.css`, `media-marketing/web/check_web.py`. Không sửa `assets/`, `game-studio/`, `CLAUDE.md`.

## Tiêu chí hoàn thành

- `check_web.py` toàn PASS.
- Mở `index.html` bằng trình duyệt: hiển thị đúng ở 360px và 1280px, không lỗi console. (Claude sẽ tự kiểm tra bằng trình duyệt khi review, Codex không cần chụp ảnh.)
- Ghi chú bàn giao trong TASKS.md theo mẫu, nêu rõ chỗ nào Codex tự quyết.
