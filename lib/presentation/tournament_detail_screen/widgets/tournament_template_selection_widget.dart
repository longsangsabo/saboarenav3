// 🎨 SABO ARENA - Tournament Template Selection Widget
// Phase 3: Template picker with categories and previews
// Allows quick tournament creation from predefined templates

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/tournament_constants.dart';
import '../../../services/tournament_template_service.dart';

class TournamentTemplateSelectionWidget extends StatefulWidget {
  const TournamentTemplateSelectionWidget({super.key});

} 
  final Function(String templateId, Map<String, dynamic> templateConfig) onTemplateSelected;
  final String? clubId;

  const TournamentTemplateSelectionWidget({
    super.key,
    required this.onTemplateSelected,
    this.clubId,
  });

  @override
  State<TournamentTemplateSelectionWidget> createState() => _TournamentTemplateSelectionWidgetState();
}

class _TournamentTemplateSelectionWidgetState extends State<TournamentTemplateSelectionWidget>
    with TickerProviderStateMixin {
  final TournamentTemplateService _templateService = TournamentTemplateService.instance;
  
  late TabController _tabController;
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<Map<String, dynamic>>> _templatesByCategory = {};
  bool _isLoading = true;
  String _selectedCategory = 'quick_start';
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      setState(() => _isLoading = true);

      // Load categories and templates
      final categories = await _templateService.getTemplateCategories();
      final allTemplates = await _templateService.getTournamentTemplates(
        clubId: widget.clubId,
      );

      // Group templates by category
      final templatesByCategory = <String, List<Map<String, dynamic>>>{};
      
      for (final template in allTemplates) {
        final category = template['category'] ?? 'custom';
        templatesByCategory[category] ??= [];
        templatesByCategory[category]!.add(template);
      }

      // Initialize tab controller
      _tabController = TabController(
        length: categories.length,
        vsync: this,
      );

      setState(() {
        _categories = categories;
        _templatesByCategory = templatesByCategory;
        _isLoading = false;
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first['category'];
        }
      });

    } catch (e) {
      debugPrint('❌ Error loading templates: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load templates');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildCategoryTabs(),
          Expanded(child: _buildTemplateGrid()),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.dashboard_customize, size: 6.w, color: Colors.blue[600]),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Template 🎯',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Quick setup with predefined tournament formats',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, size: 6.w),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_isLoading || _categories.isEmpty) {
      return SizedBox(
        height: 10.h,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 10.h,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue[600],
        labelColor: Colors.blue[600],
        unselectedLabelColor: Colors.grey[600],
        onTap: (index) {
          setState(() {
            _selectedCategory = _categories[index]['category'];
            _selectedTemplateId = null;
          });
        },
        tabs: _categories.map((category) => Tab(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getCategoryIcon(category['category']), size: 5.w),
              SizedBox(height: 1.w),
              Text(
                category['name'],
                style: TextStyle(fontSize: 10.sp),
              ),
              Container(
                margin: EdgeInsets.only(top: 1.w),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  '${category['count']}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTemplateGrid() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 4.w),
            Text('Loading templates...', style: TextStyle(fontSize: 14.sp)),
          ],
        ),
      );
    }

    final templates = _templatesByCategory[_selectedCategory] ?? [];
    
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 15.w, color: Colors.grey[400]),
            SizedBox(height: 4.w),
            Text(
              'No templates in this category',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.w),
            Text(
              'Try another category or create a custom tournament',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: templates.length,
      itemBuilder: (context, index) => _buildTemplateCard(templates[index]),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final isSelected = _selectedTemplateId == template['id'];
    final isBuiltIn = template['is_builtin'] == true;
    
    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: Container(
        margin: EdgeInsets.only(bottom: 3.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: _getFormatColor(template['tournament_format']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Icon(
                      _getFormatIcon(template['tournament_format']),
                      size: 6.w,
                      color: _getFormatColor(template['tournament_format']),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                template['name'],
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            if (isBuiltIn)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(1.w),
                                ),
                                child: Text(
                                  'OFFICIAL',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _getFormatDisplayName(template['tournament_format']),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.blue[600], size: 6.w),
                ],
              ),
              SizedBox(height: 3.w),
              Text(
                template['description'],
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
              SizedBox(height: 3.w),
              _buildTemplateStats(template),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateStats(Map<String, dynamic> template) {
    return Row(
      children: [
        _buildStatChip(
          Icons.people,
          '${template['usage_count'] ?? 0} uses',
          Colors.blue,
        ),
        SizedBox(width: 2.w),
        _buildStatChip(
          Icons.star,
          template['users']?['username'] ?? 'System',
          Colors.orange,
        ),
        Spacer(),
        if (template['is_builtin'] != true)
          Icon(Icons.favorite_border, size: 4.w, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: color[600]),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              child: Text(
                'Skip Template',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedTemplateId != null ? _useSelectedTemplate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              child: Text(
                'Use Template',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedTemplateId = template['id'];
    });
  }

  void _useSelectedTemplate() {
    if (_selectedTemplateId == null) return;

    final selectedTemplate = _templatesByCategory[_selectedCategory]
        ?.firstWhere((t) => t['id'] == _selectedTemplateId);

    if (selectedTemplate != null) {
      // Get template configuration
      Map<String, dynamic> config = {};
      
      if (_selectedTemplateId!.startsWith('builtin_')) {
        // For built-in templates, we'll pass the template data
        config = selectedTemplate;
      } else {
        // For custom templates, use the stored config
        config = selectedTemplate['template_config'] ?? {};
      }

      widget.onTemplateSelected(_selectedTemplateId!, config);
      Navigator.pop(context);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'quick_start':
        return Icons.flash_on;
      case 'championship':
        return Icons.emoji_events;
      case 'league':
        return Icons.groups;
      case 'rated':
        return Icons.star;
      case 'special':
        return Icons.celebration;
      case 'custom':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case TournamentFormats.singleElimination:
        return Icons.account_tree;
      case TournamentFormats.doubleElimination:
      case TournamentFormats.saboDoubleElimination:
      case TournamentFormats.saboDoubleElimination32:
        return Icons.device_hub;
      case TournamentFormats.roundRobin:
        return Icons.refresh;
      case TournamentFormats.swiss:
        return Icons.shuffle;
      case TournamentFormats.ladder:
        return Icons.stairs;
      case TournamentFormats.winnerTakesAll:
        return Icons.workspace_premium;
      default:
        return Icons.sports_esports;
    }
  }

  Color _getFormatColor(String format) {
    switch (format) {
      case TournamentFormats.singleElimination:
        return Colors.red;
      case TournamentFormats.doubleElimination:
      case TournamentFormats.saboDoubleElimination:
      case TournamentFormats.saboDoubleElimination32:
        return Colors.purple;
      case TournamentFormats.roundRobin:
        return Colors.green;
      case TournamentFormats.swiss:
        return Colors.blue;
      case TournamentFormats.ladder:
        return Colors.orange;
      case TournamentFormats.winnerTakesAll:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getFormatDisplayName(String format) {
    switch (format) {
      case TournamentFormats.singleElimination:
        return 'Single Elimination';
      case TournamentFormats.doubleElimination:
        return 'Double Elimination';
      case TournamentFormats.saboDoubleElimination:
        return 'SABO DE16';
      case TournamentFormats.saboDoubleElimination32:
        return 'SABO DE32';
      case TournamentFormats.roundRobin:
        return 'Round Robin';
      case TournamentFormats.swiss:
        return 'Swiss System';
      case TournamentFormats.ladder:
        return 'Ladder';
      case TournamentFormats.winnerTakesAll:
        return 'Winner Takes All';
      default:
        return format;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
