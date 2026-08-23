.PHONY: test run app icon

test:
	swift test

run:
	swift run TestChecker

icon:
	swift scripts/render-icon.swift
	iconutil -c icns Supporting/AppIcon.iconset -o Supporting/AppIcon.icns

app:
	swift build -c release --product TestChecker
	rm -rf TestChecker.app
	mkdir -p TestChecker.app/Contents/MacOS TestChecker.app/Contents/Resources
	cp .build/release/TestChecker TestChecker.app/Contents/MacOS/TestChecker
	cp Supporting/Info.plist TestChecker.app/Contents/Info.plist
	cp Supporting/AppIcon.icns TestChecker.app/Contents/Resources/AppIcon.icns
	codesign --force --sign - TestChecker.app
	open TestChecker.app
