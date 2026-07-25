import Testing
@testable import LidAngleApp

@Test func firstReadingIsShownImmediately() {
    var stabiliser = AngleStabiliser()

    #expect(stabiliser.update(with: 73) == 73)
}

@Test func alternatingNeighbouringReadingsDoNotFlicker() {
    var stabiliser = AngleStabiliser()

    #expect(stabiliser.update(with: 73) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 73) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 73) == 73)
}

@Test func persistentNeighbouringReadingIsEventuallyShown() {
    var stabiliser = AngleStabiliser()

    #expect(stabiliser.update(with: 73) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 74) == 74)
}

@Test func largerMovementIsShownImmediately() {
    var stabiliser = AngleStabiliser()

    #expect(stabiliser.update(with: 73) == 73)
    #expect(stabiliser.update(with: 75) == 75)
    #expect(stabiliser.update(with: 71) == 71)
}

@Test func returningToDisplayedValueClearsPendingChange() {
    var stabiliser = AngleStabiliser()

    #expect(stabiliser.update(with: 73) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 73) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 74) == 73)
    #expect(stabiliser.update(with: 74) == 74)
}

@Test func resetMakesNextReadingImmediate() {
    var stabiliser = AngleStabiliser()

    #expect(stabiliser.update(with: 73) == 73)
    stabiliser.reset()
    #expect(stabiliser.update(with: 74) == 74)
}
