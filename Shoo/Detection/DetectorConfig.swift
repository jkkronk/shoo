import CoreGraphics
import Foundation

/// Linear interpolation between `a` and `b` by `t` (clamped 0…1). Pure helper used by
/// the sensitivity mapping.
@inline(__always)
func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    let t = min(max(t, 0), 1)
    return a + (b - a) * t
}

/// All tunables that drive the detector's eagerness, derived deterministically from the
/// single user-facing `sensitivity` (0…1) setting.
///
/// Pure (CoreGraphics/Foundation only) so the mapping is unit-tested directly for
/// monotonicity, end-stops, and the `exitThreshold < enterThreshold` hysteresis invariant.
/// Higher sensitivity ⇒ triggers earlier/easier.
struct DetectorConfig: Equatable {
    /// Capture radius (image-normalized) for the proximity falloff — how far outside a
    /// region box a fingertip can be and still contribute.
    var reach: CGFloat
    /// EMA enters "gesture" when the smoothed region score rises to this.
    var enterThreshold: Double
    /// EMA leaves "gesture" only when it falls to this (kept below `enterThreshold`).
    var exitThreshold: Double
    /// Inflation applied to the mouth/nose region boxes.
    var regionPad: CGFloat
    /// Consecutive frames the EMA must stay above `enterThreshold` before declaring a gesture.
    var minSustainedFrames: Int
    /// Minimum Vision confidence for a hand joint to count.
    var handPointConfidence: Float
    /// Multiplier applied to mouth score when the contributing fingertips sit in the
    /// chin band but outside the mouth box (suppresses "resting chin on hand").
    var chinRestPenalty: Double
    /// EMA smoothing factor (α): `ema = α·score + (1-α)·ema`. Fixed across sensitivity.
    var smoothing: Double
    /// Whether the mouth region is watched (nail/lip biting). When false its score is zeroed.
    var mouthEnabled: Bool
    /// Whether the nose region is watched (nose-picking). When false its score is zeroed.
    var noseEnabled: Bool

    init(
        reach: CGFloat,
        enterThreshold: Double,
        exitThreshold: Double,
        regionPad: CGFloat,
        minSustainedFrames: Int,
        handPointConfidence: Float,
        chinRestPenalty: Double = 0.4,
        smoothing: Double = 0.5,
        mouthEnabled: Bool = true,
        noseEnabled: Bool = true
    ) {
        self.reach = reach
        self.enterThreshold = enterThreshold
        self.exitThreshold = exitThreshold
        self.regionPad = regionPad
        self.minSustainedFrames = minSustainedFrames
        self.handPointConfidence = handPointConfidence
        self.chinRestPenalty = chinRestPenalty
        self.smoothing = smoothing
        self.mouthEnabled = mouthEnabled
        self.noseEnabled = noseEnabled
    }

    /// Apply the user's watched-gesture selection to region gating. The mouth region covers
    /// nail-biting and lip-biting; the nose region covers nose-picking. (Hair-pulling has no
    /// dedicated detector region yet, so it doesn't gate anything here.)
    func applying(gestures: GestureMask) -> DetectorConfig {
        var config = self
        config.mouthEnabled = gestures.contains(.nailBiting) || gestures.contains(.lipBiting)
        config.noseEnabled = gestures.contains(.nosePicking)
        return config
    }

    /// Map the 0…1 sensitivity slider to a concrete config.
    ///
    /// Tuned so the *middle* of the slider is already conservative: real-world Vision
    /// jitter (low-confidence joints, a hand near the chin, drinking) made the original
    /// lax half of the range fire constantly, so users parked the slider at the minimum.
    /// The old minimum now sits at `s = 0.5`; `s = 0` is stricter still (tight boxes,
    /// 6 sustained frames, 0.6 confidence floor) and `s = 1` matches the old midpoint.
    static func from(sensitivity s: Double) -> DetectorConfig {
        let s = min(max(s, 0), 1)
        let sustain: Int
        if s > 0.66 {
            sustain = 3
        } else if s > 0.33 {
            sustain = 4
        } else if s > 0.15 {
            sustain = 5
        } else {
            sustain = 6
        }
        return DetectorConfig(
            reach: CGFloat(lerp(0.02, 0.08, s)),       // tight → moderate capture radius
            enterThreshold: lerp(0.85, 0.60, s),        // strict → moderate
            exitThreshold: lerp(0.55, 0.35, s),         // always < enter (hysteresis)
            regionPad: CGFloat(lerp(0.0, 0.03, s)),
            minSustainedFrames: sustain,
            handPointConfidence: Float(lerp(0.6, 0.4, s))
        )
    }

    /// The default config matching `AppSettings.sensitivity`'s default of 0.5.
    static let `default` = DetectorConfig.from(sensitivity: 0.5)
}
