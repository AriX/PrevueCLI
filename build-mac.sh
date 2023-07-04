set -e # Fail script on error

cd "$(dirname "$0")"
xcodebuild

cd build

# Make the Mac distribution directory
mkdir -p mac-distribution
cp Release/PrevueCLI mac-distribution/

# Copy resources
cp ../Resources/*.prevuecommand mac-distribution/
cp -R ../Resources/Sample\ Listings mac-distribution/
