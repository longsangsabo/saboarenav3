🚫 **LỖI PERMISSION DETECTED**

Lỗi: `ERROR: 42501: must be owner of table objects`

**Nguyên nhân:** 
- Supabase không cho phép tạo policies trực tiếp qua SQL Editor
- Cần sử dụng Supabase Dashboard để tạo Storage policies

## ✅ **GIẢI PHÁP: Tạo policies qua Supabase Dashboard**

### 🚀 **Bước 1: Mở Storage Settings**
1. Vào: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/storage/policies
2. Hoặc: Dashboard → Storage → Policies

### 🚀 **Bước 2: Tạo các policies sau**

#### **Policy 1: Upload own profile images**
- **Policy name:** `Users can upload their own profile images`
- **Allowed operation:** `INSERT`
- **Target roles:** `authenticated`
- **USING expression:**
```sql
bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]
```

#### **Policy 2: Update own profile images**
- **Policy name:** `Users can update their own profile images`
- **Allowed operation:** `UPDATE`
- **Target roles:** `authenticated`
- **USING expression:**
```sql
bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]
```

#### **Policy 3: Delete own profile images**
- **Policy name:** `Users can delete their own profile images`
- **Allowed operation:** `DELETE`
- **Target roles:** `authenticated`
- **USING expression:**
```sql
bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]
```

#### **Policy 4: Public can view profile images**
- **Policy name:** `Public can view profile images`
- **Allowed operation:** `SELECT`
- **Target roles:** `public`
- **USING expression:**
```sql
bucket_id = 'profiles'
```

### 🚀 **Bước 3: Kiểm tra**
Sau khi tạo xong, bạn sẽ thấy 4 policies trong Storage → Policies

### 🚀 **Bước 4: Test Upload**
Sau khi có policies, test upload avatar/cover photo trong app.

---

## 📝 **Lưu ý:**
- ✅ Bucket "profiles" đã được tạo thành công
- ✅ StorageService và PermissionService đã ready
- 🔄 Chỉ cần tạo policies qua Dashboard là xong

## 🎯 **Kết quả mong đợi:**
- Avatar/Cover photo sẽ được upload lên Supabase Storage
- Ảnh sẽ được lưu vĩnh viễn, không mất khi restart app
- Permissions sẽ được cache, không cần xin lại