//
//  AudioAssetsPath.swift
//
//
//  Created by Pavel Moslienko on 01.08.2024.
//

import Foundation

/// File path value to create the audio file
public enum AudioAssetsPath {
    /// Save the file to the specified directory
    case byPath(_ path: URL)
    /// Save the file to a temporary directory under a specific name
    case temp(fileName: String)
    
    /// Get file path
    public var path: URL? {
        switch self {
        case let .byPath(path):
            return path
        case let .temp(fileName):
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            return tempURL.appendingPathComponent(fileName)
        }
    }
}
