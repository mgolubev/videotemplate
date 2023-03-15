//
//  Video.swift
//  VideoTemplate
//
//  Created by Michael Golubev on 14.03.2023.
//

import AVFoundation
import UIKit

class Video {
    static func create(
        from pixelBuffers: [CVPixelBuffer],
        soundUrl: URL,
        outputUrl: URL,
        completion: @escaping () -> Void
    ) {
        // Remove prev item
        try? FileManager.default.removeItem(at: outputUrl)

        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first else {
            return
        }
        let tempOutput = documentsUrl.appendingPathComponent("temp.mp4", conformingTo: .video)
        // Create writer for temp video without sound
        guard let videoWriter = try? AVAssetWriter(outputURL: tempOutput, fileType: AVFileType.mp4) else {
            return
        }
        // Get audio asset
        let audioAsset = AVURLAsset(url: soundUrl)

        // get size by first image
        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffers[0]), height: CVPixelBufferGetHeight(pixelBuffers[0]))
        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        // Create writer input
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoWriterInput.expectsMediaDataInRealTime = true

        // Add AVAssetWriterInput to AVAssetWriter
        videoWriter.add(videoWriterInput)

        // Adaptor to add pixel buffers
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32RGBA,
            kCVPixelBufferWidthKey as String: size.width,
            kCVPixelBufferHeightKey as String: size.height
        ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: pixelBufferAttributes)

        // Open AVAssetWriter
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: CMTime.zero)

        let secs = Double(audioAsset.duration.value) / Double(audioAsset.duration.timescale)
        let timeScale: Double = 100.0
        let itemDuration =  secs / Double(pixelBuffers.count) * timeScale
        // Add CVPixelBuffer's to video
        for i in 0..<pixelBuffers.count {
            let presentationTime = CMTimeMake(value: Int64(Double(i)*itemDuration), timescale: Int32(timeScale))
            let pixelBuffer = pixelBuffers[i]

            while !videoWriterInput.isReadyForMoreMediaData {
                usleep(10)
            }

            pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        }

        // Close AVAssetWriterInput и AVAssetWriter
        videoWriterInput.markAsFinished()
        videoWriter.finishWriting {
            // Add audio
            let videoAsset = AVURLAsset(url: tempOutput)

            let mixComposition = AVMutableComposition()
            let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

            let videoAssetTrack = videoAsset.tracks(withMediaType: .video)[0]
            let audioAssetTrack = audioAsset.tracks(withMediaType: .audio)[0]

            do {
                try videoTrack?.insertTimeRange(
                    CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                    of: videoAssetTrack,
                    at: .zero
                )

                try audioTrack?.insertTimeRange(
                    CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                    of: audioAssetTrack,
                    at: .zero
                )
            }
            catch {
                print("insert time range error \(error)")
            }

            let exportSession = AVAssetExportSession(
                asset: mixComposition,
                presetName: AVAssetExportPresetHighestQuality
            )
            exportSession?.outputFileType = .mp4
            exportSession?.outputURL = outputUrl

            exportSession?.exportAsynchronously {
                try? FileManager.default.removeItem(at: tempOutput)
                completion()
            }
        }
    }
}
