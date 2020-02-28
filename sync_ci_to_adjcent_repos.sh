#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-13 15:36:35 +0000 (Thu, 13 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
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

sed 's/#.*//; s/:/ /' "$srcdir/bash-tools/setup/repolist.txt" |
grep -v -e bash-tools -e '^[[:space:]]*$' |
while read -r repo dir; do
    if [ "$repo" = lib ]; then
        continue
    fi
    if [ -z "$dir" ]; then
        dir="$repo"
    fi
    repo="$(tr '[:upper:]' '[:lower:]' <<< "$repo")"
    if ! [ -d "../$dir" ]; then
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    for filename in *.yml .circleci/config.yml; do
        target="../$dir/$filename"
        echo "syncing $filename -> $target"
        sed "s,/lib,/$repo," "$filename" > "$target"
        if [ "$repo" = "nagios-plugins" ]; then
            perl -pi -e 's/(^[[:space:]]+make ci$)/\1 ci zookeeper-retry/' "$target"
        fi
    done
done
