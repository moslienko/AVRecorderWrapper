//
//  RecorderState.swift
//
//
//  Created by Pavel Moslienko on 01.08.2024.
//

import Foundation

/// Possible states for audio recording
public enum RecorderState {
    /// The recorder is currently recording audio.
    case recording
    
    /// The recorder has been stopped and is not recording.
    case stopped
    
    /// The user has denied permission to record audio.
    case denied
    
    /// The recording is temporarily paused.
    case paused
    
    /// The recording has been resumed after being paused.
    case continued
}
