#!/bin/bash

echo "Fixing sizer extensions and theme references..."

# Fix animated_stats_card.dart
sed -i 's/\.fSize/.sp/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/animated_stats_card.dart"
sed -i 's/\.v\b/.h/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/animated_stats_card.dart"
sed -i 's/\.adaptSize/.sp/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/animated_stats_card.dart"
sed -i 's/appTheme\.gray900/appTheme.gray900/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/animated_stats_card.dart"
sed -i 's/appTheme\.gray600/appTheme.gray600/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/animated_stats_card.dart"
sed -i 's/appTheme\.gray700/appTheme.gray700/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/animated_stats_card.dart"

# Fix quick_action_card.dart  
sed -i 's/\.fSize/.sp/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"
sed -i 's/\.v\b/.h/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"
sed -i 's/\.adaptSize/.sp/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"
sed -i 's/appTheme\.black900/appTheme.gray900/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"
sed -i 's/appTheme\.gray900/appTheme.gray900/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"
sed -i 's/appTheme\.gray600/appTheme.gray600/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"
sed -i 's/appTheme\.red700/appTheme.red700/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"
sed -i 's/AppColors\.primary/AppColors.primary/g' "d:/0.APP/sabo_arena/lib/presentation/club_dashboard_screen/widgets/quick_action_card.dart"

echo "Fixed sizer and theme issues!"