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
            var array = [CVPixelBuffer]()
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!

            guard let firstUrl = Bundle.main.url(forResource: "1", withExtension: "jpeg"),
                  let image = UIImage(with: firstUrl),
                  let firstBuffer = image.pixelBuffer()
            else {
                return
            }

            array.append(firstBuffer)
            var prev = firstBuffer

            for i in 2...8 {
                guard let imageUrl = Bundle.main.url(forResource: "\(i)", withExtension: "jpeg"),
                      let image = UIImage(with: imageUrl),
                      let foreground = image.frontImageBuffer(background: prev),
                      let origin = image.pixelBuffer()
                else {
                    continue
                }
                array.append(foreground)
                array.append(origin)
                prev = origin
            }

            guard let audio = Bundle.main.url(forResource: "music", withExtension: "aac") else {
                return
            }

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

