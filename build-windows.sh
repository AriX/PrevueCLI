cd "$(dirname "$0")"

export SDKROOT=/c/Library/Developer/Platforms/Windows.platform/Developer/SDKs/Windows.sdk
export SWIFTFLAGS="-sdk $SDKROOT -I $SDKROOT/usr/lib/swift -L $SDKROOT/usr/lib/swift/windows"
export PATH="$PATH:/c/Library/Developer/Toolchains/unknown-Asserts-development.xctoolchain/usr/bin"

clang -c Shared/UVSGSerialData/UVSGSerialData.c

swiftc $SWIFTFLAGS -IShared/ Shared/*/*.swift Shared/Commands/*/*.swift PrevueCLI/main.swift UVSGSerialData.o -o prevue
