//
//  CIImage+Utils.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 15.03.2023.
//

import CoreImage

extension CIImage {
    func mask() -> CIImage? {
        let morphologyFilter = CIFilter(name: "CIMorphologyGradient")
        morphologyFilter?.setValue(self, forKey: kCIInputImageKey)
        morphologyFilter?.setValue(2, forKey: kCIInputRadiusKey)

        let maskToAlphaFilter = CIFilter(name: "CIMaskToAlpha")
        maskToAlphaFilter?.setValue(self, forKey: kCIInputImageKey)

        let filter = CIFilter(name: "CISourceOverCompositing")
        filter?.setValue(morphologyFilter?.outputImage, forKey: kCIInputBackgroundImageKey)
        filter?.setValue(maskToAlphaFilter?.outputImage, forKey: kCIInputImageKey)

        return filter?.outputImage
    }

    func apply(mask: CIImage, background: CIImage?) -> CIImage? {
        let filter = CIFilter(name: "CIBlendWithMask")
        filter?.setValue(self, forKey: kCIInputImageKey)
        filter?.setValue(mask, forKey: kCIInputMaskImageKey)
        if let background = background {
            filter?.setValue(background, forKey: kCIInputBackgroundImageKey)
        }
        return filter?.outputImage
    }

    enum ResizeMode {
        case fit
        case fill
    }
    func resizing(size newSize: CGSize, mode: ResizeMode = .fill) -> CIImage? {
        let scale: CGFloat
        switch mode {
        case .fit:
            scale = min(newSize.width/CGFloat(self.extent.width), newSize.height/CGFloat(self.extent.height))
        case .fill:
            scale = max(newSize.width/CGFloat(self.extent.width), newSize.height/CGFloat(self.extent.height))
        }
        let size = CGSize(width: newSize.width / scale, height: newSize.height / scale)

        let origin = CGPoint(x: (CGFloat(self.extent.width) - size.width) / 2, y: (CGFloat(self.extent.height) - size.height) / 2)
        let trasformed = self.transformed(by: .init(translationX: -origin.x, y: -origin.y))

        let resizeFilter = CIFilter(name:"CILanczosScaleTransform")
        let newScale = newSize.height / size.height
        let aspectRatio = newSize.width / (size.width * newScale)

        resizeFilter?.setValue(trasformed, forKey: kCIInputImageKey)
        resizeFilter?.setValue(newScale, forKey: kCIInputScaleKey)
        resizeFilter?.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)

        return resizeFilter?.outputImage
    }
}
