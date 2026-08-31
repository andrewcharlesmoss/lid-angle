import Testing
@testable import LidAngleApp

@Test func aboutValuesFollowBundleMetadata() {
    let version = AppVersion(info: [
        "CFBundleShortVersionString": "2.3.4",
        "CFBundleVersion": "42",
        "CFBundleIdentifier": "example.lid-angle"
    ])
    #expect(version.version == "2.3.4")
    #expect(version.build == "42")
    #expect(version.identifier == "example.lid-angle")
}

@Test func unbundledBuildDoesNotClaimAReleaseVersion() {
    let version = AppVersion(info: [:])
    #expect(version.version == "Development")
    #expect(version.build == "local")
    #expect(version.identifier == "unbundled")
}
