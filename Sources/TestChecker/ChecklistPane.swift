import SwiftUI
import TestCheckerCore

/// 左ペイン: 進捗サマリ + 実施選択 + テストケース一覧。
struct ChecklistPane: View {
    @Environment(EditorSession.self) private var session
    /// 絞り込み対象の状態。nil はすべて表示。
    @State private var filter: TestStatus?

    var body: some View {
        @Bindable var session = session
        VStack(spacing: 0) {
            header
            Divider()
            if session.spec.cases.isEmpty {
                ContentUnavailableView(
                    "テストケースがありません",
                    systemImage: "checklist",
                    description: Text("仕様書に `- [ ] ID-001 タイトル` 形式の行を書いてください。")
                )
            } else if groupedCases.isEmpty {
                emptyFilterView
            } else {
                List {
                    ForEach(groupedCases, id: \.heading) { group in
                        Section(group.heading.isEmpty ? "（見出しなし）" : group.heading) {
                            ForEach(group.cases, id: \.line) { testCase in
                                CaseRow(testCase: testCase)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .background(Palette.paneBackground)
    }

    private var header: some View {
        @Bindable var session = session
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.spec.project ?? session.document.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                TextField("担当者", text: $session.tester)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)
            }
            runPicker
            SummaryBar(summary: session.summary)
            filterPicker
        }
        .padding(12)
    }

    private var runPicker: some View {
        HStack {
            Menu {
                ForEach(session.availableRunURLs, id: \.self) { url in
                    Button(url.deletingPathExtension().lastPathComponent) { session.selectRun(url) }
                }
                if session.availableRunURLs.isEmpty {
                    Text("結果ファイルなし")
                }
            } label: {
                Label(
                    session.runURL?.deletingPathExtension().lastPathComponent ?? "未開始（最初のチェックで作成）",
                    systemImage: "doc.text")
                .lineLimit(1)
            }
            .menuStyle(.borderlessButton)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    /// 絞り込み結果が0件のときの表示。ペインの幅を押し広げないよう固有幅を持たせない。
    private var emptyFilterView: some View {
        VStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("「\(filter?.displayName ?? "すべて")」のケースはありません")
                .font(.callout)
            Text("絞り込みを変更してください。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // セグメントコントロールはアイコンを単色テンプレート化してしまうため、
    // 状態色を出せる自前のボタン列にしている。
    private var filterPicker: some View {
        HStack(spacing: 2) {
            FilterButton(isSelected: filter == nil, help: "すべて") {
                Text("すべて").font(.caption)
            } action: { filter = nil }
            ForEach(Self.filterOrder, id: \.self) { status in
                FilterButton(isSelected: filter == status, help: status.displayName) {
                    Image(systemName: status.symbol)
                        .foregroundStyle(status.color)
                } action: { filter = status }
            }
        }
        .padding(2)
        .background(Palette.cardBackground, in: RoundedRectangle(cornerRadius: 7))
        .help("状態で絞り込む")
    }

    private static let filterOrder: [TestStatus] = [.notRun, .pass, .fail, .skip, .recheck]

    private struct Group {
        let heading: String
        let cases: [TestCase]
    }

    private var groupedCases: [Group] {
        var groups: [Group] = []
        let cases = session.spec.cases.filter { filter == nil || session.status(for: $0) == filter }
        for c in cases {
            let heading = c.headingPath.joined(separator: " › ")
            if groups.last?.heading == heading {
                groups[groups.count - 1] = Group(heading: heading, cases: groups[groups.count - 1].cases + [c])
            } else {
                groups.append(Group(heading: heading, cases: [c]))
            }
        }
        return groups
    }
}

/// フィルタバーの1ボタン。選択中はアクセント枠付きの白/暗背景で強調する。
private struct FilterButton<Content: View>: View {
    let isSelected: Bool
    let help: String
    @ViewBuilder let content: Content
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, minHeight: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            isSelected ? AnyShapeStyle(Palette.paneBackground) : AnyShapeStyle(.clear),
            in: RoundedRectangle(cornerRadius: 5)
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(.tint, lineWidth: 1)
            }
        }
        .help(help)
    }
}

/// 状態別の件数と積み上げバー。
struct SummaryBar: View {
    let summary: TestSummary

    private static let order: [TestStatus] = [.pass, .fail, .recheck, .skip, .notRun]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Self.order, id: \.self) { status in
                        let n = summary.count(status)
                        if n > 0 {
                            Rectangle()
                                .fill(status.color)
                                .frame(width: geo.size.width * CGFloat(n) / CGFloat(max(summary.total, 1)))
                        }
                    }
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            HStack(spacing: 10) {
                ForEach(Self.order, id: \.self) { status in
                    HStack(spacing: 3) {
                        Circle().fill(status.color).frame(width: 7, height: 7)
                        Text("\(status.displayName) \(summary.count(status))")
                    }
                }
                Spacer()
                Text("\(summary.total) 件")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

/// テストケース1行。状態メニュー + タイトル + メモ欄。
struct CaseRow: View {
    @Environment(EditorSession.self) private var session
    let testCase: TestCase
    @State private var note = ""

    var body: some View {
        let status = session.status(for: testCase)
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Menu {
                    ForEach(TestStatus.allCases, id: \.self) { s in
                        Button {
                            session.setStatus(s, for: testCase)
                        } label: {
                            Label(s.displayName, systemImage: s.symbol)
                        }
                    }
                } label: {
                    // borderlessButton はラベルを単色テンプレート化して状態色を潰すため、
                    // plain ボタンスタイルで色をそのまま描画させる
                    Image(systemName: status.symbol)
                        .foregroundStyle(status.color)
                        .font(.title3)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .fixedSize()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if let id = testCase.id {
                            Text(id).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        Text(testCase.title)
                    }
                    ForEach(testCase.details, id: \.self) { d in
                        Text(d).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture { session.jump(to: testCase) }

            if status != .notRun {
                TextField("メモ（FAIL理由・Issue番号など）", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .onChange(of: note) { _, new in session.setNote(new, for: testCase) }
            }
        }
        .padding(.vertical, 2)
        .onAppear { note = session.note(for: testCase) }
        .onChange(of: session.runURL) { _, _ in note = session.note(for: testCase) }
    }
}

extension TestStatus {
    var displayName: String {
        switch self {
        case .notRun: "未実施"
        case .pass: "PASS"
        case .fail: "FAIL"
        case .skip: "SKIP"
        case .recheck: "要再確認"
        }
    }

    var symbol: String {
        switch self {
        case .notRun: "circle"
        case .pass: "checkmark.circle.fill"
        case .fail: "xmark.circle.fill"
        case .skip: "minus.circle.fill"
        case .recheck: "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notRun: .secondary.opacity(0.6)
        case .pass: .green
        case .fail: .red
        case .skip: .gray
        case .recheck: .orange
        }
    }
}
