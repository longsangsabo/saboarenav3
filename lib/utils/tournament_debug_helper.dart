/// Debug utility để kiểm tra tournament participants trực tiếp
class TournamentDebugHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Kiểm tra tất cả tournaments và participants count
  static Future<void> debugAllTournaments() async {
    try {
      debugPrint('🔍 === TOURNAMENT DEBUG START ===');

      // 1. Lấy tất cả tournaments
      final tournaments = await _supabase
          .from('tournaments')
          .select('id, title, max_participants, current_participants, status')
          .order('created_at', ascending: false);

      debugPrint('📊 Found ${tournaments.length} tournaments:');

      for (final tournament in tournaments) {
        final tournamentId = tournament['id'];
        final title = tournament['title'];

        debugPrint('\n🏆 Tournament: $title (ID: $tournamentId)');
        debugPrint(
            '   Max: ${tournament['max_participants']}, Current: ${tournament['current_participants']}, Status: ${tournament['status']}');

        // 2. Đếm participants thực tế trong database
        final participantsResponse = await _supabase
            .from('tournament_participants')
            .select('id')
            .eq('tournament_id', tournamentId);

        final actualCount = participantsResponse.length;
        debugPrint('   💡 Actual participants in DB: $actualCount');

        // 3. Kiểm tra payment status distribution
        final participants = await _supabase
            .from('tournament_participants')
            .select('payment_status, status')
            .eq('tournament_id', tournamentId);

        final confirmed = participants
            .where((p) => p['payment_status'] == 'confirmed')
            .length;
        final pending =
            participants.where((p) => p['payment_status'] == 'pending').length;

        debugPrint(
            '   💰 Payment Status - Confirmed: $confirmed, Pending: $pending');

        // 4. Nếu có mismatch, show chi tiết
        if (actualCount != (tournament['current_participants'] ?? 0)) {
          debugPrint('   ⚠️  MISMATCH DETECTED!');
          await _debugSpecificTournament(tournamentId);
        }
      }

      debugPrint('\n🔍 === TOURNAMENT DEBUG END ===');
    } catch (e) {
      debugPrint('❌ Debug error: $e');
    }
  }

  /// Debug chi tiết một tournament cụ thể
  static Future<void> _debugSpecificTournament(String tournamentId) async {
    try {
      debugPrint('\n🔍 === DETAILED DEBUG FOR $tournamentId ===');

      // Raw participants query
      final participants = await _supabase
          .from('tournament_participants')
          .select('id, user_id, payment_status, status, registered_at')
          .eq('tournament_id', tournamentId)
          .order('registered_at');

      debugPrint('📊 Raw participants: ${participants.length}');

      for (int i = 0; i < participants.length; i++) {
        final p = participants[i];
        debugPrint(
            '   ${i + 1}. User ID: ${p['user_id']}, Payment: ${p['payment_status']}, Status: ${p['status']}');
      }

      // Test join query
      try {
        final withUsers =
            await _supabase.from('tournament_participants').select('''
              *,
              users (
                id,
                full_name,
                email
              )
            ''').eq('tournament_id', tournamentId);

        debugPrint('📊 With users join: ${withUsers.length}');

        final nullUsers = withUsers.where((p) => p['users'] == null).length;
        if (nullUsers > 0) {
          debugPrint('   ⚠️  $nullUsers participants have null user data!');
        }
      } catch (e) {
        debugPrint('   ❌ Join query failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Specific debug error: $e');
    }
  }

  /// Gọi từ UI để trigger debug
  static Future<void> debugFromUI(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Running tournament debug... Check console')),
    );

    await debugAllTournaments();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug completed - check console logs')),
    );
  }
}
