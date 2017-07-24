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

CPANM = cpanm

ifdef PERLBREW_PERL
	SUDO2 =
else
	SUDO2 = sudo
endif

# must come after to reset SUDO2 to blank if root
# EUID /  UID not exported in Make
# USER not populated in Docker
ifeq '$(shell id -u)' '0'
	SUDO =
	SUDO2 =
else
	SUDO = sudo
endif

.PHONY: build
build:
	if [ -x /sbin/apk ];        then make apk-packages; fi
	if [ -x /usr/bin/apt-get ]; then make apt-packages; fi
	if [ -x /usr/bin/yum ];     then make yum-packages; fi

	git submodule init
	git submodule update --recursive
	git update-index --assume-unchanged resources/custom_tlds.txt

	#(echo y; echo o conf prerequisites_policy follow; echo o conf commit) | cpan
	which cpanm || { yes "" | $(SUDO2) cpan App::cpanminus; }
	# some libraries need this to be present first
	$(SUDO2) $(CPANM) --notest Test::More
	yes "" | $(SUDO2) $(CPANM) --notest `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/cpan-requirements.txt`

	# newer versions of the Redis module require Perl >= 5.10, this will install the older compatible version for RHEL5/CentOS5 servers still running Perl 5.8 if the latest module fails
	# the backdated version might not be the perfect version, found by digging around in the git repo
	$(SUDO2) $(CPANM) --notest Redis || $(SUDO2) $(CPANM) --notest DAMS/Redis-1.976.tar.gz

	@echo
	@echo "BUILD SUCCESSFUL (lib)"

.PHONY: quick
quick:
	QUICK=1 make

.PHONY: apk-packages
apk-packages:
	$(SUDO) apk update
	$(SUDO) apk add `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/apk-packages.txt`

.PHONY: apk-packages-remove
apk-packages-remove:
	$(SUDO) apk del `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/apk-packages-dev.txt` || :
	$(SUDO) rm -fr /var/cache/apk/*

.PHONY: apt-packages
apt-packages:
	$(SUDO) apt-get update
	$(SUDO) apt-get install -y `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/deb-packages.txt`

.PHONY: apt-packages-remove
apt-packages-remove:
	$(SUDO) apt-get purge -y `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/deb-packages-dev.txt`

.PHONY: yum-packages
yum-packages:
	for x in `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/rpm-packages.txt`; do rpm -q $$x || $(SUDO) yum install -y $$x; done

.PHONY: yum-packages-remove
yum-packages-remove:
	for x in `sed 's/#.*//; /^[[:space:]]*$$/d' < setup/rpm-packages-dev.txt`; do rpm -q $$x && $(SUDO) yum remove -y $$x; done

.PHONY: test
test:
	tests/all.sh

.PHONY: install
install:
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"


.PHONY: update
update:
	make update-no-recompile
	make


.PHONY: update2
update2:
	make update-no-recompile

.PHONY: update-no-recompile
update-no-recompile:
	git pull
	git submodule update --init --recursive

.PHONY: update-submodules
update-submodules:
	git submodule update --init --remote
.PHONY: updatem
updatem:
	make update-submodules

tld:
	wget -t 100 --retry-connrefused -O resources/tlds-alpha-by-domain.txt http://data.iana.org/TLD/tlds-alpha-by-domain.txt

.PHONY: clean
clean:
	@echo Nothing to clean

.PHONY: push
push:
	git push
