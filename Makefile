.PHONY: test run app icon

test:
	swift test

run:
	swift run MDReader

icon:
	swift scripts/render-icon.swift
	iconutil -c icns Supporting/AppIcon.iconset -o Supporting/AppIcon.icns

app:
	swift build -c release --product MDReader
	rm -rf MDReader.app
	mkdir -p MDReader.app/Contents/MacOS MDReader.app/Contents/Resources
	cp .build/release/MDReader MDReader.app/Contents/MacOS/MDReader
	cp Supporting/Info.plist MDReader.app/Contents/Info.plist
	cp Supporting/AppIcon.icns MDReader.app/Contents/Resources/AppIcon.icns
	codesign --force --sign - MDReader.app
	open MDReader.app
