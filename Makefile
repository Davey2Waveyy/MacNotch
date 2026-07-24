.PHONY: build test run package release clean
build:
	swift build
test:
	swift run MacNotchTests
package:
	bash Scripts/package-app.sh
run: package
	-pkill -x NotchApple; sleep 0.4
	open ./build/Topsoil.app
release:
	@test -n "$(VERSION)" || (echo "usage: make release VERSION=0.1.0"; exit 1)
	bash Scripts/package-app.sh $(VERSION)
	git tag -a v$(VERSION) -m "v$(VERSION)"
	git push origin v$(VERSION)
	gh release create v$(VERSION) build/Topsoil.dmg \
	  --title "Topsoil v$(VERSION)" \
	  --notes "Download Topsoil.dmg, open it, drag Topsoil to Applications.\n\nAfter notarization, Topsoil should open normally. If macOS still blocks launch, right-click Topsoil and choose Open as a fallback."
clean:
	swift package clean
	rm -rf build
