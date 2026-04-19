#!/bin/bash
# One-click release script for TypeNote.
#
# Usage:
#   ./release.sh <version>          e.g. ./release.sh 1.1
#
# First-time setup (run once):
#   1. Store notarization credentials in Keychain:
#        xcrun notarytool store-credentials "TypeNote" \
#          --apple-id "your@email.com" \
#          --team-id "$(grep -E '^DEVELOPMENT_TEAM\s*=' LocalConfig.xcconfig | sed 's/.*=\s*//')" \
#          --password "<app-specific-password>"
#
#   2. Place Sparkle's sign_update binary in scripts/:
#        Download from https://github.com/sparkle-project/Sparkle/releases
#        cp /path/to/Sparkle/bin/sign_update scripts/sign_update
#        chmod +x scripts/sign_update
#
#   3. Generate EdDSA key pair (one time only):
#        scripts/generate_keys   (also from Sparkle release archive)
#        → saves private key to Keychain, paste public key into Info.plist as SUPublicEDKey

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCHEME="TypeNote"
PROJECT="TypeNote.xcodeproj"
NOTARYTOOL_PROFILE="TypeNote"
GITHUB_REPO="huihuisang/TypeNote"
# ─────────────────────────────────────────────────────────────────────────────

# Read DEVELOPMENT_TEAM from LocalConfig.xcconfig
TEAM_ID=$(grep -E "^DEVELOPMENT_TEAM\s*=" LocalConfig.xcconfig 2>/dev/null | sed 's/.*=\s*//' | tr -d ' ')
[[ -n "$TEAM_ID" ]] || die "DEVELOPMENT_TEAM not found in LocalConfig.xcconfig\nRun: cp LocalConfig.xcconfig.template LocalConfig.xcconfig"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $*${NC}"; }
ok()   { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
die()  { echo -e "${RED}✗ $*${NC}"; exit 1; }
# ─────────────────────────────────────────────────────────────────────────────

VERSION="${1:?Usage: ./release.sh <version>  e.g. ./release.sh 1.1}"
TAG="v$VERSION"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build/release"
ARCHIVE_PATH="$BUILD_DIR/$SCHEME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH="$EXPORT_PATH/$SCHEME.app"
DMG_NAME="TypeNote-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

cd "$ROOT_DIR"

# ── Locate sign_update (prefer local scripts/, fallback to SPM DerivedData) ──
SIGN_UPDATE="$ROOT_DIR/scripts/sign_update"
if [[ ! -f "$SIGN_UPDATE" ]]; then
  SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData/TypeNote-* -path "*/artifacts/sparkle/Sparkle/bin/sign_update" 2>/dev/null | head -1)
fi

# ── Preflight checks ──────────────────────────────────────────────────────────
log "Checking prerequisites..."
command -v gh &>/dev/null         || die "gh not found — install with: brew install gh"
command -v create-dmg &>/dev/null || die "create-dmg not found — install with: brew install create-dmg"
command -v xcrun &>/dev/null      || die "Xcode command line tools not found"
[[ -f "$SIGN_UPDATE" ]]           || die "sign_update not found — open the project in Xcode once to let SPM resolve packages"
# Verify notarytool keychain profile exists (one-time setup required)
xcrun notarytool history --keychain-profile "$NOTARYTOOL_PROFILE" &>/dev/null \
  || die "Notarytool profile '$NOTARYTOOL_PROFILE' not found in Keychain.\nRun once to set it up:\n  xcrun notarytool store-credentials \"$NOTARYTOOL_PROFILE\" \\\\\n    --apple-id \"<your@email.com>\" \\\\\n    --team-id \"$TEAM_ID\" \\\\\n    --password \"<app-specific-password>\""
[[ -z "$(git status --porcelain)" ]] || warn "Uncommitted changes present — continuing anyway"
ok "Prerequisites OK"

# ── 1. Archive ────────────────────────────────────────────────────────────────
log "Archiving $SCHEME $VERSION..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=macOS" \
  MARKETING_VERSION="$VERSION" \
  2>&1 | grep -E "^(Archive|error:|warning: )" || true

[[ -d "$ARCHIVE_PATH" ]] || die "Archive failed — run manually to see full output"
ok "Archive complete"

