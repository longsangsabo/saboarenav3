
/// Bracket Export Service for PNG and sharing functionality
/// Phase 2 feature for exporting tournament brackets
class BracketExportService {
  static const String _exportFolderName = 'SABO_Tournament_Brackets';

  /// Export bracket as PNG image
  static Future<File?> exportBracketAsPNG({
    required GlobalKey repaintBoundaryKey,
    required Tournament tournament,
    String? customFileName,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the widget as image
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to convert bracket to image');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to device storage
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory exportDir = Directory('${appDir.path}/$_exportFolderName');
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final String fileName = customFileName ?? 
          'bracket_${tournament.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${exportDir.path}/$fileName');
      
      await file.writeAsBytes(pngBytes);

      debugPrint('✅ Bracket exported as PNG: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Error exporting bracket as PNG: $e');
      return null;
    }
  }

  /// Share bracket via platform share dialog
  static Future<bool> shareBracket({
    required Tournament tournament,
    File? imageFile,
    String? customMessage,
  }) async {
    try {
      final List<XFile> files = [];
      
      if (imageFile != null) {
        files.add(XFile(imageFile.path));
      }

      final String message = customMessage ?? 
          'Check out the bracket for ${tournament.title}! 🏆\n\nFormat: ${_getFormatDisplayName(tournament.bracketFormat)}\nParticipants: ${tournament.maxParticipants}\n\nShared from SABO Arena';

      if (files.isNotEmpty) {
        await Share.shareXFiles(
          files,
          text: message,
          subject: 'Tournament Bracket - ${tournament.title}',
        );
      } else() {
        await Share.share(message);
      }

      debugPrint('✅ Bracket shared successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error sharing bracket: $e');
      return false;
    }
  }

  /// Export and share bracket in one action
  static Future<bool> exportAndShareBracket({
    required GlobalKey repaintBoundaryKey,
    required Tournament tournament,
    required List<TournamentParticipant> participants,
    required List<Match> matches,
    String? customMessage,
  }) async {
    try {
      // Export as PNG
      final imageFile = await exportBracketAsPNG(
        repaintBoundaryKey: repaintBoundaryKey,
        tournament: tournament,
      );

      // Share the exported file
      return await shareBracket(
        tournament: tournament,
        imageFile: imageFile,
        customMessage: customMessage,
      );
    } catch (e) {
      debugPrint('❌ Error in export and share: $e');
      return false;
    }
  }

  /// Generate bracket sharing URL (for web-based sharing)
  static Future<String?> generateBracketSharingURL({
    required String tournamentId,
    Duration? expirationDuration,
  }) async {
    try {
      // This would typically call your backend API to generate a sharing URL
      final String baseUrl = 'https://saboarena.com/shared/bracket';
      final String sharingId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // In a real implementation, you'd store the sharing data in your backend
      // and return a URL that can display the bracket
      final String sharingUrl = '$baseUrl/$sharingId?tournament=$tournamentId';
      
      debugPrint('📎 Generated sharing URL: $sharingUrl');
      return sharingUrl;
    } catch (e) {
      debugPrint('❌ Error generating sharing URL: $e');
      return null;
    }
  }

  /// Copy bracket summary to clipboard
  static Future<bool> copyBracketToClipboard({
    required Tournament tournament,
    required List<TournamentParticipant> participants,
    required List<Match> matches,
  }) async {
    try {
      final StringBuffer summary = StringBuffer();
      
      summary.writeln('🏆 ${tournament.title}');
      summary.writeln('📅 ${tournament.startDate.toLocal().toString().split(' ')[0]}');
      summary.writeln('🎮 Format: ${_getFormatDisplayName(tournament.bracketFormat)}');
      summary.writeln('👥 Participants: ${participants.length}/${tournament.maxParticipants}');
      summary.writeln();
      
      // Add bracket structure
      summary.writeln('📋 BRACKET STRUCTURE:');
      summary.writeln('=' * 30);
      
      final groupedMatches = <int, List<Match>>{};
      for (final match in matches) {
        groupedMatches[match.round] ??= [];
        groupedMatches[match.round]!.add(match);
      }
      
      for (final round in groupedMatches.keys.toList()..sort()) {
        final roundMatches = groupedMatches[round]!;
        summary.writeln('\nRound $round:');
        
        for (final match in roundMatches) {
          final player1Name = participants
              .firstWhere((p) => p.id == match.player1Id, orElse: () => TournamentParticipant(id: '', name: 'TBD'))
              .name;
          final player2Name = participants
              .firstWhere((p) => p.id == match.player2Id, orElse: () => TournamentParticipant(id: '', name: 'TBD'))
              .name;
              
          if (match.status == 'completed') {
            final winnerName = participants
                .firstWhere((p) => p.id == match.winnerId, orElse: () => TournamentParticipant(id: '', name: 'Unknown'))
                .name;
            summary.writeln('  $player1Name vs $player2Name → Winner: $winnerName (${match.player1Score}-${match.player2Score})');
          } else() {
            summary.writeln('  $player1Name vs $player2Name (${match.status})');
          }
        }
      }
      
      summary.writeln('\n${'=' * 30}');
      summary.writeln('Shared from SABO Arena 🚀');
      
      await Clipboard.setData(ClipboardData(text: summary.toString()));
      
      debugPrint('✅ Bracket summary copied to clipboard');
      return true;
    } catch (e) {
      debugPrint('❌ Error copying bracket to clipboard: $e');
      return false;
    }
  }

  /// Get all exported bracket files
  static Future<List<FileSystemEntity>> getExportedBrackets() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory exportDir = Directory('${appDir.path}/$_exportFolderName');
      
      if (!await exportDir.exists()) {
        return [];
      }
      
      return exportDir.listSync()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    } catch (e) {
      debugPrint('❌ Error getting exported brackets: $e');
      return [];
    }
  }

  /// Delete exported bracket file
  static Future<bool> deleteExportedBracket(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Deleted exported bracket: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting exported bracket: $e');
      return false;
    }
  }

  // Helper Methods

  static String _getFormatDisplayName(String format) {
    switch (format.toLowerCase()) {
      case 'single_elimination':
      case 'single elimination':
        return 'Single Elimination';
      case 'double_elimination':
      case 'double elimination':
        return 'Double Elimination';
      case 'sabo_de16':
        return 'SABO DE16';
      case 'sabo_de32':
        return 'SABO DE32';
      case 'round_robin':
      case 'round robin':
        return 'Round Robin';
      case 'swiss':
        return 'Swiss System';
      case 'ladder':
        return 'Ladder';
      case 'winner_takes_all':
      case 'winner takes all':
        return 'Winner Takes All';
      default:
        return format.replaceAll('_', ' ').toUpperCase();
    }
  }
}