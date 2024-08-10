//
//  RecorderViewController.swift
//  AVRecorderWrapperExample
//
//  Created by Pavel Moslienko on 01.08.2024.
//

import AppViewUtilits
import AVRecorderWrapper
import UIKit

extension DecorateWrapper where Element: UIButton {
    static func largeButtonStyle() -> DecorateWrapper {
        .wrap {
            $0.tintColor = .systemBlue
            $0.configuration = .filled()
        }
    }
    
    static func circleIconButtonStyle() -> DecorateWrapper {
        .wrap {
            $0.tintColor = .white
            $0.backgroundColor = .clear
            $0.backgroundColor = .systemBlue
            $0.layer.cornerRadius = 32
        }
    }
}

class RecorderViewController: UIViewController {
    
    private let recordWrapper = AVRecorderWrapper.shared
    
    private lazy var permissionButton: UIButton = {
        let button = AppButton(title: "Request permission")
        button.apply(.largeButtonStyle())
        button.addAction { [weak self] in
            self?.checkPermissions()
        }
        return button
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = ""
        label.textColor = .label
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .right
        label.numberOfLines = 1
        
        return label
    }()
    
    private lazy var filePathLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = ""
        label.textColor = .label
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .left
        label.numberOfLines = 0
        
        return label
    }()
    
    //pause
    lazy var startPauseRecordButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.circleIconButtonStyle())
        button.addAction { [weak self] in
            guard let self = self else {
                return
            }
            print("path - \(self.recordWrapper.isRecording)")
            self.filePathLabel.text = self.recordWrapper.path?.path?.absoluteString
            
            if self.recordWrapper.isRecording {
                self.recordWrapper.pauseOrContinueRecord()
            } else {
                self.recordWrapper.tryStartRecord()
            }
        }
        
        return button
    }()
    
    lazy var stopRecordButton: UIButton = {
        let button = AppButton(type: .system)
        button.apply(.circleIconButtonStyle())
        button.setImage(UIImage(systemName: "stop"), for: [])
        button.addAction { [weak self] in
            self?.recordWrapper.stopRecording()
        }
        
        return button
    }()
    
    lazy var buttonsStack: UIStackView = {
        let stackView = UIStackView.stackView(
            [startPauseRecordButton, stopRecordButton],
            axis: .horizontal,
            alignment: .center,
            distribution: .fill,
            spacing: 16.0
        )
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    lazy var mainStack: UIStackView = {
        let stackView = UIStackView.stackView(
            [permissionButton, durationLabel, buttonsStack, filePathLabel],
            axis: .vertical,
            alignment: .center,
            distribution: .fill,
            spacing: 16.0
        )
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadData()
    }
    
    private func reloadData() {
        recordWrapper.setObservers(
            didStartRecording: {
                print("didStartRecording...")
                self.stopRecordButton.isHidden = false
            },
            didFinishRecording: {
                print("didFinishRecording...")
                self.startPauseRecordButton.setImage(UIImage(systemName: "record.circle"), for: [])
                self.stopRecordButton.isHidden = true
                self.durationLabel.text = ""
                
                self.recordWrapper.start(path: .temp(fileName: "\(Date().timeIntervalSince1970).m4a"))
            },
            didUpdateState: { state in
                print("updateState...\(state)")
                self.buttonsStack.isHidden = false
                
                switch state {
                case .recording:
                    self.startPauseRecordButton.setImage(UIImage(systemName: "pause"), for: [])
                case .stopped:
                    self.stopRecordButton.isHidden = true
                case .denied:
                    self.buttonsStack.isHidden = true
                case .paused:
                    self.startPauseRecordButton.setImage(UIImage(systemName: "record.circle"), for: [])
                case .continued:
                    break
                }
            },
            didUpdateTime: { time in
                self.durationLabel.text = time.asString(style: .short)
            }
        )
    }
}

// MARK: - Setup methods
private extension RecorderViewController {
    
    func setupUI() {
        self.title = "Recorder"
        self.view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(mainStack)
        layoutUI()
        self.buttonsStack.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pathLabelTapped(_:)))
        self.filePathLabel.isUserInteractionEnabled = true
        self.filePathLabel.addGestureRecognizer(tapGesture)
    }
    
    func layoutUI() {
        NSLayoutConstraint.activate([
            permissionButton.heightAnchor.constraint(equalToConstant: 32.0),
            startPauseRecordButton.widthAnchor.constraint(equalToConstant: 64.0),
            startPauseRecordButton.heightAnchor.constraint(equalToConstant: 64.0),
            stopRecordButton.widthAnchor.constraint(equalToConstant: 64.0),
            stopRecordButton.heightAnchor.constraint(equalToConstant: 64.0),
            
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            mainStack.bottomAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
        ])
    }
    
    @objc
    func pathLabelTapped(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else {
            return
        }
        UIPasteboard.general.string = label.text
        
        let alert = UIAlertController(title: "The path was copied", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel))
        present(alert, animated: true)    }
}

// MARK: - Module methods
private extension RecorderViewController {
    
    func checkPermissions() {
        recordWrapper.checkPermission { isGranted in
            onMainThread { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.permissionButton.isUserInteractionEnabled = !isGranted
                self.permissionButton.layer.opacity = isGranted ? 0.7 : 1.0
                self.buttonsStack.isHidden = !isGranted
                
                if isGranted {
                    self.recordWrapper.start(path: .temp(fileName: "\(Date().timeIntervalSince1970).m4a"))
                    self.startPauseRecordButton.setImage(UIImage(systemName: "record.circle"), for: [])
                    self.stopRecordButton.isHidden = !self.recordWrapper.isRecording
                }
            }
        }
    }
}
