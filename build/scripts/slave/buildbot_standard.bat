@echo off

:: TODO(timurrrr) echo @@@BUILD_STEP clobber@@@

echo @@@BUILD_STEP update@@@
:: TODO(timurrrr)
::if [ "$BUILDBOT_CLOBBER" != "" ]; then
::  echo @@@BUILD_STEP clobber build@@@
::  rmdir /S /Q llvm || goto :DIE
::  rmdir /S /Q llvm-build || goto :DIE
::  mkdir llvm-build || goto :DIE
::  rmdir /S /Q win_tests || goto :DIE
::fi

set REV_ARG=
if NOT "%BUILDBOT_REVISION%" == "" set REV_ARG="-r%BUILDBOT_REVISION%"

:: call -> because "svn" might be a batch script, ouch
call svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm %REV_ARG% || goto :DIE
call svn co http://llvm.org/svn/llvm-project/cfe/trunk llvm/tools/clang %REV_ARG% || goto :DIE
call svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt %REV_ARG% || goto :DIE
call svn co http://address-sanitizer.googlecode.com/svn/trunk/win/tests win_tests || echo "Failed to update Windows tests, alas..."

set ROOT=%cd%

echo @@@BUILD_STEP build asan RTL@@@
:: TODO(timurrrr): Only needed to build asan_thunk.dll actually.
:: Still useful to detect build errors early...
set ASAN_PATH=compiler-rt\lib\asan
cd %ASAN_PATH% || goto :DIE
:: This only compiles, not links.
del *.pdb *.obj *.lib || goto :DIE

:: /WX <- treat warnings as errors
:: /W3 <- warnings level 3
:: /MP <- parallel buidling (currently disabled)
:: /MT <- Multi-Threaded CRT with static linking
:: /Zi <- generate debug info
cl /nologo /WX /W3 /MT /Zi /I.. /I../../include /c *.cc ../P="" /c *.cc inter../sanitizer_commcc interception/*.cc || goto :DIE
lib /nologo /OUT:asan_rtl.lib *.obj ||l /nologo /WX /W3 /MT /Zi /DASAN_DLL_THUNK /c asan_dll_thunk.cc || goto :DIE
lib /nologo /OUT:asan_dll_thunk.lib asan_dll_thunk.obj || g%ROOT%

echo @@@BUILD_STEP cmake llvm@@@
mkdir llvm-build
:: TODO(timurrrr): Is this enough to force a full re-configure?
del llvm-build\CMakeCache.txt
cd llvm-build
cmake -DLLVM_TARGETS_TO_BUILD=X86 ..\llvm || goto :DIE
echo @@@BUILD_STEP build llvm@@@
cmake --build . || goto :DIE
cd %ROOT%

:: TODO(timurrrr) echo @@@BUILD_STEP test llvm@@@

echo @@@BUILD_STEP asan test@@@
cd win_tests || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATRM_F="/cygdrive/c/cygwin/bin/rm -f"Tclean || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATFORM=Windows CC=../llvm-build/bi-cl FILECHECK=../llvm-build/bin/Debug/FileCheck CFLAGS="-fsanitize=address" EXTRA_OBJ=../compiler-rt/lib/asan/asan_rtl.libe-k || goto :DIE

echo @@@BUILD_STEP asan DLL thunk test@@@
cd dll_tests || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATRM_F="/cygdrive/c/cygwin/bin/rm -f"Tclean || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATFORM=W../llvm-build/bin/Debug/clang-cl FILECHECK=../../llvm-build/bin/Debug/FileCheck CFLAGS="-fsanitize=address" EXTRA_HOST_LIBS=../../compiler-rt/lib/asan/asan_rtl.lib EXTRA_GUEST_LIBS="../../compiler-rt/lib/asan/asan_dll_thunk.lib" -k || goto :DIE
cd %ROOT%

:: TODO(timurrrr) echo @@@BUILD_STEP @@BUILD_STEP asan _tests@@@

echo "ALL DONE"
goto ::: TODO(timurrrr) : get the current process's PID?
taskkill /F /IM cmake.exe /T
taskkill /F /IM MSBuild.exe /T
exit /b 42
