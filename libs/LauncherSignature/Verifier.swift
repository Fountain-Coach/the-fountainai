import Foundation

public func verifyLauncherSignature() {
    let env = ProcessInfo.processInfo.environment
    guard let runtimeSig = env["LAUNCHER_SIGNATURE"], runtimeSig == embeddedLauncherSignature else {
        FileHandle.standardError.write(Data("Missing or invalid launcher signature\n".utf8))
        exit(1)
    }
}
