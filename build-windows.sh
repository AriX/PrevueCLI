cd "$(dirname "$0")"

export SDKROOT=/c/Library/Developer/Platforms/Windows.platform/Developer/SDKs/Windows.sdk
export SWIFTFLAGS="-sdk $SDKROOT -I $SDKROOT/usr/lib/swift -L $SDKROOT/usr/lib/swift/windows"
export PATH="$PATH:/c/Library/Developer/Toolchains/unknown-Asserts-development.xctoolchain/usr/bin"

mkdir -p build
cd build

clang -c ../Modules/UVSGSerialData/UVSGSerialData.c
clang -c -I../Modules/Yams/Yams/Sources/CYaml/include/ ../Modules/Yams/Yams/Sources/CYaml/src/*.c

swiftc $SWIFTFLAGS -DSWIFT_PACKAGE -I../Modules/ -I../Modules/Yams/Yams/Sources/CYaml/include/ ../Shared/*/*.swift ../Shared/Commands/*/*.swift ../PrevueCLI/*.swift *.o ../Modules/Yams/Yams/Sources/Yams/*.swift -o PrevueCLI.exe
