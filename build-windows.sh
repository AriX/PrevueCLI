set -e # Fail script on error

cd "$(dirname "$0")"
# This doesn't work when run from MSYS2 for some reason ("Missing or empty JSON output from manifest compilation")
# swift build -c release

# Make the distribution directory
mkdir -p build/distribution
cp .build/release/PrevueCLI.exe build/distribution/

# Copy resources
cp Resources/*.prevuecommand build/distribution/
cp -R Resources/Sample\ Listings build/distribution/

export SWIFT_DLLS="$PROGRAMFILES/swift/runtime-development/usr/bin"
export MSVC_RUNTIME_DLLS="$VCToolsRedistDir/x64/Microsoft.VC143.CRT"

# Copy required libraries
cp "$SWIFT_DLLS"/*.dll "$MSVC_RUNTIME_DLLS"/*.dll build/distribution/
