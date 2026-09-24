import CoreMedia
import XCTest
@testable import Shoo

/// A range with whole-number fps bounds, as most webcams report (durations 1/max … 1/min).
private func range(_ min: Double, _ max: Double) -> FrameRateCap.Range {
    FrameRateCap.Range(
        minFPS: min, maxFPS: max,
        minFrameDuration: CMTime(value: 1, timescale: CMTimeScale(max)),
        maxFrameDuration: CMTime(value: 1, timescale: CMTimeScale(min)))
}

final class FrameRateCapTests: XCTestCase {
    /// 12 fps requested on a 15–30 camera must clamp UP to 15 (the floor) — this is the crash
    /// the helper exists to prevent.
    func testBelowFloorClampsUpToMinimum() {
        let result = FrameRateCap.clamp(desiredFPS: 12, into: [range(15, 30)])
        XCTAssertEqual(result?.fps, 15)
        XCTAssertEqual(result?.duration, CMTime(value: 1, timescale: 15))
    }

    /// PowerCoordinator's thermal/low-power backoff to 6 fps hits the same path; must also clamp.
    func testReducedFPSBelowFloorClampsUp() {
        let result = FrameRateCap.clamp(desiredFPS: 6, into: [range(15, 30)])
        XCTAssertEqual(result?.fps, 15)
    }

    func testWithinRangeIsUnchanged() {
        let result = FrameRateCap.clamp(desiredFPS: 24, into: [range(15, 30)])
        XCTAssertEqual(result?.fps, 24)
        XCTAssertEqual(result?.duration, CMTime(value: 1, timescale: 24))
    }

    func testAboveCeilingClampsDownToMaximum() {
        let result = FrameRateCap.clamp(desiredFPS: 60, into: [range(15, 30)])
        XCTAssertEqual(result?.fps, 30)
        XCTAssertEqual(result?.duration, CMTime(value: 1, timescale: 30))
    }

    func testLowTargetAchievableOnWideRangeCamera() {
        let result = FrameRateCap.clamp(desiredFPS: 12, into: [range(1, 30)])
        XCTAssertEqual(result?.fps, 12)
        XCTAssertEqual(result?.duration, CMTime(value: 1, timescale: 12))
    }

    /// Non-contiguous ranges: a value in the gap snaps to the nearest range edge.
    func testGapBetweenRangesSnapsToNearestEdge() {
        // Gap is (15, 24); 16 is nearer the lower range's ceiling (15).
        let result = FrameRateCap.clamp(desiredFPS: 16, into: [range(5, 15), range(24, 30)])
        XCTAssertEqual(result?.fps, 15)
    }

    /// A camera that only runs at 29.97 fps (common for capture cards and virtual cameras) must
    /// get its own 1001/30000 s duration. Rebuilding it from the rounded rate (1/30 s) is outside
    /// the supported range, which AVFoundation answers with an uncatchable exception.
    func testFractionalOnlyRateUsesTheDevicesOwnDuration() {
        let ntsc = CMTime(value: 1001, timescale: 30000)
        let only2997 = FrameRateCap.Range(
            minFPS: 30000.0 / 1001, maxFPS: 30000.0 / 1001, minFrameDuration: ntsc, maxFrameDuration: ntsc)

        let result = FrameRateCap.clamp(desiredFPS: 12, into: [only2997])

        XCTAssertEqual(result?.duration, ntsc)
        XCTAssertTrue(result.map { only2997.contains($0.duration) } ?? false)
        // What the old code applied — outside the range, i.e. the crash.
        XCTAssertFalse(only2997.contains(CMTime(value: 1, timescale: 30)))
    }

    /// Snapping down to a fractional ceiling uses the device's own shortest duration too.
    func testFractionalCeilingUsesTheDevicesOwnDuration() {
        let ceiling = CMTime(value: 1001, timescale: 30000)
        let ntscCamera = FrameRateCap.Range(
            minFPS: 5, maxFPS: 30000.0 / 1001, minFrameDuration: ceiling,
            maxFrameDuration: CMTime(value: 1, timescale: 5))

        let result = FrameRateCap.clamp(desiredFPS: 60, into: [ntscCamera])

        XCTAssertEqual(result?.duration, ceiling)
    }

    func testEmptyRangesReturnsNil() {
        XCTAssertNil(FrameRateCap.clamp(desiredFPS: 12, into: []))
    }

    func testInvalidRangesAreIgnored() {
        // Zero/negative and inverted ranges are dropped; only (15,30) remains.
        let result = FrameRateCap.clamp(
            desiredFPS: 12, into: [range(0, 0), range(30, 15), range(15, 30)])
        XCTAssertEqual(result?.fps, 15)
    }
}
