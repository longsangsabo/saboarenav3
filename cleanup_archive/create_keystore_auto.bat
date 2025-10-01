@echo off
echo Creating keystore for SABO Arena...
echo.

"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass "Acookingoil123@" -keypass "Acookingoil123@" -dname "CN=SABO Arena, OU=Development, O=SABO, L=Ho Chi Minh, ST=Ho Chi Minh, C=VN"

if exist upload-keystore.jks (
    echo.
    echo ✓ Keystore created successfully!
    echo File: upload-keystore.jks
    echo Alias: upload
    echo Password: Acookingoil123@
    echo.
    echo IMPORTANT: Keep this file and password safe!
) else (
    echo ✗ Failed to create keystore
)

pause