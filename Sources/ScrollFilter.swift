import CoreGraphics

/// Change only discrete hardware wheel events; leave continuous input and inertia alone.
enum ScrollFilter {
    static func shouldReverse(_ event: CGEvent) -> Bool {
        event.type == .scrollWheel
            && event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0
            && event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0
            && event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0
    }

    static func apply(to event: CGEvent, horizontal: Bool) {
        guard shouldReverse(event) else { return }
        reverse(event, fields: [
            .scrollWheelEventDeltaAxis1,
            .scrollWheelEventFixedPtDeltaAxis1,
            .scrollWheelEventPointDeltaAxis1
        ])
        if horizontal {
            reverse(event, fields: [
                .scrollWheelEventDeltaAxis2,
                .scrollWheelEventFixedPtDeltaAxis2,
                .scrollWheelEventPointDeltaAxis2
            ])
        }
    }

    private static func reverse(_ event: CGEvent, fields: [CGEventField]) {
        // Setting line delta also recalculates pixel and fixed-point deltas.
        // Snapshot them first, then restore each representation with its sign flipped.
        let values = fields.map { event.getIntegerValueField($0) }
        for (field, value) in zip(fields, values) {
            // Scroll delta payloads are signed 32-bit values, including 16.16 fixed point.
            let reversed = value <= Int64(Int32.min) ? Int64(Int32.max) : -value
            event.setIntegerValueField(field, value: reversed)
        }
    }
}
