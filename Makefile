DPKG=dpkg
DPKG_OPTS=-b

*.deb:	clean src/*
	rm -Rf build
	mkdir -p out
	cp -r src build
	git log | gzip -9 >build/usr/share/doc/kiosk-browser/changelog.gz
	chmod -R g-w build
	fakeroot ${DPKG} ${DPKG_OPTS} build out
	rm -Rf build

test: out/*.deb
	lintian -i out/*.deb

info: out/*.deb
	dpkg-deb -I out/*.deb
	dpkg-deb -c out/*.deb

repo: out/*.deb
	/data/mnt/is24-ubuntu-repo/putinrepo.sh out/*.deb

clean:
	rm -fr out build


