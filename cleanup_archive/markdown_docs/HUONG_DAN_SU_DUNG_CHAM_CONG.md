# 📱 HƯỚNG DẪN SỬ DỤNG HỆ THỐNG CHẤM CÔNG NHÂN VIÊN

## 🎯 TỔNG QUAN
Hệ thống chấm công cho phép nhân viên check-in/out bằng QR code với xác thực GPS và quản lý giờ nghỉ tự động.

---

## 👨‍💼 DÀNH CHO NHÂN VIÊN

### 🚪 1. TRUY CẬP HỆ THỐNG CHẤM CÔNG

#### **Cách 1: Qua Personal Profile (Đã loại bỏ)**
- ❌ Không còn menu chấm công trong user profile

#### **Cách 2: Qua Club Owner Dashboard (Chính thức)**
1. **Đăng nhập** bằng tài khoản được cấp quyền nhân viên
2. **Vào "My Clubs"** → Chọn câu lạc bộ đang làm việc
3. **Nhấn "Chấm công"** (nút màu xanh)
4. **Hệ thống kiểm tra role** và hiển thị giao diện phù hợp

#### **Yêu cầu quyền truy cập:**
- Phải được thêm vào bảng `club_staff` với role: `owner`, `manager`, `staff`, hoặc `trainee`
- Trạng thái `is_active = true`
- Thuộc câu lạc bộ có trong hệ thống

### 📱 2. MÀN HÌNH CHẤM CÔNG CHÍNH

#### � Thông tin nhân viên:
- **Badge role**: Hiển thị chức vụ (Chủ CLB/Quản lý/Nhân viên/Thực tập)
- **Tên câu lạc bộ**: CLB đang làm việc
- **Trạng thái**: Đang hoạt động

#### 📊 Thông tin chấm công:
- **Trạng thái hiện tại**: Chưa vào ca / Đang làm việc / Đang nghỉ
- **Giờ vào ca**: Thời gian check-in hôm nay  
- **Tổng thời gian làm**: Số giờ đã làm việc
- **Giờ nghỉ**: Tổng thời gian nghỉ giải lao
- **Ca làm việc hôm nay**: Danh sách ca được phân công

### 📷 3. CHECK-IN (VÀO CA)

#### **Cách 1: Nút Floating Action Button**
1. **Nhấn nút tròn** ở góc dưới phải màn hình
2. **Camera tự động mở** với overlay hướng dẫn

#### **Cách 2: Nút trong Quick Actions**  
1. **Nhấn "Chấm công"** trong phần Quick Actions
2. **Camera sẽ mở** với khung quét QR

#### **Quy trình quét QR:**
1. **Hướng camera** vào mã QR tại vị trí làm việc
2. **Hệ thống tự động**:
   - Xác thực mã QR: `sabo-club-001-attendance-location:10.7769,106.7009`
   - Kiểm tra vị trí GPS (phải trong bán kính 50m)
   - Ghi nhận thời gian vào ca
3. **Thông báo kết quả**: "Đã check-in thành công!" hoặc thông báo lỗi

#### ⚠️ Lưu ý quan trọng:
- **QR Code demo**: Dùng nút QR nhỏ bên cạnh nút chấm công để xem QR test
- **GPS bắt buộc**: Phải bật Location Services
- **Vị trí**: Phải ở trong bán kính 50m từ câu lạc bộ
- **Giới hạn**: Mỗi ca chỉ được check-in một lần
- **Mock GPS**: Hệ thống demo luôn cho phép (distance = 25m)

### 🚪 4. CHECK-OUT (TAN CA)

#### Bước thực hiện:
1. **Nhấn nút "Quét QR để tan ca"**
2. **Quét mã QR** tại vị trí làm việc
3. **Xác nhận tan ca** trong hộp thoại
4. **Hệ thống tự động**:
   - Tính tổng thời gian làm việc
   - Tính giờ tăng ca (nếu có)
   - Cập nhật trạng thái "Đã tan ca"

### ☕ 5. QUẢN LÝ GIỜ NGHỈ

#### Các loại nghỉ:
- **🍽️ Nghỉ ăn**: Nghỉ trưa, nghỉ tối
- **😴 Nghỉ giải lao**: Nghỉ ngắn 10-15 phút
- **👤 Nghỉ cá nhân**: Đi vệ sinh, việc cá nhân

#### Bắt đầu nghỉ:
1. **Nhấn vào loại nghỉ** (Nghỉ ăn / Nghỉ giải lao / Nghỉ cá nhân)
2. **Xác nhận** trong hộp thoại
3. **Thời gian nghỉ bắt đầu** được ghi nhận

#### Kết thúc nghỉ:
1. **Nhấn nút "Kết thúc nghỉ"** (màu đỏ)
2. **Hệ thống tự động**:
   - Tính thời gian nghỉ
   - Cập nhật trạng thái "Đang làm việc"
   - Hiển thị tổng thời gian nghỉ

### 📊 6. XEM LỊCH SỬ CHẤM CÔNG
1. **Cuộn xuống** trong màn hình chấm công
2. **Xem chi tiết**:
   - Lịch sử check-in/out các ngày trước
   - Tổng giờ làm mỗi ngày
   - Thời gian nghỉ chi tiết
   - Ghi chú đặc biệt (muộn, sớm, etc.)

---

## 👩‍💼 DÀNH CHO CHỦ CÂU LẠC BỘ

### 📊 1. TRUY CẬP DASHBOARD QUẢN LÝ
1. **Đăng nhập** với tài khoản chủ câu lạc bộ
2. **Chọn câu lạc bộ** cần quản lý
3. **Vào "Quản lý nhân viên"** → **"Dashboard chấm công"**

