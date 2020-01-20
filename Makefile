.PHONY: info repo clean

*.deb:	check_status clean
	rm -Rf build
	mkdir -p out
	cp -r src build
	cp -r DEBIAN build
	V=$$(git rev-list HEAD | wc -l) ; sed -i -e "s/Version:.*/Version: $$V/" build/DEBIAN/control
	git log | gzip -9 >build/usr/share/doc/kiosk-browser/changelog.gz
	chmod -R g-w build
	chmod 0440 build/etc/sudoers.d/kiosk-browser
	/usr/sbin/visudo -c -f build/etc/sudoers.d/kiosk-browser
	fakeroot dpkg -b build out
	rm -Rf build
	lintian --suppress-tags postrm-contains-additional-updaterc.d-calls -i out/*.deb

info: out/*.deb
	dpkg-deb -I out/*.deb
	dpkg-deb -c out/*.deb

repo: out/*.deb
	../putinrepo.sh out/*.deb

clean:
	rm -fr out build

check_status:
	@git diff-index --quiet HEAD -- || { echo ; git status -s ; echo -e "\nERROR: All changes must be comitted!\n" ; false ; }
