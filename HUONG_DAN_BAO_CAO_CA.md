# 📊 **HƯỚNG DẪN SỬ DỤNG HỆ THỐNG BÁO CÁO CA**
## Sabo Arena - Club Shift Reporting System

---

## 🎯 **TỔNG QUAN HỆ THỐNG**

Hệ thống báo cáo ca là tính năng quản lý doanh thu, chi phí và hiệu suất làm việc theo từng ca tại câu lạc bộ. Hệ thống cho phép:

- ✅ **Quản lý ca làm việc**: Bắt đầu, kết thúc và theo dõi ca
- ✅ **Theo dõi doanh thu thời gian thực**: Ghi nhận từng giao dịch
- ✅ **Quản lý chi phí**: Theo dõi mọi khoản chi trong ca
- ✅ **Quản lý kho hàng**: Kiểm soát tồn kho theo ca
- ✅ **Báo cáo tự động**: Tạo báo cáo chi tiết cuối ca
- ✅ **Thống kê và phân tích**: Hiển thị xu hướng và hiệu suất

---

## 🚀 **CÁCH TRUY CẬP**

### 📱 **Trên Mobile App:**
1. Đăng nhập với tài khoản chủ CLB hoặc nhân viên có quyền
2. Vào **Dashboard CLB** → Chọn **"Báo cáo ca"**
3. Hoặc từ menu chính → **"Chấm công nhân viên"** (có cả báo cáo ca)

### 🔐 **Phân quyền truy cập:**
- **Chủ CLB**: Toàn quyền xem, tạo, quản lý tất cả ca
- **Quản lý**: Có thể tạo ca và xem báo cáo
- **Nhân viên**: Chỉ xem và quản lý ca của mình
- **Thực tập sinh**: Chỉ được xem báo cáo đã được duyệt

---

## 📋 **HƯỚNG DẪN SỬ DỤNG CHI TIẾT**

### 🟢 **1. BẮT ĐẦU CA LÀM VIỆC**

#### Bước 1: Tạo ca mới
- Nhấn nút **"Bắt Đầu Ca Mới"** (dấu + xanh lá)
- Chọn **ngày làm việc** (hôm nay hoặc ngày khác)
- Đặt **giờ bắt đầu** và **giờ kết thúc** dự kiến
- Nhập **số tiền mặt đầu ca** (tiền có sẵn trong két)
- Thêm **ghi chú** nếu cần (tùy chọn)

#### Bước 2: Xác nhận thông tin
- Kiểm tra lại thông tin đã nhập
- Nhấn **"Bắt Đầu"** để kích hoạt ca

> 💡 **Lưu ý**: Một nhân viên chỉ có thể có 1 ca đang hoạt động cùng lúc

### 🔵 **2. QUẢN LÝ CA ĐANG HOẠT ĐỘNG**

#### Tab "Tổng Quan"
- **Thời gian thực**: Hiển thị thời gian ca đã chạy
- **Doanh thu hiện tại**: Tổng tiền đã thu
- **Phân tích thanh toán**: Tiền mặt, thẻ, chuyển khoản
- **Hoạt động gần đây**: 5 giao dịch mới nhất

#### Tab "Giao Dịch"  
**Thêm giao dịch mới:**
- Nhấn **"Thêm Giao Dịch"**
- Chọn loại: **Doanh thu** hoặc **Hoàn tiền**
- Chọn danh mục: Tiền bàn, Đồ ăn, Đồ uống, v.v.
- Nhập **mô tả** và **số tiền**
- Chọn **phương thức thanh toán**
- Nhập **số bàn** (nếu có)

**Xem danh sách giao dịch:**
- Hiển thị theo thời gian mới nhất
- Phân màu: Xanh (thu), Đỏ (chi), Cam (hoàn tiền)
- Thông tin đầy đủ: Giờ, số tiền, phương thức

