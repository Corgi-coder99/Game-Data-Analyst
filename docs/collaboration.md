# Quy ước phối hợp giữa Claude Code và Codex

Áp dụng cho mọi việc trong D:\Dev\ai-company. Cả hai bên đọc file này và TASKS.md trước khi bắt đầu.

## 1. Vai trò

- Claude Code: điều phối, viết spec, thiết kế, tài liệu, phân tích dữ liệu, review mã của Codex.
- Codex: viết mã theo spec đã giao (scripts, mã game, web), kèm kiểm thử cơ bản.
- VU: duyệt việc lớn, quyết định khi hai bên bất đồng hoặc bị chặn.

## 2. Năm nguyên tắc để không trùng lặp

1. Một việc chỉ có một chủ (owner).
2. Một file chỉ có một người ghi tại một thời điểm.
3. Nhận việc trước khi làm: ghi owner và đổi trạng thái thành In progress trong TASKS.md.
4. Mỗi bên làm trên nhánh git riêng. Codex làm trong worktree riêng (xem mục 5).
5. Bàn giao bằng ghi chú rõ ràng: đã làm gì, file nào đổi, cách kiểm tra.

## 3. Quy trình một việc

1. Claude (hoặc VU) tạo việc trong TASKS.md: mô tả, owner, file được sửa, tiêu chí hoàn thành.
2. Owner đổi trạng thái thành In progress và bắt đầu trên nhánh claude/<id> hoặc codex/<id>.
3. Làm xong: commit nhỏ, viết ghi chú bàn giao dưới việc đó, đổi trạng thái thành Review.
4. Bên còn lại review. Không đạt thì ghi nhận xét và trả về In progress.
5. Review đạt thì merge vào main và đổi trạng thái thành Done. Việc lớn cần VU duyệt trước khi merge.

## 4. Quyền sở hữu thư mục mặc định

| Thư mục hoặc file | Bên được ghi |
|---|---|
| docs/, design/, shared/, CLAUDE.md, TASKS.md | Claude |
| src/, scripts/, tools/, tests/ | Codex |
| data-analytics/ (báo cáo, notebook phân tích) | Claude |
| data-analytics/ (mã xử lý dữ liệu) | Codex |
| deliverables/ | Bên tạo ra sản phẩm, bên kia chỉ đọc |

Muốn thay đổi file thuộc bên kia: tạo việc mới trong TASKS.md đề xuất thay đổi, không sửa trực tiếp.

## 5. Git và worktree

- Claude làm trong thư mục chính D:\Dev\ai-company.
- Codex làm trong worktree riêng, tạo một lần bằng:
  git worktree add D:\Dev\ai-company-codex -b codex/work
- Trước khi bắt đầu một việc: lấy bản mới nhất của main. Commit nhỏ, thông điệp rõ ràng.
- Không push lên GitHub nếu VU chưa đồng ý.

## 6. Khi có xung đột hoặc bị chặn

- Thấy file ngoài quyền sở hữu có thay đổi chưa commit: dừng, ghi vào mục Blocked trong TASKS.md, hỏi VU.
- Không tự gọi nhau quá 3 vòng cho cùng một việc. Sau 3 vòng chưa xong thì báo VU.

## 7. Điều không được làm

- Sửa dòng việc của bên kia (trừ khi đổi trạng thái lúc review).
- Chạy lệnh xóa file hoặc thư mục ngoài phạm vi việc được giao.
- Commit mật khẩu, khóa API hoặc dữ liệu cá nhân.
- Làm việc với dữ liệu người dùng thô. Chỉ dùng dữ liệu đã ẩn danh hoặc tổng hợp, theo quy tắc trong CLAUDE.md.
