import Flutter
import UIKit
import PDFKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let pdfChannel = FlutterMethodChannel(
      name: "pdf_compressor",
      binaryMessenger: controller.binaryMessenger
    )
    
    pdfChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "compressPdf" {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let quality = args["quality"] as? Double else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }
        
        self.compressPdf(inputPath: inputPath, outputPath: outputPath, quality: quality, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func compressPdf(inputPath: String, outputPath: String, quality: Double, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: inputPath)) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "PDF_LOAD_ERROR", message: "Failed to load PDF", details: nil))
          }
          return
        }
        
        // Determine compression settings - VERY aggressive for actual size reduction
        let imageQuality: CGFloat = CGFloat(quality.clamped(to: 0.1...0.9))
        // Much lower DPI and JPEG quality to actually reduce file size
        let dpi: CGFloat
        let jpegQuality: CGFloat
        switch quality {
        case 0.0..<0.4: // Max compression
          dpi = 72  // Very low DPI (screen resolution) for maximum compression
          jpegQuality = 0.2  // Very low JPEG quality
        case 0.4..<0.7: // Medium
          dpi = 120
          jpegQuality = 0.4
        default: // High quality
          dpi = 180
          jpegQuality = 0.6
        }
        
        // Create output PDF context with compression
        let outputURL = URL(fileURLWithPath: outputPath)
        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "PDF_CREATE_ERROR", message: "Failed to create PDF consumer", details: nil))
          }
          return
        }
        
        // Get first page bounds for media box
        guard let firstPage = pdfDocument.page(at: 0) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "PDF_PAGE_ERROR", message: "PDF has no pages", details: nil))
          }
          return
        }
        
        let mediaBox = firstPage.bounds(for: .mediaBox)
        var pdfMediaBox = mediaBox
        
        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &pdfMediaBox, nil) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "PDF_CONTEXT_ERROR", message: "Failed to create PDF context", details: nil))
          }
          return
        }
        
        // Calculate scale factor for DPI reduction
        let pointsPerInch: CGFloat = 72.0
        let scale = dpi / pointsPerInch
        
        // Process each page
        for pageIndex in 0..<pdfDocument.pageCount {
          guard let page = pdfDocument.page(at: pageIndex) else { continue }
          
          let pageBounds = page.bounds(for: .mediaBox)
          var pageMediaBox = pageBounds
          
          pdfContext.beginPDFPage([kCGPDFContextMediaBox: NSValue(cgRect: pageMediaBox)] as CFDictionary)
          
          // Render page at reduced resolution for compression
          let renderSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
          
          UIGraphicsBeginImageContextWithOptions(renderSize, false, 1.0)
          defer { UIGraphicsEndImageContext() }
          
          guard let renderContext = UIGraphicsGetCurrentContext() else {
            pdfContext.endPDFPage()
            continue
          }
          
          // Scale and render
          renderContext.scaleBy(x: scale, y: scale)
          page.draw(with: .mediaBox, to: renderContext)
          
          guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext(),
                let cgImage = renderedImage.cgImage else {
            pdfContext.endPDFPage()
            continue
          }
          
          // Compress image with aggressive JPEG compression
          guard let imageData = renderedImage.jpegData(compressionQuality: jpegQuality),
                let compressedImage = UIImage(data: imageData),
                let finalCgImage = compressedImage.cgImage else {
            pdfContext.endPDFPage()
            continue
          }
          
          // Draw compressed image to PDF
          pdfContext.draw(finalCgImage, in: pageBounds)
          pdfContext.endPDFPage()
        }
        
        pdfContext.closePDF()
        
        // Write compressed PDF
        do {
          try mutableData.write(to: outputURL, options: .atomic)
          DispatchQueue.main.async {
            result(outputPath)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "PDF_SAVE_ERROR", message: "Failed to save: \(error.localizedDescription)", details: nil))
          }
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "COMPRESSION_ERROR", message: error.localizedDescription, details: nil))
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
