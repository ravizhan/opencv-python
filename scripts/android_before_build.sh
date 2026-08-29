#!/bin/sh
# Patch OpenCV CMake files to enable Python bindings on Android.
# Called by cibuildwheel before_build. Idempotent: safe to run multiple times.
set -ex

cd opencv

# 1. Enable python module on Android (remove ANDROID from the disable check)
sed -i 's/if(ANDROID OR APPLE_FRAMEWORK OR WINRT)/if(APPLE_FRAMEWORK OR WINRT)  # Android: removed ANDROID exclusion/' \
    modules/python/CMakeLists.txt
grep "removed ANDROID exclusion" modules/python/CMakeLists.txt || echo "WARNING: patch 1 failed"

# 2. Enable python detection on Android
sed -i 's/if(NOT ANDROID AND NOT IOS AND NOT XROS)/if(NOT IOS AND NOT XROS)  # Android: removed ANDROID exclusion/' \
    cmake/OpenCVDetectPython.cmake
sed -i 's/endif(NOT ANDROID AND NOT IOS AND NOT XROS)/endif(NOT IOS AND NOT XROS)  # Android: removed ANDROID exclusion/' \
    cmake/OpenCVDetectPython.cmake
grep "removed ANDROID exclusion" cmake/OpenCVDetectPython.cmake || echo "WARNING: patch 2 failed"

# 3. Enable LAPACK option visibility on Android
sed -i 's/VISIBLE_IF NOT ANDROID AND NOT IOS AND NOT XROS$/VISIBLE_IF NOT IOS AND NOT XROS # Android: removed ANDROID exclusion/' \
    CMakeLists.txt
grep "removed ANDROID exclusion" CMakeLists.txt || echo "WARNING: patch 3 failed"

# 4. Fix linker flags: remove --no-undefined-version which causes '-version' error on Android
if ! grep -q 'no-undefined-version' modules/python/common.cmake 2>/dev/null; then
    sed -i '/^string(REGEX REPLACE.*--no-undefined/i\
string(REPLACE "-Wl,--no-undefined-version" "" CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS}")  # Android: fix linker' \
        modules/python/common.cmake
fi
grep "no-undefined-version" modules/python/common.cmake || echo "WARNING: patch 4 failed"

echo "=== All patches applied ==="
cd ..
