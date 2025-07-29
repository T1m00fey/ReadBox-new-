//
//  VideoCacheManager.swift
//  ReadBox
//
//  Created by Macbook Pro on 24.07.2025.
//

import Foundation

class VideoCacheManager {
    static let shared = VideoCacheManager()

    private init() {}

    func cachedURL(for originalURL: URL) -> URL {
        let filename = originalURL.lastPathComponent
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    func isCached(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: cachedURL(for: url).path)
    }

    func downloadIfNeeded(from remoteURL: URL) async throws -> URL {
        let cached = cachedURL(for: remoteURL)

        if FileManager.default.fileExists(atPath: cached.path) {
            return cached
        }

        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
        try FileManager.default.copyItem(at: tempURL, to: cached)
        return cached
    }
}
