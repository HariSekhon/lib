#  vim:ts=4:sts=4:sw=4:noet
#
#  Author: Hari Sekhon
#  Date: 2013-01-06 15:45:00 +0000 (Sun, 06 Jan 2013)
#
#  https://github.com/harisekhon/lib
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ===================
# bootstrap commands:

# setup/bootstrap.sh
#
# OR
#
# Alpine:
#
#   apk add --no-cache git make && git clone https://github.com/harisekhon/lib && cd lib && make
#
# Debian / Ubuntu:
#
#   apt-get update && apt-get install -y make git && git clone https://github.com/harisekhon/lib && cd lib && make
#
# RHEL / CentOS:
#
#   yum install -y make git && git clone https://github.com/harisekhon/lib && cd lib && make

# ===================

ifneq ("$(wildcard bash-tools/Makefile.in)", "")
	include bash-tools/Makefile.in
endif

REPO := HariSekhon/lib

CODE_FILES := $(shell find . -type f -name '*.pl' -o -type f -name '*.pm' -o -type f -name '*.sh' -o -type f -name '*.t' | grep -v -e bash-tools -e Hbase)

ifndef CPANM
	CPANM := cpanm
endif

.PHONY: build
build: init
	@echo ==============
	@echo Perl Lib Build
	@echo ==============
	@$(MAKE) git-summary
	@echo

	@# doesn't exit Make anyway, only line, and don't wanna use oneshell
	@#if [ -z "$(CPANM)" ]; then make; exit $$?; fi
	$(MAKE) system-packages-perl
	$(MAKE) perl

	git update-index --assume-unchanged resources/custom_tlds.txt

	@echo
	@echo "BUILD SUCCESSFUL (lib)"
	@echo
	@echo

.PHONY: init
init:
	git submodule update --init --recursive

.PHONY: perl
perl:
	perl -v

	#(echo y; echo o conf prerequisites_policy follow; echo o conf commit) | cpan
	which $(CPANM) || { yes "" | $(SUDO_PERL) cpan App::cpanminus; }
	$(CPANM) -V | head -n2

	@echo "Installing Test::More first because some libraries need this to already be present to build"
	$(BASH_TOOLS)/perl_cpanm_install_if_absent.sh Test::More

	@echo
	# called within cpan target
	@#$(MAKE) cpan-optional
	$(MAKE) cpan
	@echo
	@# newer versions of the Redis module require Perl >= 5.10, this will install the older compatible version for RHEL5/CentOS5 servers still running Perl 5.8 if the latest module fails
	@# the backdated version might not be the perfect version, found by digging around in the git repo
	@#echo "Installing Redis module or backdated version for older Perl"
	@#$(SUDO_PERL) $(CPANM) --notest Redis || $(SUDO_PERL) $(CPANM) --notest DAMS/Redis-1.976.tar.gz

.PHONY: test
test:
	tests/all.sh

.PHONY: unittest
unittest:
	tests/unittest.sh

.PHONY: install
install: build
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"

tld:
	wget -t 100 --retry-connrefused -O resources/tlds-alpha-by-domain.txt http://data.iana.org/TLD/tlds-alpha-by-domain.txt

.PHONY: clean
clean:
	:

.PHONY: deep-clean
deep-clean: clean
	# have to remove .cache for Python because we call bash-tools/check_pytools.sh which does a python build
	$(SUDO) rm -fr /root/.cpan \
				   /root/.cpanm \
				   /root/.cache \
				   ~/.cpan \
				   ~/.cpanm \
				   ~/.cache \
				   2>/dev/null