### 📈 2. MÀN HÌNH DASHBOARD

#### Tab "Hôm nay":
- **👥 Danh sách nhân viên**: Trạng thái real-time
- **⏰ Giờ làm việc**: Thời gian vào/ra ca
- **📍 Vị trí check-in**: GPS location
- **⚠️ Cảnh báo**: Muộn, thiếu chấm công

#### Tab "Tuần này":
- **📊 Biểu đồ**: Tỷ lệ chấm công đúng giờ
- **📋 Thống kê**: Tổng giờ làm việc
- **💰 Chi phí lương**: Tính toán sơ bộ

#### Tab "Thống kê":
- **📈 Hiệu suất**: So sánh theo thời gian
- **🎯 KPI**: Chỉ số chấm công
- **📑 Báo cáo**: Export Excel/PDF

### 🔍 3. TÌM KIẾM VÀ LỌC DỮ LIỆU
1. **Lọc theo ngày**: Chọn khoảng thời gian
2. **Lọc theo nhân viên**: Tìm kiếm tên
3. **Lọc theo trạng thái**: Đúng giờ / Muộn / Vắng
4. **Xuất báo cáo**: Tải file Excel/PDF

### ⚙️ 4. CÀI ĐẶT CHẤM CÔNG
1. **Quản lý QR Code**:
   - Tạo QR mới cho vị trí
   - Cập nhật tọa độ GPS
   - In QR code để dán tại vị trí

2. **Cài đặt ca làm việc**:
   - Giờ bắt đầu/kết thúc ca
   - Thời gian nghỉ trưa
   - Quy định muộn/sớm

3. **Thông báo tự động**:
   - Nhắc nhở chấm công
   - Cảnh báo muộn
   - Báo cáo hàng tuần

---

## 🔧 KHẮC PHỤC SỰ CỐ

### ❌ Không quét được QR Code
**Nguyên nhân**: Camera không hoạt động
**Giải pháp**:
1. Kiểm tra quyền truy cập Camera
2. Đảm bảo đủ ánh sáng
3. Giữ camera ổn định 2-3 giây
4. Làm sạch camera lens

### 📍 Lỗi GPS không chính xác
**Nguyên nhân**: GPS không được bật hoặc tín hiệu yếu
**Giải pháp**:
1. Bật Location Services
2. Ra ngoài trời để GPS chính xác hơn
3. Đợi 30 giây để GPS ổn định
4. Khởi động lại ứng dụng

### ⏰ Quên check-out
**Giải pháp**:
1. Liên hệ quản lý để chỉnh sửa
2. Hoặc hệ thống tự động check-out lúc 22:00
3. Ghi chú trong báo cáo

### 🔄 Ứng dụng bị lag/crash
**Giải pháp**:
1. Đóng và mở lại app
2. Restart điện thoại
3. Cập nhật app lên phiên bản mới
4. Xóa cache ứng dụng

---

## 📞 HỖ TRỢ KỸ THUẬT

### 🆘 Khi cần hỗ trợ:
1. **Chụp màn hình** lỗi gặp phải
2. **Ghi chú** thời gian và tình huống
3. **Liên hệ**: 
   - Email: support@saboarena.com
   - Hotline: 1900-xxxx
   - Chat trong app: Menu → Hỗ trợ

### 📋 Thông tin cần cung cấp:
- Tên đăng nhập
- Câu lạc bộ đang làm việc
- Model điện thoại
- Thời gian xảy ra lỗi
- Screenshot lỗi

---

## 🔒 BẢO MẬT VÀ QUYỀN RIÊNG TƯ

### 🛡️ Dữ liệu được bảo vệ:
- Thông tin GPS chỉ sử dụng để xác thực vị trí
- Dữ liệu chấm công được mã hóa
- Chỉ quản lý mới xem được thông tin nhân viên
- Tuân thủ GDPR và quy định bảo mật Việt Nam

### 👤 Quyền riêng tư:
- Nhân viên có quyền xem dữ liệu của mình
- Không theo dõi vị trí ngoài giờ làm việc
- Có thể yêu cầu xóa dữ liệu cá nhân

---

## 🎯 TIPS & TRICKS

### ⚡ Sử dụng hiệu quả:
1. **Check-in ngay** khi đến nơi làm việc
2. **Đặt nhắc nhở** 5 phút trước giờ tan ca
3. **Kiểm tra trạng thái** trước khi rời khỏi nơi làm việc
4. **Báo cáo sớm** nếu có vấn đề kỹ thuật

### 📱 Tối ưu hiệu suất:
1. Đóng các app khác khi sử dụng
2. Đảm bảo pin đủ (ít nhất 20%)
3. Kết nối Wi-Fi hoặc 3G/4G ổn định
4. Cập nhật app thường xuyên

---

## 📊 CÁC CHỈ SỐ QUAN TRỌNG

### ⏰ Thời gian:
- **Muộn**: > 5 phút sau giờ quy định
- **Sớm**: < 30 phút trước giờ tan ca
- **Tăng ca**: > 8 giờ/ngày
- **Nghỉ tối đa**: 1 giờ/ca

### 📈 KPI chấm công:
- **Đúng giờ**: ≥ 95%
- **Đầy đủ**: 100% check-in + check-out
- **Hiệu suất**: Tổng giờ làm việc/tuần
- **Tuân thủ**: Theo đúng quy định ca làm việc

**📞 Hotline hỗ trợ 24/7: 1900-SABO (7226)**
**🌐 Website: https://saboarena.com/support**