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

# Library dependencies are handled in one place in calling project

export PATH := $(PATH):/usr/local/bin

CPANM := cpanm

SUDO := sudo
SUDO_PERL := sudo

ifdef PERLBREW_PERL
	SUDO_PERL =
endif

# must come after to reset SUDO_PERL to blank if root
# EUID /  UID not exported in Make
# USER not populated in Docker
ifeq '$(shell id -u)' '0'
	SUDO =
	SUDO_PERL =
endif

# ===================
# bootstrap commands:

# Alpine:
#
#   apk add --no-cache git make && git clone https://github.com/harisekhon/lib && cd lib && make

# Debian / Ubuntu:
#
#   apt-get update && apt-get install -y make git && git clone https://github.com/harisekhon/lib && cd lib && make

# RHEL / CentOS:
#
#   yum install -y make git && git clone https://github.com/harisekhon/lib && cd lib && make

# ===================

.PHONY: build
build:
	@echo ==============
	@echo Perl Lib Build
	@echo ==============

	if [ -x /sbin/apk ];        then make apk-packages; fi
	if [ -x /usr/bin/apt-get ]; then make apt-packages; fi
	if [ -x /usr/bin/yum ];     then make yum-packages; fi

	git submodule init
	git submodule update --recursive
	git update-index --assume-unchanged resources/custom_tlds.txt

	#(echo y; echo o conf prerequisites_policy follow; echo o conf commit) | cpan
	which cpanm || { yes "" | $(SUDO_PERL) cpan App::cpanminus; }
	# some libraries need this to be present first
	$(SUDO_PERL) $(CPANM) --notest Test::More
	yes "" | $(SUDO_PERL) $(CPANM) --notest `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/cpan-requirements.txt`

	# newer versions of the Redis module require Perl >= 5.10, this will install the older compatible version for RHEL5/CentOS5 servers still running Perl 5.8 if the latest module fails
	# the backdated version might not be the perfect version, found by digging around in the git repo
	$(SUDO_PERL) $(CPANM) --notest Redis || $(SUDO_PERL) $(CPANM) --notest DAMS/Redis-1.976.tar.gz

	@echo
	@echo "BUILD SUCCESSFUL (lib)"
	@echo
	@echo

.PHONY: quick
quick:
	QUICK=1 make

.PHONY: apk-packages
apk-packages:
	$(SUDO) apk update
	$(SUDO) apk add `sed 's/#.*//; /^[[:space:]]*$$/d' setup/apk-packages.txt setup/apk-packages-dev.txt`

.PHONY: apk-packages-remove
apk-packages-remove:
	$(SUDO) apk del `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/apk-packages-dev.txt` || :
	$(SUDO) rm -fr /var/cache/apk/*

.PHONY: apt-packages
apt-packages:
	$(SUDO) apt-get update
	$(SUDO) apt-get install -y `sed 's/#.*//; /^[[:space:]]*$$/d' setup/deb-packages.txt setup/deb-packages-dev.txt`
	# Ubuntu 12 Precise which is still used in Travis CI uses libmysqlclient-dev, but Debian 9 Stretch and Ubuntu 16 Xenial
	# use libmariadbd-dev so this must now be handled separately as a failback
	$(SUDO) apt-get install -y libmariadbd-dev || $(SUDO) apt-get install -y libmysqlclient-dev

.PHONY: apt-packages-remove
apt-packages-remove:
	$(SUDO) apt-get purge -y `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/deb-packages-dev.txt`
	$(SUDO) apt-get purge -y libmariadbd-dev || :
	$(SUDO) apt-get purge -y libmysqlclient-dev || :

.PHONY: yum-packages
yum-packages:
	for x in `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/rpm-packages.txt setup/rpm-packages-dev.txt`; do rpm -q $$x || $(SUDO) yum install -y $$x; done

.PHONY: yum-packages-remove
yum-packages-remove:
	for x in `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/rpm-packages-dev.txt`; do if rpm -q $$x; then $(SUDO) yum remove -y $$x; fi; done

.PHONY: test
test:
	tests/all.sh

.PHONY: install
install:
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"


.PHONY: update
update: update-no-recompile build
	:

.PHONY: update2
update2: update-no-recompile
	:

.PHONY: update-no-recompile
update-no-recompile:
	git pull
	git submodule update --init --recursive

.PHONY: update-submodules
update-submodules:
	git submodule update --init --remote
.PHONY: updatem
updatem: update-submodules
	:

tld:
	wget -t 100 --retry-connrefused -O resources/tlds-alpha-by-domain.txt http://data.iana.org/TLD/tlds-alpha-by-domain.txt

.PHONY: clean
clean:
	:

.PHONY: deep-clean
deep-clean: clean
	$(SUDO) rm -fr /root/.cache \
				   /root/.cpan \
				   /root/.cpanm \
				   ~/.cache \
				   ~/.cpan \
				   ~/.cpanm \
				   2>/dev/null

.PHONY: push
push:
	git push
