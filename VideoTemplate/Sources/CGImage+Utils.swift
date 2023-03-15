//
//  CGImage+Utils.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 15.03.2023.
//

import CoreGraphics

extension CGImage {
    enum ResizeMode {
        case fit
        case fill
    }
    func resizing(size newSize: CGSize, mode: ResizeMode = .fit) -> CGImage? {
        let width: Int = Int(newSize.width)
        let height: Int = Int(newSize.height)

        let bytesPerPixel = bitsPerPixel / bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel

        let scale: CGFloat
        switch mode {
        case .fit:
            scale = min(newSize.width/CGFloat(self.width), newSize.height/CGFloat(self.height))
        case .fill:
            scale = max(newSize.width/CGFloat(self.width), newSize.height/CGFloat(self.height))
        }
        let size = CGSize(width: CGFloat(self.width) * scale, height: CGFloat(self.height) * scale)

        guard let colorSpace = colorSpace,
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: destBytesPerRow,
                space: colorSpace,
                bitmapInfo: alphaInfo.rawValue
              )
        else {
            return nil
        }

        context.interpolationQuality = .high
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(origin: .zero, size: newSize))

        let origin = CGPoint(x: (newSize.width - size.width) / 2, y: (newSize.height - size.height) / 2)
        context.draw(self, in: CGRect(origin: origin, size: size))

        return context.makeImage()
    }
}
