//
//  RecorderError.swift
//
//
//  Created by Pavel Moslienko on 10.08.2024.
//

import Foundation

/// Types of errors that may occur during audio recording
public enum RecorderError: Error {
    /// The path to the file to be recorded is missing
    case missingFilePath
    
    /// Standard error model
    case systemError(_ error: Error)
    
    /// Cannot create an audio session
    case failedStartAudioSession
    
    /// Unknown error
    case unknownError
}
