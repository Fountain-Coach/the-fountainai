import Foundation

// Internal helper for validating the runtime signature without exiting. This
// allows unit tests to exercise both the success and failure paths.
func isLauncherSignatureValid(
    environment: [String: String] = ProcessInfo.processInfo.environment
) -> Bool {
    guard let runtimeSig = environment["LAUNCHER_SIGNATURE"] else { return false }
    return runtimeSig == embeddedLauncherSignature
}

public func verifyLauncherSignature() {
    guard isLauncherSignatureValid() else {
        FileHandle.standardError.write(Data("Missing or invalid launcher signature\n".utf8))
        exit(1)
    }
}
