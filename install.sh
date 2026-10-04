#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?pikopod version, like 0.1.2}"
DEST="${2:-$RUNNER_TEMP/pikopod-$VERSION}"
BASE="https://github.com/Pikopod/pikopod/releases/download/v${VERSION}"

case "$(uname -s)" in
  Linux) OS=linux ;;
  Darwin) OS=darwin ;;
  *) echo "unsupported runner OS: $(uname -s)" >&2; exit 2 ;;
esac
case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "unsupported runner architecture: $(uname -m)" >&2; exit 2 ;;
esac

ARCHIVE="pikopod_${VERSION}_${OS}_${ARCH}.tar.gz"
mkdir -p "$DEST"
cd "$DEST"
for f in "$ARCHIVE" SHA256SUMS SHA256SUMS.pem SHA256SUMS.sig; do
  curl -fsSL --retry 3 -o "$f" "$BASE/$f"
done

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c SHA256SUMS --ignore-missing
else
  shasum -a 256 -c SHA256SUMS --ignore-missing
fi
cosign verify-blob --certificate SHA256SUMS.pem --signature SHA256SUMS.sig SHA256SUMS \
  --certificate-identity-regexp '^https://github.com/Pikopod/pikopod/\.github/workflows/release\.yml@refs/tags/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

tar xzf "$ARCHIVE"
chmod +x pikopod
echo "$DEST" >> "${GITHUB_PATH:-/dev/null}"
echo "pikopod $VERSION verified and installed at $DEST/pikopod"
