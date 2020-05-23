cd "$(dirname "$0")"

export DEVELOPER_DIR=C:/Library/Developer
export SDKROOT=$DEVELOPER_DIR/Platforms/Windows.platform/Developer/SDKs/Windows.sdk
export SWIFTFLAGS="-sdk $SDKROOT -I $SDKROOT/usr/lib/swift -L $SDKROOT/usr/lib/swift/windows"
export PATH="$PATH:/c/Library/Developer/Toolchains/unknown-Asserts-development.xctoolchain/usr/bin"

export ICU_DLLS=C:/Library/icu-64/usr/bin
export SWIFT_DLLS=C:/Library/Swift-development/bin
export MSVC_RUNTIME_DLLS="C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Redist/MSVC/14.25.28508/onecore/x64/Microsoft.VC142.CRT"

mkdir -p build
cd build

# Build Yams
cmake -G Ninja -B Yams -D BUILD_SHARED_LIBS=YES -D BUILD_TESTING=NO -D CMAKE_BUILD_TYPE=Release -D CMAKE_Swift_FLAGS="$SWIFTFLAGS" -D CMAKE_C_FLAGS="-DWIN32" ../Modules/Yams/Yams
cmake --build Yams

# Build UVSGSerialData
clang -c ../Modules/UVSGSerialData/UVSGSerialData.c

# Build the Swift code
swiftc $SWIFTFLAGS -I../Modules/ -I../Modules/Yams/Yams/Sources/CYaml/include/ -IYams/swift -LYams/lib ../Shared/*/*.swift ../Shared/Commands/*/*.swift ../PrevueCLI/*.swift *.o -o PrevueCLI.exe

# Make the Windows distribution directory
mkdir -p windows-distribution
cp PrevueCLI.exe Yams/bin/*.dll windows-distribution/

# Copy required libraries
cp $ICU_DLLS/*.dll $SWIFT_DLLS/*.dll "$MSVC_RUNTIME_DLLS"/*.dll windows-distribution/

# Copy resources
cp ../Resources/*.prevuecommand windows-distribution/
cp -R ../Resources/Sample\ Listings windows-distribution/
