//
//  TimelineViewViewController.swift
//  kablam-iOS-native-app
//
//  Created by Vamsi Thiruveedula on 18/07/25.
//

import UIKit
import AVFoundation
import AVKit

class TimelineViewViewController: UIViewController {

    var videoURL: URL?
    var stickerTracks: [StickerTrack] = []

    private var videoDuration: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Show the video
        if let videoURL = videoURL {
            let asset = AVAsset(url: videoURL)
            videoDuration = asset.duration.seconds

            let player = AVPlayer(url: videoURL)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = CGRect(x: 0, y: 100, width: view.bounds.width, height: 300)
            view.layer.addSublayer(playerLayer)
            player.play()
        }

        // Add the timeline view below the video
        let timelineView = TimelineBarView(
            frame: CGRect(x: 16, y: 420, width: view.bounds.width - 32, height: 80),
            duration: videoDuration,
            stickerTracks: stickerTracks
        )
        timelineView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        timelineView.layer.cornerRadius = 12
        view.addSubview(timelineView)
    }
}

// MARK: - TimelineBarView

class TimelineBarView: UIView {
    let duration: Double
    let stickerTracks: [StickerTrack]

    init(frame: CGRect, duration: Double, stickerTracks: [StickerTrack]) {
        self.duration = duration
        self.stickerTracks = stickerTracks
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard duration > 0 else { return }
        let context = UIGraphicsGetCurrentContext()

        // Draw timeline base
        let timelineY = rect.height / 2
        context?.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context?.setLineWidth(4)
        context?.move(to: CGPoint(x: 0, y: timelineY))
        context?.addLine(to: CGPoint(x: rect.width, y: timelineY))
        context?.strokePath()

        // Draw time markers (every 5s)
        let markerInterval: Double = 5
        let markerCount = Int(duration / markerInterval) + 1
        let markerColor = UIColor.white.withAlphaComponent(0.7)
        let labelFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        for i in 0..<markerCount {
            let t = Double(i) * markerInterval
            let x = CGFloat(t / duration) * rect.width
            // Marker line
            context?.setStrokeColor(markerColor.cgColor)
            context?.setLineWidth(2)
            context?.move(to: CGPoint(x: x, y: timelineY - 10))
            context?.addLine(to: CGPoint(x: x, y: timelineY + 10))
            context?.strokePath()
            // Label
            let label = "\(Int(t))s"
            let attr = NSAttributedString(string: label, attributes: [.font: labelFont, .foregroundColor: markerColor])
            attr.draw(at: CGPoint(x: x - 10, y: timelineY + 14))
        }

        // Draw sticker tracks
        for track in stickerTracks {
            let startX = CGFloat(track.startTime / duration) * rect.width
            let endX = CGFloat((track.startTime + track.duration) / duration) * rect.width
            let barRect = CGRect(x: startX, y: timelineY - 16, width: max(endX - startX, 24), height: 32)
            let barColor = UIColor.systemBlue.withAlphaComponent(0.7)
            context?.setFillColor(barColor.cgColor)
            context?.fill(barRect)

            // Draw sticker icon
            let iconRect = CGRect(x: startX, y: timelineY - 32, width: 32, height: 32)
            track.image.draw(in: iconRect)
        }
    }
}

