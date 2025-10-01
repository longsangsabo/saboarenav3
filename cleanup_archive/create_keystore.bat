@echo off
echo Creating Android keystore for SABO Arena...
echo.
echo Please enter the following information when prompted:
echo - Store password: (remember this password!)
echo - Key password: (can be same as store password)
echo - First and last name: Your name or company name
echo - Organization: Your organization
echo - City: Your city
echo - State: Your state/province
echo - Country code: VN (for Vietnam)
echo.
pause

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

echo.
echo Keystore created successfully!
echo IMPORTANT: Keep the upload-keystore.jks file and passwords safe!
echo You will need them for every app update.
pause