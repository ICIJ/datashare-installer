#!/bin/bash
set -euo pipefail

repo=ICIJ/datashare-installer
release=${1:-}

if [[ -z "$release" ]]; then
  echo "usage: $0 <release_name>"
  exit 1
fi

upload_url=$(curl -sS --fail -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$repo/releases/tags/${release}" | jq -r '.upload_url')
if [[ -z "$upload_url" || "$upload_url" == "null" ]]; then
  echo "no release found for tag ${release}" >&2
  exit 1
fi
upload_url="${upload_url%\{*}"

echo "uploading asset to release to url : $upload_url"

curl -sS --fail \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/x-xar" \
  --data-binary "@mac/dist/datashare-$release.pkg" "$upload_url?name=datashare-$release.pkg&label=datashare-$release.pkg"

curl -sS --fail \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/vnd.microsoft.portable-executable" \
  --data-binary "@windows/dist/datashare-$release.exe" "$upload_url?name=datashare-$release.exe&label=datashare-$release.exe"
