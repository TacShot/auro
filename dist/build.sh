#!/usr/bin/env bash
# build.sh — Build and package Auro.app into a distributable DMG/zip.
# Usage: bash dist/build.sh [--configuration Release|Debug] [--output <dir>]
# Requirements: Xcode command-line tools (xcodebuild, hdiutil)

set -euo pipefail

# ---------- defaults ----------
CONFIGURATION="Release"
SCHEME="Auro"
PROJECT="Auro.xcodeproj"
OUTPUT_DIR="$(pwd)/dist/output"
APP_NAME="Auro"

# ---------- dependency checks ----------
require_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

require_command xcodebuild
require_command zip

if ! xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools not configured. Run: xcode-select --install" >&2
    exit 1
fi

echo "==> Xcode version"
xcodebuild -version
echo ""

# ---------- argument parsing ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --configuration) CONFIGURATION="$2"; shift 2 ;;
        --output)        OUTPUT_DIR="$2";    shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------- resolve paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_PATH="${REPO_ROOT}/${PROJECT}"
ARCHIVE_PATH="${OUTPUT_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${OUTPUT_DIR}/export"
APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"
ZIP_PATH="${OUTPUT_DIR}/${APP_NAME}-${CONFIGURATION}.zip"
DMG_PATH="${OUTPUT_DIR}/${APP_NAME}-${CONFIGURATION}.dmg"

mkdir -p "${OUTPUT_DIR}"

echo "==> Building ${APP_NAME} [${CONFIGURATION}]"
echo "    Project : ${PROJECT_PATH}"
echo "    Archive : ${ARCHIVE_PATH}"
echo "    Output  : ${OUTPUT_DIR}"
echo ""

# ---------- archive ----------
echo "==> Archiving..."
xcodebuild archive \
    -project "${PROJECT_PATH}" \
    -scheme  "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | grep -E "^(Build|error:|warning:|note:|archive)" || true

# ---------- export app bundle ----------
echo ""
echo "==> Exporting app bundle..."
mkdir -p "${EXPORT_PATH}"
cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/"

# ---------- zip ----------
echo ""
echo "==> Creating ZIP: ${ZIP_PATH}"
cd "${EXPORT_PATH}"
zip -r --symlinks "${ZIP_PATH}" "${APP_NAME}.app"
cd - > /dev/null

# ---------- DMG (optional, requires hdiutil) ----------
if command -v hdiutil &>/dev/null; then
    echo ""
    echo "==> Creating DMG: ${DMG_PATH}"
    STAGING_DIR="$(mktemp -d)"
    cp -R "${APP_PATH}" "${STAGING_DIR}/"
    hdiutil create \
        -volname "${APP_NAME}" \
        -srcfolder "${STAGING_DIR}" \
        -ov \
        -format UDZO \
        "${DMG_PATH}"
    rm -rf "${STAGING_DIR}"
    echo "    DMG : ${DMG_PATH}"
else
    echo ""
    echo "==> hdiutil not found — skipping DMG creation (macOS only)"
fi

echo ""
echo "==> Done!"
echo "    ZIP : ${ZIP_PATH}"
[[ -f "${DMG_PATH}" ]] && echo "    DMG : ${DMG_PATH}"
