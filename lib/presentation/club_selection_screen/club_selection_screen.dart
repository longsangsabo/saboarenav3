import 'package:flutter/material.dart';
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/presentation/rank_registration_screen/rank_registration_screen.dart';

class ClubSelectionScreen extends StatefulWidget {
  const ClubSelectionScreen({super.key});

@override
  State<ClubSelectionScreen> createState() => _ClubSelectionScreenState();
}

class _ClubSelectionScreenState extends State<ClubSelectionScreen> {
  final ClubService _clubService = ClubService.instance;
  late Future<List<Club>> _clubsFuture;
  List<Club> _allClubs = [];
  List<Club> _filteredClubs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clubsFuture = _loadClubs();
    _searchController.addListener(_filterClubs);
  }

  Future<List<Club>> _loadClubs() async {
    try {
      final clubs = await _clubService.getAllClubs();
      setState(() {
        _allClubs = clubs;
        _filteredClubs = clubs;
      });
      return clubs;
    } catch (e) {
      debugPrint('Error loading clubs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Không thể tải danh sách câu lạc bộ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  void _filterClubs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClubs = _allClubs.where((club) {
        return club.name.toLowerCase().contains(query) ||
               (club.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _sendRankRequest(Club club) async {
    // Navigate to the improved rank registration screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RankRegistrationScreen(clubId: club.id),
      ),
    ).then((result) {
      if (result == true) {
        // Request was submitted successfully, go back to previous screen
        Navigator.pop(context, true);
      }
    });
  }



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn Câu Lạc Bộ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildClubList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm câu lạc bộ...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildClubList() {
    return FutureBuilder<List<Club>>(
      future: _clubsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải danh sách CLB.'));
        }
        if (_filteredClubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không tìm thấy câu lạc bộ nào.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: _filteredClubs.length,
          itemBuilder: (context, index) {
            final club = _filteredClubs[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                      ? NetworkImage(club.logoUrl!)
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: (club.logoUrl == null || club.logoUrl!.isEmpty)
                      ? Text(club.name.isNotEmpty ? club.name[0] : 'C')
                      : null,
                ),
                title: Text(club.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (club.address != null)
                      Text(club.address!, style: TextStyle(fontSize: 12)),
                    if (club.totalTables > 0)
                      Text('${club.totalTables} bàn bi-a', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _sendRankRequest(club),
              ),
            );
          },
        );
      },
    );
  }
}

