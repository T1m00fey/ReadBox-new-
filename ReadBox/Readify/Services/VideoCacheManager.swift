//
//  VideoCacheManager.swift
//  ReadBox
//
//  Created by Macbook Pro on 24.07.2025.
//

import Foundation

actor VideoCacheManager {
    static let shared = VideoCacheManager()

    private let fm = FileManager.default

    private var inFlight: [String: Task<URL, Error>] = [:]

    private var cacheDir: URL {
        let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("video-cache", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func localPath(for id: String) -> URL {
        cacheDir.appendingPathComponent(id).appendingPathExtension("mp4")
    }

    func cachedLocalURL(id: String) -> URL? {
        let url = localPath(for: id)
        return fm.fileExists(atPath: url.path) ? url : nil
    }

    func warmCache(remoteURL: URL, id: String) async {
        if cachedLocalURL(id: id) != nil { return }
        if inFlight[id] != nil { return }

        inFlight[id] = Task.detached(priority: .utility) { [weak self] in
            guard let self else { throw URLError(.unknown) }
            let target = await self.localPath(for: id)

            let (tmp, _) = try await URLSession.shared.download(from: remoteURL)

            try? await self.removeFileIfExists(at: target)
            try FileManager.default.moveItem(at: tmp, to: target)

            return target
        }

        _ = try? await inFlight[id]?.value
        inFlight[id] = nil
    }

    private func removeFileIfExists(at url: URL) async throws {
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }

    // MARK: - Очистка кеша

    func clearPost(id postId: String, maxIndex: Int) async {
        for i in 0..<maxIndex {
            let cacheId = "video_\(postId)_\(i)"
            if let task = inFlight.removeValue(forKey: cacheId) {
                task.cancel()
            }
            let local = localPath(for: cacheId)
            if fm.fileExists(atPath: local.path) {
                try? fm.removeItem(at: local)
            }
        }
    }

    func clearAll() async {
        for (_, task) in inFlight { task.cancel() }
        inFlight.removeAll()
        let dir = cacheDir
        if fm.fileExists(atPath: dir.path) {
            try? fm.removeItem(at: dir)
        }
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }

}
