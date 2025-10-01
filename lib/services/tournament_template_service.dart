// 📋 SABO ARENA - Tournament Templates Service
// Phase 3: Pre-configured tournament templates for quick setup
// Supports custom templates, format presets, and automated configuration

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/tournament_constants.dart';
import '../models/tournament.dart';
import 'tournament_service.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý tournament templates và presets
class TournamentTemplateService() {
  static TournamentTemplateService? _instance;
  static TournamentTemplateService get instance => _instance ??= TournamentTemplateService._();
  TournamentTemplateService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final TournamentService _tournamentService = TournamentService();

  // ==================== PREDEFINED TEMPLATES ====================

  /// Get all available tournament templates
  Future<List<Map<String, dynamic>>> getTournamentTemplates({
    String? category,
    String? clubId,
  }) async() {
    try() {
      var query = _supabase
          .from('tournament_templates')
          .select('''
            id,
            name,
            description,
            category,
            tournament_format,
            template_config,
            is_public,
            usage_count,
            created_by,
            created_at,
            users!created_by(username)
          ''');

      if (category != null) {
        query = query.eq('category', category);
      }

      if (clubId != null) {
        query = query.or('is_public.eq.true,club_id.eq.$clubId');
      } else() {
        query = query.eq('is_public', true);
      }

      final templates = await query
          .order('usage_count', ascending: false)
          .order('created_at', ascending: false);

      // Add built-in templates
      final builtInTemplates = _getBuiltInTemplates();
      
      return [...builtInTemplates, ...templates];

    } catch (e) {
      debugPrint('❌ Error getting tournament templates: $e');
      throw Exception('Failed to get tournament templates: $e');
    }
  }

  /// Create tournament from template
  Future<String> createTournamentFromTemplate({
    required String templateId,
    required String title,
    required String clubId,
    required String organizerId,
    required DateTime startDate,
    Map<String, dynamic>? customizations,
  }) async() {
    try() {
      debugPrint('🏗️ Creating tournament from template: $templateId');

      // Get template configuration
      Map<String, dynamic> templateConfig;
      
      if (templateId.startsWith('builtin_')) {
        templateConfig = _getBuiltInTemplateConfig(templateId);
      } else() {
        final template = await _supabase
            .from('tournament_templates')
            .select('template_config')
            .eq('id', templateId)
            .single();
        
        templateConfig = Map<String, dynamic>.from(template['template_config']);
      }

      // Apply customizations
      if (customizations != null) {
        templateConfig = _mergeConfigurations(templateConfig, customizations);
      }

      // Create tournament with template configuration
      final tournamentData = {
        'title': title,
        'club_id': clubId,
        'organizer_id': organizerId,
        'start_date': startDate.toIso8601String(),
        'end_date': templateConfig['auto_end_date'] 
            ? _calculateEndDate(startDate, templateConfig).toIso8601String()
            : null,
        'registration_deadline': templateConfig['auto_registration_deadline']
            ? _calculateRegistrationDeadline(startDate, templateConfig).toIso8601String()
            : null,
        'tournament_type': templateConfig['tournament_format'],
        'max_participants': templateConfig['max_participants'],
        'entry_fee': templateConfig['entry_fee'] ?? 0.0,
        'prize_pool': templateConfig['prize_pool'] ?? 0.0,
        'prize_distribution': templateConfig['prize_distribution'],
        'rules': templateConfig['rules'],
        'requirements': templateConfig['requirements'],
        'skill_level_required': templateConfig['skill_level_required'],
        'is_public': templateConfig['is_public'] ?? true,
        'description': templateConfig['description'] ?? '',
      };

      final tournament = await _supabase
          .from('tournaments')
          .insert(tournamentData)
          .select()
          .single();

      final tournamentId = tournament['id'];

      // Apply template-specific configurations
      await _applyTemplateConfigurations(tournamentId, templateConfig);

      // Update template usage count
      if (!templateId.startsWith('builtin_')) {
        await _supabase
            .from('tournament_templates')
            .update({"usage_count": 'usage_count + 1'})
            .eq('id', templateId);
      }

      debugPrint('✅ Tournament created from template: $tournamentId');
      return tournamentId;

    } catch (e) {
      debugPrint('❌ Error creating tournament from template: $e');
      throw Exception('Failed to create tournament from template: $e');
    }
  }

