.PHONY: build test run package clean
build:
	swift build
test:
	swift run MacNotchTests
package:
	bash Scripts/package-app.sh
run: package
	-pkill -x MacNotch; sleep 0.4
	open ./build/MacNotch.app
clean:
	swift package clean
	rm -rf build
