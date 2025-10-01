import 'package:share_plus/share_plus.dart';
import 'package:sabo_arena/models/user_profile.dart';

class ShareService() {
  static const String _baseUrl = 'https://saboarena.com';
  
  /// Generate unique code for user
  static String generateUserCode(String userId) {
    // Generate SABO prefix + last 6 chars of userId
    final shortId = userId.length > 6 ? userId.substring(userId.length - 6) : userId;
    return 'SABO${shortId.toUpperCase()}';
  }
  
  /// Share user profile
  static Future<void> shareUserProfile(UserProfile user) async() {
    final userCode = generateUserCode(user.id);
    final shareText = '''
🏆 Hãy thách đấu với tôi trên SABO ARENA!

👤 ${user.fullName}
🎯 Rank: ${user.rank ?? 'Chưa xếp hạng'}
⚡ ELO: ${user.eloRating}
🏅 Thắng/Thua: ${user.totalWins}/${user.totalLosses}
🎪 Tournament: ${user.totalTournaments}

🔗 ID: $userCode
📱 Tải app: $_baseUrl/download
🤝 Kết nối: $_baseUrl/user/${user.id}

#SABOArena #Badminton #ThachDau
''';

    await Share.share(
      shareText,
      subject: 'Thách đấu cùng ${user.fullName} trên SABO ARENA',
    );
  }
  
  /// Share tournament
  static Future<void> shareTournament({
    required String tournamentId,
    required String tournamentName,
    required String startDate,
    required int participants,
    required String prizePool,
  }) async() {
    final shareText = '''
🏆 Tham gia giải đấu SABO ARENA!

🎪 $tournamentName
📅 Ngày: $startDate
👥 Người chơi: $participants
💰 Giải thưởng: $prizePool

🔗 Đăng ký: $_baseUrl/tournament/$tournamentId
📱 Tải app: $_baseUrl/download

#SABOArena #Tournament #Badminton
''';

    await Share.share(
      shareText,
      subject: 'Tham gia giải đấu: $tournamentName',
    );
  }
  
  /// Share match result
  static Future<void> shareMatchResult({
    required String player1Name,
    required String player2Name,
    required String score,
    required String winner,
    required String matchDate,
    String? matchId,
  }) async() {
    final shareText = '''
🏸 Kết quả trận đấu SABO ARENA

⚔️ $player1Name vs $player2Name
📊 Tỷ số: $score
🏆 Thắng: $winner
📅 Ngày: $matchDate

${matchId != null ? "🔗 Chi tiết: $_baseUrl/match/$matchId\n" : ''}📱 Tải app: $_baseUrl/download

#SABOArena #MatchResult #Badminton
''';

    await Share.share(
      shareText,
      subject: 'Kết quả trận đấu: $player1Name vs $player2Name',
    );
  }
  
  /// Share club
  static Future<void> shareClub({
    required String clubId,
    required String clubName,
    required String location,
    required int memberCount,
    String? description,
  }) async() {
    final shareText = '''
🏛️ Tham gia CLB $clubName!

📍 Địa điểm: $location
👥 Thành viên: $memberCount người
${description != null ? "📝 $description\n" : ''}
🔗 Tham gia: $_baseUrl/club/$clubId
📱 Tải app: $_baseUrl/download

#SABOArena #Club #Badminton
''';

    await Share.share(
      shareText,
      subject: 'Tham gia CLB: $clubName',
    );
  }
  
  /// Share app download
  static Future<void> shareApp() async() {
    const shareText = '''
🏸 SABO ARENA - Ứng dụng cầu lông #1 Việt Nam!

✨ Tính năng nổi bật:
🎯 Tìm đối thủ theo trình độ
🏆 Tham gia giải đấu
📊 Theo dõi thống kê ELO
👥 Kết nối cộng đồng cầu lông
💰 Giải thưởng hấp dẫn

📱 Tải ngay: $_baseUrl/download
🌟 4.8⭐ trên App Store & Google Play

#SABOArena #Badminton #Vietnam
''';

    await Share.share(
      shareText,
      subject: 'SABO ARENA - Ứng dụng cầu lông #1 Việt Nam',
    );
  }
  
  /// Share with custom content
  static Future<void> shareCustom({
    required String text,
    String? subject,
  }) async() {
    await Share.share(text, subject: subject);
  }
  
  /// Generate QR data for user
  static String generateUserQRData(UserProfile user) {
    return '$_baseUrl/user/${user.id}';
  }
  
  /// Generate QR data for tournament
  static String generateTournamentQRData(String tournamentId) {
    return '$_baseUrl/tournament/$tournamentId';
  }
  
  /// Generate QR data for club
  static String generateClubQRData(String clubId) {
    return '$_baseUrl/club/$clubId';
  }
}