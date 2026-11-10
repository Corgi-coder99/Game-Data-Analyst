# Content bible: Data Corp v2

Phiên bản 0.1, 2026-11-10. Owner: Claude. Nguồn thiết kế: `docs/GDD-v2-concept.md`. Dữ liệu máy đọc: `data/news.json` (41 mẫu tin, 10 nguồn). **Tất cả tên, tổ chức, mã chứng khoán và số liệu trong game đều hư cấu.** Không dùng tên công ty, thương hiệu, nhân vật hay sự kiện có thật.

## 1. Thế giới

Nước **Cộng hòa Tân Lạc** (hư cấu), tiền tệ **đồng lạc**. Thế giới đang trong một **cuộc khủng hoảng tín dụng chung chung**: lãi suất tăng, tín dụng thắt chặt, đồng lạc mất giá, sức mua giảm. Không gắn với quốc gia, năm hay biến cố có thật. Chỉ số chứng khoán chính là **TLX-30**. Hai mã minh họa: **LCD** (một công ty phân phối nhỏ), **BMT** (một công ty vật liệu). Cả hai hư cấu.

## 2. Công ty

**Công ty Phân phối Lục Châu** (hư cấu): nhập khẩu và phân phối hàng gia dụng (đồ nhựa, dụng cụ kim loại) cho đại lý bán lẻ. Quy mô vừa và nhỏ, vay ngân hàng để nhập hàng, bán chịu cho đại lý.

Ý nghĩa các chỉ số trong game:

| Chỉ số (đã có trong mô phỏng) | Trong bối cảnh Lục Châu |
|---|---|
| Users | Đại lý đang hoạt động |
| Retention | Tỷ lệ đại lý giữ lại mỗi tuần |
| Conversion | Tỷ lệ đơn hàng chốt được |
| CAC | Chi phí để có thêm một đại lý |
| ARPU | Doanh thu bình quân mỗi đại lý mỗi tuần |
| LTV/CAC | Giá trị một đại lý so với chi phí có được họ |
| Data Integrity | Độ sạch của dữ liệu nội bộ (bảng số liệu, báo cáo tuần) |
| Cash | Tiền mặt của công ty |

Công ty nhạy với: **lãi suất** (chi phí vay), **tỷ giá** (hàng nhập khẩu đắt lên), **giá nguyên liệu** (giá vốn), **sức mua** (nhu cầu đại lý), **tín dụng** (khả năng vay thêm), và **chứng khoán** chỉ là chỉ báo tâm lý (công ty không niêm yết).

## 3. Nhân vật

| Vai | Tên | Tính cách ngắn gọn |
|---|---|---|
| Sếp, Giám đốc Tài chính | **Chị Hạnh** | Thẳng, ít lời, ghét bị đưa số mà không có căn cứ; thưởng người nói rõ mức chắc chắn |
| Kế toán trưởng | **Anh Khôi** | Cẩn thận, hay nghi ngờ số liệu, nhắc người chơi đối chiếu sổ sách |
| Thực tập sinh | **Bé Mai** | Hào hứng, hay đọc tin đồn trên mạng xã hội rồi kể lại (nguồn gợi tin sai và tin đúng một phần) |
| Nhân viên kho, bảo vệ | **Chú Tư** | Nói chuyện đời thường, đôi khi báo trước vấn đề nội bộ |
| Người chơi | **Bạn** (đặt được tên) | Nhân viên phân tích, bắt đầu ở bậc Thực tập |

Tên chỉ là tên chung, không nhằm vào người thật. Nếu trùng người thật ngoài ý muốn thì đổi.

## 4. Nguồn tin (10 nguồn, xem `data/news.json`)

| Loại | Nguồn (hư cấu) | Độ tin cậy | Trễ |
|---|---|---:|---:|
| Chính thức | Cục Thống kê Tân Lạc | 0,95 | 2 ngày |
| Chính thức | Ngân hàng Trung ương Tân Lạc | 0,97 | 0 |
| Chính thức | Sở Giao dịch Tân Lạc | 0,97 | 0 |
| Báo chí | Nhật báo Tân Lạc | 0,82 | 1 ngày |
| Báo chí | Bản tin Tài chính Sáng | 0,80 | 0 |
| Báo chí | Hãng tin Đại Dương | 0,85 | 1 ngày |
| Mạng xã hội | Diễn đàn Nhà đầu tư Ẩn danh | 0,40 | 0 |
| Mạng xã hội | Mạng Tám Chuyện | 0,45 | 0 |
| Nội bộ | Tin nội bộ (nặc danh) | 0,35 | 0 |
| Nội bộ | Đồng nghiệp trong công ty | 0,60 | 0 |

