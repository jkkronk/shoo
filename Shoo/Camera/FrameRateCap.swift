import CoreMedia

/// Pure helper for clamping a desired capture frame rate into a device's supported ranges.
///
/// Setting `AVCaptureDevice.activeVideoMin/MaxFrameDuration` to a value outside the active
/// format's `videoSupportedFrameRateRanges` raises an Objective-C `NSException` (uncatchable
/// from Swift), so the value must be provably in range *before* it's applied. Kept free of
/// AVFoundation so it can be unit-tested in isolation (see `ShooTests/FrameRateCapTests`).
enum FrameRateCap {
    /// One supported frame-rate range, mirroring `AVFrameRateRange`: the fps bounds plus the
    /// exact frame durations the device accepts at those bounds.
    struct Range {
        let minFPS: Double
        let maxFPS: Double
        /// The frame duration at `maxFPS`: the shortest the device accepts.
        let minFrameDuration: CMTime
        /// The frame duration at `minFPS`: the longest the device accepts.
        let maxFrameDuration: CMTime

        /// Whether the device accepts `duration` for this range (exact rational comparison).
        func contains(_ duration: CMTime) -> Bool {
            CMTimeCompare(duration, minFrameDuration) >= 0 && CMTimeCompare(duration, maxFrameDuration) <= 0
        }
    }

    /// Clamp `desiredFPS` into the device's supported ranges and return the frame duration to
    /// lock `activeVideoMin/MaxFrameDuration` to.
    ///
    /// - Parameters:
    ///   - desiredFPS: the fps we'd like to cap to (may be below the device floor).
    ///   - ranges: mapped from `AVCaptureDevice.Format.videoSupportedFrameRateRanges`.
    /// - Returns: the resulting fps and a duration the device accepts, or `nil` if there are
    ///   no usable ranges (caller should then leave the device default untouched).
    static func clamp(desiredFPS: Int, into ranges: [Range]) -> (fps: Double, duration: CMTime)? {
        // Keep only sane ranges (positive, min <= max, real durations).
        let valid = ranges.filter {
            $0.minFPS > 0 && $0.maxFPS >= $0.minFPS
                && $0.minFrameDuration.isValid && $0.maxFrameDuration.isValid
        }
        guard desiredFPS > 0, !valid.isEmpty else { return nil }

        // Already achievable as-is.
        let requested = CMTime(value: 1, timescale: CMTimeScale(clamping: desiredFPS))
        if valid.contains(where: { $0.contains(requested) }) {
            return (Double(desiredFPS), requested)
        }

        // Otherwise snap to the nearest range edge (below-floor → floor, above-ceiling →
        // ceiling, gaps between ranges → nearer edge) and use the device's own duration for that
        // edge. Rebuilding it from the fps instead (1/round(fps)) can land just outside a
        // fractional edge — 1/30 s on a camera that only does 29.97 fps — and raise the exception.
        let target = Double(desiredFPS)
        let nearest = valid.min { lhs, rhs in
            distance(target, to: lhs) < distance(target, to: rhs)
        }!
        return target < nearest.minFPS
            ? (nearest.minFPS, nearest.maxFrameDuration)
            : (nearest.maxFPS, nearest.minFrameDuration)
    }

    /// Distance from `fps` to a range: 0 inside, else the gap to the nearer edge.
    private static func distance(_ fps: Double, to range: Range) -> Double {
        if fps < range.minFPS { return range.minFPS - fps }
        if fps > range.maxFPS { return fps - range.maxFPS }
        return 0
    }
}
