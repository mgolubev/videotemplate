//
//  Effects.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 25.03.2023.
//

import Foundation
import CoreVideo
import CoreImage

protocol Effects {
    func apply(to items: [ImageItem]) -> [CVPixelBuffer]
}

class SampleImageEffects: Effects {
    let ciContext: CIContext

    init(context: CIContext) {
        self.ciContext = context
    }

    func apply(to items: [ImageItem]) -> [CVPixelBuffer] {
        var effects: [Effect] = []
        effects.append(NoEffect(item: items[0]))
        effects.append(NoEffect(item: items[0]))
        effects.append(MoveEffect(first: items[0], last: items[1], point: .init(x: 100, y: 100)))
        effects.append(CutMoveEffect(first: items[0], last: items[1], point: .init(x: 100, y: 100)))
        effects.append(NoEffect(item: items[1]))
        effects.append(ComposeEffect(first: items[1], last: items[2]))
        effects.append(NoEffect(item: items[2]))
        effects.append(ComposeEffect(first: items[2], last: items[3]))
        effects.append(BorderEffect(first: items[2], last: items[3], scale: 1.2, point: .init(x: -200, y: -380)))
        effects.append(NoEffect(item: items[3]))
        effects.append(CutEffect(first: items[3], last: items[4], angle: -.pi/180*1))
        effects.append(CutRotateEffect(first: items[3], last: items[4], angle: -.pi/180*1))
        effects.append(NoEffect(item: items[4]))
        effects.append(ComposeEffect(first: items[4], last: items[5]))
        effects.append(NoEffect(item: items[5]))
        effects.append(ScaleEffect(first: items[5], last: items[6], scale: 1.1))
        effects.append(ScaleEffect(first: items[6], last: items[6], scale: 1.1))
        effects.append(NoEffect(item: items[6]))
        effects.append(CutScaleEffect(first: items[6], last: items[7], scale: 1.1))
        effects.append(CutEffect(first: items[6], last: items[7]))
        effects.append(NoEffect(item: items[7]))
        effects.append(NoEffect(item: items[7]))

        return effects.compactMap { $0.pixelBuffer(context: ciContext) }
    }
}

protocol Effect {
    func pixelBuffer(context: CIContext) -> CVPixelBuffer?
}

class NoEffect: Effect {
    private let item: ImageItem
    init(item: ImageItem) {
        self.item = item
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        return item.ciImage.pixelBuffer(with: context, size: item.originSize)
    }
}

class MoveEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem
    private let point: CGPoint

    init(first: ImageItem, last: ImageItem, point: CGPoint) {
        self.first = first
        self.last = last
        self.point = point
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        let result = last.foregroundImage(
            with: .identity.translatedBy(x: point.x, y: point.y),
            background: first.ciImage
        )?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}

class CutMoveEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem
    private let point: CGPoint

    init(first: ImageItem, last: ImageItem, point: CGPoint) {
        self.first = first
        self.last = last
        self.point = point
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        guard let mask = last.mask else { return nil }
        let background = first.foregroundImage(with: mask, background: last.ciImage)
        let result = last.foregroundImage(
            with: .identity.translatedBy(x: point.x, y: point.y),
            background: background
        )?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}

class ComposeEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem

    init(first: ImageItem, last: ImageItem) {
        self.first = first
        self.last = last
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        let result = last.foregroundImage(
            background: first.ciImage
        )?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}

class BorderEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem
    private let scale: CGFloat
    private let point: CGPoint

    var image: CIImage?

    init(first: ImageItem, last: ImageItem, scale: CGFloat, point: CGPoint) {
        self.first = first
        self.last = last
        self.scale = scale
        self.point = point
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        guard let mask = last.mask?.applyingFilter(
            "CIMorphologyGradient",
            parameters: [kCIInputRadiusKey : 30]
        ).applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputContrastKey: 1
            ]
        ).applyingFilter(
            "CIExposureAdjust",
            parameters: [
                kCIInputEVKey: 1
            ]
        )
        else { return nil }

        let background = last.foregroundImage(
            background: first.ciImage
        )

        image = last.foregroundImage(
            with: mask.transformed(
                by: .identity.translatedBy(x: point.x, y: point.y).scaledBy(x: scale, y: scale)
            ),
            background: background
        )
        let result = image?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}

class CutEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem
    private let angle: CGFloat

    init(first: ImageItem, last: ImageItem, angle: CGFloat = 0) {
        self.first = first
        self.last = last
        self.angle = angle
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        guard let mask = last.mask else { return nil }
        let result = first.foregroundImage(
            with: mask.transformed(by: .identity.rotated(by: angle)),
            background: last.ciImage.transformed(by: .identity.rotated(by: angle))
        )?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}

class CutRotateEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem
    private let angle: CGFloat

    init(first: ImageItem, last: ImageItem, angle: CGFloat = 0) {
        self.first = first
        self.last = last
        self.angle = angle
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        guard let mask = last.mask else { return nil }
        let background = first.foregroundImage(
            with: mask.transformed(by: .identity.rotated(by: angle)),
            background: last.ciImage.transformed(by: .identity.rotated(by: angle))
        )
        let result = last.foregroundImage(
            background: background
        )?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}

class ScaleEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem
    private let scale: CGFloat

    init(first: ImageItem, last: ImageItem, scale: CGFloat) {
        self.first = first
        self.last = last
        self.scale = scale
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        let result = last.foregroundImage(
            with: .identity.scaledBy(x: scale, y: scale).translatedBy(x: -100, y: -100),
            background: first.ciImage
        )?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}

class CutScaleEffect: Effect {
    private let first: ImageItem
    private let last: ImageItem
    private let scale: CGFloat

    init(first: ImageItem, last: ImageItem, scale: CGFloat = 0) {
        self.first = first
        self.last = last
        self.scale = scale
    }

    func pixelBuffer(context: CIContext) -> CVPixelBuffer? {
        guard let mask = last.mask else { return nil }
        let result = first.foregroundImage(
            with: mask.transformed(by: .identity.scaledBy(x: scale, y: scale).translatedBy(x: -100, y: -100)),
            background: last.ciImage
        )?.pixelBuffer(with: context, size: last.originSize)
        return result
    }
}
