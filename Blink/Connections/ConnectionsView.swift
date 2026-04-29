import SwiftUI

struct ConnectionsView: View {
  let onConnect: (String) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var hosts: [BKHosts] = []
  @State private var searchText = ""

  private var filtered: [BKHosts] {
    guard !searchText.isEmpty else { return hosts }
    return hosts.filter {
      ($0.host ?? "").localizedCaseInsensitiveContains(searchText) ||
      ($0.hostName ?? "").localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    NavigationView {
      Group {
        if hosts.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "server.rack")
              .font(.system(size: 48))
              .foregroundColor(.secondary)
            Text("No saved connections")
              .font(.headline)
            Text("Add hosts in Settings → Hosts")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List(filtered, id: \.host) { host in
            Button(action: {
              dismiss()
              onConnect("ssh \(host.host ?? "")")
            }) {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text(host.host ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                  if let u = host.user, !u.isEmpty,
                     let h = host.hostName, !h.isEmpty {
                    Text("\(u)@\(h)")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  } else if let h = host.hostName, !h.isEmpty {
                    Text(h)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
                Spacer()
                Image(systemName: "terminal")
                  .foregroundColor(.accentColor)
              }
            }
          }
          .searchable(text: $searchText, prompt: "Search")
        }
      }
      .navigationTitle("Connections")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .onAppear {
      hosts = (BKHosts.allHosts() as? [BKHosts]) ?? []
    }
  }
}
