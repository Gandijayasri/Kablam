//
//  EditorViewController.swift
//  kablam-iOS-native-app
//
//  Created by Vamsi Thiruveedula on 17/07/25.
//


import UIKit
import AVKit
import AVFoundation
import Photos



// MARK: - StickerTrack Model
struct StickerTrack {
let image: UIImage
var startTime: Double
var duration: Double
var startPosition: CGPoint
var endPosition: CGPoint
var startScale: CGFloat
var endScale: CGFloat
var startRotation: CGFloat
var endRotation: CGFloat

// Computed properties for current state
var currentPosition: CGPoint {
return startPosition // For now, return start position
}

var currentScale: CGFloat {
return startScale // For now, return start scale
}

var currentRotation: CGFloat {
return startRotation // For now, return start rotation
}
}

class EditorViewController: UIViewController {
    var videoURL: URL?
    private var stickerTracks: [StickerTrack] = []
    private var activeStickerViews: [UIImageView] = []
    private var videoSize: CGSize = .zero
    private var timeObserver: Any?
    
    // MARK: - UI Elements
    // Top Bar
    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let aspectButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    // Video Preview
    private let videoView = UIView()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    // Timeline/Controls
    private let controlsBar = UIView()
    private let fullscreenButton = UIButton(type: .system)
    private let undoButton = UIButton(type: .system)
    private let redoButton = UIButton(type: .system)
    private let timeLabel = UILabel()
    private let playButton = UIButton(type: .system)
    // Bottom Sheet (Sticker Panel)
    private let stickerPanel = UIView()
    private let stickerTabBar = UISegmentedControl(items: ["Stickers", "GIF", "Image"])
    private let stickersLabel = UILabel()
    private let freeLabel = UILabel()
    private let premiumLabel = UILabel()
    private lazy var freeStickersCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical // <-- Set to vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        // Set itemSize as needed, for example:
        layout.itemSize = CGSize(width: 60, height: 60)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(StickerCell.self, forCellWithReuseIdentifier: "StickerCell")
        return collection
    }()
    private lazy var premiumStickersCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical // <-- Set to vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        // Set itemSize as needed, for example:
        layout.itemSize = CGSize(width: 60, height: 60)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(StickerCell.self, forCellWithReuseIdentifier: "StickerCell")
        return collection
    }()
    // Placeholder sticker data
    private var stickers: [Sticker] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "App_Blue") ?? UIColor(red: 18/255, green: 15/255, blue: 34/255, alpha: 1)
        setupTopBar()
        setupVideoView()
        setupControlsBar()
        setupStickerPanel()
        fetchStickers()
        setupPlayerIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        freeStickersCollection.setNeedsLayout()
        freeStickersCollection.layoutIfNeeded()
        freeStickersCollection.reloadData()
        print("freeStickersCollection frame:", freeStickersCollection.frame)
        print("Superview:", freeStickersCollection.superview ?? "nil")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }
    
    private func setupTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 56)
        ])
        // Back Button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        // Aspect Button
        aspectButton.setTitle("  Original ▼", for: .normal)
        aspectButton.setTitleColor(.white, for: .normal)
        aspectButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        aspectButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(aspectButton)
        NSLayoutConstraint.activate([
            aspectButton.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            aspectButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
        // Share Button
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = UIColor(named: "AppButton_Pink") ?? .systemPink
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(shareButton)
        NSLayoutConstraint.activate([
            shareButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            shareButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            shareButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            shareButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        shareButton.addTarget(self, action: #selector(handleShareTapped), for: .touchUpInside)
        
        // Update share button title to show sticker count
        updateShareButtonTitle()
    }
    
    private func setupVideoView() {
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.backgroundColor = .black
        videoView.layer.cornerRadius = 20
        videoView.clipsToBounds = true
        view.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            videoView.heightAnchor.constraint(equalTo: videoView.widthAnchor, multiplier: 0.75)
        ])
    }
    
    private func setupPlayerIfNeeded() {
        guard let url = videoURL else { return }
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspect
        if let playerLayer = playerLayer {
            videoView.layer.addSublayer(playerLayer)
        }
        
        // Configure player for looping
        player?.actionAtItemEnd = .none
        
        // Add time observer for updating time label
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateTimeLabel(currentTime: time)
        }
        
        // Add notification for when video ends
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        player?.play()
        
        // Get video size for sticker constraints
        let asset = AVAsset(url: url)
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            videoSize = videoTrack.naturalSize
        }
        
        // Update initial time label
        updateTimeLabel(currentTime: .zero)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    private func setupControlsBar() {
        controlsBar.translatesAutoresizingMaskIntoConstraints = false
        controlsBar.backgroundColor = .clear
        view.addSubview(controlsBar)
        NSLayoutConstraint.activate([
            controlsBar.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 8),
            controlsBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlsBar.heightAnchor.constraint(equalToConstant: 48)
        ])
        // Fullscreen
        fullscreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        fullscreenButton.tintColor = .white
        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullscreenButton.addTarget(self, action: #selector(handleFullscreenTapped), for: .touchUpInside)
        controlsBar.addSubview(fullscreenButton)
        NSLayoutConstraint.activate([
            fullscreenButton.leadingAnchor.constraint(equalTo: controlsBar.leadingAnchor),
            fullscreenButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            fullscreenButton.widthAnchor.constraint(equalToConstant: 36),
            fullscreenButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        // Undo
        undoButton.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        undoButton.tintColor = .white
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        controlsBar.addSubview(undoButton)
        NSLayoutConstraint.activate([
            undoButton.leadingAnchor.constraint(equalTo: fullscreenButton.trailingAnchor, constant: 24),
            undoButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            undoButton.widthAnchor.constraint(equalToConstant: 36),
            undoButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        // Play button
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(handlePlayButtonTapped), for: .touchUpInside)
        controlsBar.addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.trailingAnchor.constraint(equalTo: controlsBar.trailingAnchor),
            playButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 36),
            playButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        // Redo
        redoButton.setImage(UIImage(systemName: "arrow.uturn.forward"), for: .normal)
        redoButton.tintColor = .white
        redoButton.translatesAutoresizingMaskIntoConstraints = false
        controlsBar.addSubview(redoButton)
        NSLayoutConstraint.activate([
            redoButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -24),
            redoButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor),
            redoButton.widthAnchor.constraint(equalToConstant: 36),
            redoButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        // Time label
        timeLabel.text = "00:06 / 00:12"
        timeLabel.textColor = .white
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsBar.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: controlsBar.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor)
        ])
    }
    
    private func setupStickerPanel() {
        stickerPanel.translatesAutoresizingMaskIntoConstraints = false
        stickerPanel.backgroundColor = UIColor(white: 0.1, alpha: 0.98)
        stickerPanel.layer.cornerRadius = 24
        view.addSubview(stickerPanel)
        NSLayoutConstraint.activate([
            stickerPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickerPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickerPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stickerPanel.heightAnchor.constraint(equalToConstant: 320)
        ])
        // Tabs
        stickerTabBar.selectedSegmentIndex = 0
        stickerTabBar.setTitleTextAttributes([.foregroundColor: UIColor(named: "AppButton_Pink") ?? .systemPink, .font: UIFont.boldSystemFont(ofSize: 16)], for: .selected)
        stickerTabBar.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.7), .font: UIFont.systemFont(ofSize: 16)], for: .normal)
        stickerTabBar.translatesAutoresizingMaskIntoConstraints = false
        stickerPanel.addSubview(stickerTabBar)
        NSLayoutConstraint.activate([
            stickerTabBar.topAnchor.constraint(equalTo: stickerPanel.topAnchor, constant: 16),
            stickerTabBar.centerXAnchor.constraint(equalTo: stickerPanel.centerXAnchor),
            stickerTabBar.widthAnchor.constraint(equalToConstant: 260),
            stickerTabBar.heightAnchor.constraint(equalToConstant: 36)
        ])
        // Stickers label
        stickersLabel.text = "STICKERS"
        stickersLabel.textColor = UIColor(named: "AppButton_Pink") ?? .systemPink
        stickersLabel.font = UIFont.boldSystemFont(ofSize: 16)
        stickersLabel.textAlignment = .center
        stickersLabel.translatesAutoresizingMaskIntoConstraints = false
        stickerPanel.addSubview(stickersLabel)
        NSLayoutConstraint.activate([
            stickersLabel.topAnchor.constraint(equalTo: stickerTabBar.bottomAnchor, constant: 8),
            stickersLabel.centerXAnchor.constraint(equalTo: stickerPanel.centerXAnchor)
        ])
        // Add both collection views to the sticker panel
        stickerPanel.addSubview(freeStickersCollection)
        stickerPanel.addSubview(premiumStickersCollection)
        freeStickersCollection.translatesAutoresizingMaskIntoConstraints = false
        premiumStickersCollection.translatesAutoresizingMaskIntoConstraints = false

        // Set vertical scrolling for both collections
        if let freeLayout = freeStickersCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            freeLayout.scrollDirection = .vertical
        }
        if let premiumLayout = premiumStickersCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            premiumLayout.scrollDirection = .vertical
        }

        // Update constraints for vertical layout
        NSLayoutConstraint.activate([
            freeStickersCollection.topAnchor.constraint(equalTo: stickersLabel.bottomAnchor, constant: 16),
            freeStickersCollection.leadingAnchor.constraint(equalTo: stickerPanel.leadingAnchor, constant: 16),
            freeStickersCollection.trailingAnchor.constraint(equalTo: stickerPanel.trailingAnchor, constant: -16),
            freeStickersCollection.heightAnchor.constraint(equalToConstant: 140), // Adjust as needed

            premiumStickersCollection.topAnchor.constraint(equalTo: freeStickersCollection.bottomAnchor, constant: 16),
            premiumStickersCollection.leadingAnchor.constraint(equalTo: stickerPanel.leadingAnchor, constant: 16),
            premiumStickersCollection.trailingAnchor.constraint(equalTo: stickerPanel.trailingAnchor, constant: -16),
            premiumStickersCollection.heightAnchor.constraint(equalToConstant: 140), // Adjust as needed
            premiumStickersCollection.bottomAnchor.constraint(equalTo: stickerPanel.bottomAnchor, constant: -16)
        ])

        stickerPanel.bringSubviewToFront(freeStickersCollection)
    }
    
    private func fetchStickers() {
        let baseUrl = "https://d285u8trpbevz4.cloudfront.net/api/stickers"
        let bearerToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiMzExZDFmM2ZhMzdhM2QwNDA3ZmJmYTgwZTllNmNkYmE3ZTYzNWU2YTY3ZjJiMjgxZmYwOGY5ZDM0ZGUwNzA3NWE5YjIxZDA4N2YyYjcyNDMiLCJpYXQiOjE3NTIyMjg1NDIuNzYwNTUyLCJuYmYiOjE3NTIyMjg1NDIuNzYwNTU4LCJleHAiOjE3ODM3NjQ1NDIuNzUyMTMsInN1YiI6IjM5Iiwic2NvcGVzIjpbXX0.G5GR3cd2-RCxml34KcmrnJpPH33TZEbYFxBHgQhFO8zParnAYSPnWgRbRofa2OkOk8s5Cy4c75zwEEoHF7-1_OxpQdViued_f0W5oiFIW-RlnNSmk8Dc_a5F_ZbQC_mpiRp6JjosuWMahXBpK-tsQ3PfxsNrJ0jJ3jMlTFS3SHjuU7rKmkEB4lPHWmZCfRKgJMMKONX-Nn3TlqT8SPqTZPEv3fjFTSpHtPoVPlO7aw0B3yBmTh8D4b2ynpIe5Jp3-xtjn42TYz1d03BoAtPevDZuzWczJj81Do8qiuetfWkFpFt7eGLjAv5n1SVYvpXM-aD1a7p0xuF9pFxqAmVI0VneBjRkkujtJBxgJcubhnxo7Sgt6GGr8ciTlPSuXt6OLUWHgwQ-Om0ocaFj19xgrkixL-0FgsLMzTzEd_qh6xgUr6emuUdgWp8c-EEmJ2o6aEs2mTbVDHiPLx0aQsV_2-XXLQdyswB0wrd6slUxB2hV5llR_MuZ-Cp8oaBaf41gjTJxp0k7SxfbA03FkjOoDeHb31qzXKWR7PPdOZ25HdfMJJ7Nbyesy2Px2cy6qrFqvgG20mQxtI2AjGDMPr8KnsCb-k6taOmcpB0-zLvox3qr6HtIpctLay7iH6gY1kbJ2AabBHbRqgzu_mbFQfWcacKcYOb-VZXfrkLUQLUnh3M"
        guard let url = URL(string: baseUrl) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let data = data {
                print("Raw JSON response:\n", String(data: data, encoding: .utf8) ?? "No data string")
                do {
                    let decodeData = try JSONDecoder().decode([Sticker].self, from: data)
                    DispatchQueue.main.async {
                        print("Decoded stickers:", decodeData)
                        self?.stickers = decodeData
                        self?.freeStickersCollection.reloadData()
                    }
                } catch {
                    print("Decoding error:", error.localizedDescription)
                }
            }
        }.resume()
    }

    private func addDraggableSticker(image: UIImage) {
        let stickerImageView = UIImageView(image: image)
        stickerImageView.isUserInteractionEnabled = true
        stickerImageView.frame = CGRect(x: videoView.bounds.midX - 40, y: videoView.bounds.midY - 40, width: 80, height: 80)
        stickerImageView.contentMode = .scaleAspectFit

        // Add pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleStickerPan(_:)))
        stickerImageView.addGestureRecognizer(panGesture)
        
        // Add pinch gesture for scaling
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleStickerPinch(_:)))
        stickerImageView.addGestureRecognizer(pinchGesture)
        
        // Add rotation gesture
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleStickerRotation(_:)))
        stickerImageView.addGestureRecognizer(rotationGesture)
        
        // Add long press gesture for deletion
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleStickerLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        stickerImageView.addGestureRecognizer(longPressGesture)

        videoView.addSubview(stickerImageView)
        activeStickerViews.append(stickerImageView)
        
        // Create and store sticker track
        let stickerTrack = StickerTrack(
            image: image,
            startTime: 0.0,
            duration: 10.0, // Default duration
            startPosition: stickerImageView.center,
            endPosition: stickerImageView.center,
            startScale: 1.0,
            endScale: 1.0,
            startRotation: 0.0,
            endRotation: 0.0
        )
        stickerTracks.append(stickerTrack)
        updateShareButtonTitle()
    }
    
    private func updateShareButtonTitle() {
        let stickerCount = stickerTracks.count
        if stickerCount > 0 {
            shareButton.setTitle("Export (\(stickerCount))", for: .normal)
            shareButton.tintColor = UIColor.black
            shareButton.setImage(nil, for: .normal) // Clear any existing image
            shareButton.titleLabel?.textColor = UIColor.black
            shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            shareButton.backgroundColor = UIColor(named: "AppButton_Pink") ?? .systemPink
            shareButton.layer.cornerRadius = 16
        } else {
            shareButton.setTitle("", for: .normal) // Clear any existing title
            shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
            shareButton.backgroundColor = .clear
            shareButton.layer.cornerRadius = 0
        }
    }
    
    @objc private func handleStickerLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let stickerView = gesture.view as? UIImageView else { return }
        
        let alert = UIAlertController(title: "Remove Sticker", message: "Do you want to remove this sticker?", preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.removeSticker(stickerView)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(removeAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func removeSticker(_ stickerView: UIImageView) {
        if let index = activeStickerViews.firstIndex(of: stickerView) {
            activeStickerViews.remove(at: index)
            stickerTracks.remove(at: index)
            stickerView.removeFromSuperview()
            updateShareButtonTitle()
        }
    }
    
    private func clearAllStickers() {
        for stickerView in activeStickerViews {
            stickerView.removeFromSuperview()
        }
        activeStickerViews.removeAll()
        stickerTracks.removeAll()
        updateShareButtonTitle()
    }
    
    // MARK: - Video Player Methods
    
    @objc private func handlePlayButtonTapped() {
        if player?.timeControlStatus == .playing {
            player?.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player?.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    @objc private func playerItemDidReachEnd() {
        // Loop the video
        player?.seek(to: .zero)
        player?.play()
    }
    
    private func updateTimeLabel(currentTime: CMTime) {
        guard let player = player else { return }
        
        let currentSeconds = currentTime.seconds
        let totalSeconds = player.currentItem?.duration.seconds ?? 0
        
        // Validate time values before formatting
        guard !currentSeconds.isNaN && !currentSeconds.isInfinite,
              !totalSeconds.isNaN && !totalSeconds.isInfinite else {
            timeLabel.text = "00:00 / 00:00"
            return
        }
        
        let currentTimeString = formatTime(seconds: currentSeconds)
        let totalTimeString = formatTime(seconds: totalSeconds)
        
        timeLabel.text = "\(currentTimeString) / \(totalTimeString)"
    }
    
    private func formatTime(seconds: Double) -> String {
        // Validate the input to prevent crashes
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else {
            return "00:00"
        }
        
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    @objc private func handleFullscreenTapped() {
        // Toggle fullscreen mode
        if isFullscreen {
            exitFullscreen()
        } else {
            enterFullscreen()
        }
    }
    
    private var isFullscreen = false
    
    private func enterFullscreen() {
        isFullscreen = true
        fullscreenButton.setImage(UIImage(systemName: "arrow.down.right.and.arrow.up.left"), for: .normal)
        
        // Hide other UI elements
        topBar.isHidden = true
        controlsBar.isHidden = true
        stickerPanel.isHidden = true
        
        // Expand video view
        UIView.animate(withDuration: 0.3) {
            self.videoView.frame = self.view.bounds
            self.playerLayer?.frame = self.videoView.bounds
        }
    }
    
    private func exitFullscreen() {
        isFullscreen = false
        fullscreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        
        // Show other UI elements
        topBar.isHidden = false
        controlsBar.isHidden = false
        stickerPanel.isHidden = false
        
        // Restore video view
        UIView.animate(withDuration: 0.3) {
            self.videoView.frame = CGRect(x: 16, y: self.topBar.frame.maxY + 8, width: self.view.bounds.width - 32, height: (self.view.bounds.width - 32) * 0.75)
            self.playerLayer?.frame = self.videoView.bounds
        }
    }
    
    // MARK: - Animation Methods
    
    private func setStickerAnimation(for stickerView: UIImageView, endPosition: CGPoint, endScale: CGFloat, endRotation: CGFloat, duration: Double) {
        guard let index = activeStickerViews.firstIndex(of: stickerView) else { return }
        
        stickerTracks[index].endPosition = endPosition
        stickerTracks[index].endScale = endScale
        stickerTracks[index].endRotation = endRotation
        stickerTracks[index].duration = duration
        
        // Animate the sticker view
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            stickerView.center = endPosition
            stickerView.transform = CGAffineTransform(scaleX: endScale, y: endScale).rotated(by: endRotation)
        })
    }
    
    private func createAnimatedSticker(image: UIImage, startPosition: CGPoint, endPosition: CGPoint, duration: Double) {
        let stickerImageView = UIImageView(image: image)
        stickerImageView.isUserInteractionEnabled = true
        stickerImageView.frame = CGRect(x: startPosition.x - 40, y: startPosition.y - 40, width: 80, height: 80)
        stickerImageView.contentMode = .scaleAspectFit
        
        // Add gestures
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleStickerPan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleStickerPinch(_:)))
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleStickerRotation(_:)))
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleStickerLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        
        stickerImageView.addGestureRecognizer(panGesture)
        stickerImageView.addGestureRecognizer(pinchGesture)
        stickerImageView.addGestureRecognizer(rotationGesture)
        stickerImageView.addGestureRecognizer(longPressGesture)
        
        videoView.addSubview(stickerImageView)
        activeStickerViews.append(stickerImageView)
        
        // Create animated sticker track
        let stickerTrack = StickerTrack(
            image: image,
            startTime: 0.0,
            duration: duration,
            startPosition: startPosition,
            endPosition: endPosition,
            startScale: 1.0,
            endScale: 1.0,
            startRotation: 0.0,
            endRotation: 0.0
        )
        stickerTracks.append(stickerTrack)
        updateShareButtonTitle()
        
        // Start animation
        setStickerAnimation(for: stickerImageView, endPosition: endPosition, endScale: 1.0, endRotation: 0.0, duration: duration)
    }

    @objc private func handleStickerPan(_ gesture: UIPanGestureRecognizer) {
        guard let stickerView = gesture.view else { return }
        
        switch gesture.state {
        case .began:
            // Add visual feedback when dragging starts
            UIView.animate(withDuration: 0.1) {
                stickerView.alpha = 0.8
                stickerView.transform = stickerView.transform.scaledBy(x: 1.05, y: 1.05)
            }
            
        case .changed:
            let translation = gesture.translation(in: videoView)
            
            // Calculate new position
            let newCenter = CGPoint(x: stickerView.center.x + translation.x, y: stickerView.center.y + translation.y)
            
            // Constrain to video bounds
            let constrainedCenter = constrainPointToVideoBounds(newCenter, for: stickerView)
            stickerView.center = constrainedCenter
            
            // Update sticker track position
            if let stickerView = stickerView as? UIImageView,
               let index = activeStickerViews.firstIndex(of: stickerView) {
                stickerTracks[index].startPosition = constrainedCenter
                stickerTracks[index].endPosition = constrainedCenter
            }
            
            gesture.setTranslation(.zero, in: videoView)
            
        case .ended, .cancelled:
            // Restore normal appearance when dragging ends
            UIView.animate(withDuration: 0.1) {
                stickerView.alpha = 1.0
                stickerView.transform = stickerView.transform.scaledBy(x: 1.0/1.05, y: 1.0/1.05)
            }
            
        default:
            break
        }
    }
    
    @objc private func handleStickerPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let stickerView = gesture.view else { return }
        
        let scale = gesture.scale
        let newScale = stickerView.transform.a * scale
        
        // Constrain scale between 0.1 and 3.0
        let constrainedScale = max(0.1, min(3.0, newScale))
        stickerView.transform = CGAffineTransform(scaleX: constrainedScale, y: constrainedScale)
        
        // Update sticker track scale
        if let stickerView = stickerView as? UIImageView,
           let index = activeStickerViews.firstIndex(of: stickerView) {
            stickerTracks[index].startScale = constrainedScale
            stickerTracks[index].endScale = constrainedScale
        }
        
        gesture.scale = 1.0
    }
    
    @objc private func handleStickerRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let stickerView = gesture.view else { return }
        
        let rotation = gesture.rotation
        let newRotation = stickerView.transform.b + rotation
        
        stickerView.transform = CGAffineTransform(rotationAngle: newRotation)
        
        // Update sticker track rotation
        if let stickerView = stickerView as? UIImageView,
           let index = activeStickerViews.firstIndex(of: stickerView) {
            stickerTracks[index].startRotation = newRotation
            stickerTracks[index].endRotation = newRotation
        }
        
        gesture.rotation = 0.0
    }
    
    private func constrainPointToVideoBounds(_ point: CGPoint, for stickerView: UIView) -> CGPoint {
        let videoBounds = videoView.bounds
        
        // Account for the sticker's current transform (scale and rotation)
        let transformedBounds = stickerView.bounds.applying(stickerView.transform)
        let scaledWidth = transformedBounds.width
        let scaledHeight = transformedBounds.height
        
        let minX = scaledWidth / 2
        let maxX = videoBounds.width - scaledWidth / 2
        let minY = scaledHeight / 2
        let maxY = videoBounds.height - scaledHeight / 2
        
        let constrainedX = max(minX, min(maxX, point.x))
        let constrainedY = max(minY, min(maxY, point.y))
        
        return CGPoint(x: constrainedX, y: constrainedY)
    }

    @objc private func handleShareTapped() {
        print("Share button tapped")
        
        // Check if we have stickers to export
        if stickerTracks.isEmpty {
            let alert = UIAlertController(title: "No Stickers", message: "Add some stickers to your video before exporting.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            present(alert, animated: true)
            return
        }
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Exporting Video", message: "Please wait while we export your video with stickers...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Export video with stickers
        renderVideoWithStickers { [weak self] outputURL in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    if let outputURL = outputURL {
                        // Show success and navigate to timeline
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("Presenting TimelineViewViewController with rendered video")
                            let timelineVC = TimelineViewViewController()
                            timelineVC.videoURL = outputURL
                            self?.present(timelineVC, animated: true)
                        }
                    } else {
                        // Show error
                        self?.showExportError()
                    }
                }
            }
        }
    }

    
    private func showExportError() {
        let alert = UIAlertController(title: "Export Failed", message: "Failed to export video. Please try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    

        func renderVideoWithStickers(completion: @escaping (URL?) -> Void) {
        // Stop video playback first
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        
        // Always use the safe method - just copy the video for now
        // We'll add sticker functionality later once we have a stable foundation
        renderVideoWithoutStickers(completion: completion)
    }
            
    
    // Most basic export - just the original video
    private func renderVideoWithoutStickers(completion: @escaping (URL?) -> Void) {
        guard let _ = self.videoURL else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        // Try AVAssetWriter approach which is more stable
        renderVideoWithAVAssetWriter(completion: completion)
    }
    
    // Use AVAssetWriter for more stable video processing
    private func renderVideoWithAVAssetWriter(completion: @escaping (URL?) -> Void) {
        guard let videoURL = self.videoURL else {
                completion(nil)
                return
            }

            let asset = AVAsset(url: videoURL)
            let composition = AVMutableComposition()
            
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                completion(nil)
                return
            }
            
            // Video time range
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            // Add video track to composition
            guard let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                completion(nil)
                return
            }

            try? compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform

            // Create video composition
            let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            let renderSize = CGSize(width: abs(videoSize.width), height: abs(videoSize.height))
            
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = renderSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

            // Parent layer for rendering
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: renderSize)
            videoLayer.frame = parentLayer.frame
            parentLayer.addSublayer(videoLayer)

            // Add stickers
            for sticker in stickerTracks {
                let stickerLayer = CALayer()
                stickerLayer.contents = sticker.image.cgImage
                stickerLayer.frame = CGRect(
                    origin: sticker.startPosition,
                    size: CGSize(width: 100, height: 100) // Adjust as needed
                )
                stickerLayer.opacity = 1.0
                stickerLayer.masksToBounds = true

                // Optional animation (if using startTime/duration)
                let start = CMTime(seconds: sticker.startTime, preferredTimescale: 600)
                let duration = CMTime(seconds: sticker.duration, preferredTimescale: 600)
                
                let fadeIn = CABasicAnimation(keyPath: "opacity")
                fadeIn.fromValue = 0
                fadeIn.toValue = 1
                fadeIn.beginTime = AVCoreAnimationBeginTimeAtZero + start.seconds
                fadeIn.duration = 0.1
                fadeIn.isRemovedOnCompletion = false
                fadeIn.fillMode = .forwards
                stickerLayer.add(fadeIn, forKey: "fadeIn")

                parentLayer.addSublayer(stickerLayer)
            }

            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                postProcessingAsVideoLayer: videoLayer,
                in: parentLayer
            )

            // Instruction
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = timeRange

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]

            // Export
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("rendered-\(UUID().uuidString).mp4")
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(at: outputURL)
            }

            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                completion(nil)
                return
            }

            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.videoComposition = videoComposition
            exportSession.shouldOptimizeForNetworkUse = true

            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("Export complete: \(outputURL)")
                    DispatchQueue.main.async { completion(outputURL) }
                case .failed, .cancelled:
                    print("Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async { completion(nil) }
                default:
                    break
                }
            }
    }
    
    
 
}

