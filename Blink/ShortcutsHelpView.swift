import SwiftUI

private struct ShortcutRow: View {
  let keys: String
  let action: String

  var body: some View {
    HStack {
      Text(action)
        .foregroundColor(.primary)
      Spacer()
      Text(keys)
        .font(.system(.body, design: .monospaced))
        .foregroundColor(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(5)
    }
  }
}

private struct ShortcutSection: View {
  let title: String
  let rows: [(String, String)]

  var body: some View {
    Section(header: Text(title).font(.headline).padding(.top, 8)) {
      ForEach(rows, id: \.0) { keys, action in
        ShortcutRow(keys: keys, action: action)
      }
    }
  }
}

struct ShortcutsHelpView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        ShortcutSection(title: "Split Panes", rows: [
          ("⌘D",   "Split Horizontally"),
          ("⌘⇧D",  "Split Vertically"),
          ("⌘]",   "Focus Next Pane"),
          ("⌘[",   "Focus Prev Pane"),
          ("⌘⇧W",  "Close Pane"),
        ])
        ShortcutSection(title: "Tabs", rows: [
          ("⌘T",   "New Tab"),
          ("⌘W",   "Close Tab"),
          ("⌘⇧]",  "Next Tab"),
          ("⌘⇧[",  "Prev Tab"),
        ])
        ShortcutSection(title: "Windows", rows: [
          ("⌘⇧T",  "New Window"),
          ("⌘O",   "Focus Other Window"),
        ])
        ShortcutSection(title: "View", rows: [
          ("⌘⇧=",  "Zoom In"),
          ("⌘-",   "Zoom Out"),
          ("⌘=",   "Zoom Reset"),
          ("⌘,",   "Settings"),
        ])
        ShortcutSection(title: "Other", rows: [
          ("⌘/",             "Show This Help"),
          ("⌘C",             "Copy"),
          ("⌘V",             "Paste"),
          ("⌘⇧,",            "Snippets"),
          ("⌘⇧.",            "Scratch"),
          ("double-tap bottom", "Quick Actions"),
        ])
      }
      .listStyle(.plain)
      .navigationTitle("Keyboard Shortcuts")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}
