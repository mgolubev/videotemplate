//
//  MaskImage.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 14.03.2023.
//

import CoreML
import UIKit

extension UIImage {
    convenience init?(with url: URL) {
        self.init(contentsOfFile: url.path)
    }

    func pixelBuffer() -> CVPixelBuffer? {
        let imageWidth = Int(self.size.width)
        let imageHeight = Int(self.size.height)

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            imageWidth,
            imageHeight,
            kCVPixelFormatType_32ARGB,
            nil,
            &pixelBuffer
        )

        guard let pixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }

        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        guard let context = context,
              let cgImage = cgImage ?? { () -> CGImage? in
                  guard let ciImage = ciImage else { return nil }
                  return CIContext().createCGImage(ciImage, from: .init(origin: .zero, size: self.size))
              }()
        else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))

        return pixelBuffer
    }

    func frontImageBuffer(background: CVPixelBuffer) -> CVPixelBuffer? {
        let square = CGSize(width: 1024, height: 1024)
        guard let model = Model.shared.mlModel, // load model
              let cgImage = cgImage,
              let resized = cgImage.resizing(size: square) // resize image
        else {
            return nil
        }
        // Provide image input to model
        guard let input = Model.input(image: resized),
              let result = try? model.prediction(from: input),
              let featureName = result.featureNames.first,
              let imageBuffer = result.featureValue(for: featureName)?.imageBufferValue
        else {
            return nil
        }

        guard let mask = CIImage(cvPixelBuffer: imageBuffer).mask(),
              let ciImage = CIImage(cgImage: resized).apply(
                mask: mask,
                background: CIImage(cvImageBuffer: background).resizing(size: square, mode: .fit)
              )?.resizing(size: self.size)
        else {
            return nil
        }

        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            [
                kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
            ] as CFDictionary,
            &pixelBuffer
        )

        guard let pixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        CIContext().render(ciImage, to: pixelBuffer)
        return pixelBuffer
    }
}

private class Model {
    static var shared = Model()

    lazy var mlModel: MLModel? = {
        try? segmentation_8bit(configuration: .init()).model
    }()

    static func input(image: CGImage) -> MLFeatureProvider? {
        try? segmentation_8bitInput(imgWith: image)
    }
}
