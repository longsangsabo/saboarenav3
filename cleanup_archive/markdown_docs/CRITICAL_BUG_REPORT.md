# 🚨 CRITICAL BUG: SABO DE16 LOSER ADVANCEMENT

## VẤN ĐỀ NGHIÊM TRỌNG
**WR3 (Winners Round 3) THIẾU LOGIC ADVANCE LOSER!**

### HIỆN TẠI:
```dart
_processWR3Completion() {
  // ✅ Advance winner to SABO Finals (R250/R251)
  // ❌ KHÔNG advance loser! - THIẾU HOÀN TOÀN!
}
```

### ĐÚNG PHẢI LÀ:
```
WR3 M1 (Match 13): Winner → SEMI1 (R250), Loser → LBR202 M1
WR3 M2 (Match 14): Winner → SEMI2 (R251), Loser → LBR202 M1
```

### LOGIC THIẾU:
1. **WR3 losers phải đi xuống LBR202**
2. **Cả 2 WR3 losers đánh nhau trong LBR202 M1**
3. **Winner của LBR202 sẽ đánh với SABO Final winner**

### IMPACT:
- Tournament sẽ BỊ ĐỨNG khi complete WR3
- WR3 losers sẽ biến mất khỏi bracket
- Không thể hoàn thành tournament

### SOLUTION NEEDED:
Thêm loser advancement logic vào `_processWR3Completion()`

## STATUS: 🔴 CRITICAL - PHẢI FIX NGAY!