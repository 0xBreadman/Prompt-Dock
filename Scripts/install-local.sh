#!/bin/zsh

set -euo pipefail

project_root=${0:A:h:h}
local_build_dir=$(mktemp -d /tmp/prompt-dock-build.XXXXXX)
target_app='/Applications/Prompt Dock.app'
identity_name='Prompt Dock Local Code Signing'
login_keychain=$(security default-keychain -d user | tr -d '"[:space:]')

cleanup() {
    if [[ "$local_build_dir" == /tmp/prompt-dock-build.* && -d "$local_build_dir" ]]; then
        find "$local_build_dir" -depth -delete
    fi
}
trap cleanup EXIT

identity_hash=$(
    security find-certificate -Z -c "$identity_name" "$login_keychain" \
        | awk '/SHA-1 hash:/{print $3; exit}'
)

if [[ -z "$identity_hash" ]]; then
    print -u2 "Missing local signing identity: $identity_name"
    exit 1
fi

xcodebuild \
    -project "$project_root/AIPromptDock.xcodeproj" \
    -scheme AIPromptDock \
    -configuration Release \
    -derivedDataPath "$local_build_dir" \
    -destination 'generic/platform=macOS' \
    ARCHS='arm64 x86_64' \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

built_app="$local_build_dir/Build/Products/Release/Prompt Dock.app"
codesign \
    --force \
    --deep \
    --sign "$identity_hash" \
    --options runtime \
    --entitlements "$project_root/Sources/AIPromptDock/AIPromptDock.entitlements" \
    "$built_app"
codesign --verify --deep --strict "$built_app"

pkill -x 'Prompt Dock' 2>/dev/null || true
for attempt in {1..5}; do
    pgrep -x 'Prompt Dock' >/dev/null || break
    sleep 1
done

if [[ -d "$target_app" ]]; then
    rollback_app="$HOME/.Trash/PromptDock-previous-$(date '+%Y%m%d-%H%M%S').app"
    mv "$target_app" "$rollback_app"
fi

ditto "$built_app" "$target_app"
xattr -dr com.apple.quarantine "$target_app" 2>/dev/null || true
codesign --verify --deep --strict "$target_app"
open "$target_app"
