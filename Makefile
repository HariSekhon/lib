#
#  Author: Hari Sekhon
#  Date: 2013-01-06 15:45:00 +0000 (Sun, 06 Jan 2013)
#

# Library dependencies are handled in one place in calling project

.PHONY: make
make:
	[ -x /usr/bin/apt-get ] && make apt-packages || :
	[ -x /usr/bin/yum ]     && make yum-packages || :

	yes | sudo cpan \
		Data::Dumper \
		JSON \
		JSON:XS \
		LWP::Simple \
		LWP::UserAgent \
		MongoDB \
		MongoDB::MongoClient \
		Net::LDAP \
		Net::LDAPI \
		Net::LDAPS \
		Net::DNS \
		Net::SSH::Expect \
		Redis \
		Readonly \
		Readonly::XS \
		Thrift \
		Time::HiRes \
		;

.PHONY: apt-packages
apt-packages:
	apt-get install -y gcc || :
	# needed to fetch the library submodule at end of build
	apt-get install -y build-essential libwww-perl git || :
	# for DBD::mysql as well as headers to build DBD::mysql if building from CPAN
	apt-get install -y libdbd-mysql-perl libmysqlclient-dev || :

.PHONY: yum-packages
yum-packages:
	yum install -y gcc || :
	# needed to fetch the library submodule at end of build
	yum install -y perl-CPAN perl-libwww-perl git || :
	# for DBD::mysql as well as headers to build DBD::mysql if building from CPAN
	yum install -y perl-DBD-MySQL mysql-devel || :

.PHONY: test
test:
	prove t --timer -v	

.PHONY: install
install:
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"

.PHONY: update
update:
	git pull
	make