#### Tab "Kho"
**Thêm hàng hóa:**
- Nhấn **"Thêm Hàng Hóa"**
- Nhập **tên sản phẩm**
- Chọn **danh mục**: Đồ ăn, Đồ uống, Thiết bị
- Nhập **số lượng đầu ca**
- Ghi nhận **số lượng bán**, **hỏng**, **bổ sung**
- Nhập **giá vốn** và **giá bán**

**Theo dõi tồn kho:**
- Xem tồn kho thời gian thực
- Tính toán tự động: Đầu ca - Bán - Hỏng + Bổ sung = Cuối ca
- Hiển thị **doanh thu** và **tỷ lệ hỏng**

#### Tab "Chi Phí"
**Ghi nhận chi phí:**
- Nhấn **"Thêm Chi Phí"**
- Chọn loại: Điện nước, Nguyên liệu, Bảo trì, Nhân sự
- Mô tả chi tiết chi phí
- Nhập **số tiền** và **phương thức thanh toán**
- Thêm **tên nhà cung cấp** (nếu có)
- Upload **hóa đơn** (tùy chọn)

**Duyệt chi phí:**
- Chi phí > 100k cần được duyệt
- Quản lý/Chủ CLB có thể duyệt
- Hiển thị trạng thái: Chờ duyệt / Đã duyệt

### 🔴 **3. KẾT THÚC CA LÀM VIỆC**

#### Bước 1: Kiểm tra thông tin
- Xem lại **tổng doanh thu**
- Kiểm tra **chi phí đã ghi nhận**
- Rà soát **tồn kho cuối ca**

#### Bước 2: Đếm tiền cuối ca
- Nhấn nút **"Kết Thúc Ca"** (biểu tượng STOP)
- Nhập **số tiền mặt thực tế** có trong két
- Hệ thống tự động tính **chênh lệch**

#### Bước 3: Xác nhận kết thúc
- Kiểm tra thông tin tổng kết
- Nhấn **"Kết Thúc Ca"** để hoàn tất

> ⚠️ **Quan trọng**: Sau khi kết thúc ca không thể chỉnh sửa giao dịch

### 📊 **4. XEM BÁO CÁO VÀ THỐNG KÊ**

#### Tab "Lịch Sử"
**Bộ lọc báo cáo:**
- **Trạng thái**: Tất cả, Nháp, Đã gửi, Đã duyệt
- **Khoảng thời gian**: Chọn từ ngày - đến ngày
- **Xóa bộ lọc**: Nút X để reset

**Thông tin báo cáo:**
- **Doanh thu, Chi phí, Lợi nhuận** mỗi ca
- **Số bàn phục vụ** và **tỷ lệ lợi nhuận**
- **Đánh giá hiệu suất**: Xuất sắc → Thua lỗ
- **Cảnh báo chênh lệch tiền mặt** (nếu có)

#### Tab "Thống Kê"
**Chọn khoảng thời gian:**
- 7 ngày / 30 ngày / 3 tháng
- Tự động cập nhật biểu đồ

**Các loại thống kê:**
- **Xu hướng doanh thu**: Biểu đồ đường theo ngày
- **Phân bổ doanh thu vs chi phí**: Biểu đồ tròn
- **Hiệu suất trung bình**: So sánh với tiêu chuẩn
- **Doanh thu bình quân/ca**: Theo dõi xu hướng

---

## 🔧 **TÍNH NĂNG NÂNG CAO**

### � **Biểu Đồ Thống Kê**
- **Xu hướng doanh thu**: Biểu đồ đường theo thời gian
- **Phân bổ chi phí**: Biểu đồ tròn theo danh mục
- **So sánh hiệu suất**: Cột biểu đồ theo ca
- **Tỷ lệ thanh toán**: Phân tích tiền mặt vs thẻ

### 🎯 **Chỉ Số Hiệu Suất**
- **Profit Margin**: Tỷ lệ lợi nhuận trên doanh thu
- **Revenue per Table**: Doanh thu bình quân mỗi bàn
- **Inventory Turnover**: Tốc độ quay vòng hàng tồn kho
- **Staff Productivity**: Hiệu suất nhân viên

