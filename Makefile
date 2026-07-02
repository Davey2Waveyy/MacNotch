.PHONY: build test run package release clean
build:
	swift build
test:
	swift run MacNotchTests
package:
	bash Scripts/package-app.sh
run: package
	-pkill -x NotchApple; sleep 0.4
	open ./build/NotchApple.app
release:
	@test -n "$(VERSION)" || (echo "usage: make release VERSION=0.1.0"; exit 1)
	bash Scripts/package-app.sh $(VERSION)
	git tag -a v$(VERSION) -m "v$(VERSION)"
	git push origin v$(VERSION)
	gh release create v$(VERSION) build/NotchApple.dmg \
	  --title "NotchApple v$(VERSION)" \
	  --notes "Download NotchApple.dmg, open it, drag NotchApple to Applications.\n\nFirst launch: right-click → Open to bypass Gatekeeper."
clean:
	swift package clean
	rm -rf build
