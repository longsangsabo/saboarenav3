# HƯỚNG DẪN CHẠY SQL SCRIPTS

## Thứ tự chạy scripts:

### 1. **01_fix_user_profiles_references.sql**
- **Mục đích**: Sửa tất cả references đến bảng users không tồn tại
- **Cách chạy**: Copy toàn bộ nội dung và paste vào Supabase SQL Editor
- **Kết quả mong đợi**: Không có lỗi, tất cả policies được tạo thành công

### 2. **02_create_match_update_function.sql**
- **Mục đích**: Tạo RPC function để update kết quả match
- **Cách chạy**: Copy toàn bộ nội dung và paste vào Supabase SQL Editor
- **Kết quả mong đợi**: Function `update_match_result` được tạo thành công

### 3. **03_test_match_update_function.sql**
- **Mục đích**: Test function update match
- **Cách chạy**: 
  1. Chạy query đầu tiên để lấy match_id và player_id
  2. Replace UUID trong comment với giá trị thực
  3. Uncomment và chạy từng query test
- **Kết quả mong đợi**: Match được update thành công

### 4. **04_create_start_match_function.sql**
- **Mục đích**: Tạo function để start match
- **Cách chạy**: Copy toàn bộ nội dung và paste vào Supabase SQL Editor
- **Kết quả mong đợi**: Function `start_match` được tạo thành công

### 5. **05_verify_tournament_data.sql**
- **Mục đích**: Kiểm tra dữ liệu tournament và matches
- **Cách chạy**: Copy toàn bộ nội dung và paste vào Supabase SQL Editor
- **Kết quả mong đợi**: Hiển thị thông tin tournament, participants và matches

## Sau khi chạy xong:

1. **Test trong Flutter app**:
   - Vào tab "Trận đấu" 
   - Kiểm tra xem tên players có hiển thị đúng không
   - Test update điểm số
   - Test start match

2. **Nếu vẫn có lỗi**:
   - Chạy lại script 05 để kiểm tra dữ liệu
   - Kiểm tra log Flutter để xem lỗi cụ thể
   - Báo lại cho tôi để debug tiếp

## Lưu ý:

- **QUAN TRỌNG**: Backup database trước khi chạy (nếu là production)
- Chạy từng script một theo thứ tự
- Đợi script hoàn thành trước khi chạy script tiếp theo
- Nếu có lỗi, dừng lại và báo lỗi để tôi hỗ trợ