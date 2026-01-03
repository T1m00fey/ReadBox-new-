//
//  StorageReference.swift
//  ReadBox
//
//  Created by Macbook Pro on 07.11.2025.
//

import SwiftUI
import FirebaseStorage

extension StorageReference {
    func dataAsync(maxSize: Int64) async throws -> Data {
        try await withCheckedThrowingContinuation { c in
            self.getData(maxSize: maxSize) { data, error in
                if let data { c.resume(returning: data) }
                else { c.resume(throwing: error ?? NSError()) }
            }
        }
    }

    func downloadURLAsync() async throws -> URL {
        try await withCheckedThrowingContinuation { c in
            self.downloadURL { url, error in
                if let url { c.resume(returning: url) }
                else { c.resume(throwing: error ?? NSError()) }
            }
        }
    }
}