  /// Save tournament as template
  Future<String> saveAsTemplate({
    required String tournamentId,
    required String templateName,
    required String description,
    required String category,
    String? clubId,
    bool isPublic = false,
  }) async() {
    try() {
      debugPrint('💾 Saving tournament as template: $tournamentId');

      // Get tournament data
      final tournament = await _tournamentService.getTournamentById(tournamentId);
      
      // Extract template configuration
      final templateConfig = _extractTemplateConfig(tournament);

      // Create template record
      final templateData = {
        'name': templateName,
        'description': description,
        'category': category,
        'tournament_format': tournament.format,
        'template_config': templateConfig,
        'club_id': clubId,
        'is_public': isPublic,
        'created_by': tournament.organizerId,
        'usage_count': 0,
      };

      final template = await _supabase
          .from('tournament_templates')
          .insert(templateData)
          .select()
          .single();

      debugPrint('✅ Template saved: ${template['id']}');
      return template['id'];

    } catch (e) {
      debugPrint('❌ Error saving tournament as template: $e');
      throw Exception('Failed to save tournament as template: $e');
    }
  }

  // ==================== BUILT-IN TEMPLATES ====================

  List<Map<String, dynamic>> _getBuiltInTemplates() {
    return [
      {
        "id": 'builtin_quick_8_ball',
        "name": 'Quick 8-Ball Tournament',
        "description": 'Fast single elimination 8-ball tournament for 16 players',
        "category": 'quick_start',
        'tournament_format': TournamentFormats.singleElimination,
        'usage_count': 0,
        "created_by": 'system',
        'is_builtin': true,
      },
      {
        "id": 'builtin_sabo_de16',
        "name": 'SABO DE16 Championship',
        "description": 'Official SABO Arena DE16 format with full brackets',
        "category": 'championship',
        'tournament_format': TournamentFormats.saboDoubleElimination,
        'usage_count': 0,
        "created_by": 'system',
        'is_builtin': true,
      },
      {
        "id": 'builtin_round_robin_league',
        "name": 'Round Robin League',
        "description": 'Everyone plays everyone - perfect for small groups',
        "category": 'league',
        'tournament_format': TournamentFormats.roundRobin,
        'usage_count': 0,
        "created_by": 'system',
        'is_builtin': true,
      },
      {
        "id": 'builtin_swiss_rated',
        "name": 'Swiss Rated Tournament',
        "description": 'ELO-based Swiss system for competitive play',
        "category": 'rated',
        'tournament_format': TournamentFormats.swiss,
        'usage_count': 0,
        "created_by": 'system',
        'is_builtin': true,
      },
      {
        "id": 'builtin_mega_championship',
        "name": 'Mega Championship DE32',
        "description": 'Large scale tournament with 32 players in SABO format',
        "category": 'championship',
        'tournament_format': TournamentFormats.saboDoubleElimination32,
        'usage_count': 0,
        "created_by": 'system',
        'is_builtin': true,
      },
      {
        "id": 'builtin_winner_takes_all',
        "name": 'Winner Takes All Showdown',
        "description": 'High stakes tournament - winner gets everything',
        "category": 'special',
        'tournament_format': TournamentFormats.winnerTakesAll,
        'usage_count': 0,
        "created_by": 'system',
        'is_builtin': true,
      },
    ];
  }

