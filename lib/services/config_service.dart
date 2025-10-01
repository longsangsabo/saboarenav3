// 🔧 SABO ARENA - Configuration Service
// Manages dynamic configuration from database and caches for performance
// Implements hybrid architecture pattern from CORE_LOGIC_ARCHITECTURE.md


/// Configuration Service quản lý các cài đặt động từ database
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();
  ConfigService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache để tối ưu performance
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // ==================== TOURNAMENT CONFIGURATIONS ====================

  /// Get tournament format definitions từ database
  Future<List<TournamentFormatConfig>> getTournamentFormats() async {
    const cacheKey = 'tournament_formats';
    
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((json) => TournamentFormatConfig.fromJson(json))
          .toList();
    }

    try {
      final response = await _supabase
          .from('tournament_formats')
          .select('*')
          .eq('is_active', true)
          .order('format_name');

      final formats = response
          .map<TournamentFormatConfig>((json) => TournamentFormatConfig.fromJson(json))
          .toList();

      _cache[cacheKey] = response;
      _updateCacheTimestamp();

      return formats;
    } catch (error) {
      throw Exception('Failed to get tournament formats: $error');
    }
  }

  /// Get specific tournament format by code
  Future<TournamentFormatConfig?> getTournamentFormat(String formatCode) async {
    final formats = await getTournamentFormats();
    return formats.where((f) => f.formatCode == formatCode).firstOrNull;
  }

  /// Get prize pool configurations
  Future<List<PrizePoolConfig>> getPrizePoolConfigurations() async {
    const cacheKey = 'prize_pool_configs';
    
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((json) => PrizePoolConfig.fromJson(json))
          .toList();
    }

    try {
      final response = await _supabase
          .from('prize_pool_configurations')
          .select('*')
          .eq('is_active', true)
          .order('min_players');

      final configs = response
          .map<PrizePoolConfig>((json) => PrizePoolConfig.fromJson(json))
          .toList();

      _cache[cacheKey] = response;
      _updateCacheTimestamp();

      return configs;
    } catch (error) {
      throw Exception('Failed to get prize pool configurations: $error');
    }
  }

  // ==================== PLATFORM SETTINGS ====================

  /// Get platform settings (ELO K-factors, timeouts, etc.)
  Future<PlatformSettings> getPlatformSettings() async {
    const cacheKey = 'platform_settings';
    
    if (_isCacheValid(cacheKey)) {
      return PlatformSettings.fromJson(_cache[cacheKey]);
    }

    try {
      final response = await _supabase
          .from('platform_settings')
          .select('*')
          .eq('is_active', true)
          .single();

      final settings = PlatformSettings.fromJson(response);
      
      _cache[cacheKey] = response;
      _updateCacheTimestamp();

      return settings;
    } catch (error) {
      throw Exception('Failed to get platform settings: $error');
    }
  }

  /// Get ELO configuration
  Future<EloConfig> getEloConfig() async {
    final settings = await getPlatformSettings();
    return settings.eloConfig;
  }

  /// Get tournament timeouts configuration
  Future<TournamentTimeouts> getTournamentTimeouts() async {
    final settings = await getPlatformSettings();
    return settings.tournamentTimeouts;
  }

  // ==================== RANKING DEFINITIONS ====================

  /// Get ranking definitions từ database
  Future<List<RankingDefinition>> getRankingDefinitions() async {
    const cacheKey = 'ranking_definitions';
    
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((json) => RankingDefinition.fromJson(json))
          .toList();
    }

    try {
      final response = await _supabase
          .from('ranking_definitions')
          .select('*')
          .eq('is_active', true)
          .order('min_elo');

      final definitions = response
          .map<RankingDefinition>((json) => RankingDefinition.fromJson(json))
          .toList();

      _cache[cacheKey] = response;
      _updateCacheTimestamp();

      return definitions;
    } catch (error) {
      throw Exception('Failed to get ranking definitions: $error');
    }
  }

  /// Get ranking definition by ELO
  Future<RankingDefinition?> getRankingByElo(int elo) async {
    final definitions = await getRankingDefinitions();
    
    for (final definition in definitions.reversed) {
      if (elo >= definition.minElo) {
        return definition;
      }
    }
    
    return definitions.firstOrNull; // Return lowest rank if not found
  }

  // ==================== GAME FORMATS ====================

  /// Get game formats (8-ball, 9-ball, etc.)
  Future<List<GameFormatConfig>> getGameFormats() async {
    const cacheKey = 'game_formats';
    
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((json) => GameFormatConfig.fromJson(json))
          .toList();
    }

    try {
      final response = await _supabase
          .from('game_formats')
          .select('*')
          .eq('is_active', true)
          .order('popularity DESC');

      final formats = response
          .map<GameFormatConfig>((json) => GameFormatConfig.fromJson(json))
          .toList();

      _cache[cacheKey] = response;
      _updateCacheTimestamp();

      return formats;
    } catch (error) {
      throw Exception('Failed to get game formats: $error');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Check if cache is still valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    if (_lastCacheUpdate == null) return false;
    
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  /// Update cache timestamp
  void _updateCacheTimestamp() {
    _lastCacheUpdate = DateTime.now();
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  /// Clear specific cache key
  void clearCacheKey(String key) {
    _cache.remove(key);
  }

  /// Force refresh all configurations
  Future<void> refreshConfigurations() async {
    clearCache();
    await Future.wait([
      getTournamentFormats(),
      getPrizePoolConfigurations(),
      getPlatformSettings(),
      getRankingDefinitions(),
      getGameFormats(),
    ]);
  }

  // ==================== ADMIN METHODS ====================

  /// Update platform settings (admin only)
  Future<void> updatePlatformSettings(PlatformSettings settings) async {
    try {
      await _supabase
          .from('platform_settings')
          .upsert(settings.toJson())
          .eq('id', settings.id);
      
      clearCacheKey('platform_settings');
    } catch (error) {
      throw Exception('Failed to update platform settings: $error');
    }
  }

  /// Add or update tournament format (admin only)
  Future<void> upsertTournamentFormat(TournamentFormatConfig format) async {
    try {
      await _supabase
          .from('tournament_formats')
          .upsert(format.toJson());
      
      clearCacheKey('tournament_formats');
    } catch (error) {
      throw Exception('Failed to upsert tournament format: $error');
    }
  }

  /// Toggle tournament format active status (admin only)
  Future<void> toggleTournamentFormatStatus(String formatCode, bool isActive) async {
    try {
      await _supabase
          .from('tournament_formats')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('format_code', formatCode);
      
      clearCacheKey('tournament_formats');
    } catch (error) {
      throw Exception('Failed to toggle tournament format status: $error');
    }
  }
}

// ==================== CONFIGURATION MODELS ====================

/// Tournament Format Configuration từ database
class TournamentFormatConfig {
  final String id;
  final String formatCode;
  final String formatName;
  final String formatNameVi;
  final String? description;
  final String? descriptionVi;
  final String eliminationType;
  final String bracketType;
  final int minPlayers;
  final int maxPlayers;
  final String roundsFormula;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentFormatConfig({
    required this.id,
    required this.formatCode,
    required this.formatName,
    required this.formatNameVi,
    this.description,
    this.descriptionVi,
    required this.eliminationType,
    required this.bracketType,
    required this.minPlayers,
    required this.maxPlayers,
    required this.roundsFormula,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentFormatConfig.fromJson(Map<String, dynamic> json) {
    return TournamentFormatConfig(
      id: json['id'],
      formatCode: json['format_code'],
      formatName: json['format_name'],
      formatNameVi: json['format_name_vi'],
      description: json['description'],
      descriptionVi: json['description_vi'],
      eliminationType: json['elimination_type'],
      bracketType: json['bracket_type'],
      minPlayers: json['min_players'],
      maxPlayers: json['max_players'],
      roundsFormula: json['rounds_formula'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'format_code': formatCode,
      'format_name': formatName,
      'format_name_vi': formatNameVi,
      'description': description,
      'description_vi': descriptionVi,
      'elimination_type': eliminationType,
      'bracket_type': bracketType,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'rounds_formula': roundsFormula,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Prize Pool Configuration
class PrizePoolConfig {
  final String id;
  final int minPlayers;
  final int maxPlayers;
  final String distributionType;
  final Map<String, double> distribution;
  final bool isActive;

  PrizePoolConfig({
    required this.id,
    required this.minPlayers,
    required this.maxPlayers,
    required this.distributionType,
    required this.distribution,
    required this.isActive,
  });

  factory PrizePoolConfig.fromJson(Map<String, dynamic> json) {
    return PrizePoolConfig(
      id: json['id'],
      minPlayers: json['min_players'],
      maxPlayers: json['max_players'],
      distributionType: json['distribution_type'],
      distribution: Map<String, double>.from(
        json['distribution'] is String 
          ? jsonDecode(json['distribution'])
          : json['distribution']
      ),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'distribution_type': distributionType,
      'distribution': jsonEncode(distribution),
      'is_active': isActive,
    };
  }
}

/// Platform Settings
class PlatformSettings {
  final String id;
  final EloConfig eloConfig;
  final TournamentTimeouts tournamentTimeouts;
  final Map<String, dynamic> generalSettings;
  final bool isActive;
  final DateTime updatedAt;

  PlatformSettings({
    required this.id,
    required this.eloConfig,
    required this.tournamentTimeouts,
    required this.generalSettings,
    required this.isActive,
    required this.updatedAt,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      id: json['id'],
      eloConfig: EloConfig.fromJson(
        json['elo_config'] is String 
          ? jsonDecode(json['elo_config'])
          : json['elo_config']
      ),
      tournamentTimeouts: TournamentTimeouts.fromJson(
        json['tournament_timeouts'] is String 
          ? jsonDecode(json['tournament_timeouts'])
          : json['tournament_timeouts']
      ),
      generalSettings: json['general_settings'] is String 
          ? jsonDecode(json['general_settings'])
          : json['general_settings'],
      isActive: json['is_active'] ?? true,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'elo_config': jsonEncode(eloConfig.toJson()),
      'tournament_timeouts': jsonEncode(tournamentTimeouts.toJson()),
      'general_settings': jsonEncode(generalSettings),
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// ELO Configuration
class EloConfig {
  final int startingElo;
  final int kFactorNew;
  final int kFactorRegular;
  final int kFactorExpert;
  final int minElo;
  final int maxElo;
  final Map<String, int> bonusModifiers;

  EloConfig({
    required this.startingElo,
    required this.kFactorNew,
    required this.kFactorRegular,
    required this.kFactorExpert,
    required this.minElo,
    required this.maxElo,
    required this.bonusModifiers,
  });

  factory EloConfig.fromJson(Map<String, dynamic> json) {
    return EloConfig(
      startingElo: json['starting_elo'] ?? 1000,
      kFactorNew: json['k_factor_new'] ?? 32,
      kFactorRegular: json['k_factor_regular'] ?? 24,
      kFactorExpert: json['k_factor_expert'] ?? 16,
      minElo: json['min_elo'] ?? 100,
      maxElo: json['max_elo'] ?? 3000,
      bonusModifiers: Map<String, int>.from(json['bonus_modifiers'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'starting_elo': startingElo,
      'k_factor_new': kFactorNew,
      'k_factor_regular': kFactorRegular,
      'k_factor_expert': kFactorExpert,
      'min_elo': minElo,
      'max_elo': maxElo,
      'bonus_modifiers': bonusModifiers,
    };
  }
}

/// Tournament Timeouts Configuration
class TournamentTimeouts {
  final int registrationDeadlineHours;
  final int matchTimeoutMinutes;
  final int roundStartDelayMinutes;
  final int forfeitTimeoutMinutes;

  TournamentTimeouts({
    required this.registrationDeadlineHours,
    required this.matchTimeoutMinutes,
    required this.roundStartDelayMinutes,
    required this.forfeitTimeoutMinutes,
  });

  factory TournamentTimeouts.fromJson(Map<String, dynamic> json) {
    return TournamentTimeouts(
      registrationDeadlineHours: json['registration_deadline_hours'] ?? 24,
      matchTimeoutMinutes: json['match_timeout_minutes'] ?? 60,
      roundStartDelayMinutes: json['round_start_delay_minutes'] ?? 15,
      forfeitTimeoutMinutes: json['forfeit_timeout_minutes'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'registration_deadline_hours': registrationDeadlineHours,
      'match_timeout_minutes': matchTimeoutMinutes,
      'round_start_delay_minutes': roundStartDelayMinutes,
      'forfeit_timeout_minutes': forfeitTimeoutMinutes,
    };
  }
}

/// Ranking Definition từ database
class RankingDefinition {
  final String id;
  final String rankCode;
  final String rankName;
  final String rankNameVi;
  final int minElo;
  final int maxElo;
  final String colorHex;
  final String iconCode;
  final int displayOrder;
  final bool isActive;

  RankingDefinition({
    required this.id,
    required this.rankCode,
    required this.rankName,
    required this.rankNameVi,
    required this.minElo,
    required this.maxElo,
    required this.colorHex,
    required this.iconCode,
    required this.displayOrder,
    required this.isActive,
  });

  factory RankingDefinition.fromJson(Map<String, dynamic> json) {
    return RankingDefinition(
      id: json['id'],
      rankCode: json['rank_code'],
      rankName: json['rank_name'],
      rankNameVi: json['rank_name_vi'],
      minElo: json['min_elo'],
      maxElo: json['max_elo'],
      colorHex: json['color_hex'],
      iconCode: json['icon_code'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'rank_code': rankCode,
      'rank_name': rankName,
      'rank_name_vi': rankNameVi,
      'min_elo': minElo,
      'max_elo': maxElo,
      'color_hex': colorHex,
      'icon_code': iconCode,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}

/// Game Format Configuration
class GameFormatConfig {
  final String id;
  final String formatCode;
  final String formatName;
  final String formatNameVi;
  final String? description;
  final String? descriptionVi;
  final int ballCount;
  final String rules;
  final int popularity;
  final bool isActive;

  GameFormatConfig({
    required this.id,
    required this.formatCode,
    required this.formatName,
    required this.formatNameVi,
    this.description,
    this.descriptionVi,
    required this.ballCount,
    required this.rules,
    required this.popularity,
    required this.isActive,
  });

  factory GameFormatConfig.fromJson(Map<String, dynamic> json) {
    return GameFormatConfig(
      id: json['id'],
      formatCode: json['format_code'],
      formatName: json['format_name'],
      formatNameVi: json['format_name_vi'],
      description: json['description'],
      descriptionVi: json['description_vi'],
      ballCount: json['ball_count'] ?? 15,
      rules: json['rules'] ?? '',
      popularity: json['popularity'] ?? 5,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'format_code': formatCode,
      'format_name': formatName,
      'format_name_vi': formatNameVi,
      'description': description,
      'description_vi': descriptionVi,
      'ball_count': ballCount,
      'rules': rules,
      'popularity': popularity,
      'is_active': isActive,
    };
  }
}

// Extension method for nullable firstOrNull
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}