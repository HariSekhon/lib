#
#  Author: Hari Sekhon
#  Date: 2013-01-06 15:45:00 +0000 (Sun, 06 Jan 2013)
#

# Library dependencies are handled in one place in calling project

.PHONY: make
make:
	@echo 'Nothing to make :)'

.PHONY: test
test:
	prove t --timer -v	

.PHONY: install
install:
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"
