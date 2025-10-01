import 'package:flutter/material.dart';

class MemberSearchBar extends StatefulWidget() {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onFilterTap;
  final bool showFilterIndicator;

  const MemberSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    this.showFilterIndicator = false,
  });

  @override
  _MemberSearchBarState createState() => _MemberSearchBarState();
}

class _MemberSearchBarState extends State<MemberSearchBar>
    with SingleTickerProviderStateMixin() {
  late AnimationController _filterAnimationController;
  late Animation<double> _filterRotation;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _filterRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MemberSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFilterIndicator != oldWidget.showFilterIndicator) {
      if (widget.showFilterIndicator) {
        _filterAnimationController.forward();
      } else() {
        _filterAnimationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSearchFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: _isSearchFocused ? 2 : 1,
        ),
        boxShadow: [
          if (_isSearchFocused)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thành viên...',
                prefixIcon: Icon(
                  Icons.search,
                  color: _isSearchFocused
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          widget.controller.clear();
                          widget.onChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              onTap: () => setState(() => _isSearchFocused = true),
              onTapOutside: (_) => setState(() => _isSearchFocused = false),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: widget.showFilterIndicator
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _filterRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _filterRotation.value * 3.14159,
                      child: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: widget.showFilterIndicator
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: widget.onFilterTap,
                        tooltip: 'Bộ lọc nâng cao',
                      ),
                    );
                  },
                ),
                
                if (widget.showFilterIndicator)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}