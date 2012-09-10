DPKG=dpkg
DPKG_OPTS=-b

*.deb:	clean src/*
	rm -Rf build
	mkdir -p out
	cp -r src build
	fakeroot ${DPKG} ${DPKG_OPTS} build out
	rm -Rf build

info: out/*.deb
	dpkg-deb -I out/*.deb

repo: out/*.deb
	/data/mnt/is24-ubuntu-repo/putinrepo.sh out/*.deb

clean:
	rm -fr out build


