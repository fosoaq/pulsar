import IOKit.pwr_mgt

/// Holds a power assertion that stops idle system sleep; the display can still turn off.
@MainActor
final class SleepGuard {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        if active {
            let status = IOPMAssertionCreateWithName(
                "PreventUserIdleSystemSleep" as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Pulsar runs scheduled speed tests" as CFString,
                &assertionID
            )
            isActive = status == kIOReturnSuccess
        } else {
            IOPMAssertionRelease(assertionID)
            isActive = false
        }
    }
}
