.PHONY: test run app icon install-skill uninstall-skill

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

# test-spec スキルを Claude Code / Codex のグローバルスキルとして登録する(symlink なので更新は自動反映)
SKILL_SRC := $(abspath skills/test-spec)
install-skill:
	mkdir -p ~/.claude/skills ~/.codex/skills
	ln -sfn $(SKILL_SRC) ~/.claude/skills/test-spec
	ln -sfn $(SKILL_SRC) ~/.codex/skills/test-spec
	@echo "installed: ~/.claude/skills/test-spec, ~/.codex/skills/test-spec"
	@echo "Cursor: Settings > Rules > User Rules に以下を追加してください:"
	@echo "  テスト仕様書を作成・更新するときは $(SKILL_SRC)/SKILL.md を読んで従うこと"

uninstall-skill:
	rm -f ~/.claude/skills/test-spec ~/.codex/skills/test-spec
