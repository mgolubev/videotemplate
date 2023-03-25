//
//  ForegroundMaskModel.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 25.03.2023.
//

import CoreML
import CoreImage

class ForegroundMaskModel {
    static var shared = ForegroundMaskModel()

    private let square = CGSize(width: 1024, height: 1024)

    private let ciContext = CIContext()

    private lazy var blackBackground: CIImage = {
        CIImage(color: .black).cropped(to: .init(origin: .zero, size: square))
    }()

    private lazy var mlModel: MLModel? = {
        try? segmentation_8bit(configuration: .init()).model
    }()

    func mask(from source: CIImage) -> CIImage? {
        guard
            let model = mlModel,
            let resized = source.resizingToFit(size: square),
            let image = resized.addingBackground(image: blackBackground),
            let cgSource = ciContext.createCGImage(image, from: .init(origin: .zero, size: square)),
            let input = input(image: cgSource),
            let result = try? model.prediction(from: input),
            let featureName = result.featureNames.first,
            let imageBuffer = result.featureValue(for: featureName)?.imageBufferValue
        else {
            return nil
        }
        return CIImage(cvImageBuffer: imageBuffer).resizingToFill(size: source.extent.size)
    }

    private func input(image: CGImage) -> MLFeatureProvider? {
        try? segmentation_8bitInput(imgWith: image)
    }

    private init() {}
}
