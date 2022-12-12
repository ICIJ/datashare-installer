#!/bin/bash
repo=ICIJ/datashare-installer
release=$1

if [[ -z "$release" ]]; then
  echo "usage: $0 <release_name>"
  exit 1
fi

upload_url=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -d "{\"tag_name\":\"${release}\", \"name\":\"${release}\",\"body\":\"release ${release}\"}" "https://api.github.com/repos/$repo/releases" | jq -r '.upload_url')
upload_url="${upload_url%\{*}"

echo "uploading asset to release to url : $upload_url"

curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/x-xar" \
  --data-binary "@mac/dist/datashare-$release.pkg" "$upload_url?name=datashare-$release.pkg&label=datashare-$release.pkg"

curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/vnd.microsoft.portable-executable" \
  --data-binary "@windows/dist/datashare-$release.exe" "$upload_url?name=datashare-$release.exe&label=datashare-$release.exe"
  
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/x-sh" \
  --data-binary "@linux/dist/datashare-$release.sh" "$upload_url?name=datashare-$release.sh&label=datashare-$release.sh"
