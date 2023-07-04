set -e # Fail script on error

cd "$(dirname "$0")"

mkdir -p build
cd build

# Build Yams
cmake -G Ninja -B Yams -D BUILD_SHARED_LIBS=YES -D BUILD_TESTING=NO -D CMAKE_BUILD_TYPE=Release ../Modules/Yams
cmake --build Yams

# Build UVSGSerialData
clang -fPIC -c ../Modules/UVSGSerialData/UVSGSerialData.c ../Modules/PowerPacker/pplib.c

# Build the Swift code
swiftc $SWIFTFLAGS -I../Modules/ -I../Modules/Yams/Sources/CYaml/include/ -IYams/swift -LYams/lib ../Source/*/*.swift ../Source/*/*/*.swift ../Source/*/*/*/*.swift ../PrevueCLI/*.swift ../Modules/PowerPacker/*.swift ../Modules/BinaryCoder/*.swift ../Modules/CSV.swift/Sources/CSV/*.swift *.o -o PrevueCLI -Xlinker '-rpath=$ORIGIN'

# Make the Linux distribution directory
mkdir -p linux-distribution
cp PrevueCLI Yams/lib/*.so linux-distribution/

# Copy required libraries
cp -P "$(dirname $(dirname $(which swift)))/lib/swift/linux/lib"* linux-distribution/
rm linux-distribution/lib_InternalSwift* linux-distribution/libswift_Differentiation.so linux-distribution/libXCTest.so

# Copy resources
cp ../Resources/*.prevuecommand linux-distribution/
cp -R ../Resources/Sample\ Listings linux-distribution/
