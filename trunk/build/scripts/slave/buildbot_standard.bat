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
call svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk llvm/projects/compiler-rt %REV_ARG% || goto :DIE
call svn co http://address-sanitizer.googlecode.com/svn/trunk/win/tests win_tests || echo "Failed to update Windows tests, alas..."

set ROOT=%cd%

echo @@@BUILD_STEP cmake llvm@@@
mkdir llvm-build
cd llvm-build || goto :DIE

:: TODO(timurrrr): Is this enough to force a full re-configure?
del CMakeCache.txt
rmdir /S /Q CMakeFiles

cmake -GNinja -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 ..\llvm || goto :DIE

echo @@@BUILD_STEP build compiler-rt@@@
:: Build compiler-rt separately first, as this should help us find ASan RTL
:: compile-time bugs quicker.
ninja compiler-rt

echo @@@BUILD_STEP build llvm@@@
ninja || goto :DIE
cd %ROOT%

:: TODO(timurrrr) echo @@@BUILD_STEP test llvm@@@

echo @@@BUILD_STEP asan test@@@
cd win_tests || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATRM_F="/cygdrive/c/cygwin/bin/rm -f"Tclean || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATFORM=Windows CC=../llclang-cl FILECHECK=../llvm-build/bin/FileCheck CFLAGS="-fsanitize=address -Zi" UAR_FLAG="-fsanitize=use-after-return" -k || goto :DIE

echo @@@BUILD_STEP asan DLL thunk test@@@
cd dll_tests || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATRM_F="/cygdrive/c/cygwin/bin/rm -f"Tclean || goto :DIE
cd win_tests
C:\cyg-sgwin\bin\make PLATFORM=W../llvm-build/bin/clang-cl FILECHECK=../../llvm-build/bin/FileCheck CFLAGS="-fsanitize=address -Zi" -k || goto :DIE
cd %ROOT%

:: TODO(timurrrr) echo @@@BUILD_STEP @@BUILD_STEP asan :: TODO(timurrrr)
:: echo @@@BUILD_STEP build asan RTL with clang@@@san _tests@@@

echo "ALL DONE"
goto ::: TODO(timurrrr) : get the current process's PID?
taskkill /F /IM cmake.exe /T 2>err
taskkill /F /IM MSBuild.exe /T 2>err
exit /b 42
