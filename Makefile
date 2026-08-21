.PHONY: test run app

test:
	swift test

run:
	swift run MDReader

app:
	swift build -c release --product MDReader
	rm -rf MDReader.app
	mkdir -p MDReader.app/Contents/MacOS
	cp .build/release/MDReader MDReader.app/Contents/MacOS/MDReader
	cp Supporting/Info.plist MDReader.app/Contents/Info.plist
	codesign --force --sign - MDReader.app
	open MDReader.app
