#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-07-31 12:18:38 +0100 (Sun, 31 Jul 2016)
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
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$srcdir/.."

export PROJECT="lib (perl)"

# shellcheck disable=SC1091
. bash-tools/lib/utils.sh

section "Perl Lib Tests"

perl_lib_start_time="$(start_timer)"

tests/find_uncovered_subs.sh

# overlaps with bash-tools
#bash-tools/checks/check_perl_syntax.sh HariSekhonUtils.pm

tests/unittest.sh

bash-tools/checks/check_all.sh

time_taken "$perl_lib_start_time" "Perl Lib Tests Completed in"
section2 "Perl Lib Tests Successful"
