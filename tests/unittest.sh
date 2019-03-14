#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-07-31 12:18:38 +0100 (Sun, 31 Jul 2016)
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
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$srcdir/.."

. bash-tools/utils.sh

section "Running Perl Unit Tests"

#PERL5LIB=${PERLBREW_ROOT:-} PERL5OPT=-MDevel::Cover=-coverage,statement,branch,condition,path,subroutine prove -I . -lrsv --timer t
PERL5LIB=${PERLBREW_ROOT:-} prove -I . -lrsv --timer t
