import CoreGraphics
import Vision

public enum EyeGeometry {
    /// Openness of an eye outline: bounding-box height / width.
    /// Open eyes land around 0.3+; a closed eye collapses toward 0.
    public static func opennessRatio(_ points: [CGPoint]) -> Double {
        guard points.count >= 3,
              let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max(),
              maxX > minX
        else { return 0 }
        return Double(maxY - minY) / Double(maxX - minX)
    }

    /// Linear map: openness 0 → probability 1, openness ≥ openThreshold → probability 0.
    public static func closedProbability(openness: Double, openThreshold: Double = 0.3) -> Double {
        guard openThreshold > 0 else { return 0 }
        return max(0, min(1, 1 - openness / openThreshold))
    }
}

public enum FaceAnalyzer {
    /// nil when no face is detected. Otherwise the max closed-eyes probability
    /// across faces. Per face we use the most-open eye (a wink is not a defect).
    public static func closedEyesProbability(in image: CGImage) throws -> Double? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        guard let faces = request.results, !faces.isEmpty else { return nil }

        var worst: Double?
        for face in faces {
            guard let landmarks = face.landmarks else { continue }
            let eyes = [landmarks.leftEye, landmarks.rightEye].compactMap { $0 }
            guard !eyes.isEmpty else { continue }
            let probs = eyes.map {
                EyeGeometry.closedProbability(
                    openness: EyeGeometry.opennessRatio($0.normalizedPoints))
            }
            let faceProb = probs.min() ?? 0
            worst = max(worst ?? 0, faceProb)
        }
        return worst
    }
}