### 🔄 **Giao Ca (Handover)**
```
🚧 Đang phát triển - Sẽ có trong bản cập nhật tiếp theo
Cho phép giao ca giữa các nhân viên với ghi chú chi tiết
```

### 📱 **Thông Báo Real-time**
```
🚧 Đang phát triển - Sẽ có trong bản cập nhật tiếp theo
Thông báo tự động khi có giao dịch bất thường
```

### 📄 **Xuất Báo Cáo PDF**
```
🚧 Đang phát triển - Sẽ có trong bản cập nhật tiếp theo
Xuất báo cáo chi tiết dạng PDF để lưu trữ
```

---

## ⚠️ **LƯU Ý QUAN TRỌNG**

### 🔒 **Bảo Mật**
- Chỉ nhân viên có quyền mới được truy cập
- Dữ liệu được mã hóa và bảo mật trên cloud
- Lịch sử thay đổi được lưu trữ đầy đủ

### 💾 **Sao Lưu Dữ Liệu**
- Tự động sao lưu mỗi 15 phút
- Dữ liệu được đồng bộ với server
- Có thể khôi phục khi mất kết nối

### 🌐 **Hoạt Động Offline**
```
Tính năng offline đang được phát triển
Hiện tại cần kết nối internet ổn định
```

### 🔄 **Đồng Bộ Dữ Liệu**
- Tự động đồng bộ khi có internet
- Thông báo lỗi nếu đồng bộ thất bại
- Ưu tiên dữ liệu trên server

---

## 🆘 **KHẮC PHỤC SỰ CỐ**

### ❌ **Lỗi Thường Gặp**

**1. Không thể bắt đầu ca:**
- ✅ Kiểm tra đã kết thúc ca trước chưa
- ✅ Xác nhận có quyền tạo ca
- ✅ Kiểm tra kết nối internet

**2. Mất dữ liệu giao dịch:**
- ✅ Kiểm tra tab "Lịch sử" 
- ✅ Reload ứng dụng
- ✅ Liên hệ hỗ trợ kỹ thuật

**3. Chênh lệch tiền mặt lớn:**
- ✅ Kiểm tra lại giao dịch tiền mặt
- ✅ Xem có giao dịch chưa ghi nhận
- ✅ Xác nhận số tiền đầu ca chính xác

### 📞 **Liên Hệ Hỗ Trợ**
```
📧 Email: support@saboarena.com
📱 Hotline: 1900-SABO (1900-7226)
💬 Chat: Trong ứng dụng → Cài đặt → Hỗ trợ
```

---

## 📈 **CẬP NHẬT TÍNH NĂNG**

### ✅ **Đã Hoàn Thành** (v1.0)
- ✅ Quản lý ca làm việc hoàn chỉnh
- ✅ Ghi nhận giao dịch theo thời gian thực
- ✅ Quản lý chi phí và kho hàng
- ✅ Báo cáo tự động cuối ca
- ✅ Thống kê với biểu đồ fl_chart
- ✅ Phân quyền role-based truy cập
- ✅ Mock data service để test UI
- ✅ Responsive design cho mobile
- ✅ Vietnamese localization

### 🔄 **Đang Phát Triển** (v1.1)
- 🔄 Deploy database schema lên Supabase
- 🔄 Tích hợp ShiftReportingService thật
- 🔄 Giao ca giữa nhân viên
- 🔄 Thông báo real-time
- 🔄 Xuất báo cáo PDF
- 🔄 Tích hợp camera quét mã
- 🔄 Backup & restore dữ liệu

### 🔮 **Sắp Ra Mắt** (v1.2+)
- AI phân tích xu hướng
- Dự báo doanh thu
- Tích hợp POS system
- Mobile banking connect
- Voice command

---

**🎯 Được phát triển bởi Sabo Arena Development Team**  
**📅 Cập nhật lần cuối: 30/09/2025**  
**📖 Phiên bản tài liệu: 1.0**