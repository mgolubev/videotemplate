//
//  ImageItem.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 25.03.2023.
//

import CoreImage

class ImageItem {
    var imageUrl: URL

    let originSize: CGSize
    let ciImage: CIImage
    var mask: CIImage?

    var transform: CGAffineTransform = .identity

    let lock = NSLock()

    init?(at imageUrl: URL) {
        self.imageUrl = imageUrl
        guard let image = CIImage(contentsOf: imageUrl) else { return nil }
        originSize = image.extent.size
        ciImage = image
    }

    func prepareMask(_ maskImage: MaskImage, completion: (() -> Void)?) {
        let image = self.ciImage
        DispatchQueue.global().async {
            let mask = maskImage.mask(from: image)
            self.lock.lock()
            self.mask = mask
            self.lock.unlock()
            completion?()
        }
    }

    func prepareMask(_ maskImage: MaskImage) -> Self {
        let image = self.ciImage
        let mask = maskImage.mask(from: image)
        self.lock.lock()
        self.mask = mask
        self.lock.unlock()
        return self
    }

    func foregroundImage(with transform: CGAffineTransform? = nil, background: CIImage? = nil) -> CIImage? {
        guard let mask = mask else { return nil }
        return ciImage.apply(mask: mask, background: background?.resizingToFill(size: originSize), transform: transform)
    }

    func foregroundImage(with otherMask: CIImage, background: CIImage? = nil) -> CIImage? {
        return ciImage.apply(mask: otherMask, background: background, transform: transform)
    }
}

protocol MaskImage {
    func mask(from source: CIImage) -> CIImage?
}
