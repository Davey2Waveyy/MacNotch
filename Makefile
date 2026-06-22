.PHONY: build test run package clean
build:
	swift build
test:
	swift run MacNotchTests
package:
	bash Scripts/package-app.sh
run: package
	open ./build/MacNotch.app
clean:
	swift package clean
	rm -rf build
