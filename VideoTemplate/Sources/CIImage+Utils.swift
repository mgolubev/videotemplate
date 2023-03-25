//
//  CIImage+Utils.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 15.03.2023.
//

import CoreImage

extension CIImage {
    func apply(mask: CIImage, background: CIImage? = nil, transform: CGAffineTransform? = nil) -> CIImage? {
        guard let filter = CIFilter(name: "CIBlendWithMask") else { return nil }
        if let transform = transform {
            let image = self.transformed(by: transform)
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(mask.transformed(by: transform), forKey: kCIInputMaskImageKey)
        }
        else {
            filter.setValue(self, forKey: kCIInputImageKey)
            filter.setValue(mask, forKey: kCIInputMaskImageKey)
        }
        if let background = background {
            filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        }
        return filter.outputImage
    }

    func resizingToFit(size: CGSize) -> CIImage? {
        let imageSize = extent.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let rectAspectRatio = size.width / size.height

        var scale: CGFloat
        if imageAspectRatio > rectAspectRatio {
            scale = size.width / imageSize.width
        } else {
            scale = size.height / imageSize.height
        }
        let translateX = (size.width - (imageSize.width*scale)) / 2
        let translateY = (size.height - (imageSize.height*scale)) / 2
        return transformed(
            by: .identity
                .translatedBy(x: translateX, y: translateY)
                .scaledBy(x: scale, y: scale)
        )
    }

    func resizingToFill(size: CGSize) -> CIImage? {
        let imageSize = extent.size

        let imageAspectRatio = imageSize.width / imageSize.height
        let rectAspectRatio = size.width / size.height

        var scale: CGFloat

        if imageAspectRatio > rectAspectRatio {
            scale = size.height / imageSize.height
        } else {
            scale = size.width / imageSize.width
        }

        let translateX = (size.width - (imageSize.width*scale)) / 2
        let translateY = (size.height - (imageSize.height*scale)) / 2

        return transformed(
            by: .identity
                .translatedBy(x: translateX, y: translateY)
                .scaledBy(x: scale, y: scale)
        )
    }

    func addingBackground(image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(image, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage
    }

    func pixelBuffer(with context: CIContext, size: CGSize) -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            nil,
            &pixelBuffer
        )

        if status != kCVReturnSuccess {
            return nil
        }

        guard let buffer = pixelBuffer else {
            return nil
        }

        context.render(self, to: buffer)

        return buffer
    }
}
