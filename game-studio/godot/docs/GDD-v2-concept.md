# GDD v2 (concept): Data Corp, nhân viên phân tích trong cơn khủng hoảng

Phiên bản 0.1 concept, 2026-11-10. Owner: Claude (thiết kế). Chờ VU duyệt hướng đi trước khi tạo việc lập trình. Giữ nguyên lõi của `docs/GDD.md` v0.2 (chỉ số, thẻ, sự kiện có nguyên nhân gốc ẩn, dữ liệu có thể sai), nhưng đổi cách chơi và bối cảnh.

## 1. Tóm tắt một câu

Bạn là nhân viên phân tích dữ liệu của một công ty nhỏ trong giai đoạn kinh tế khó khăn. Mỗi ngày bạn ngồi vào bàn làm việc trong văn phòng pixel, đọc "internet" trên màn hình máy tính (tin tài chính thế giới, giá cả, chứng khoán, tin đồn), kiểm chứng tin nào đáng tin, rồi viết báo cáo dự báo và đề xuất hành động cho sếp. Báo cáo đúng thì công ty sống sót, bạn được thưởng và thăng chức; báo cáo sai thì bị phạt, giáng chức, hoặc bị đuổi việc.

Thể loại: indie, mô phỏng công sở và phân tích, chơi một mình, 640x360 pixel art. Một ván demo 10 ngày làm việc, bản đầy đủ 30 ngày.

## 2. Giữ gì, đổi gì

| Lõi hiện có (đã có mã và kiểm thử) | Trong bản v2 |
|---|---|
| 7 chỉ số dashboard (Users, Retention, Conversion, CAC, ARPU, LTV/CAC, Data Integrity) | Dashboard của công ty trên màn hình máy tính. "Users" là khách hàng đang hoạt động. Data Integrity trở thành **độ tin cậy của dữ liệu nội bộ** (dữ liệu bẩn thì số trên dashboard nhiễu) |
| Cash, thắng thua, điểm | Cash là tiền của công ty. Công ty cạn tiền thì công ty phá sản (kết thúc ván) |
| 8 sự kiện có triệu chứng và nguyên nhân gốc ẩn | **Cú sốc thị trường**: tin tức là triệu chứng, nguyên nhân thật (lãi suất, giá nguyên liệu, tỷ giá, đối thủ, tin giả) ẩn đến khi bạn kiểm chứng |
| Thẻ phân tích (SQL Deep-Dive, A/B Test, Funnel Report, Clean Data) | **Công cụ phân tích** dùng trên máy tính: truy vấn dữ liệu lịch sử, kiểm định giả thuyết, báo cáo dòng tiền, làm sạch và lọc nguồn nhiễu. Tốn Energy (tập trung) và Budget |
| Thẻ hành động (Fix Checkout, Onboarding, Ads, Loyalty, SEO, Support, Influencer, Giảm giá) | **Hành động bạn đề xuất cho sếp** trong báo cáo (đổi tên theo ngữ cảnh: siết thu hồi công nợ, giữ chân khách, chi marketing, khuyến mãi, cắt chi phí vận hành, v.v.). Sếp quyết định có làm hay không |
| Thẻ xử lý chỉ gỡ sự kiện khi nguyên nhân đã lộ (T-011) | Đề xuất hành động đúng chỉ hiệu quả khi bạn đã xác định đúng nguyên nhân của cú sốc |
| Màn kết thúc "sự thật so với đã thấy" | **Họp đánh giá cuối ngày**: sếp công bố sự thật, đối chiếu với dự báo của bạn |

## 3. Vòng chơi mỗi ngày

1. **Đến văn phòng (cảnh pixel).** Nhân vật đi vào văn phòng, chào đồng nghiệp, ngồi vào bàn. Sếp (Giám đốc Tài chính) gửi một **câu hỏi trong ngày**, ví dụ: "Giá nguyên liệu có tăng tiếp không? Chúng ta có nên nhập thêm hàng?"
2. **Màn hình máy tính (khối chính của game).** Cửa sổ trong "internet giả lập":
   - **Bản tin tài chính thế giới:** tin vĩ mô (lãi suất, lạm phát, tỷ giá), thị trường hàng hóa, chứng khoán.
   - **Bảng giá:** mã chứng khoán và hàng hóa giả tưởng, biểu đồ giá theo ngày.
   - **Mạng xã hội và diễn đàn:** tin đồn, ý kiến cá nhân, ảnh chụp "nội bộ".
   - **Báo cáo chính thức:** thông cáo, số liệu thống kê (đáng tin nhưng thường trễ).
   - **Dashboard công ty:** các chỉ số hiện có.
   Mỗi tin có **nguồn**, **giờ đăng**, **độ chắc chắn tự nhận**. Người chơi đọc, ghim bằng chứng, loại tin nhiễu.
