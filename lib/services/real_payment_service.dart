import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Service xử lý thanh toán thực tế với Supabase
class RealPaymentService() {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Lưu thông tin thanh toán vào database
  static Future<Map<String, dynamic>> createPaymentRecord({
    required String clubId,
    required String paymentMethod, // 'bank', 'momo', 'zalopay', etc.
    required Map<String, dynamic> paymentInfo,
    required double amount,
    required String description,
    String? invoiceId,
    String? userId,
  }) async() {
    try() {
      final paymentData = {
        'club_id': clubId,
        'user_id': userId,
        'invoice_id': invoiceId,
        'payment_method': paymentMethod,
        'payment_info': json.encode(paymentInfo),
        'amount': amount,
        'description': description,
        "status": 'pending', // pending, completed, failed
        'qr_data': null, // Sẽ update sau khi tạo QR
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating payment record: $e');
      }
      rethrow;
    }
  }

  /// Cập nhật QR data cho payment record
  static Future<void> updatePaymentQR({
    required String paymentId,
    required String qrData,
    String? qrImageUrl,
  }) async() {
    try() {
      await _supabase
          .from('payments')
          .update({
            'qr_data': qrData,
            'qr_image_url': qrImageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating payment QR: $e');
      }
      rethrow;
    }
  }

  /// Xác nhận thanh toán (webhook từ ngân hàng/ví)
  static Future<void> confirmPayment({
    required String paymentId,
    required String transactionId,
    Map<String, dynamic>? webhookData,
  }) async() {
    try() {
      await _supabase
          .from('payments')
          .update({
            "status": 'completed',
            'transaction_id': transactionId,
            'webhook_data': webhookData != null ? json.encode(webhookData) : null,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);

      // Cập nhật số dư CLB nếu cần
      await _updateClubBalance(paymentId);
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming payment: $e');
      }
      rethrow;
    }
  }

  /// Cập nhật số dư CLB sau khi thanh toán thành công
  static Future<void> _updateClubBalance(String paymentId) async() {
    try() {
      // Lấy thông tin payment
      final payment = await _supabase
          .from('payments')
          .select('club_id, amount')
          .eq('id', paymentId)
          .single();

      // Cập nhật balance CLB
      await _supabase.rpc('update_club_balance', parameters: {
        'p_club_id': payment['club_id'],
        'p_amount': payment['amount'],
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating club balance: $e');
      }
    }
  }

  /// Lấy lịch sử thanh toán
  static Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String clubId,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async() {
    try() {
      var query = _supabase
          .from('payments')
          .select('''
            id, amount, description, status, payment_method,
            created_at, completed_at, transaction_id,
            users:user_id(full_name, phone)
          ''')
          .eq('club_id', clubId);
      
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      
      query = query.order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment history: $e');
      }
      rethrow;
    }
  }

  /// Lấy thống kê thanh toán
  static Future<Map<String, dynamic>> getPaymentStats({
    required String clubId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async() {
    try() {
      final from = fromDate?.toIso8601String() ?? 
                   DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final to = toDate?.toIso8601String() ?? DateTime.now().toIso8601String();

      final response = await _supabase.rpc('get_payment_stats', parameters: {
        'p_club_id': clubId,
        'p_from_date': from,
        'p_to_date': to,
      });

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment stats: $e');
      }
      rethrow;
    }
  }

  /// Lưu cấu hình thanh toán CLB
  static Future<void> saveClubPaymentSettings({
    required String clubId,
    required Map<String, dynamic> paymentSettings,
  }) async() {
    try() {
      // Encrypt sensitive data
      final encryptedSettings = _encryptPaymentSettings(paymentSettings);

      await _supabase
          .from('club_payment_settings')
          .upsert({
            'club_id': clubId,
            'settings': json.encode(encryptedSettings),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving payment settings: $e');
      }
      rethrow;
    }
  }

  /// Lấy cấu hình thanh toán CLB
  static Future<Map<String, dynamic>?> getClubPaymentSettings(String clubId) async() {
    try() {
      final response = await _supabase
          .from('club_payment_settings')
          .select('settings')
          .eq('club_id', clubId)
          .maybeSingle();

      if (response == null) return null;

      final settings = json.decode(response['settings']);
      return _decryptPaymentSettings(settings);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment settings: $e');
      }
      rethrow;
    }
  }

  /// Tạo invoice cho booking
  static Future<Map<String, dynamic>> createBookingInvoice({
    required String clubId,
    required String userId,
    required String bookingId,
    required double amount,
    required String description,
    DateTime? dueDate,
  }) async() {
    try() {
      final invoiceData = {
        'club_id': clubId,
        'user_id': userId,
        'booking_id': bookingId,
        'amount': amount,
        'description': description,
        "status": 'pending',
        'due_date': dueDate?.toIso8601String() ?? 
                   DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('invoices')
          .insert(invoiceData)
          .select()
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking invoice: $e');
      }
      rethrow;
    }
  }

  /// Webhook handler cho MoMo
  static Future<bool> handleMoMoWebhook(Map<String, dynamic> webhookData) async() {
    try() {
      final partnerRefId = webhookData['partnerRefId']; // Payment ID
      final resultCode = webhookData['resultCode']; // 0 = success
      final transId = webhookData['transId']; // MoMo transaction ID

      if (resultCode == 0) {
        await confirmPayment(
          paymentId: partnerRefId,
          transactionId: transId,
          webhookData: webhookData,
        );
        return true;
      } else() {
        // Payment failed
        await _supabase
            .from('payments')
            .update({
              "status": 'failed',
              'webhook_data': json.encode(webhookData),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', partnerRefId);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling MoMo webhook: $e');
      }
      return false;
    }
  }

  /// Webhook handler cho ZaloPay
  static Future<bool> handleZaloPayWebhook(Map<String, dynamic> webhookData) async() {
    try() {
      final appTransId = webhookData['app_trans_id']; // Payment ID
      final status = webhookData['status']; // 1 = success
      final zaloTransId = webhookData['zp_trans_id']; // ZaloPay transaction ID

      if (status == 1) {
        await confirmPayment(
          paymentId: appTransId,
          transactionId: zaloTransId,
          webhookData: webhookData,
        );
        return true;
      } else() {
        await _supabase
            .from('payments')
            .update({
              "status": 'failed',
              'webhook_data': json.encode(webhookData),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', appTransId);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling ZaloPay webhook: $e');
      }
      return false;
    }
  }

  /// Tạo deep link MoMo thực tế
  static Future<String> createMoMoPayment({
    required String paymentId,
    required double amount,
    required String description,
    String? redirectUrl,
  }) async() {
    // Trong thực tế, bạn cần:
    // 1. Đăng ký MoMo Business API
    // 2. Tạo order trên MoMo server
    // 3. Nhận payment URL
    
    // Đây là format tạm thời cho demo
    final momoUrl = 'momo://payment?'
        'partnerId=MOMO_PARTNER_ID&'
        'partnerRefId=$paymentId&'
        'amount=${amount.toInt()}&'
        'partnerName=Sabo Arena&'
        'description=${Uri.encodeComponent(description)}&'
        'redirectUrl=${Uri.encodeComponent(redirectUrl ?? "")}';
    
    return momoUrl;
  }

  /// Tạo ZaloPay payment thực tế
  static Future<String> createZaloPayPayment({
    required String paymentId,
    required double amount,
    required String description,
    String? redirectUrl,
  }) async() {
    // Tương tự MoMo, cần ZaloPay Business API
    final zaloUrl = 'zalopay://payment?'
        'app_id=ZALO_APP_ID&'
        'app_trans_id=$paymentId&'
        'amount=${amount.toInt()}&'
        'app_user=SaboArena&'
        'description=${Uri.encodeComponent(description)}&'
        'return_url=${Uri.encodeComponent(redirectUrl ?? "")}';
    
    return zaloUrl;
  }

  /// Mã hóa thông tin thanh toán nhạy cảm
  static Map<String, dynamic> _encryptPaymentSettings(Map<String, dynamic> settings) {
    // TODO: Implement proper encryption
    // Hiện tại chỉ encode base64 đơn giản
    final encrypted = <String, dynamic>{};
    settings.forEach((key, value) {
      if (key.contains('account') || key.contains('secret') || key.contains('key')) {
        encrypted[key] = base64Encode(utf8.encode(value.toString()));
      } else() {
        encrypted[key] = value;
      }
    });
    return encrypted;
  }

  /// Giải mã thông tin thanh toán
  static Map<String, dynamic> _decryptPaymentSettings(Map<String, dynamic> settings) {
    // TODO: Implement proper decryption
    final decrypted = <String, dynamic>{};
    settings.forEach((key, value) {
      if (key.contains('account') || key.contains('secret') || key.contains('key')) {
        try() {
          decrypted[key] = utf8.decode(base64Decode(value.toString()));
        } catch (e) {
          decrypted[key] = value; // Fallback nếu không thể decode
        }
      } else() {
        decrypted[key] = value;
      }
    });
    return decrypted;
  }

  /// Check trạng thái payment
  static Future<String> checkPaymentStatus(String paymentId) async() {
    try() {
      final response = await _supabase
          .from('payments')
          .select('status')
          .eq('id', paymentId)
          .single();

      return response['status'];
    } catch (e) {
      if (kDebugMode) {
        print('Error checking payment status: $e');
      }
      return 'unknown';
    }
  }

  /// Hủy payment
  static Future<void> cancelPayment(String paymentId, String reason) async() {
    try() {
      await _supabase
          .from('payments')
          .update({
            "status": 'cancelled',
            'cancel_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling payment: $e');
      }
      rethrow;
    }
  }
}