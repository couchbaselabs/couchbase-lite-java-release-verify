#!/usr/bin/env bash
# verify_java_debian.sh - Debian/Ubuntu specific verification script
# Usage: ./verify_java_debian.sh <version> [artifact]
set -euo pipefail

VERSION="${1:?Usage: $0 <version> [artifact]}"
ARTIFACT="${2:-couchbase-lite-java-ee}"

echo "======================================"
echo "Couchbase Lite Java Verification"
echo "======================================"
echo "Version: $VERSION"
echo "Artifact: $ARTIFACT"
echo "Platform: Debian/Ubuntu Linux"
echo "======================================"

# Check prerequisites
check_prereqs() {
  echo ""
  echo "Checking prerequisites..."
  
  if ! command -v java &> /dev/null; then
    echo "Java not found. Installing OpenJDK 11..."
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jdk
  else
    echo "Java found: $(java -version 2>&1 | head -n 1)"
  fi
  
  if ! command -v curl &> /dev/null; then
    echo "curl not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y curl
  else
    echo "curl found"
  fi
}

check_prereqs

# Step 1: Download and verify artifacts
echo ""
echo "Step 1: Downloading and verifying artifacts..."
WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf -- "$WORK_DIR"; }
trap cleanup EXIT

OUT_DIR="${WORK_DIR}/cbl-downloads"

CENTRAL_BASE="https://repo1.maven.org/maven2"
EE_BASE="https://mobile.maven.couchbase.com/maven2/dev"
GROUP_PATH="com/couchbase/lite"

COMMUNITY=("couchbase-lite-java")
ENTERPRISE=("couchbase-lite-java-ee")

download_one() {
  local repo="$1" artifact="$2" version="$3" dest="$4"
  local base="${repo}/${GROUP_PATH}/${artifact}/${version}"
  local jar="${artifact}-${version}.jar"
  local pom="${artifact}-${version}.pom"

  mkdir -p "$dest"

  curl -fL --retry 3 --retry-delay 2 --show-error -o "${dest}/${jar}" "${base}/${jar}"
  curl -fL --retry 3 --retry-delay 2 --show-error -o "${dest}/${pom}" "${base}/${pom}"

  test -s "${dest}/${jar}"
  test -s "${dest}/${pom}"
}

for a in "${COMMUNITY[@]}"; do
  download_one "$CENTRAL_BASE" "$a" "$VERSION" "${OUT_DIR}/community"
done

for a in "${ENTERPRISE[@]}"; do
  download_one "$EE_BASE" "$a" "$VERSION" "${OUT_DIR}/enterprise"
done

echo "All artifacts downloaded successfully"