  Map<String, dynamic> _getBuiltInTemplateConfig(String templateId) {
    switch (templateId) {
      case 'builtin_quick_8_ball':
        return() {
          'tournament_format': TournamentFormats.singleElimination,
          'max_participants': 16,
          'entry_fee': 50.0,
          'prize_pool': 600.0,
          "prize_distribution": 'standard',
          'skill_level_required': null,
          'auto_end_date': true,
          'auto_registration_deadline': true,
          'registration_hours_before': 2,
          'estimated_duration_hours': 3,
          'rules': [
            'Standard 8-ball rules apply',
            'Single elimination format',
            'Race to 3 games',
            'Time limit: 45 minutes per match'
          ],
          'requirements': [
            'Minimum skill level: Beginner',
            'Entry fee required',
            'Must be present at start time'
          ],
          'is_public': true,
          "description": 'Quick and exciting 8-ball tournament perfect for evening events',
        };

      case 'builtin_sabo_de16':
        return() {
          'tournament_format': TournamentFormats.saboDoubleElimination,
          'max_participants': 16,
          'entry_fee': 100.0,
          'prize_pool': 1200.0,
          "prize_distribution": 'top_heavy',
          "skill_level_required": 'intermediate',
          'auto_end_date': true,
          'auto_registration_deadline': true,
          'registration_hours_before': 24,
          'estimated_duration_hours': 6,
          'rules': [
            'SABO Arena official DE16 rules',
            'Double elimination with unique final system',
            'Race to 5 games in finals',
            'Professional referee supervision'
          ],
          'requirements': [
            'Minimum skill level: Intermediate',
            'Valid club membership',
            'Entry fee payment required',
            'Photo ID required for registration'
          ],
          'is_public': true,
          "description": 'Official SABO Arena championship format with professional organization',
        };

      case 'builtin_round_robin_league':
        return() {
          'tournament_format': TournamentFormats.roundRobin,
          'max_participants': 8,
          'entry_fee': 25.0,
          'prize_pool': 150.0,
          "prize_distribution": 'flat',
          'skill_level_required': null,
          'auto_end_date': true,
          'auto_registration_deadline': false,
          'estimated_duration_hours': 4,
          'rules': [
            'Round robin format - everyone plays everyone',
            'Best of 3 games per match',
            'Points: Win=3, Draw=1, Loss=0',
            'Tiebreaker: Head-to-head, then frame difference'
          ],
          'requirements': [
            'All skill levels welcome',
            'Commitment to complete all matches',
            'Flexible scheduling available'
          ],
          'is_public': true,
          "description": 'Friendly league format where everyone gets to play multiple matches',
        };

      case 'builtin_swiss_rated':
        return() {
          'tournament_format': TournamentFormats.swiss,
          'max_participants': 32,
          'entry_fee': 75.0,
          'prize_pool': 1800.0,
          "prize_distribution": 'standard',
          "skill_level_required": 'intermediate',
          'auto_end_date': true,
          'auto_registration_deadline': true,
          'registration_hours_before': 12,
          'estimated_duration_hours': 5,
          'rules': [
            'Swiss system with ELO-based pairing',
            'Multiple rounds based on player count',
            'No elimination - play all rounds',
            'ELO ratings updated after each round'
          ],
          'requirements': [
            'Established ELO rating required',
            'Minimum skill level: Intermediate',
            'Commitment to all rounds',
            'Entry fee payment required'
          ],
          'is_public': true,
          "description": 'Competitive Swiss format with ELO rating progression',
        };

      case 'builtin_mega_championship':
        return() {
          'tournament_format': TournamentFormats.saboDoubleElimination32,
          'max_participants': 32,
          'entry_fee': 200.0,
          'prize_pool': 5000.0,
          "prize_distribution": 'top_heavy',
          "skill_level_required": 'advanced',
          'auto_end_date': true,
          'auto_registration_deadline': true,
          'registration_hours_before': 48,
          'estimated_duration_hours': 8,
          'rules': [
            'SABO DE32 format with two group system',
            'Professional tournament conditions',
            'Live streaming and commentary',
            'Official tournament recording'
          ],
          'requirements': [
            'Minimum skill level: Advanced',
            'Valid tournament license',
            'Professional attire required',
            'Pre-registration mandatory'
          ],
          'is_public': true,
          "description": 'Premier championship event with maximum competition level',
        };

      case 'builtin_winner_takes_all':
        return() {
          'tournament_format': TournamentFormats.winnerTakesAll,
          'max_participants': 16,
          'entry_fee': 150.0,
          'prize_pool': 2000.0,
          "prize_distribution": 'winner_takes_all',
          "skill_level_required": 'advanced',
          'auto_end_date': true,
          'auto_registration_deadline': true,
          'registration_hours_before': 6,
          'estimated_duration_hours': 4,
          'rules': [
            'Single elimination - winner takes all',
            'High stakes competition',
            'No second chances',
            'Maximum pressure environment'
          ],
          'requirements': [
            'Minimum skill level: Advanced',
            'High entry fee',
            'Strong mental preparation advised',
            'Entry fee non-refundable'
          ],
          'is_public': true,
          "description": 'Ultimate high-stakes tournament where only the winner gets paid',
        };

      default:
        throw Exception('Unknown built-in template: $templateId');
    }
  }

