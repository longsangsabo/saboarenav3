@echo off
echo Building SABO Arena for iOS Release...
echo.

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean
call flutter pub get

echo.
echo Building iOS IPA...
call flutter build ios --release --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ iOS build completed!
    echo Note: You need to archive and export the IPA using Xcode
    echo Open ios/Runner.xcworkspace in Xcode to create distribution build
) else (
    echo.
    echo ✗ Build failed! Check the error messages above.
)

echo.
pause