Độ tin cậy là xác suất tham khảo để phát sinh tin sai, **người chơi không thấy con số này**. Người chơi chỉ thấy loại nguồn (chip) và phải tự học qua trải nghiệm, kèm các công cụ kiểm chứng.

## 5. Nhãn "kind" và "truth" của tin

| kind | truth | Ý nghĩa |
|---|---|---|
| signal | dung | Phản ánh đúng trạng thái hoặc cú sốc thật |
| trap | sai | Sai hoặc phóng đại, dễ gây hiểu lầm |
| partial | mot_phan | Đúng một phần (hướng đúng, độ lớn sai, hoặc thiếu ngữ cảnh) |
| stale | cu | Đúng nhưng đã cũ so với tình hình hiện tại |
| noise | khong_lien_quan | Không liên quan tới công ty |

Mỗi ván phải có đủ cả năm kind. Tỷ lệ gợi ý khi phát sinh tin mỗi ngày: signal khoảng 45%, trap 17%, partial 10%, stale 10%, noise 15% (Codex chỉnh bằng mô phỏng, giữ trong khoảng nửa này).

## 6. Biến trạng thái thế giới (ẩn)

`lai_suat`, `ty_gia`, `nguyen_lieu`, `suc_mua`, `chung_khoan`, `tin_dung`. Mỗi biến có giá trị theo ngày (tăng, giảm, ngang, kèm độ lớn). Tin có `link: "state:<biến>"` phản ánh biến đó. Công ty chịu tác động qua mô phỏng hiện có (ví dụ lãi suất tăng làm chi phí cố định tăng, tỷ giá tăng làm giá vốn tăng, sức mua giảm làm Conversion và Retention giảm). Hệ số cụ thể do spec T-018 quy định.

## 7. Cú sốc: ánh xạ 8 sự kiện hiện có

| Sự kiện (id đã có) | Triệu chứng trên dashboard | Nguyên nhân thật (bối cảnh Lục Châu) | Tin gợi ý (id trong news.json) | Cách xử lý (thẻ đã có) |
|---|---|---|---|---|
| `app_bug` | Retention giảm ở đại lý mới | Cổng đặt hàng lỗi khi mở lần đầu | `noi_bo_cong_dat_hang_loi` | Onboarding Redesign |
| `competitor_discount` | Retention giảm ở nhóm nhạy giá | Đối thủ nhập hàng rẻ hơn (tỷ giá) và giảm giá | `suc_mua_doi_thu_giam_gia`, `suc_mua_giam_gia_quang_cao` | Loyalty, Giảm giá |
| `logging_error` | Dashboard báo Retention giảm | Báo cáo tuần có dòng trùng, số thật không đổi | `noi_bo_bang_so_trung` | Clean Data |
| `checkout_outage` | Conversion giảm | Đối tác thanh toán sự cố | `tin_dung_bao_tri_thanh_toan` | Fix Checkout Bug |
| `server_outage` | Users và Conversion giảm | Hệ thống kho quá tải giờ cao điểm | `noi_bo_kho_cham` | Support Automation |
| `trend_shift` | CAC tăng | Sức mua chuyển sang hàng thiết yếu | `suc_mua_thiet_yeu` | SEO Content |
| `bad_traffic` | Retention giảm sau chiến dịch | Chiến dịch quảng cáo nhắm sai đối tượng | `noi_bo_quang_cao_it_don` | Onboarding Redesign |
| `price_fatigue` | Conversion giảm | Giá nguyên liệu tăng kéo giá bán tăng, khách ngán | `suc_mua_khach_phan_nan_gia`, `nguyen_lieu_nhua_thep_tang` | Giảm giá, Loyalty |

Bản mở rộng sau demo có thể thêm cú sốc vĩ mô thuần túy (ví dụ lãi suất tăng đột ngột) nhưng demo chỉ dùng 8 cú sốc trên để không đổi mô phỏng cốt lõi.

## 8. Công cụ phân tích (đổi tên từ thẻ phân tích)

| Id công cụ | Thẻ hiện có | Tên hiển thị | Tác dụng |
|---|---|---|---|
| `truy_van_lich_su` | SQL Deep-Dive | Truy vấn dữ liệu lịch sử | Xem chuỗi giá và chỉ số quá khứ, lộ nguyên nhân nội bộ |
| `kiem_dinh_gia_thuyet` | A/B Test | Kiểm định giả thuyết | Giảm nhiễu dự báo, lộ nguyên nhân xu hướng và giá |
| `doi_chieu_nguon` | Funnel Report | Đối chiếu nguồn tin | So hai nguồn, cho biết tin được xác nhận, bác bỏ, hay chưa đủ căn cứ |
| `lam_sach_du_lieu` | Clean Data | Làm sạch dữ liệu | Tăng độ sạch của dữ liệu nội bộ, lọc dòng trùng |

