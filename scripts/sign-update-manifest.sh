#!/usr/bin/env bash

# scripts/update-manifest.txt에 ECDSA(P-256/SHA-256) 서명을 만든다.
# 개인키는 이 레포에 없고 릴리스 담당자 로컬 머신에만 둔다 — install.sh와
# scripts/lib/update.sh에 박힌 공개키와 짝을 이룬다. 새 릴리스마다:
#   1. scripts/generate-update-manifest.sh > scripts/update-manifest.txt
#   2. scripts/sign-update-manifest.sh
#   3. scripts/update-manifest.txt / .sig 커밋 + 태그
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/scripts/update-manifest.txt"
SIGNATURE="$MANIFEST.sig"
KEY="${UBS_SIGNING_KEY:-$HOME/.ubs-release-signing/ubs-manifest-signing-key.pem}"

command -v openssl >/dev/null 2>&1 || { echo "openssl이 필요합니다." >&2; exit 1; }
[ -f "$MANIFEST" ] || { echo "manifest가 없습니다: $MANIFEST (먼저 generate-update-manifest.sh 실행)" >&2; exit 1; }
[ -f "$KEY" ] || {
  echo "서명 개인키를 찾을 수 없습니다: $KEY" >&2
  echo "UBS_SIGNING_KEY로 경로를 지정하거나 새로 생성하세요:" >&2
  echo "  openssl ecparam -name prime256v1 -genkey -noout -out \"$KEY\"" >&2
  exit 1
}

PUBKEY="$(openssl ec -in "$KEY" -pubout 2>/dev/null)"
EMBEDDED="$(sed -n '/-----BEGIN PUBLIC KEY-----/,/-----END PUBLIC KEY-----/p' "$ROOT/scripts/lib/update.sh" |
  sed "s/^UBS_UPDATE_MANIFEST_PUBLIC_KEY='//; s/'\$//")"
if [ "$PUBKEY" != "$EMBEDDED" ]; then
  echo "경고: 이 키의 공개키가 scripts/lib/update.sh에 박힌 것과 다릅니다 — install.sh/update.sh를 먼저 갱신하세요." >&2
  exit 1
fi

openssl dgst -sha256 -sign "$KEY" -out "$SIGNATURE" "$MANIFEST"
echo "서명 완료: $SIGNATURE"
