// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation

public enum IPCSocketPath {
    public static let environmentKey = "AEROFLOW_SOCKET"
    public static let secretSuffix = ".secret"

    public static func resolvedPath(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> String {
        if let override = environment[environmentKey], !override.isEmpty {
            return override
        }

        if let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return cachesDirectory
                .appendingPathComponent("com.frostymur.AeroFlow", isDirectory: true)
                .appendingPathComponent("ipc.sock", isDirectory: false)
                .path
        }

        return NSString(string: NSHomeDirectory())
            .appendingPathComponent("Library/Caches/com.frostymur.AeroFlow/ipc.sock")
    }

    public static func secretPath(forSocketPath socketPath: String) -> String {
        socketPath + secretSuffix
    }
}
