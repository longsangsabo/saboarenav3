import 'package:flutter/material.dart';
import '../../../models/member_data.dart';
import 'member_list_item.dart';

class MemberListView extends StatefulWidget {
  const MemberListView({super.key});

} 
  final List<MemberData> members;
  final List<String> selectedMembers;
  final Function(String, bool) onMemberSelected;
  final Function(String, String) onMemberAction;
  final Future<void> Function() onRefresh;

  const MemberListView({
    super.key,
    required this.members,
    required this.selectedMembers,
    required this.onMemberSelected,
    required this.onMemberAction,
    required this.onRefresh,
  });

  @override
  _MemberListViewState createState() => _MemberListViewState();
}

class _MemberListViewState extends State<MemberListView>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MemberListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.members != oldWidget.members) {
      _listAnimationController.reset();
      _listAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: AnimatedBuilder(
        animation: _listAnimationController,
        builder: (context, child) {
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: widget.members.length,
            itemBuilder: (context, index) {
              final member = widget.members[index];
              final isSelected = widget.selectedMembers.contains(member.id);
              
              // Staggered animation
              final animationDelay = index * 0.1;
              final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    animationDelay > 1.0 ? 1.0 : animationDelay,
                    1.0,
                    curve: Curves.easeOut,
                  ),
                ),
              );

              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: MemberListItem(
                      member: member,
                      isSelected: isSelected,
                      onSelectionChanged: (selected) =>
                          widget.onMemberSelected(member.id, selected),
                      onAction: (action) =>
                          widget.onMemberAction(action, member.id),
                      showSelection: widget.selectedMembers.isNotEmpty,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Không tìm thấy thành viên',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () => widget.onRefresh(),
            icon: Icon(Icons.refresh),
            label: Text('Làm mới'),
          ),
        ],
      ),
    );
  }
}
