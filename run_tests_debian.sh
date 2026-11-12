#!/usr/bin/env bash
# run_tests_debian.sh - Run the Java verification tests
# Usage: ./run_tests_debian.sh <version> [artifact]
set -euo pipefail

VERSION="${1:?Usage: $0 <version> [artifact]}"
ARTIFACT="${2:-couchbase-lite-java-ee}"

# Step 2: Run Java tests
echo ""
echo "Step 2: Running Java verification tests..."
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# libLiteCore.so needs ICU 76 on Linux and the Maven jar doesn't include it.
# Use the support libs released with this version.
WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf -- "$WORK_DIR"; }
trap cleanup EXIT

SUPPORT_LIBS_URL="https://packages.couchbase.com/releases/couchbase-lite-java/${VERSION}/couchbase-lite-java-linux-supportlibs-${VERSION}.zip"
curl -fL --retry 3 --retry-delay 2 --show-error -o "${WORK_DIR}/supportlibs.zip" "$SUPPORT_LIBS_URL"
unzip -q "${WORK_DIR}/supportlibs.zip" -d "${WORK_DIR}/supportlibs"
export LD_LIBRARY_PATH="${WORK_DIR}/supportlibs${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

cd "$SCRIPT_DIR/java-tests"

# Make gradlew executable if it exists
if [ -f ./gradlew ]; then
  chmod +x ./gradlew
fi

# Run tests
./gradlew clean test \
  --no-daemon \
  -PcblVersion="$VERSION" \
  -PcblArtifact="$ARTIFACT"

echo ""
echo "======================================"
echo "Verification completed successfully!"
echo "======================================"
echo "Test results: $SCRIPT_DIR/java-tests/build/reports/tests/test/index.html"