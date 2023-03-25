//
//  ViewController.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 14.03.2023.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global().async {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!

            let model = ForegroundMaskModel.shared

            let start = Date()
            let items: [ImageItem] = (0...7).compactMap { index in
                guard let url = Bundle.main.url(forResource: "\(index)", withExtension: "jpeg") else { return nil }
                return .init(at: url)
            }

            let group = DispatchGroup()

            items.enumerated().forEach { index, item in
                group.enter()
                item.prepareMask(model) {
                    group.leave()
                }
            }

            group.notify(queue: .global()) {
                print("items generating time \(Date().timeIntervalSince(start))")

                let effects = Effects(context: CIContext())
                let array = effects.apply(to: items)

                guard let audio = Bundle.main.url(forResource: "music", withExtension: "aac") else { return }

                let outputUrl = documentsUrl.appendingPathComponent("video.mp4", conformingTo: .video)
                Video.create(
                    from: array,
                    soundUrl: audio,
                    outputUrl: outputUrl
                ) {
                    DispatchQueue.main.async {
                        self.share(url: outputUrl)
                    }
                }
            }
        }
    }

    private func share(url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // Pre-configuring activity items
        activityViewController.activityItemsConfiguration = [
            UIActivity.ActivityType.message
        ] as? UIActivityItemsConfigurationReading

        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            .print,
            .assignToContact,
            .addToReadingList,
            .postToFlickr,
            .markupAsPDF
        ]

        activityViewController.isModalInPresentation = true
        present(activityViewController, animated: true)
    }
}

extension ForegroundMaskModel: MaskImage {}
