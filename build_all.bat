@echo off
cd /d "E:\G.A - Song"

echo ========================================
echo  STEP 1: flutter clean
echo ========================================
call flutter clean
if %errorlevel% neq 0 (
    echo CLEAN FAILED
    exit /b %errorlevel%
)

echo ========================================
echo  STEP 2: flutter pub get
echo ========================================
call flutter pub get
if %errorlevel% neq 0 (
    echo PUB GET FAILED
    exit /b %errorlevel%
)

echo ========================================
echo  STEP 3: flutter analyze
echo ========================================
call flutter analyze
if %errorlevel% neq 0 (
    echo ANALYZE FOUND ISSUES
    exit /b %errorlevel%
)

echo ========================================
echo  STEP 4: flutter test
echo ========================================
call flutter test
if %errorlevel% neq 0 (
    echo TESTS FAILED
    exit /b %errorlevel%
)

echo ========================================
echo  STEP 5: flutter build apk --release
echo ========================================
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ANDROID BUILD FAILED
    exit /b %errorlevel%
)

echo ========================================
echo  STEP 6: flutter build windows --release
echo ========================================
call flutter build windows --release
if %errorlevel% neq 0 (
    echo WINDOWS BUILD FAILED
    exit /b %errorlevel%
)

echo ========================================
echo  ✅ ALL BUILDS SUCCESSFUL!
echo ========================================
exit /b 0
