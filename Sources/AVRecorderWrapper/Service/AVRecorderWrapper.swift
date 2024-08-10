//
//  AVRecorderWrapper.swift
//
//
//  Created by Pavel Moslienko on 01.08.2024.
//

import Accelerate
import AppViewUtilits
import AVFoundation
import Foundation
import UIKit

/// Defining the delegate methods for `AVRecorderWrapper`.
public protocol AVRecorderWrapperDelegate: AnyObject {
    
    /// Called when recording has started.
    func didStartRecording()
    
    /// Called when recording has finished.
    func didFinishRecording()
    
    /// Called to update the state of the recorder.
    /// - Parameter state: The current state of the recorder.
    func updateState(_ state: RecorderState)
    
    /// Called to update the elapsed recording time.
    /// - Parameter seconds: The current recording time in seconds.
    func updateTime(seconds: Double)
    
    /// Called when an error is received during the audio recording process.
    /// - Parameter error: Error encountered.
    func handleRecorderError(_ error: RecorderError)
}

/// A wrapper class that provides an interface for managing audio recording using `AVAudioRecorder`.
public class AVRecorderWrapper: UIView {
    
    /// A shared instance of `AVRecorderWrapper` for easy access.
    public static let shared = AVRecorderWrapper()
    
    // MARK: - Parameters
    
    /// A delegate to receive recording updates.
    public weak var delegate: AVRecorderWrapperDelegate?
    
    /// A boolean indicating whether the recorder is currently recording.
    public var isRecording: Bool {
        self.audioRecorder?.isRecording ?? false
    }
    
    /// The file path where the recorded audio will be saved.
    private(set) public var path: AudioAssetsPath?
    
    /// The audio session used for managing audio recording.
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    /// The `AVAudioRecorder` instance used for recording audio.
    private var audioRecorder: AVAudioRecorder?
    
    /// A timer to track the recording duration.
    private var timer: Timer?
    
    /// The current recording time.
    private var currentTime: TimeInterval = TimeInterval()
    
    /// A dictionary containing the recorder settings.
    private var recorderSettings: [String: Any] = [:]
    
    /// The default settings used for recording audio.
    private var defaultRecorderSettings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    // MARK: - Callbacks
    
    /// A callback that is triggered when recording starts.
    public var didStartRecording: Callback?
    
    /// A callback that is triggered when recording finishes.
    public var didFinishRecording: Callback?
    
    /// A callback that is triggered to update the recorder state.
    public var didUpdateState: DataCallback<RecorderState>?
    
    /// A callback that is triggered to update the elapsed recording time.
    public var didUpdateTime: DataCallback<Double>?
    
    /// A callback that is triggered when an error is received during the audio recording process.
    public var didHandleRecorderError: DataCallback<RecorderError>?
}

// MARK: - Public methods
public extension AVRecorderWrapper {
    
    /// Init recording audio params.
    /// - Parameters:
    ///   - path: The file path where the recorded audio will be saved.
    ///   - recorderSettings: The settings used for the audio recorder. If not provided, default settings will be used.
    func start(path: AudioAssetsPath, recorderSettings: [String: Any] = [:]) {
        self.path = path
        self.recorderSettings = recorderSettings.isEmpty ? self.defaultRecorderSettings : recorderSettings
    }
    
    /// Sets up the observers for recording callbacks.
    /// - Parameters:
    ///   - didStartRecording: A callback triggered when recording starts.
    ///   - didFinishRecording: A callback triggered when recording finishes.
    ///   - didUpdateState: A callback triggered to update the recorder state.
    ///   - didUpdateTime: A callback triggered to update the elapsed recording time.
    ///   - didHandleRecorderError: A callback that is triggered when an error is received during the audio recording process.
    func setObservers(
        didStartRecording: Callback?,
        didFinishRecording: Callback?,
        didUpdateState: DataCallback<RecorderState>?,
        didUpdateTime: DataCallback<Double>?,
        didHandleRecorderError: DataCallback<RecorderError>?
    ) {
        self.didStartRecording = didStartRecording
        self.didFinishRecording = didFinishRecording
        self.didUpdateState = didUpdateState
        self.didUpdateTime = didUpdateTime
        self.didHandleRecorderError = didHandleRecorderError
    }
    
