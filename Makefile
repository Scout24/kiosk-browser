DPKG=dpkg
DPKG_OPTS=-b

*.deb:	clean src/*
	rm -Rf build
	mkdir -p out
	cp -r src build
	git log | gzip -9 >build/usr/share/doc/kiosk-browser/changelog.gz
	chmod -R g-w build
	chmod 0440 build/etc/sudoers.d/kiosk-browser
	visudo -c -f build/etc/sudoers.d/kiosk-browser
	fakeroot ${DPKG} ${DPKG_OPTS} build out
	rm -Rf build
	lintian -i out/*.deb

info: out/*.deb
	dpkg-deb -I out/*.deb
	dpkg-deb -c out/*.deb

repo: out/*.deb
	/data/mnt/is24-ubuntu-repo/putinrepo.sh out/*.deb

clean:
	rm -fr out build


