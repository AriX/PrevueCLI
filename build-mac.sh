set -e # Fail script on error

cd "$(dirname "$0")"
swift build -c release

# Make the distribution directory
mkdir -p build/distribution
cp .build/release/PrevueCLI build/distribution/

# Copy resources
cp Resources/*.prevuecommand build/distribution/
cp -R Resources/Sample\ Listings build/distribution/
