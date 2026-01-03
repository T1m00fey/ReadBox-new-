//
//  VideoCacheManager.swift
//  ReadBox
//
//  Created by Macbook Pro on 24.07.2025.
//

import Foundation

final class VideoCacheManager {
    static let shared = VideoCacheManager()
    
    private let directoryURL: URL
    
    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        directoryURL = base.appendingPathComponent("VideoCache", isDirectory: true)
        
        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    private func fileURL(for id: String) -> URL {
        directoryURL.appendingPathComponent(id).appendingPathExtension("mp4")
    }
    
    func cachedURL(
        for remoteURL: URL,
        id: String,
        ignoreCache: Bool = false
    ) async throws -> URL {
        let localURL = fileURL(for: id)
        
        if !ignoreCache,
           FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        let (tmpURL, _) = try await URLSession.shared.download(from: remoteURL)
        
        try? FileManager.default.removeItem(at: localURL)
        try FileManager.default.moveItem(at: tmpURL, to: localURL)
        
        return localURL
    }
    
    func clear() {
        try? FileManager.default.removeItem(at: directoryURL)
        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