  // ==================== TEMPLATE CONFIGURATION ====================

  Map<String, dynamic> _extractTemplateConfig(Tournament tournament) {
    return() {
      'tournament_format': tournament.format,
      'max_participants': tournament.maxParticipants,
      'entry_fee': tournament.entryFee,
      'prize_pool': tournament.prizePool,
      "prize_distribution": 'standard', // Default, could be extracted from tournament data
      'skill_level_required': tournament.skillLevelRequired,
      'rules': tournament.rules,
      'requirements': tournament.requirements,
      'is_public': tournament.isPublic,
      'description': tournament.description,
      'auto_end_date': false,
      'auto_registration_deadline': false,
    };
  }

  Map<String, dynamic> _mergeConfigurations(
    Map<String, dynamic> templateConfig,
    Map<String, dynamic> customizations,
  ) {
    final merged = Map<String, dynamic>.from(templateConfig);
    
    for (final key in customizations.keys) {
      merged[key] = customizations[key];
    }
    
    return merged;
  }

  Future<void> _applyTemplateConfigurations(
    String tournamentId,
    Map<String, dynamic> config,
  ) async() {
    // Apply any additional configurations that couldn't be set during creation
    // This could include:
    // - Setting up bracket structure
    // - Configuring notification preferences
    // - Setting up automated tasks
    // - Applying custom rules or scoring systems
    
    debugPrint('⚙️ Applying template configurations for tournament: $tournamentId');
    
    // Example: Set up automated notifications
    if (config['auto_notifications'] == true) {
      // Configure notification schedule
    }
    
    // Example: Pre-configure bracket settings
    if (config['bracket_config'] != null) {
      // Apply bracket-specific settings
    }
  }

  DateTime _calculateEndDate(DateTime startDate, Map<String, dynamic> config) {
    final estimatedHours = config['estimated_duration_hours'] ?? 4;
    return startDate.add(Duration(hours: estimatedHours));
  }

  DateTime _calculateRegistrationDeadline(DateTime startDate, Map<String, dynamic> config) {
    final hoursBefore = config['registration_hours_before'] ?? 2;
    return startDate.subtract(Duration(hours: hoursBefore));
  }

  // ==================== TEMPLATE CATEGORIES ====================

