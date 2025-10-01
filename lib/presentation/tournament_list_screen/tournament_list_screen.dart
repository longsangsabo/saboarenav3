import 'package:flutter/material.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/models/tournament.dart';
import 'package:sabo_arena/presentation/tournament_list_screen/widgets/tournament_card_widget.dart';
import 'package:sabo_arena/presentation/tournament_list_screen/widgets/tournament_filter_bottom_sheet.dart';
import 'package:sabo_arena/presentation/tournament_list_screen/widgets/tournament_search_delegate.dart';
import 'package:sabo_arena/presentation/demo_bracket_screen/demo_bracket_screen.dart';
import 'package:sabo_arena/services/tournament_service.dart';


class TournamentListScreen extends StatefulWidget() {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen>
    with TickerProviderStateMixin() {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService.instance;
  bool _isLoading = true;
  String _selectedTab = 'upcoming';
  Map<String, dynamic> _currentFilters = {
    'locationRadius': 10.0,
    'entryFeeRange': <String>[],
    'formats': <String>[],
    'skillLevels': <String>[],
    'hasLiveStream': false,
    'hasAvailableSlots': false,
    'hasPrizePool': false,
  };

  List<Tournament> _allTournaments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTournaments();
  }

  Future<void> _loadTournaments() async() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try() {
      final tournaments = await _tournamentService.getTournaments(status: _selectedTab);
      
      // Apply sorting logic: newest created first, then by start date
      tournaments.sort((a, b) {
        // First priority: creation time (newest first)
        final aCreated = a.createdAt;
        final bCreated = b.createdAt;
        
        // If created within 24 hours of each other, sort by start date (closest first)
        final timeDiff = aCreated.difference(bCreated).inHours.abs();
        if (timeDiff < 24) {
          final aStart = a.startDate;
          final bStart = b.startDate;
          
          // For upcoming tournaments, show earliest start date first
          if (_selectedTab == 'upcoming') {
            return aStart.compareTo(bStart);
          }
          // For ongoing tournaments, show earliest start date first  
          else if (_selectedTab == 'live') {
            return aStart.compareTo(bStart);
          }
          // For completed tournaments, show latest end date first
          else if (_selectedTab == 'completed') {
            final aEnd = a.endDate ?? a.startDate;
            final bEnd = b.endDate ?? b.startDate;
            return bEnd.compareTo(aEnd);
          }
        }
        
        // Otherwise, newest created first
        return bCreated.compareTo(aCreated);
      });
      
      debugPrint('📋 Tournament list sorting applied for tab "$_selectedTab":');
      for (int i = 0; i < tournaments.take(3).length; i++) {
        final t = tournaments[i];
        debugPrint('   ${i+1}. "${t.title}" - Created: ${t.createdAt.toString().substring(0, 19)}, Start: ${t.startDate.toString().substring(0, 19)}');
      }
      
      if (mounted) {
        setState(() {
          _allTournaments = tournaments;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Show error if data loading fails
      if (mounted) {
        setState(() {
          _allTournaments = [];
          _isLoading = false;
          _errorMessage = 'Không thể tải dữ liệu giải đấu: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final newTab = ['upcoming', 'live', 'completed'][_tabController.index];
    if (newTab != _selectedTab) {
      setState(() {
        _selectedTab = newTab;
      });
      _loadTournaments();
    }
  }

  void _handleNavigation(String route) {
    if (route != AppRoutes.tournamentListScreen) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  List<Tournament> get _filteredTournaments() {
    // Temporarily simplified to fix dead_null_aware_expression warnings
    return _allTournaments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giải đấu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            tooltip: 'Demo Bảng Đấu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DemoBracketScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sắp diễn ra'),
            Tab(text: 'Đang diễn ra'),
            Tab(text: 'Đã kết thúc'),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterBottomSheet(context),
        child: const Icon(Icons.filter_list),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 2, // Tournaments tab
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  _handleNavigation(AppRoutes.homeFeedScreen);
                  break;
                case 1:
                  _handleNavigation(AppRoutes.findOpponentsScreen);
                  break;
                case 2:
                  // Already on tournaments
                  break;
                case 3:
                  _handleNavigation(AppRoutes.clubMainScreen);
                  break;
                case 4:
                  _handleNavigation(AppRoutes.userProfileScreen);
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Đối thủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Giải đấu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business_outlined),
                activeIcon: Icon(Icons.business),
                label: 'Câu lạc bộ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage ?? ''));
    }
    if (_filteredTournaments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTournaments,
        child: const Center(child: Text("Không có giải đấu nào.")),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: ListView.builder(
        itemCount: _filteredTournaments.length,
        itemBuilder: (context, index) {
          final tournament = _filteredTournaments[index];
          return TournamentCardWidget(tournament: tournament);
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TournamentFilterBottomSheet(
        currentFilters: _currentFilters,
        onFiltersApplied: (filters) {
          setState(() {
            _currentFilters = filters;
          });
        },
      ),
    );
  }

  Map<String, dynamic> _tournamentToMap(Tournament tournament) {
    return() {
      'id': tournament.id,
      'title': tournament.title,
      'clubName': tournament.clubId ?? 'N/A',
      'format': tournament.gameFormat,
      'entryFee': tournament.entryFee > 0
          ? "${tournament.entryFee.toStringAsFixed(0)}đ"
          : 'Miễn phí',
      'coverImage': tournament.coverImageUrl,
      'skillLevelRequired': tournament.skillLevelRequired,
    };
  }

  void _showSearch(BuildContext context) {
    final tournamentsForSearch = _filteredTournaments.map(_tournamentToMap).toList();

    showSearch<String>(
      context: context,
      delegate: TournamentSearchDelegate(
        tournaments: tournamentsForSearch,
        onTournamentSelected: (tournamentMap) {
          Navigator.pushNamed(
            context,
            AppRoutes.tournamentDetailScreen,
            arguments: tournamentMap['id'],
          );
        },
      ),
    );
  }
}
