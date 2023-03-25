//
//  ImageItems.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 25.03.2023.
//

import CoreVideo

class ImageItems {
    private let model: MaskImage
    private let images: [String]
    private let effects: Effects

    init(model: MaskImage, images: [String], effects: Effects) {
        self.model = model
        self.images = images
        self.effects = effects
    }

    func applyEffects(completion: @escaping ([CVPixelBuffer]) -> Void) {
        DispatchQueue.global().async {
            let start = Date()

//            var maxHeight
            let items: [ImageItem] = self.images.compactMap { image in
                guard let url = Bundle.main.url(forResource: image, withExtension: "jpeg") else { return nil }
                return .init(at: url)
            }

            let group = DispatchGroup()

            items.enumerated().forEach { index, item in
                group.enter()
                item.prepareMask(self.model) {
                    group.leave()
                }
            }

            group.notify(queue: .global()) {
                print("items generating time \(Date().timeIntervalSince(start))")
                let array = self.effects.apply(to: items)
                completion(array)
            }
        }
    }
}
