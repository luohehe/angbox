import Foundation
import SwiftUI

@MainActor
class SwingStore: ObservableObject {
    @Published var swings: [SwingData] = []
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0

    private let saveKey = "saved_swings"

    init() {
        loadSwings()
    }

    func addSwing(_ swing: SwingData) {
        swings.insert(swing, at: 0)
        saveSwings()
    }

    func updateSwing(_ swing: SwingData) {
        if let index = swings.firstIndex(where: { $0.id == swing.id }) {
            swings[index] = swing
            saveSwings()
        }
    }

    func deleteSwing(_ swing: SwingData) {
        swings.removeAll { $0.id == swing.id }
        if let videoURL = swing.videoURL {
            try? FileManager.default.removeItem(at: videoURL)
        }
        saveSwings()
    }

    func deleteSwings(at offsets: IndexSet) {
        for index in offsets {
            if let videoURL = swings[index].videoURL {
                try? FileManager.default.removeItem(at: videoURL)
            }
        }
        swings.remove(atOffsets: offsets)
        saveSwings()
    }

    private func saveSwings() {
        if let encoded = try? JSONEncoder().encode(swings) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadSwings() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([SwingData].self, from: data) {
            swings = decoded
        }
    }

    var averageScore: Int {
        let analyzed = swings.compactMap { $0.analysis?.overallScore }
        guard !analyzed.isEmpty else { return 0 }
        return analyzed.reduce(0, +) / analyzed.count
    }

    var totalSwings: Int {
        swings.count
    }

    var recentImprovement: Int? {
        let recentAnalyzed = swings.prefix(5).compactMap { $0.analysis?.overallScore }
        let olderAnalyzed = swings.dropFirst(5).prefix(5).compactMap { $0.analysis?.overallScore }

        guard recentAnalyzed.count >= 3, olderAnalyzed.count >= 3 else { return nil }

        let recentAvg = recentAnalyzed.reduce(0, +) / recentAnalyzed.count
        let olderAvg = olderAnalyzed.reduce(0, +) / olderAnalyzed.count

        return recentAvg - olderAvg
    }
}
