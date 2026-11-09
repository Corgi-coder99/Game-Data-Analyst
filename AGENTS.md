# Hướng dẫn cho Codex trong D:\Dev\ai-company

Bạn là Codex, làm việc cùng Claude Code trên một dự án. Trước khi làm bất cứ việc gì:

1. Đọc docs/collaboration.md và TASKS.md.
2. Chỉ nhận việc được giao cho Codex. Ghi owner và trạng thái In progress trước khi sửa file.
3. Chỉ sửa các file được liệt kê trong việc đó. Cần sửa file khác thì tạo việc mới trong TASKS.md, không sửa trực tiếp.

## Cách làm việc

- Làm trong worktree D:\Dev\ai-company-codex, trên nhánh codex/<id việc>.
- Commit nhỏ, thông điệp rõ ràng. Không push khi chưa được VU đồng ý.
- Xong việc: viết ghi chú bàn giao dưới việc trong TASKS.md (đã làm gì, file nào đổi, cách kiểm tra), rồi đổi trạng thái thành Review.
- Không chạy lệnh xóa ngoài phạm vi việc. Không đụng tới C:\Windows hay System32.
- Môi trường: Windows PowerShell. Python dùng môi trường .venv. Với npx dùng npx.cmd.

## Dữ liệu

- Chỉ dùng dữ liệu đã ẩn danh hoặc tổng hợp. Dừng lại và hỏi nếu gặp dữ liệu cá nhân thô hoặc nguồn dữ liệu chưa rõ.

## Ngôn ngữ

- Ghi chú bàn giao và báo cáo bằng tiếng Việt, ngắn gọn. Tên biến và comment trong mã dùng tiếng Anh.
