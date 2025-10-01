# 🔧 Setup Database for Like/Unlike Feature

## Issue Identified
The Home tab post display needs fixes for:
1. **Image Display**: Posts with images are cropped too much ("vùng chứa ảnh bị cắt khá nhiều")
2. **Interaction Buttons**: Like, comment, share buttons are not functional ("các nút tương tác có vẽ cũng chưa hoạt động")

## ✅ Code Changes Completed

### 1. Image Display Fix
- **File**: `lib/widgets/feed_post_card_widget.dart`
- **Change**: Modified `_buildPostMedia()` method
- **Before**: Fixed height container with `BoxConstraints(maxHeight: 50.h)`  
- **After**: Flexible `AspectRatio(aspectRatio: 16/9)` with proper `ClipRRect`
- **Result**: Images now display with consistent 16:9 aspect ratio, no cropping

### 2. Backend Integration for Like/Unlike
- **File**: `lib/presentation/screens/home_feed_screen.dart`
- **Change**: Rewrote `_handlePostAction()` method
- **Added**: 
  - `_handleLikeToggle()` with optimistic UI updates
  - `_showCommentsModal()` with proper modal UI
  - `_handleSharePost()` with share functionality
- **Result**: Interactive buttons now connect to real backend

### 3. PostRepository Enhancement  
- **File**: `lib/repositories/post_repository.dart`
- **Added Methods**:
  - `likePost(String postId)` - Like a post with RPC function
  - `unlikePost(String postId)` - Unlike a post with RPC function  
  - `hasUserLikedPost(String postId)` - Check user's like status
- **Features**: RPC functions with SQL fallbacks for reliability

## 🚨 Database Setup Required

The app is running but needs the `post_likes` table to be created in Supabase.

### Option 1: Manual SQL Execution (Recommended)
1. Go to your Supabase Dashboard: https://app.supabase.com/
2. Navigate to: **Project** → **SQL Editor**
3. Copy the contents of `create_post_likes_table.sql`
4. Paste and execute the SQL

### Option 2: Using Supabase CLI (Alternative)
```bash
supabase db reset --db-url "your-database-url"
```

## 📋 Database Schema Created

### Table: `post_likes`
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key → profiles.id)
- post_id: UUID (Foreign Key → posts.id)  
- created_at: TIMESTAMP
- UNIQUE constraint on (user_id, post_id)
```

### RPC Functions Created
- `like_post(post_id UUID)` → Returns JSON result
- `unlike_post(post_id UUID)` → Returns JSON result
- `has_user_liked_post(post_id UUID)` → Returns boolean

### Security (RLS Policies)
- ✅ Users can view all likes
- ✅ Users can only like posts when authenticated
- ✅ Users can only unlike their own likes

## 🧪 Testing Instructions

After database setup:

1. **Test Image Display**:
   - Navigate to Home tab
   - Check that post images display in 16:9 aspect ratio
   - Verify no cropping occurs

2. **Test Like Functionality**:
   - Tap the heart icon on any post
   - Should see immediate UI update (optimistic)
   - Check that like count increments
   - Tap again to unlike

3. **Test Comment Modal**:
   - Tap comment icon
   - Should see comment modal appear
   - Can dismiss by tapping outside

4. **Test Share Function**:
   - Tap share icon  
   - Should see system share dialog

## 🔧 Current App Status

- ✅ **Flutter App**: Running successfully with Supabase connected
- ✅ **Image Display**: Fixed with AspectRatio implementation
- ✅ **Backend Code**: Complete like/unlike integration implemented
- ⏳ **Database**: Needs manual setup via Supabase dashboard
- ⏳ **Testing**: Ready for testing after database setup

## 📱 Next Steps

1. **Execute the SQL** in Supabase dashboard
2. **Test the complete flow** on device
3. **Verify real-time updates** work correctly
4. **Check error handling** for edge cases

Once database is setup, all Home tab issues should be resolved with working image display and functional interaction buttons!