3. **Công cụ phân tích.** Mỗi ngày có 3 Energy. Dùng công cụ để kiểm chứng: truy vấn lịch sử giá, đối chiếu hai nguồn, kiểm định giả thuyết, làm sạch dữ liệu. Kết quả: tin được xác nhận, bác bỏ, hoặc chưa đủ căn cứ.
4. **Viết báo cáo cho sếp.** Chọn: (a) dự báo cho câu hỏi trong ngày (tăng, giảm, đi ngang), (b) mức tự tin (thấp, vừa, cao), (c) các bằng chứng đã ghim, (d) tối đa 2 hành động đề xuất. Gửi báo cáo.
5. **Sếp quyết định.** Mức tin tưởng của sếp quyết định bao nhiêu đề xuất được thực hiện. Công ty chạy một tuần mô phỏng theo kinh tế hiện có (T-012), cộng với cú sốc thị trường thật đã được định trước.
6. **Họp đánh giá cuối ngày.** Sự thật được công bố: tin nào đúng, nguyên nhân thật là gì. Bạn nhận điểm chính xác, thay đổi Tin tưởng, và thưởng hoặc phạt.

## 4. Mô hình thế giới giả lập

Mỗi ván tạo ra một **kịch bản thế giới** từ seed (tái lập được):

- Một chuỗi **trạng thái thật ẩn** theo ngày: lãi suất, giá nguyên liệu, tỷ giá, tâm lý thị trường, vài mã chứng khoán, và cú sốc đang xảy ra (lấy từ 8 sự kiện hiện có, mở rộng sang bối cảnh vĩ mô).
- Một **bộ phát sinh tin tức** từ các mẫu trong `data/news.json`. Mỗi tin có: nguồn và mức uy tín, nội dung, hướng tác động, độ lệch thời gian so với sự kiện thật, và **nhãn thật ẩn**: đúng, sai, đúng một phần, hoặc đã cũ.
- Bản tin nhiễu theo uy tín nguồn: báo chính thống ít sai nhưng trễ, mạng xã hội nhanh nhưng nhiễu, tin "nội bộ" hay là bẫy.

Tất cả công ty, mã chứng khoán, cơ quan, nhân vật và số liệu đều **hư cấu**. Không dùng tên công ty, thương hiệu, sự kiện hay số liệu thật.

## 5. Dữ liệu một tin tức (mẫu)

```
id, source{id,tier:"chinh_thuc|bao_chi|mang_xa_hoi|noi_bo"}, topic, headline,
direction("tang|giam|ngang"), claimed_magnitude, published_at (giờ trong ngày),
truth("dung|sai|mot_phan|cu") [ẩn], verified_by[tool ids], links_to_event
```

## 6. Báo cáo và chấm điểm

| Thành phần | Cách tính |
|---|---|
| Độ chính xác dự báo | Dự báo đúng hướng và đúng độ lớn mức nào |
| Hiệu chỉnh tự tin | Tự tin cao mà sai bị phạt nặng; tự tin thấp mà đúng thưởng ít (khuyến khích trung thực về độ bất định) |
| Chất lượng bằng chứng | Dựa vào nguồn đã kiểm chứng thì cộng, dựa vào tin đồn chưa kiểm chứng thì trừ, kể cả khi dự báo vô tình đúng |
| Tác động đến công ty | Thay đổi Cash do các đề xuất được sếp thực hiện |

## 7. Sự nghiệp, thưởng và phạt

Thang chức: Thực tập, Chuyên viên, Chuyên viên chính, Trưởng nhóm, Giám đốc Phân tích. Chỉ số **Tin tưởng của sếp** 0 đến 100, khởi điểm 50 (giá trị khởi điểm, chỉnh bằng mô phỏng cân bằng).

- Báo cáo tốt: Tin tưởng tăng, nhận thưởng tiền. Đủ điều kiện (Tin tưởng cao và vài báo cáo đúng liên tiếp) thì được thăng chức, đổi nhiệm vụ và quyền đề xuất nhiều hành động hơn.
- Báo cáo sai: Tin tưởng giảm. Sai nặng hoặc sai liên tiếp thì bị cảnh cáo, trừ lương, giáng chức. Tin tưởng chạm 0, hoặc bị giáng chức hai lần, thì **bị đuổi việc** (kết thúc ván).
- Công ty phá sản (Cash về 0) cũng kết thúc ván, kèm ảnh chụp lại những báo cáo đã dẫn tới nó.
- Thắng: kết thúc ván với công ty còn sống và chức vụ cao hơn lúc đầu. Điểm tổng hợp từ chức vụ, Tin tưởng, Cash và số cú sốc xử lý đúng.

## 8. Mỹ thuật và âm thanh

