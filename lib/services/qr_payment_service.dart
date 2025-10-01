
/// Service để tạo QR Code cho các phương thức thanh toán
class QRPaymentService {
  static const String _vietQRBaseUrl = 'https://img.vietqr.io/image';
  
  /// Mã ngân hàng Việt Nam (BIN codes)
  static const Map<String, String> bankCodes = {
    "Vietcombank": '970436',
    "VietinBank": '970415',
    "BIDV": '970418',
    "Agribank": '970405',
    "Techcombank": '970407',
    "MBBank": '970422',
    "ACB": '970416',
    "VPBank": '970432',
    "TPBank": '970423',
    "SHB": '970443',
    "Eximbank": '970431',
    "MSB": '970426',
    "SACOMBANK": '970403',
    "HDBank": '970437',
    "VIB": '970441',
    "OCB": '970448',
    "SCB": '970429',
    "SeABank": '970440',
    "CAKE": '546034',
    "Ubank": '546035',
    "Timo": '963388',
  };

  /// Tạo URL QR Code cho chuyển khoản ngân hàng (VietQR)
  static String generateBankQRUrl({
    required String bankName,
    required String accountNumber,
    required String accountName,
    double? amount,
    String? description,
    String template = 'compact2',
  }) {
    final bankCode = bankCodes[bankName];
    if (bankCode == null) {
      throw ArgumentError('Không tìm thấy mã ngân hàng cho: $bankName');
    }

    String url = '$_vietQRBaseUrl/$bankCode-$accountNumber-$template.png';
    
    List<String> params = [];
    
    if (amount != null && amount > 0) {
      params.add('amount=${amount.toInt()}');
    }
    
    if (description != null && description.isNotEmpty) {
      params.add('addInfo=${Uri.encodeComponent(description)}');
    }
    
    if (accountName.isNotEmpty) {
      params.add('accountName=${Uri.encodeComponent(accountName)}');
    }
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    
    return url;
  }

  /// Tạo data string cho QR Code ngân hàng (theo chuẩn VietQR)
  static String generateBankQRData({
    required String bankName,
    required String accountNumber,
    required String accountName,
    double? amount,
    String? description,
  }) {
    final bankCode = bankCodes[bankName];
    if (bankCode == null) {
      throw ArgumentError('Không tìm thấy mã ngân hàng cho: $bankName');
    }

    // VietQR data format theo EMV QR Code standard
    String qrData = '00020101021238';
    
    // Thêm thông tin ngân hàng
    String bankInfo = '0010A000000727012700065$bankCode$accountNumber';
    qrData += '${bankInfo.length.toString().padLeft(2, '0')}$bankInfo';
    
    // Thêm currency (VND)
    qrData += '5303704';
    
    // Thêm số tiền nếu có
    if (amount != null && amount > 0) {
      String amountStr = amount.toStringAsFixed(0);
      qrData += '54${amountStr.length.toString().padLeft(2, '0')}$amountStr';
    }
    
    // Country code (VN)
    qrData += '5802VN';
    
    // Thêm thông tin bổ sung
    if (description != null && description.isNotEmpty) {
      String addInfo = '05${description.length.toString().padLeft(2, '0')}$description';
      qrData += '62${addInfo.length.toString().padLeft(2, '0')}$addInfo';
    }
    
    // Tính CRC (đơn giản hóa - trong thực tế cần thuật toán CRC16-CCITT)
    qrData += '6304';
    String crc = _calculateCRC16(qrData);
    qrData += crc;
    
    return qrData;
  }

  /// Tạo deep link cho MoMo
  static String generateMoMoDeepLink({
    required String phoneNumber,
    required String receiverName,
    double? amount,
    String? note,
  }) {
    String deepLink = 'momo://transfer';
    List<String> params = [];
    
    params.add('phone=$phoneNumber');
    params.add('name=${Uri.encodeComponent(receiverName)}');
    
    if (amount != null && amount > 0) {
      params.add('amount=${amount.toInt()}');
    }
    
    if (note != null && note.isNotEmpty) {
      params.add('note=${Uri.encodeComponent(note)}');
    }
    
    return '$deepLink?${params.join('&')}';
  }