# ── 2. Export (Developer ID signed .app) ─────────────────────────────────────
log "Exporting..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$ROOT_DIR/scripts/ExportOptions.plist" \
  2>&1 | grep -E "^(Export|error:)" || true

[[ -d "$APP_PATH" ]] || die "Export failed — no .app found at $APP_PATH"
ok "Export complete"

# ── 3. Create DMG ─────────────────────────────────────────────────────────────
log "Creating DMG..."
APP_ICON="$APP_PATH/Contents/Resources/AppIcon.icns"

create-dmg \
  --volname "TypeNote $VERSION" \
  --volicon "$APP_ICON" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --icon "TypeNote.app" 180 185 \
  --hide-extension "TypeNote.app" \
  --app-drop-link 480 185 \
  "$DMG_PATH" \
  "$APP_PATH"

[[ -f "$DMG_PATH" ]] || die "DMG creation failed"
ok "DMG created: $DMG_NAME"

# ── 4. Notarize ───────────────────────────────────────────────────────────────
log "Notarizing (this takes ~2 min)..."
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARYTOOL_PROFILE" \
  --wait

log "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"
ok "Notarized and stapled"

# ── 5. Sign with Sparkle ──────────────────────────────────────────────────────
log "Signing with Sparkle EdDSA key..."
SIGN_OUTPUT=$("$SIGN_UPDATE" "$DMG_PATH" 2>&1)
ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep -oE 'sparkle:edSignature="[^"]+"' | cut -d'"' -f2)
FILE_SIZE=$(stat -f%z "$DMG_PATH")

[[ -n "$ED_SIGNATURE" ]] || die "Failed to generate EdDSA signature. Output:\n$SIGN_OUTPUT"
ok "EdDSA signature: ${ED_SIGNATURE:0:20}..."

# ── 6. Create GitHub release ──────────────────────────────────────────────────
log "Creating GitHub release $TAG..."
gh release create "$TAG" "$DMG_PATH" \
  --repo "$GITHUB_REPO" \
  --title "TypeNote $VERSION" \
  --notes "### What's New

-

**[Download TypeNote-$VERSION.dmg](https://github.com/$GITHUB_REPO/releases/download/$TAG/$DMG_NAME)**"
ok "GitHub release created"

# ── 7. Update appcast.xml ─────────────────────────────────────────────────────
log "Updating appcast.xml..."
PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
DMG_URL="https://github.com/$GITHUB_REPO/releases/download/$TAG/$DMG_NAME"
NOTES_URL="https://github.com/$GITHUB_REPO/releases/tag/$TAG"

# Read current build number from the archive's Info.plist
BUILD_NUMBER=$(defaults read "$ARCHIVE_PATH/Products/Applications/$SCHEME.app/Contents/Info" CFBundleVersion 2>/dev/null || echo "1")

NEW_ITEM="
        <item>
            <title>Version $VERSION</title>
            <sparkle:releaseNotesLink>$NOTES_URL</sparkle:releaseNotesLink>
            <pubDate>$PUB_DATE</pubDate>
            <enclosure
                url=\"$DMG_URL\"
                sparkle:version=\"$BUILD_NUMBER\"
                sparkle:shortVersionString=\"$VERSION\"
                length=\"$FILE_SIZE\"
                type=\"application/octet-stream\"
                sparkle:edSignature=\"$ED_SIGNATURE\"
            />
        </item>"

# Insert new item before the first existing <item>
python3 - "$NEW_ITEM" <<'PYEOF'
import sys, re

new_item = sys.argv[1]
with open("appcast.xml", "r") as f:
    content = f.read()

# Insert before the first <item>
content = re.sub(r'(\s*<item>)', new_item + r'\1', content, count=1)

with open("appcast.xml", "w") as f:
    f.write(content)
PYEOF

ok "appcast.xml updated"

# ── 8. Commit and push ────────────────────────────────────────────────────────
log "Pushing appcast.xml..."
git add appcast.xml
git commit -m "release: $TAG"
git push
ok "appcast.xml pushed"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}🎵 TypeNote $VERSION is live!${NC}"
echo -e "   Release:  https://github.com/$GITHUB_REPO/releases/tag/$TAG"
echo -e "   DMG:      $DMG_PATH"