    /// Checks the user's permission to record audio and returns the result via a callback.
    /// - Parameter grantedCallback: A callback triggered with the result of the permission check.
    func checkPermission(grantedCallback: DataCallback<Bool>?) {
        let permission = recordingSession.recordPermission
        print("permission - \(permission)")
        switch permission {
        case .undetermined:
            recordingSession.requestRecordPermission({ (result) in
                print("result... \(result)")
                grantedCallback?(result)
            })
            break
        case .granted:
            grantedCallback?(true)
        case .denied:
            grantedCallback?(false)
        @unknown default:
            grantedCallback?(false)
        }
    }
    
    /// Attempts to start recording.
    func tryStartRecord() {
        checkPermission(grantedCallback: { isGranted in
            if isGranted {
                self.startRecord()
            } else {
                self.delegate?.updateState(.denied)
                self.didUpdateState?(.denied)
            }
        })
    }
    
    /// Attempts to continue recording.
    func tryContinueRecord() {
        checkPermission(grantedCallback: { isGranted in
            if isGranted {
                self.continueRecord()
            } else {
                self.delegate?.updateState(.denied)
                self.didUpdateState?(.denied)
            }
        })
    }
    
    /// Stops the recording process.
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
                        
        timer?.invalidate()
        try? recordingSession.setCategory(.playback, mode: .default)
        
        // Send events
        delegate?.didFinishRecording()
        delegate?.updateState(.stopped)
        
        didFinishRecording?()
        didUpdateState?(.stopped)
    }
    
    /// Pauses or continues the recording depending on the current state.
    func pauseOrContinueRecord() {
        self.isRecording ? self.pauseRecord() : self.continueRecord()
    }
    
    /// Pauses the recording process.
    func pauseRecord() {
        self.audioRecorder?.pause()
        if let time = self.audioRecorder?.currentTime {
            self.currentTime += time
        }
        self.timer?.invalidate()
        self.delegate?.updateState(.paused)
        self.didUpdateState?(.paused)
    }
}

// MARK: - Private methods
private extension AVRecorderWrapper {
    
    /// Starts the audio recording process.
    func startRecord() {
        guard let path = self.path?.path else {
            self.delegate?.handleRecorderError(.missingFilePath)
            self.didHandleRecorderError?(.missingFilePath)
            return
        }
        // Start audio recording
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: path, settings: self.recorderSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDuration), userInfo: nil, repeats: true)
            self.delegate?.didStartRecording()
            self.delegate?.updateState(.recording)
            
            self.didStartRecording?()
            self.didUpdateState?(.recording)
        } catch {
            print("failed start session")
            stopRecording()
            
            self.delegate?.handleRecorderError(.failedStartAudioSession)
            self.didHandleRecorderError?(.failedStartAudioSession)
        }
    }
    
    /// Continues a paused recording session.
    func continueRecord() {
        self.audioRecorder?.record()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDuration), userInfo: nil, repeats: true)
        self.delegate?.updateState(.recording)
        self.delegate?.updateState(.continued)
        
        self.didUpdateState?(.recording)
        self.didUpdateState?(.continued)
    }
    
    /// Updates the recording duration.
    @objc
    func updateDuration() {
        print("updateDuration, isRecording - \(self.isRecording), seconds \(Int(self.audioRecorder?.currentTime ?? .zero)), saved - \(self.currentTime)")
        if self.isRecording {
            audioRecorder?.updateMeters()
            let averagePower = audioRecorder?.averagePower(forChannel: 0) ?? 0.0
            print("Average power: \(averagePower)")
            let seconds = Int(self.audioRecorder?.currentTime ?? .zero) + Int(self.currentTime)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.updateTime(seconds: Double(seconds))
                self?.didUpdateTime?(Double(seconds))
            }
        } else {
            self.timer?.invalidate()
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AVRecorderWrapper: AVAudioRecorderDelegate {
    
    /// Called when an encoding error occurs during recording.
    /// - Parameters:
    ///   - recorder: The recorder that encountered an error.
    ///   - error: The error that occurred.
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("audioRecorderEncodeErrorDidOccur - \(String(describing: error?.localizedDescription))")
        self.stopRecording()
        
        var err: RecorderError {
            if let error = error {
                return RecorderError.systemError(error)
            }
            return RecorderError.unknownError
        }
        
        self.delegate?.handleRecorderError(err)
        self.didHandleRecorderError?(err)
    }
    
    /// Called when the recording finishes successfully or fails.
    /// - Parameters:
    ///   - recorder: The recorder that finished recording.
    ///   - flag: A boolean indicating whether the recording was successful.
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("audioRecorderDidFinishRecording successfully - \(flag)")
        if !flag {
            stopRecording()
        }
    }
}
