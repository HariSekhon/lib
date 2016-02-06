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

ifneq ("$(PERLBREW_PERL)$(TRAVIS)", "")
	SUDO2 =
else
	SUDO2 = sudo
endif

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
	if [ -x /usr/bin/apt-get ]; then make apt-packages; fi
	if [ -x /usr/bin/yum ];     then make yum-packages; fi

	git submodule init
	git submodule update --recursive
	git update-index --assume-unchanged resources/custom_tlds.txt

	# order here is important, in Travis and some stripped down client some deps are not pulled in automatically but are required for subsequent module builds
	# this doesn't work it's misaligned with the prompts, should use expect instead if I were going to do this
	#(echo y; echo o conf prerequisites_policy follow; echo o conf commit) | cpan
	yes "" | $(SUDO2) cpan App::cpanminus
	yes "" | $(SUDO2) $(CPANM) --notest \
		YAML \
		Data::Dumper \
		Devel::Cover::Report::Coveralls \
		ExtUtils::Constant \
		IO::Socket::IP \
		IO::Socket::Timeout \
		JSON \
		JSON::XS \
		LWP::Simple \
		LWP::UserAgent \
		Math::Round \
		MongoDB \
		MongoDB::MongoClient \
		Net::LDAP \
		Net::LDAPI \
		Net::LDAPS \
		Net::DNS \
		Net::SSH::Expect \
		Net::SSL \
		Readonly \
		Readonly::XS \
		Sys::Syslog \
		Term::ReadKey \
		Thrift \
		Time::HiRes \
		XML::SAX \
		XML::Simple \
		;
	# newer versions of the Redis module require Perl >= 5.10, this will install the older compatible version for RHEL5/CentOS5 servers still running Perl 5.8 if the latest module fails
	# the backdated version might not be the perfect version, found by digging around in the git repo
	$(SUDO2) $(CPANM) --notest Redis || $(SUDO2) $(CPANM) --notest DAMS/Redis-1.976.tar.gz
	@echo
	@echo "BUILD SUCCESSFUL (lib)"


.PHONY: apt-packages
apt-packages:
	$(SUDO) apt-get update
	# needed to fetch the library submodule at end of build
	$(SUDO) apt-get install -y build-essential
	$(SUDO) apt-get install -y libwww-perl
	$(SUDO) apt-get install -y git
	# needed to build Net::SSLeay for IO::Socket::SSL for Net::LDAPS
	$(SUDO) apt-get install -y libssl-dev
	$(SUDO) apt-get install -y libsasl2-dev
	# for DBD::mysql as well as headers to build DBD::mysql if building from CPAN
	$(SUDO) apt-get install -y libdbd-mysql-perl
	$(SUDO) apt-get install -y libmysqlclient-dev
	# needed to build XML::Simple dep XML::Parser
	$(SUDO) apt-get install -y libexpat1-dev

.PHONY: yum-packages
yum-packages:
	rpm -q gcc || $(SUDO) yum install -y gcc
	rpm -q perl-CPAN || $(SUDO) yum install -y perl-CPAN
	rpm -q perl-libwww-perl || $(SUDO) yum install -y perl-libwww-perl
	rpm -q git || $(SUDO) yum install -y git
	# for DBD::mysql as well as headers to build DBD::mysql if building from CPAN
	rpm -q mysql-devel || $(SUDO) yum install -y mysql-devel
	rpm -q perl-DBD-MySQL || $(SUDO) yum install -y perl-DBD-MySQL
	# needed to build XML::Simple dep XML::Parser
	rpm -q expat-devel || $(SUDO) yum install -y expat-devel


.PHONY: test
test:
	./find_uncovered_subs.sh
	@echo; echo Running unit tests
	PERL5LIB=$(PERLBREW_ROOT) PERL5OPT=-MDevel::Cover=-coverage,statement,branch,condition,path,subroutine prove -lrsv --timer t
	bash-tools/all.sh
	bash-tools/perl_syntax.sh HariSekhonUtils.pm
	# for some reason 'Base class package "Class::Accessor" is empty.' in Travis but not locally
	bash-tools/is_travis.sh || bash-tools/perl_syntax.sh HariSekhon
	bash-tools/perl_syntax.sh t


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

tld:
	wget -O resources/tlds-alpha-by-domain.txt http://data.iana.org/TLD/tlds-alpha-by-domain.txt

.PHONY: clean
clean:
	@echo Nothing to clean
