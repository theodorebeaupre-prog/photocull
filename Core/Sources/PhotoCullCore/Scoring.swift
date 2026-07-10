import Foundation

public enum Scoring {
    /// Normalizes laplacian variance to 0…1. With 256px analysis frames,
    /// variance ≥ 200 reads as fully sharp. nil (not analyzed) → neutral 0.5.
    public static func sharpnessScore(_ variance: Double?, fullSharpVariance: Double = 200) -> Double {
        guard let variance else { return 0.5 }
        return max(0, min(1, variance / fullSharpVariance))
    }

    public static func overallScore(_ a: PhotoAnalysis) -> Double {
        if a.analysisFailed { return 0 }
        var score = sharpnessScore(a.sharpness)
        if let closed = a.closedEyesProbability {
            score *= (1 - 0.6 * closed)
        }
        return max(0, min(1, score))
    }

    public static func suggestKeeper(in analyses: [PhotoAnalysis]) -> URL? {
        analyses.max { overallScore($0) < overallScore($1) }?.id
    }
}