// MARK: - StickerCell
class StickerCell: UICollectionViewCell {
    let imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension EditorViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt called for index:", indexPath.item)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCell", for: indexPath) as! StickerCell
        let sticker = stickers[indexPath.item]
        let fullURL = sticker.url.hasPrefix("/") ? "https://d285u8trpbevz4.cloudfront.net\(sticker.url)" : sticker.url
        cell.imageView.image = nil
        if let url = URL(string: fullURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let currentCell = collectionView.cellForItem(at: indexPath) as? StickerCell {
                            currentCell.imageView.image = image
                        }
                    }
                }
            }.resume()
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sticker = stickers[indexPath.item]
        let fullURL = sticker.url.hasPrefix("/") ? "https://d285u8trpbevz4.cloudfront.net\(sticker.url)" : sticker.url
        // Download the image
        if let url = URL(string: fullURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self = self, let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    // Show options for static or animated sticker
                    self.showStickerOptions(image: image)
                }
            }.resume()
        }
    }
    
    private func showStickerOptions(image: UIImage) {
        let alert = UIAlertController(title: "Add Sticker", message: "Choose how to add the sticker", preferredStyle: .actionSheet)
        
        let staticAction = UIAlertAction(title: "Static Sticker", style: .default) { _ in
            self.addDraggableSticker(image: image)
        }
        
        let animatedAction = UIAlertAction(title: "Animated Sticker", style: .default) { _ in
            self.addAnimatedSticker(image: image)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(staticAction)
        alert.addAction(animatedAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func addAnimatedSticker(image: UIImage) {
        // Create animated sticker with a simple animation
        let startPosition = CGPoint(x: videoView.bounds.minX + 50, y: videoView.bounds.midY)
        let endPosition = CGPoint(x: videoView.bounds.maxX - 50, y: videoView.bounds.midY)
        let duration = 3.0
        
        createAnimatedSticker(image: image, startPosition: startPosition, endPosition: endPosition, duration: duration)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 56, height: 56)
    }
}
