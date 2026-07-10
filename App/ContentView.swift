import PhotoCullCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var session: CullSessionViewModel
    @State private var showPicker = false
    @State private var tab: ViewTab = .grid
    @State private var confirmMove = false
    @State private var exportMessage: String?

    enum ViewTab: Hashable { case grid, review, groups }

    var body: some View {
        Group {
            if session.folder == nil {
                welcome
            } else {
                workspace
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                session.openFolder(url)
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 12) {
            Text("PhotoCull").font(.largeTitle.bold())
            Text("Open a folder of photos to start culling.\nEverything runs on your Mac — nothing leaves it.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Open Folder…") { showPicker = true }
                .keyboardShortcut("o")
        }
    }

    private var workspace: some View {
        VStack(spacing: 0) {
            if session.isAnalyzing {
                ProgressView("Analyzing \(session.photos.count) photos…")
                    .padding(6)
            }
            switch tab {
            case .grid: GridView()
            case .review: ReviewView()
            case .groups: GroupView()
            }
            CullStatusBar()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("View", selection: $tab) {
                    Text("Grid").tag(ViewTab.grid)
                    Text("Review").tag(ViewTab.review)
                    Text("Groups").tag(ViewTab.groups)
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem {
                Button("Open Folder…") { showPicker = true }
            }
            ToolbarItem {
                Button("Apply Suggestions") { session.applySuggestions() }
                    .disabled(session.isAnalyzing || session.photos.isEmpty)
                    .help("Pre-fill undecided photos with suggested keep/reject — adjust anything after")
            }
            ToolbarItem {
                Button("Write XMP Sidecars") {
                    do {
                        try session.exportXMP()
                        let undecided = session.photos.count - session.decidedCount
                        exportMessage = undecided > 0
                            ? "XMP sidecars written. \(undecided) photo(s) still undecided were skipped."
                            : "XMP sidecars written."
                    } catch {
                        exportMessage = "XMP export failed: \(error.localizedDescription)"
                    }
                }
                .disabled(session.decisions.isEmpty)
            }
            ToolbarItem {
                Button("Move Rejects…") { confirmMove = true }
                    .disabled(session.rejected.isEmpty)
            }
        }
        .confirmationDialog(
            "Move \(session.rejected.count) rejected photo(s) to _rejects?",
            isPresented: $confirmMove
        ) {
            Button("Move", role: .destructive) {
                do {
                    try session.exportMoveRejects()
                    exportMessage = "Rejects moved to _rejects."
                } catch {
                    exportMessage = "Move failed: \(error.localizedDescription)"
                }
            }
        }
        .alert(
            exportMessage ?? "",
            isPresented: Binding(
                get: { exportMessage != nil },
                set: { if !$0 { exportMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        }
    }
}
