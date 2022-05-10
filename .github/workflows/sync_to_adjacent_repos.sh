#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-07 13:45:48 +0100 (Tue, 07 Apr 2020)
#
#  https://github.com/HariSekhon/lib
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

cd "$srcdir"

sed 's/#.*//; s/:/ /' ../../bash-tools/setup/repos.txt |
grep -i -e nagios-plugins -e perl-tools |
while read -r repo dir; do
    #if [ -z "$dir" ]; then
    #    dir="$repo"
    #fi
    if ! [ -d "../../../$dir" ]; then
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    for filename in perl*.yaml; do
        target="../../../$dir/.github/workflows/$filename"
        echo "copying $filename to $target"
        sed "s/\/lib$/\/$repo/" "$filename" > "$target"
    done
done
