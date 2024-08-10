<p align="center">
   <img width="200" src="https://moslienko.github.io/Assets/AVRecorderWrapper/sdk.png" alt="AVRecorderWrapper Logo">
</p>

<p align="center">
   <a href="https://developer.apple.com/swift/">
      <img src="https://img.shields.io/badge/Swift-5.2-orange.svg?style=flat" alt="Swift 5.2">
   </a>
   <a href="https://github.com/apple/swift-package-manager">
      <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
   </a>
</p>

# AVRecorderWrapper

<p align="center">
 A wrapper for recording an audio file.
</p>

## Table of Contents

* [Installation](#installation)
* [Example](#example)
* [Usage](#usage)
	* [Init record](#init-record)
	* [Record Control](#record-Control)
	* [Available properties](#available-properties)
	* [Observers](#observers)
	* [Error handling](#error-handling)
	* [Recording states](#recording-states)
	* [Check permission](#check-permission)
* [License](#license)

## Installation
The library requires a dependency [AppViewUtilits](https://github.com/moslienko/AppViewUtilits/).

### Swift Package Manager

To integrate using Apple's [Swift Package Manager](https://swift.org/package-manager/), add the following as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/moslienko/AVRecorderWrapper.git", from: "1.0.0")
]
```

Alternatively navigate to your Xcode project, select `Swift Packages` and click the `+` icon to search for `AVRecorderWrapper`.

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate AVRecorderWrapper into your project manually. Simply drag the `Sources` Folder into your Xcode project.

## Example

The example application is the best way to see `AVRecorderWrapper` in action. Simply open the `AVRecorderWrapperExample.xcodeproj` and run the `AVRecorderWrapperExample` scheme.

## Usage

### Init record

Before you begin recording, you need to initialize it via the `start` method. Specify the directory to which the audio file will be saved and (if necessary) your own settings for `AVAudioRecorder`.

```swift
func start(path: AudioAssetsPath, recorderSettings: [String: Any] = [:])
```

For example:

```swift
AVRecorderWrapper.shared.start(path: .temp(fileName: "\(Date().timeIntervalSince1970).m4a"))
```

### Record Control

Attempts to start recording.

```swift
func tryStartRecord()
```

Pauses the recording process.

```swift
func pauseRecord()
```

Attempts to continue recording.

```swift
func tryContinueRecord()
```

Pauses or continues the recording depending on the current state.

```swift
func pauseOrContinueRecord()
```

Stops the recording process.

```swift
func stopRecording()
```

Stops the recording process.

```swift
func stopRecording()
```

### Available properties

A boolean indicating whether the recorder is currently recording.

```swift
var isRecording: Bool
```

The file path where the recorded audio will be saved.

```swift
var path: AudioAssetsPath?
```

Duration of the current recording.

```swift
var recordDuration: TimeInterval
```

### Observers

To get callbacks from the library, you can use the `setObservers `method or the `AVRecorderWrapperDelegate` delegate setting.

```swift
AVRecorderWrapper.shared.delegate = self 
```

```swift
AVRecorderWrapper.shared.setObservers(
  didStartRecording: {
    /// A callback that is triggered when recording starts.
  },
  didFinishRecording: {
    /// A callback that is triggered when recording finishes.
  },
  didUpdateState: { state in
    /// A callback that is triggered to update the recorder state.
  },
  didUpdateTime: { time in
    /// A callback that is triggered to update the elapsed recording time.
  },
  didHandleRecorderError: { error in
    // A callback that is triggered when an error is received during the audio recording process.
  }
)
```

### Error handling

```swift
enum RecorderError: Error {
  /// The path to the file to be recorded is missing
  case missingFilePath

  /// Standard error model
  case systemError(_ error: Error)

  /// Cannot create an audio session
  case failedStartAudioSession

  /// Unknown error
  case unknownError
}
```

### Recording states

```swift
enum RecorderState {
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
```


### Check permission

Checking and calling the microphone access authorization:

```swift
AVRecorderWrapper.shared.checkPermission { isGranted in
  ...
}
```

You may not call `checkPermission` before starting or continuing a record, the library will do the check itself and return `.denied` in `updateState` (delegate) or `didUpdateState` (callback) if permission has been rejected.

Don't forget to add the field to your *info.plist*:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>...</string>
```

## License

```
AVRecorderWrapper
Copyright (c) 2024 Pavel Moslienko 8676976+moslienko@users.noreply.github.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
