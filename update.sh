#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nurl gnused
set -euo pipefail
IFS=$'\n\t'

function get_vendor_hash() {
    local url="$1"
    local src="$(nurl "$url")"
    if [[ -z "$src" ]]; then
        echo "Failed to fetch $url" >&2
        exit 1
    fi
    local stderr="$(nix build --impure --no-link --expr "with (import <nixpkgs> {}); buildGoModule {pname=\"\";version=\"\";src=$src;vendorHash=\"\";}" 2>&1 > /dev/null)"
    # vendorHash line contains "got: "
    local vendor_hash="$(echo "$stderr" | grep -oP '(?<=got: ).*')"
    vendor_hash="$(echo "$vendor_hash" | tr -d '[:space:]')"
    echo "$vendor_hash"
}

function replace_vendor_hash() {
    local vendor_hash="$1"
    local file="$2"
    local tmp="$(mktemp)"
    sed "s|vendorHash = \".*\"|vendorHash = \"$vendor_hash\"|" "$file" > "$tmp"
    mv "$tmp" "$file"
}

function main() {
    local url="https://github.com/seaweedfs/seaweedfs"
    local file="./flake.nix"

    local vendor_hash="$(get_vendor_hash "$url")"
    replace_vendor_hash "$vendor_hash" "$file"
}

main
