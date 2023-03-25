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

        let items = ImageItems(
            model: ForegroundMaskModel.shared,
            images: (0...7).map { "\($0)"},
            effects: SampleImageEffects(context: CIContext())
        )
        items.applyEffects { array in
            guard let audio = Bundle.main.url(forResource: "music", withExtension: "aac") else { return }

            guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first else { return }
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
