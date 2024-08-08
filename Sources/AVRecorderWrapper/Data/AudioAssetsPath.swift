//
//  AudioAssetsPath.swift
//
//
//  Created by Pavel Moslienko on 01.08.2024.
//

import Foundation

public enum AudioAssetsPath {
    case byPath(_ path: URL)
    case temp(fileName: String)
    
    var path: URL? {
        switch self {
        case let .byPath(path):
            return path
        case let .temp(fileName):
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            return tempURL.appendingPathComponent(fileName)
        }
    }
}