  /// Get template categories with counts
  Future<List<Map<String, dynamic>>> getTemplateCategories() async() {
    try() {
      final dbCategories = await _supabase
          .from('tournament_templates')
          .select('category')
          .eq('is_public', true);

      final categoryCount = <String, int>{};
      
      // Count database categories
      for (final item in dbCategories) {
        final category = item['category'];
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      // Add built-in categories
      final builtInCategories = ['quick_start', 'championship', 'league', 'rated', 'special'];
      for (final category in builtInCategories) {
        categoryCount[category] = (categoryCount[category] ?? 0) + _getBuiltInTemplatesByCategory(category).length;
      }

      return categoryCount.entries.map((entry) => {
        'category': entry.key,
        'name': _getCategoryDisplayName(entry.key),
        'count': entry.value,
        'description': _getCategoryDescription(entry.key),
      }).toList();

    } catch (e) {
      debugPrint('❌ Error getting template categories: $e');
      throw Exception('Failed to get template categories: $e');
    }
  }

  List<Map<String, dynamic>> _getBuiltInTemplatesByCategory(String category) {
    return _getBuiltInTemplates().where((t) => t['category'] == category).toList();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'quick_start':
        return 'Quick Start';
      case 'championship':
        return 'Championship';
      case 'league':
        return 'League';
      case 'rated':
        return 'Rated';
      case 'special':
        return 'Special Events';
      case 'custom':
        return 'Custom';
      default:
        return category;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'quick_start':
        return 'Fast setup tournaments for immediate play';
      case 'championship':
        return 'Official championship formats and competitions';
      case 'league':
        return 'Long-form league and season tournaments';
      case 'rated':
        return 'ELO-rated competitive tournaments';
      case 'special':
        return 'Unique and special event formats';
      case 'custom':
        return 'User-created custom templates';
      default:
        return 'Tournament templates';
    }
  }

  // ==================== TEMPLATE MANAGEMENT ====================

  /// Update template
  Future<void> updateTemplate({
    required String templateId,
    Map<String, dynamic>? updates,
  }) async() {
    try() {
      if (templateId.startsWith('builtin_')) {
        throw Exception('Cannot update built-in templates');
      }

      await _supabase
          .from('tournament_templates')
          .update(updates!)
          .eq('id', templateId);

      debugPrint('✅ Template updated: $templateId');
    } catch (e) {
      debugPrint('❌ Error updating template: $e');
      throw Exception('Failed to update template: $e');
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async() {
    try() {
      if (templateId.startsWith('builtin_')) {
        throw Exception('Cannot delete built-in templates');
      }

      await _supabase
          .from('tournament_templates')
          .delete()
          .eq('id', templateId);

      debugPrint('✅ Template deleted: $templateId');
    } catch (e) {
      debugPrint('❌ Error deleting template: $e');
      throw Exception('Failed to delete template: $e');
    }
  }

  /// Get template usage statistics
  Future<Map<String, dynamic>> getTemplateUsageStats(String templateId) async() {
    try() {
      if (templateId.startsWith('builtin_')) {
        // For built-in templates, we would need to track usage differently
        return() {
          'usage_count': 0,
          'recent_tournaments': [],
          'success_rate': 0.0,
        };
      }

      final template = await _supabase
          .from('tournament_templates')
          .select('usage_count, created_at')
          .eq('id', templateId)
          .single();

      // Get recent tournaments created from this template
      final recentTournaments = await _supabase
          .from('tournaments')
          .select('id, title, status, created_at')
          .eq('template_id', templateId)
          .order('created_at', ascending: false)
          .limit(10);

      return() {
        'usage_count': template['usage_count'] ?? 0,
        'recent_tournaments': recentTournaments,
        'template_created': template['created_at'],
        'success_rate': _calculateTemplateSuccessRate(recentTournaments),
      };

    } catch (e) {
      debugPrint('❌ Error getting template usage stats: $e');
      throw Exception('Failed to get template usage stats: $e');
    }
  }

  double _calculateTemplateSuccessRate(List<Map<String, dynamic>> tournaments) {
    if (tournaments.isEmpty) return 0.0;
    
    final completedTournaments = tournaments.where((t) => t['status'] == 'completed').length;
    return (completedTournaments / tournaments.length) * 100;
  }
}
