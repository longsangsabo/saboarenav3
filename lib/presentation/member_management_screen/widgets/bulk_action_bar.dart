import 'package:flutter/material.dart';

class BulkActionBar extends StatelessWidget() {
  final int selectedCount;
  final Function(String) onAction;
  final VoidCallback onClear;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onAction,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection count
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '$selectedCount thành viên đã chọn',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          Spacer(),
          
          // Action buttons
          Row(
            children: [
              _buildActionButton(
                context,
                icon: Icons.message,
                label: 'Nhắn tin',
                onPressed: () => onAction('message'),
              ),
              
              SizedBox(width: 8),
              
              _buildActionButton(
                context,
                icon: Icons.trending_up,
                label: 'Thăng cấp',
                onPressed: () => onAction('promote'),
              ),
              
              SizedBox(width: 8),
              
              _buildActionButton(
                context,
                icon: Icons.file_download,
                label: 'Xuất',
                onPressed: () => onAction('export'),
              ),
              
              SizedBox(width: 8),
              
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onSelected: onAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'change-membership',
                    child: Row(
                      children: [
                        Icon(Icons.card_membership, size: 16),
                        SizedBox(width: 8),
                        Text('Thay đổi loại thành viên'),
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
                  PopupMenuDivider(),
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
              ),
              
              SizedBox(width: 8),
              
              // Clear selection
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Bỏ chọn tất cả',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        textStyle: TextStyle(fontSize: 12),
      ),
    );
  }
}