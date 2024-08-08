//
//  AudioRecordManager.swift
//
//
//  Created by Pavel Moslienko on 01.08.2024.
//

import Accelerate
import AppViewUtilits
import AVFoundation
import Foundation
import UIKit

public protocol RecorderViewControllerDelegate: AnyObject {
    func didStartRecording()
    func didFinishRecording()
    func updateState(_ state: RecorderState)
    func updateTime(seconds: Double)
}

public class AudioRecordManager: UIView {
    
    public static let shared = AudioRecordManager()
    
    // MARK: - Params
    public weak var delegate: RecorderViewControllerDelegate?
    public var isRecording: Bool {
        self.audioRecorder?.isRecording ?? false
    }
    
    private(set) public var path: AudioAssetsPath?
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var settings: [String: Any] = [:]
    private var defaultSettings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    // MARK: - Callbacks
    public var didStartRecording: Callback?
    public var didFinishRecording: Callback?
    public var updateState: DataCallback<RecorderState>?
    public var updateTime: DataCallback<Double>?
    
    //".m4a"
}

// MARK: - Public methods
public extension AudioRecordManager {
    
    func start(path: AudioAssetsPath, settings: [String: Any]) {
        self.path = path
        self.settings = settings.isEmpty ? self.defaultSettings : settings
    }
    
    func setObservers(
        didStartRecording: Callback?,
        didFinishRecording: Callback?,
        updateState: DataCallback<RecorderState>?,
        updateTime: DataCallback<Double>?
    ) {
        self.didStartRecording = didStartRecording
        self.didFinishRecording = didFinishRecording
        self.updateState = updateState
        self.updateTime = updateTime
    }
    
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
    
    func tryStartRecord() {
        checkPermission(grantedCallback: { isGranted in
            if isGranted {
                self.startRecord()
            } else {
                self.delegate?.updateState(.denied)
            }
        })
    }
    
    func tryContinueRecord() {
        checkPermission(grantedCallback: { isGranted in
            if isGranted {
                self.continueRecord()
            } else {
                self.delegate?.updateState(.denied)
            }
        })
    }
    
    func stopRecording() {
        print("stopRecording...")
        self.finishRecording()
        self.delegate?.didFinishRecording()
        self.delegate?.updateState(.stopped)
        
        self.path = nil
        self.timer?.invalidate()
        try? self.recordingSession.setCategory(.playback, mode: .default)
    }
    
    func pauseOrContinueRecord() {
        self.isRecording ? self.pauseRecord() : self.continueRecord()
    }
    
    func pauseRecord() {
        self.audioRecorder?.pause()
        self.timer?.invalidate()
        self.delegate?.updateState(.paused)
    }
    
    func finishRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

// MARK: - Private methods
private extension AudioRecordManager {
    
    func startRecord() {
        guard let path = self.path?.path else {
            return
        }
        // Start audio recording
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: path, settings: self.settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDuration), userInfo: nil, repeats: true)
            self.delegate?.didStartRecording()
            self.delegate?.updateState(.recording)
        } catch {
            print("failed start session")
            finishRecording()
        }
    }
    
    func continueRecord() {
        self.audioRecorder?.record()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDuration), userInfo: nil, repeats: true)
        self.delegate?.updateState(.recording)
        self.delegate?.updateState(.continued)
    }
    
    /// Handle interruption
    @objc
    func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let key = userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber
        else { return }
        if key.intValue == 1 {
            DispatchQueue.main.async {
                print("handleInterruption -\(self.isRecording), save...")
                if self.isRecording {
                    self.stopRecording()
                }
            }
        }
    }
    
    @objc
    func updateDuration() {
        print("updateDuration, isRecording - \(self.isRecording), seconds \(Int(self.audioRecorder?.currentTime ?? .zero))")
        if self.isRecording {
            audioRecorder?.updateMeters()
            let averagePower = audioRecorder?.averagePower(forChannel: 0) ?? 0.0
            print("Average power: \(averagePower)")
            let seconds = Int(self.audioRecorder?.currentTime ?? .zero)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.updateTime(seconds: Double(seconds))
            }
        } else{
            self.timer?.invalidate()
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordManager: AVAudioRecorderDelegate {
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("audioRecorderEncodeErrorDidOccur - \(String(describing: error?.localizedDescription))")
        self.timer?.invalidate()
    }
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("audioRecorderDidFinishRecording successfully - \(flag)")
        if !flag {
            finishRecording()
        }
        self.timer?.invalidate()
    }
}
