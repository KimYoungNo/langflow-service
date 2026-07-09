#!/bin/bash
set -Eeuo errexit
set -Eeuo pipefail

regex='^[[:space:]]*source[[:space:]]+['"'"'"]?([^[:space:]'"'"'"]+)['"'"'"]?[[:space:]]*$'
disclaimer='
# AUTO-GENERATED FILE — DO NOT EDIT
#
# This script is produced by the build/generation process.  
# Any manual modifications will be overwritten when the file is
# regenerated and will NOT be reflected in the original source.
#
# To change this script, edit the corresponding source
# and regenerate it instead.

# Author: KimYoungNo
# License: MIT'

function embed() {
  local src="$1"
  local dst="langflow-service-${src#src/body-}"
  local tmp="$(mktemp)"

  if [[ ! -f "$src" ]]; then
    return
  fi
  
  exec 3<"$src"
  lineno=0

  while IFS= read -r -u 3 line || [[ -n $line ]]; do
    if [[ $line =~ $regex && -f "src/${BASH_REMATCH[1]}" ]]; then
      cat "src/${BASH_REMATCH[1]}" >>"$tmp"
    else
      printf '%s\n' "$line" >>"$tmp"
    fi
    ((lineno+=1))
    if [ $lineno == 1 ]; then
      printf '%s\n' "$disclaimer" >>"$tmp"
    fi
  done
  exec 3<&-

  chmod --reference="$src" "$tmp"
  mv -- "$tmp" "$dst"
}

shopt -s nullglob
for script in src/body-*.sh; do
  embed "${script}"
done