.PHONY: all service bundle spawn
SERVICE=spl

all: bundle

service:
	cp -r src/* service/ro/
	$(MAKE) -C src
	cp src/$(SERVICE) service/ro/
	cp src/$(SERVICE)bin service/ro/

bundle: service
	rm -f ../$(SERVICE).tgz
	tar caf ../$(SERVICE).tgz *
	@echo "#### Double check ../$(SERVICE).tgz and submit it :) ####"

spawn: service
	( cd service/rw && setarch `uname -m` -R socat tcp-l:6666,reuseaddr,fork exec:"../ro/$(SERVICE)" )
