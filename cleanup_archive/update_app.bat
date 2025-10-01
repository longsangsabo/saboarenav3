#!/bin/bash
# Script cập nhật app nhanh chóng

echo "🔄 UPDATING SABO ARENA APP"
echo "=========================="

# Step 1: Clean và get dependencies
echo "1️⃣ Cleaning project..."
flutter clean
flutter pub get

# Step 2: Build new AAB
echo "2️⃣ Building new AAB with Supabase config..."
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ

echo "✅ New AAB created at: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📋 Next steps:"
echo "1. Go to Google Play Console"
echo "2. Production → Create new release"
echo "3. Upload new AAB file"
echo "4. Add release notes"
echo "5. Submit for review"
echo ""
echo "🚀 Update will be live in 1-3 hours (no full review needed)!"