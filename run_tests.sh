#!/usr/bin/env bash
# run_tests.sh - Run the Java verification tests
# Usage: ./run_tests.sh <version> [artifact]
set -euo pipefail

VERSION="${1:?Usage: $0 <version> [artifact]}"
ARTIFACT="${2:-couchbase-lite-java-ee}"

# Step 2: Run Java tests
echo ""
echo "Step 2: Running Java verification tests..."
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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