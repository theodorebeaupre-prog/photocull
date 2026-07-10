import CoreGraphics
import Vision

/// Wraps VNFeaturePrintObservation so the rest of the codebase never touches Vision types.
public struct FeaturePrint: @unchecked Sendable {
    let observation: VNFeaturePrintObservation

    public static func compute(for image: CGImage) throws -> FeaturePrint {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        guard let obs = request.results?.first else {
            throw CocoaError(.featureUnsupported)
        }
        return FeaturePrint(observation: obs)
    }

    public func distance(to other: FeaturePrint) throws -> Float {
        var d: Float = 0
        try observation.computeDistance(&d, to: other.observation)
        return d
    }
}
