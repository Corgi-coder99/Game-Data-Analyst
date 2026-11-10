# GDD: Data Corp (tên tạm)

Phiên bản 0.2, 2026-11-10. Owner: Claude (thiết kế). Số liệu khớp `data/config.json` sau T-012 (cập nhật các mục 3, 4, 6, 7, 8, 10). Giá trị thật luôn lấy từ `data/`; khi lệch, `data/` đúng.

## 1. Tóm tắt

Game chiến thuật nhẹ, chơi một mình, dạng thẻ bài + dashboard. Người chơi là Lead Data Analyst của một startup sắp cạn tiền. Mỗi tuần đọc dashboard, tìm nguyên nhân gốc của vấn đề, dùng thẻ quyết định để xử lý. Sống sót và tăng trưởng qua 30 tuần.

Đối tượng: dân IT, Data Analyst, marketing, sinh viên kinh tế. Một ván 10 đến 15 phút (10 tuần cho bản demo).

Mục tiêu học: phân biệt triệu chứng với nguyên nhân, đọc LTV/CAC, churn, conversion, tin dữ liệu đúng mức.

## 2. Vòng chơi (mỗi tuần)

1. **Báo cáo:** dashboard hiện các chỉ số và 1 biểu đồ (funnel, cohort hoặc time series).
2. **Sự kiện:** 1 sự kiện ngẫu nhiên có thể gây nhiễu (đối thủ giảm giá, server sập, đổi xu hướng).
3. **Rút thẻ:** rút 4 thẻ từ bộ bài. Có 3 Data Energy mỗi tuần để chơi thẻ.
4. **Chọn hành động:** chơi thẻ tốn Budget và Energy.
5. **Kết quả:** mô phỏng 1 tuần, cập nhật chỉ số, hiện chênh lệch so với dự đoán.

## 3. Chỉ số

| Chỉ số | Ý nghĩa | Khởi điểm |
|---|---|---|
| Cash | Tiền mặt. Về 0 là thua | 18,000 |
| Users | Người dùng hoạt động | 1,000 |
| ARPU | Doanh thu mỗi user mỗi tuần | 24 |
| Conversion | Tỷ lệ user trả tiền (trần 8%) | 1% |
| Retention | Tỷ lệ giữ lại mỗi tuần, Churn = 1 - Retention (trần 95%) | 85% |
| CAC | Chi phí mua 1 user mới | 80 |
| LTV | ARPU x thời gian sống trung bình (1 / Churn) | tính ra |
| LTV/CAC | Mục tiêu từ 3 trở lên | tính ra |
| Data Integrity | Độ tin cậy dữ liệu, 0 đến 100 | 80 |

Data Integrity thấp thì biểu đồ hiện số nhiễu (sai số tăng theo mức thấp). Thẻ Clean Data phục hồi chỉ số này.

## 4. Mô hình kinh tế mỗi tuần

```
new_users   = ad_spend / CAC_hieu_dung
churned     = Users x (1 - Retention)
Users'      = max(0, Users - churned + new_users)
revenue     = Users' x Conversion x ARPU
Cash'       = Cash - chi_tieu + revenue
```

- `CAC_hieu_dung = CAC x (1 + 0.01 x (ad_spend / 1000))`: chi quảng cáo càng nhiều càng đắt (hiệu suất giảm dần).
- Chi phí cố định mỗi tuần (lương, server): 200, cộng 0,05 mỗi user.
- Ở mức khởi điểm, nếu không làm gì công ty lỗ rất nhẹ và co chậm (tuần 1 còn khoảng 850 người dùng). Thẻ nâng cấp (Onboarding, Fix Checkout, Support, SEO) giảm hiệu quả một nửa mỗi lần chơi lại, nên không cộng dồn vô hạn.
- Mọi hệ số nằm trong `data/` (JSON), không viết cứng trong mã.

## 5. Thẻ quyết định (bản đầu 12 thẻ, mỗi thẻ có Budget và Energy)

**Phân tích:** SQL Deep-Dive (hiện Retention từng cohort), A/B Test (cho dự đoán sát hiệu quả thẻ kế tiếp), Funnel Report (hiện bước rò rỉ), Clean Data (tăng Data Integrity).

**Tối ưu:** Fix Checkout Bug (Conversion tăng), Onboarding Redesign (Retention tăng), Support Automation (giảm chi phí cố định).

**Tăng trưởng:** Ads Campaign (mua user), Influencer Campaign (nhiều user, Retention giảm nếu Onboarding chưa tối ưu), Loyalty Program (Retention tăng, tốn Budget đều), SEO Content (CAC giảm chậm).

**Rủi ro:** Giảm giá (Conversion tăng nhưng ARPU giảm).

