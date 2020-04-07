#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-07 13:45:48 +0100 (Tue, 07 Apr 2020)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

cd "$srcdir"

sed 's/#.*//; s/:/ /' ../../bash-tools/setup/repolist.txt |
grep -e nagios-plugins -e perl-tools |
while read -r repo dir; do
    #if [ -z "$dir" ]; then
    #    dir="$repo"
    #fi
    repo="$(tr '[:upper:]' '[:lower:]' <<< "$repo")"
    if ! [ -d "../../../$dir" ]; then
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    for filename in *.yaml; do
        target="../../../$dir/.github/workflows/$filename"
        if [ -f "$target.disabled" ]; then
            target="$target.disabled"
        fi
        if [ -n "${ALL:-}" ] || grep -Eq '^[[:space:]]*(container|python-version):' "$filename"; then
            if [ -n "${NEW:-}" ] || [ -f "$target" ]; then
                echo "syncing $filename -> $target"
                timeout=60
                if [[ "$repo" =~ nagios-plugins ]]; then
                    timeout=240
                fi
                sed "s/lib/$repo/;s/timeout-minutes:.*/timeout-minutes: $timeout/" "$filename" > "$target"
                if [ "$repo" = "nagios-plugins" ]; then
                    perl -pi -e 's/(^[[:space:]]+make$)/\1 build zookeeper/' "$target"
                fi
            fi
        fi
    done
done
