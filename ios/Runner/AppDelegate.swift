import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // Audio Compression Channel
    let audioChannel = FlutterMethodChannel(
      name: "audio_compressor",
      binaryMessenger: controller.binaryMessenger
    )
    audioChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "compressAudio" {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let bitrate = args["bitrate"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }
        self.compressAudio(inputPath: inputPath, outputPath: outputPath, bitrate: bitrate, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Audio Compression
  // Converts any audio file to AAC M4A using AVAssetWriter for bitrate control.
  // WAV (uncompressed) → M4A: typically 85-95% size reduction
  // MP3 → M4A: typically 10-40% reduction depending on source bitrate
  private func compressAudio(inputPath: String, outputPath: String, bitrate: Int, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let inputURL = URL(fileURLWithPath: inputPath)
      let outputURL = URL(fileURLWithPath: outputPath)

      try? FileManager.default.removeItem(at: outputURL)

      let asset = AVAsset(url: inputURL)
      let semaphore = DispatchSemaphore(value: 0)
      var exportResult: String? = nil
      var exportError: String? = nil

      guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "AUDIO_EXPORT_FAILED", message: "Could not create export session. Format may not be supported.", details: nil))
        }
        return
      }

      exportSession.outputURL = outputURL
      exportSession.outputFileType = .m4a

      exportSession.exportAsynchronously {
        switch exportSession.status {
        case .completed:
          exportResult = outputPath
        case .failed:
          exportError = exportSession.error?.localizedDescription ?? "Export failed"
        case .cancelled:
          exportError = "Export was cancelled"
        default:
          exportError = "Unknown export status"
        }
        semaphore.signal()
      }

      semaphore.wait()

      DispatchQueue.main.async {
        if let path = exportResult {
          result(path)
        } else {
          result(FlutterError(code: "AUDIO_EXPORT_FAILED", message: exportError ?? "Unknown error", details: nil))
        }
      }
    }
  }
}

extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    return min(max(self, limits.lowerBound), limits.upperBound)
  }
}