Hiệu quả cụ thể của từng thẻ do `data/cards.json` quyết định.

## 6. Sự kiện (bản đầu 8 sự kiện)

Mỗi sự kiện có **nguyên nhân gốc** ẩn và **triệu chứng** hiện trên dashboard. Người chơi phải phân biệt hai thứ này.

Ví dụ: Retention tụt. Nguyên nhân có thể là bug app (hiện ở một cohort), đối thủ giảm giá (hiện ở nhóm nhạy giá), hoặc dữ liệu log lỗi (Data Integrity thấp, thực tế không có gì xảy ra). Thẻ phân tích đúng giúp lộ nguyên nhân. **Thẻ xử lý chỉ gỡ được sự kiện khi nguyên nhân của nó đã lộ.** Chơi thẻ xử lý "đoán mò" vẫn có hiệu ứng riêng của thẻ nhưng sự kiện vẫn còn và không tính điểm xử lý.

## 7. Thắng và thua

- **Thua:** Cash về 0, hoặc LTV/CAC dưới 1 trong 4 tuần liên tiếp mà Cash dưới 2,000.
- **Thắng:** qua hết số tuần của ván và giữ được công ty. Bản demo (10 tuần): Cash từ 9,500, LTV/CAC từ 2 và Users từ 750 (75% số khởi điểm). Bản đầy đủ (30 tuần): Cash từ 15,000, LTV/CAC từ 2, Users từ 750.
- **Điểm:** ván thắng = 1,000 + 0,1 x Cash + 100 x min(LTV/CAC, 5) + 100 x số sự kiện xử lý đúng. Ván thua tối đa 900 điểm (theo số tuần sống sót và sự kiện xử lý đúng), nên luôn thấp hơn mọi ván thắng.

## 8. Độ khó

Xác suất có sự kiện mỗi tuần tăng dần theo pha: tuần 1 đến 10 là 45%, tuần 11 đến 20 là 55%, tuần 21 đến 30 là 70%. Data Integrity tụt dần từ tuần 11 (1 điểm mỗi tuần), và từ tuần 21 (2 điểm mỗi tuần), nên dữ liệu càng về sau càng nhiễu.

## 9. Giao diện và mỹ thuật

- Màn hình 640x360, scale nguyên, nearest filter (đã cấu hình trong `project.godot`).
- Chủ đề dashboard công ty tối màu, tuân theo style bible tại `shared/style-bible` (hiện chưa có; khi chưa có, tạm dùng bảng màu ít màu và ghi lại để ép sau).
- Biểu đồ vẽ bằng mã trong Godot (đường, cột, phễu), không dùng ảnh ngoài.
- Âm thanh: tiếng phím, bíp số liệu. Chỉ dùng âm thanh tự tạo hoặc có giấy phép.

## 10. Kỹ thuật (cho Codex)

- Godot 4, GDScript. Dữ liệu ở `data/*.json` (config, cards, events), nạp qua `scripts/data.gd`.
- Lõi mô phỏng thuần logic ở `scripts/sim/` (không phụ thuộc node) để chạy headless.
- `tests/balance_sim.gd`: chạy hàng nghìn ván với vài chiến lược (ngẫu nhiên, chỉ chi quảng cáo, chỉ tối ưu, cân bằng), in tỷ lệ thắng và phân bố Cash.
- Mục tiêu cân bằng (đo ở demo 10 tuần, 2.000 ván mỗi chiến lược): chỉ quảng cáo không thắng (tối đa 10%), ngẫu nhiên tối đa 20%, chiến lược cân bằng thắng 35 đến 55%, chiến lược phân tích (lộ nguyên nhân rồi mới xử lý) thắng cao hơn cân bằng ít nhất 10 điểm %. Kết quả đo sau T-012: ngẫu nhiên 18,9%, cân bằng 43,05%, phân tích 55,5%, chỉ quảng cáo và chỉ tối ưu 0%. Con số này đo trên bot giả lập, cần playtest người thật để xác nhận.

## 11. Phạm vi bản demo (10 tuần)

6 thẻ, 4 sự kiện, 1 loại biểu đồ funnel và 1 biểu đồ đường. Không có lưu tiến trình, không có bảng xếp hạng.

## 12. Ngoài phạm vi (chưa làm)

Bảng xếp hạng trực tuyến, 5 công ty khác nhau, chế độ Sandbox, màn gõ SQL thật. Chỉ đưa vào web quảng cáo khi game đã có thật.

## 13. Câu hỏi mở

- Tên chính thức, có giữ "Data Corp" không (cần kiểm tra trùng tên trước khi phát hành).
- Nền tảng phát hành đầu tiên: web (WebAssembly) hay Windows.
