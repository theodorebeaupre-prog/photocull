import PhotoCullCore
import SwiftUI

@MainActor
final class CullSessionViewModel: ObservableObject {
    @Published var folder: URL?
    @Published var photos: [PhotoAnalysis] = []
    @Published var groups: [PhotoGroup] = []
    @Published var decisions: [URL: CullDecision] = [:]
    @Published var isAnalyzing = false

    private var featurePrints: [URL: FeaturePrint] = [:]
    private let engine = CullEngine()
    private let store = SessionStore.default
    private var analysisTask: Task<Void, Never>?

    func openFolder(_ url: URL) {
        analysisTask?.cancel()
        folder = url
        photos = []
        groups = []
        decisions = [:]
        featurePrints = [:]

        if let saved = store.load(forFolder: url) {
            decisions = Dictionary(uniqueKeysWithValues: saved.decisions.map {
                (url.appendingPathComponent($0.key), $0.value)
            })
        }

        isAnalyzing = true
        analysisTask = Task {
            for await item in engine.analyzeFolder(url) {
                photos.append(item.analysis)
                if let fp = item.featurePrint {
                    featurePrints[item.analysis.id] = fp
                }
            }
            if Task.isCancelled { return }
            photos.sort { $0.id.lastPathComponent < $1.id.lastPathComponent }
            let known = Set(photos.map(\.id))
            decisions = decisions.filter { known.contains($0.key) }
            persist()
            regroup()
            isAnalyzing = false
        }
    }

    func regroup() {
        let items = photos.map { GroupingItem(id: $0.id, captureDate: $0.captureDate) }
        let prints = featurePrints
        var computed = Grouping.groupPhotos(items) { a, b in
            guard let fa = prints[a], let fb = prints[b] else { return nil }
            return try? fa.distance(to: fb)
        }
        for i in computed.indices {
            let members = computed[i].members.compactMap { id in
                photos.first { $0.id == id }
            }
            computed[i].suggestedKeeper = Scoring.suggestKeeper(in: members)
        }
        groups = computed
    }

    func decision(for id: URL) -> CullDecision {
        decisions[id] ?? .undecided
    }

    /// Smart default derived from analysis: blurry or closed eyes → reject,
    /// burst keeper → keep, burst non-keeper → reject. nil = no signal.
    func suggestedDecision(for id: URL) -> CullDecision? {
        guard let photo = photos.first(where: { $0.id == id }),
              !photo.analysisFailed else { return nil }
        if Scoring.sharpnessScore(photo.sharpness) < 0.25 { return .reject }
        if (photo.closedEyesProbability ?? 0) > 0.6 { return .reject }
        if let group = groups.first(where: { $0.members.count > 1 && $0.members.contains(id) }),
           let keeper = group.suggestedKeeper {
            return id == keeper ? .keep : .reject
        }
        return nil
    }

    /// Fills suggestions into undecided photos only — never overwrites a
    /// manual decision. The user adjusts instead of deciding from scratch.
    func applySuggestions() {
        for photo in photos where decision(for: photo.id) == .undecided {
            if let suggested = suggestedDecision(for: photo.id) {
                decisions[photo.id] = suggested
            }
        }
        persist()
    }

    var keptCount: Int { decisions.values.filter { $0 == .keep }.count }
    var rejectedCount: Int { decisions.values.filter { $0 == .reject }.count }
    var decidedCount: Int { keptCount + rejectedCount }

    /// Goal-gradient progress: the completed analysis counts as step one,
    /// so the bar never reads zero once photos are loaded.
    var cullProgress: Double {
        guard !photos.isEmpty else { return 0 }
        return Double(decidedCount + 1) / Double(photos.count + 1)
    }

    func setDecision(_ d: CullDecision, for id: URL) {
        decisions[id] = d
        persist()
    }

    var rejected: [URL] {
        decisions.filter { $0.value == .reject }.map(\.key)
    }

    func exportXMP() throws {
        for (url, d) in decisions where d != .undecided {
            try XMPWriter.writeSidecar(for: url, decision: d)
        }
    }

    func exportMoveRejects() throws {
        guard let folder else { return }
        let candidates = rejected
        defer {
            let gone = candidates.filter { !FileManager.default.fileExists(atPath: $0.path) }
            photos.removeAll { gone.contains($0.id) }
            for url in gone {
                decisions.removeValue(forKey: url)
                featurePrints.removeValue(forKey: url)
            }
            regroup()
            persist()
        }
        try RejectMover.moveRejects(candidates, from: folder)
    }

    private func persist() {
        guard let folder else { return }
        let relative = Dictionary(uniqueKeysWithValues: decisions.map {
            ($0.key.lastPathComponent, $0.value)
        })
        try? store.save(SessionState(folder: folder, decisions: relative))
    }
}