- 640x360, scale nguyên, nearest filter (đã cấu hình). Phong cách pixel art, văn phòng nhìn ngang, bảng màu giới hạn (đề xuất tối đa 32 màu; sẽ khóa trong style bible mới).
- Cảnh: văn phòng chung, bàn của người chơi, phòng sếp, phòng họp. Chuyển sang màn hình máy tính bằng cách "ngồi vào bàn". Ngày đổi theo ánh sáng cửa sổ.
- Màn hình máy tính là giao diện có cửa sổ kéo, tab, thanh tác vụ giả lập (nhưng không là hệ điều hành hay trình duyệt thật).
- Âm thanh: tiếng phím, chuông thông báo, nhạc nền nhẹ. Chỉ dùng âm thanh tự tạo hoặc giấy phép rõ ràng.

## 9. Phạm vi demo (10 ngày)

3 nguồn tin cơ bản, khoảng 40 mẫu tin, 6 chủ đề thị trường, 8 cú sốc (từ 8 sự kiện hiện có), 3 mức chức vụ, 1 sếp, 3 đồng nghiệp trang trí, 1 bàn làm việc. Chưa có: nhiều công ty, lưu tiến trình, bảng xếp hạng, đa ngôn ngữ.

## 10. Kế hoạch tái sử dụng mã

Giữ nguyên `scripts/sim/` (kinh tế công ty, thẻ, sự kiện, điểm) làm "mô phỏng công ty". Thêm tầng mới `scripts/world/` (trạng thái thế giới ẩn, bộ phát sinh tin tức, báo cáo và chấm điểm, sự nghiệp) gọi vào mô phỏng công ty. Giao diện mới (văn phòng và màn hình máy tính) thay `scenes/game.tscn`; cảnh dashboard hiện tại trở thành một cửa sổ của màn hình máy tính. Toàn bộ kiểm thử hiện có phải tiếp tục qua.

## 11. Trung thực và quy định

- Mọi tên, số liệu, sự kiện trong game là hư cấu. Hiện rõ trong game và trên trang giới thiệu: "Số liệu trong game là mô phỏng hư cấu, không phải dữ liệu thị trường thật và không phải lời khuyên đầu tư."
- Không bán hay gợi ý cách giao dịch thật; không có tiền thật trong game.
- Không dùng thương hiệu, nhân vật, ảnh, âm nhạc có bản quyền. Asset phải có giấy phép rõ ràng hoặc do ta tạo ra.
- Ghi rõ nội dung do AI hỗ trợ tạo ra khi nền tảng yêu cầu.
- Landing page hiện tại (T-007) mô tả game cũ: phải viết lại sau khi hướng đi này được duyệt, chỉ nói những gì bản mới thật sự có.

## 12. Lộ trình đề xuất (giai đoạn)

| Giai đoạn | Nội dung | Owner |
|---|---|---|
| A | Style bible mới và content bible (mẫu tin, nguồn, chủ đề, nhân vật) | Claude |
| B | Tầng thế giới: kịch bản thế giới, phát sinh tin tức, báo cáo, chấm điểm, sự nghiệp, kèm mô phỏng cân bằng chạy không giao diện | Codex theo spec |
| C | Giao diện: cảnh văn phòng, màn hình máy tính và các cửa sổ, luồng báo cáo, họp cuối ngày (mỹ thuật tạm) | Codex theo spec |
| D | Pass mỹ thuật pixel và âm thanh | Cần quyết định nguồn asset (mục 13) |
| E | QA, playtest, cập nhật landing page và video theo bản mới | Claude |

## 13. Câu hỏi mở

1. **Nguồn mỹ thuật pixel: ĐÃ CHỐT (VU, 2026-11-10): sprite viết bằng mã.** Sprite đơn giản tạo bằng mã (script sinh ảnh hoặc vẽ trong Godot) với bảng màu giới hạn, bản quyền thuộc dự án. Có thể thay bằng bản vẽ đẹp hơn sau. Style bible (T-016) phải mô tả sprite ở mức đơn giản khả thi bằng mã (nhân vật khoảng 16x24, bàn, máy tính, cửa sổ UI).
2. **Bản v2 thay thế hay cùng tồn tại với bản dashboard hiện tại?** Mặc định đề xuất: giữ bản hiện tại trên `master` như một mốc (gắn tag), phát triển v2 trên nhánh riêng, chỉ thay khi đạt bản demo. Chưa được VU xác nhận.
3. **Tên game:** mặc định giữ "Data Corp (tên tạm)", kiểm tra trùng tên trước khi phát hành. Chưa được VU xác nhận.
4. **Bối cảnh vĩ mô hư cấu:** mặc định dùng một "cuộc khủng hoảng tín dụng" chung chung trong thế giới hư cấu không gắn quốc gia hay sự kiện thật. Chưa được VU xác nhận.
