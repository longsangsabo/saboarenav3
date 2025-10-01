🚨 CRITICAL FIX PLAN: ELO-RANK SYSTEM STANDARDIZATION

PROBLEM IDENTIFIED:
- UI components use SaboRankSystem.getRankFromElo()
- Tournament services use RankingConstants.getRankFromElo() 
- 3 critical inconsistencies for edge case ELOs (< 1000, > 2999)
- Creates frontend-backend inconsistency in user experience

SOLUTION:
Standardize ALL services to use RankingConstants.getRankFromElo()

FILES TO UPDATE:
1. lib/presentation/user_profile_screen/widgets/profile_header_widget.dart
   - Line 379: SaboRankSystem.getRankFromElo(currentElo) → RankingConstants.getRankFromElo(currentElo)
   - Line 459: SaboRankSystem.getRankFromElo(currentElo) → RankingConstants.getRankFromElo(currentElo)

2. lib/presentation/club_profile_screen/club_profile_screen.dart  
   - Line 639: SaboRankSystem.getRankFromElo(currentElo) → RankingConstants.getRankFromElo(currentElo)
   - Line 652: SaboRankSystem.getRankFromElo(currentElo) → RankingConstants.getRankFromElo(currentElo)
   - Line 710: SaboRankSystem.getRankFromElo(elo) → RankingConstants.getRankFromElo(elo)
   - Line 711: SaboRankSystem.getRankFromElo(elo) → RankingConstants.getRankFromElo(elo)

ADDITIONAL CONSIDERATIONS:
- Update color and display name logic since SaboRankSystem provides those
- Ensure all imports are updated
- Test critical user flows after changes

BUSINESS IMPACT:
✅ Fixes inconsistent rank display for edge case ELOs
✅ Ensures UI and tournament calculations match
✅ Eliminates user confusion about their actual rank
✅ Maintains business rules: rank I = ELO 1200, rank I+ = ELO 1300

TESTING REQUIRED:
1. User registration flow (ELO 1000)
2. Club verification (ELO 1200) 
3. Tournament participation and rank updates
4. Edge cases (very low/high ELOs)