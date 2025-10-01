import 'package:flutter/material.dart';
import 'package:sabo_arena/repositories/comment_repository.dart';

class TestCommentWidget extends StatefulWidget {
  const TestCommentWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  const TestCommentWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  _TestCommentWidgetState createState() => _TestCommentWidgetState();
}

class _TestCommentWidgetState extends State<TestCommentWidget> {
  final CommentRepository _commentRepository = CommentRepository();
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
  }

  Future<void> _testCreateComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      setState(() => _isPosting = true);
      debugPrint('🧪 Testing comment creation...');
      debugPrint('Content: ${_commentController.text.trim()}');
      
      final result = await _commentRepository.createComment(
        'test-post-id', // Dummy post ID
        _commentController.text.trim(),
      );
      
      debugPrint('✅ Comment created: $result');
      _commentController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Comment test successful!')),
      );
    } catch (e) {
      debugPrint('❌ Comment creation failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Comment')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Test Comment Creation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a test comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                _isPosting
                    ? CircularProgressIndicator()
                    : IconButton(
                        onPressed: _commentController.text.trim().isEmpty ? null : _testCreateComment,
                        icon: Icon(
                          Icons.send,
                          color: _commentController.text.trim().isEmpty
                              ? Colors.grey
                              : Colors.blue,
                        ),
                      ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Instructions:\n'
              '1. Type a comment\n'
              '2. Send button should become blue and clickable\n'
              '3. Click send to test backend\n'
              '4. Check console for results',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}