Hành động đề xuất cho sếp dùng lại 8 thẻ còn lại, đổi tên theo ngữ cảnh: Fix Checkout Bug thành "Siết thu hồi công nợ qua cổng thanh toán", Onboarding Redesign thành "Cải tiến quy trình đặt hàng cho đại lý mới", Ads Campaign thành "Chi marketing tìm đại lý", Influencer Campaign thành "Hợp tác kênh phân phối lớn", Loyalty Program thành "Chương trình giữ chân đại lý", SEO Content thành "Nội dung và kênh bán lẻ trực tuyến", Support Automation thành "Tự động hóa kho và chăm sóc", Giảm giá thành "Khuyến mãi tạm thời". Tên thật dùng trong `data/strings.json` (Codex).

## 9. Câu hỏi trong ngày của sếp (mẫu cho demo 10 ngày)

1. Giá nguyên liệu nhập khẩu tuần này sẽ tăng, giảm hay đi ngang?
2. Có nên nhập thêm một lô hàng lớn trước khi tỷ giá tăng nữa không?
3. Lãi suất vay doanh nghiệp tuần tới sẽ đổi hướng thế nào?
4. Sức mua hàng gia dụng quý này sẽ hồi phục hay tiếp tục giảm?
5. Đối thủ giảm giá có đáng lo không, hay chỉ là quảng cáo?
6. Ngân hàng đối tác có đáng tin để dồn khoản thanh toán lớn không?
7. Chúng ta có nên dùng khoản dự phòng cho chiến dịch bán hàng không?
8. Số liệu báo cáo tuần có đáng tin để trình lên ban giám đốc không?
9. Tin đồn về một ngân hàng sắp sụp có cần hành động ngay không?
10. Nhìn lại cả đợt: công ty nên giữ tiền mặt hay đầu tư kho?

Câu hỏi nào cũng có đáp án định trước theo kịch bản thế giới của ván (Codex sinh ra từ seed).

## 10. Giọng điệu và lời thoại mẫu

Ngắn, đời thường, hơi châm biếm nhẹ, không hù dọa, không phán xét.

- Chị Hạnh khi báo cáo tốt: "Tốt. Lần sau cứ nói rõ mức chắc chắn như vậy."
- Khi sai nhưng đã tự tin thấp: "Sai, nhưng cô đã báo trước là chưa chắc. Tôi ghi nhận."
- Khi sai và tự tin cao: "Cô nói chắc chắn. Giờ công ty đang trả giá cho điều đó."
- Cảnh cáo: "Đây là cảnh cáo thứ hai. Tôi cần thấy bằng chứng trong báo cáo, không phải cảm giác."
- Thăng chức: "Từ tuần sau cô lên Chuyên viên. Đừng làm tôi hối hận."
- Đuổi việc: "Tôi tiếc, nhưng công ty không đứng vững được nếu tiếp tục như vậy."
- Anh Khôi: "Số này khớp sổ sách chưa? Anh thấy có hai dòng trùng."
- Bé Mai: "Trên Tám Chuyện người ta bảo giá nhựa sắp gấp đôi đấy chị!"
- Chú Tư: "Kho hôm nay chậm lắm, máy tính cứ đơ giờ nhập hàng."

## 11. Cấm

- Tên công ty, ngân hàng, cơ quan, báo, người nổi tiếng, sự kiện kinh tế có thật.
- Số liệu thị trường thật. Mọi số là do mô phỏng sinh ra.
- Lời khuyên đầu tư thật, hướng dẫn giao dịch thật, tiền thật trong game.
- Nội dung chính trị, tôn giáo, kích động hoặc phân biệt đối xử.
- Thông điệp gợi ý rằng tin đồn trên mạng xã hội luôn sai: có tin đúng trên mọi loại nguồn, để người chơi phải kiểm chứng thay vì dựa vào quy tắc cứng.

## 12. Dòng chú thích bắt buộc trong game và trang giới thiệu

"Dữ liệu và tên trong game là hư cấu, do mô phỏng sinh ra. Không phải dữ liệu thị trường thật và không phải lời khuyên đầu tư. Một phần nội dung và mã được tạo với hỗ trợ của AI."