  /// Tạo deep link cho ZaloPay  
  static String generateZaloPayDeepLink({
    required String phoneNumber,
    required String receiverName,
    double? amount,
    String? note,
  }) {
    String deepLink = 'zalopay://transfer';
    List<String> params = [];
    
    params.add('phone=$phoneNumber');
    params.add('name=${Uri.encodeComponent(receiverName)}');
    
    if (amount != null && amount > 0) {
      params.add('amount=${amount.toInt()}');
    }
    
    if (note != null && note.isNotEmpty) {
      params.add('note=${Uri.encodeComponent(note)}');
    }
    
    return '$deepLink?${params.join('&')}';
  }

  /// Tạo QR data cho ví điện tử
  static String generateEWalletQRData({
    required String walletType, // 'momo', 'zalopay', 'viettelpay'
    required String phoneNumber,
    required String receiverName,
    double? amount,
    String? note,
  }) {
    switch (walletType.toLowerCase()) {
      case 'momo':
        return generateMoMoDeepLink(
          phoneNumber: phoneNumber,
          receiverName: receiverName,
          amount: amount,
          note: note,
        );
      case 'zalopay':
        return generateZaloPayDeepLink(
          phoneNumber: phoneNumber,
          receiverName: receiverName,
          amount: amount,
          note: note,
        );
      case 'viettelpay':
        return 'viettelpay://transfer?phone=$phoneNumber&name=${Uri.encodeComponent(receiverName)}'
            '${amount != null ? "&amount=${amount.toInt()}" : ''}'
            '${note != null ? "&note=${Uri.encodeComponent(note)}" : ''}';
      default:
        throw ArgumentError('Không hỗ trợ loại ví: $walletType');
    }
  }

  /// Validate thông tin ngân hàng
  static bool validateBankInfo({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) {
    if (!bankCodes.containsKey(bankName)) return false;
    if (accountNumber.isEmpty || accountNumber.length < 6) return false;
    if (accountName.isEmpty) return false;
    
    // Kiểm tra số tài khoản chỉ chứa số
    if (!RegExp(r'^\d+$').hasMatch(accountNumber)) return false;
    
    return true;
  }

  /// Validate thông tin ví điện tử
  static bool validateEWalletInfo({
    required String walletType,
    required String phoneNumber,
    required String receiverName,
  }) {
    if (!['momo', 'zalopay', 'viettelpay'].contains(walletType.toLowerCase())) {
      return false;
    }
    
    if (receiverName.isEmpty) return false;
    
    // Validate số điện thoại Việt Nam
    if (!RegExp(r'^(0|\+84)[3-9]\d{8}$').hasMatch(phoneNumber)) return false;
    
    return true;
  }

  /// Tạo QR Code cho thanh toán hóa đơn
  static Future<String> generateInvoiceQR({
    required String paymentMethod, // 'bank' hoặc tên ví
    required Map<String, dynamic> paymentInfo,
    required double amount,
    required String invoiceId,
    String? description,
  }) async {
    String qrData;
    String finalDescription = description ?? 'Thanh toan hoa don $invoiceId';
    
    if (paymentMethod == 'bank') {
      qrData = generateBankQRData(
        bankName: paymentInfo['bankName'],
        accountNumber: paymentInfo['accountNumber'],
        accountName: paymentInfo['accountName'],
        amount: amount,
        description: finalDescription,
      );
    } else() {
      qrData = generateEWalletQRData(
        walletType: paymentMethod,
        phoneNumber: paymentInfo['phoneNumber'],
        receiverName: paymentInfo['receiverName'],
        amount: amount,
        note: finalDescription,
      );
    }
    
    return qrData;
  }

  /// Lấy thông tin ngân hàng từ tên
  static Map<String, String>? getBankInfo(String bankName) {
    final code = bankCodes[bankName];
    if (code == null) return null;
    
    return() {
      'name': bankName,
      'code': code,
    };
  }

  /// Lấy danh sách tất cả ngân hàng hỗ trợ
  static List<String> getSupportedBanks() {
    return bankCodes.keys.toList()..sort();
  }

  /// Đơn giản hóa tính CRC16 (trong thực tế nên dùng thư viện chuyên dụng)
  static String _calculateCRC16(String data) {
    // Đây là implementation đơn giản
    // Trong production nên dùng thuật toán CRC16-CCITT chuẩn
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else() {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Test kết nối VietQR API
  static Future<bool> testVietQRConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_vietQRBaseUrl/970436-1234567890-compact2.png'),
        headers: {"User-Agent": 'SaboArena/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('VietQR connection test failed: $e');
      }
      return false;
    }
  }
}