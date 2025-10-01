import 'package:flutter/material.dart';
import '../../../models/member_data.dart';

class MemberListItem extends StatefulWidget {
  const MemberListItem({super.key});

} 
  final MemberData member;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final Function(String) onAction;
  final bool showSelection;

  const MemberListItem({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onAction,
    this.showSelection = false,
  });

  @override
  _MemberListItemState createState() => _MemberListItemState();
}

class _MemberListItemState extends State<MemberListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Animation<Color?>? _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorAnimation ??= ColorTween(
        begin: Colors.transparent,
        end: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MemberListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _colorAnimation?.value ?? Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: widget.isSelected ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.showSelection 
                    ? () => widget.onSelectionChanged(!widget.isSelected)
                    : () => widget.onAction('view-profile'),
                onLongPress: () => widget.onSelectionChanged(!widget.isSelected),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Selection checkbox
                      if (widget.showSelection)
                        Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Checkbox(
                            value: widget.isSelected,
                            onChanged: (value) =>
                                widget.onSelectionChanged(value ?? false),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      
                      // Avatar with online status
                      _buildAvatar(),
                      
                      SizedBox(width: 12),
                      
                      // Member info
                      Expanded(
                        child: _buildMemberInfo(),
                      ),
                      
                      // Stats and actions
                      _buildMemberStats(),
                      
                      SizedBox(width: 8),
                      
                      // Action menu
                      _buildActionMenu(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getMembershipColor().withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: widget.member.user.avatar.isNotEmpty 
                ? NetworkImage(widget.member.user.avatar) 
                : null,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: widget.member.user.avatar.isEmpty 
                ? Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                : null,
          ),
        ),
        
        // Online status
        if (widget.member.user.isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        
        // Membership badge
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _getMembershipColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getMembershipLabel(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and status badge
        Row(
          children: [
            Flexible(
              child: Text(
                widget.member.user.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 6),
            _buildStatusBadge(),
          ],
        ),
        
        SizedBox(height: 6),
        
        // Rank and ELO in compact row
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getRankColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRankLabel(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getRankColor(),
                ),
              ),
            ),
            
            SizedBox(width: 8),
            
            Text(
              'ELO: ${widget.member.user.elo}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 4),
        
        // Join date only (compact)
        Text(
          'Tham gia: ${_formatDate(widget.member.membershipInfo.joinDate)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Win rate compact
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${(widget.member.activityStats.winRate * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),
        
        SizedBox(height: 4),
        
        // Matches count
        Text(
          '${widget.member.activityStats.totalMatches} trận',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      onSelected: widget.onAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view-profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 16),
              SizedBox(width: 8),
              Text('Xem hồ sơ'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'message',
          child: Row(
            children: [
              Icon(Icons.message, size: 16),
              SizedBox(width: 8),
              Text('Nhắn tin'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'view-stats',
          child: Row(
            children: [
              Icon(Icons.bar_chart, size: 16),
              SizedBox(width: 8),
              Text('Thống kê'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'promote',
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 16),
              SizedBox(width: 8),
              Text('Thăng cấp'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'suspend',
          child: Row(
            children: [
              Icon(Icons.block, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text('Tạm khóa', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Xóa khỏi CLB', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help;
    
    switch (widget.member.membershipInfo.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'inactive':
        statusColor = Colors.grey;
        statusIcon = Icons.pause_circle;
        break;
      case 'suspended':
        statusColor = Colors.orange;
        statusIcon = Icons.block;
        break;
      case 'pending':
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
    }
    
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        statusIcon,
        size: 12,
        color: statusColor,
      ),
    );
  }

  Color _getMembershipColor() {
    switch (widget.member.membershipInfo.type) {
      case 'regular':
        return Colors.grey;
      case 'vip':
        return Colors.amber;
      case 'premium':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMembershipLabel() {
    switch (widget.member.membershipInfo.type) {
      case 'regular':
        return 'REG';
      case 'vip':
        return 'VIP';
      case 'premium':
        return 'PRE';
      default:
        return 'REG';
    }
  }

  Color _getRankColor() {
    switch (widget.member.user.rank) {
      case 'beginner':
        return Colors.green;
      case 'amateur':
        return Colors.blue;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'professional':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getRankLabel() {
    switch (widget.member.user.rank) {
      case 'beginner':
        return 'Mới';
      case 'amateur':
        return 'Nghiệp dư';
      case 'intermediate':
        return 'Trung bình';
      case 'advanced':
        return 'Nâng cao';
      case 'professional':
        return 'Chuyên nghiệp';
      default:
        return 'Không xác định';
    }
  }



  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
