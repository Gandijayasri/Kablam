//
//  ExportScreenViewController.swift
//  kablam-iOS-native-app
//
//  Created by Vamsi Thiruveedula on 17/07/25.
//

//import UIKit
//import AVKit
//
//class ExportScreenViewController: UIViewController {
//    var videoURL: URL?
//    
//    // UI Elements
//    private let topBar = UIView()
//    private let backButton = UIButton(type: .system)
//    private let titleLabel = UILabel()
//    private let previewImageView = UIImageView()
//    private let exportSettingLabel = UILabel()
//    private let exportSegment = UISegmentedControl(items: ["Auto", "Manual"])
//    private let exportSettingDetail = UILabel()
//    private let fileSizeLabel = UILabel()
//    private let fileSizeValue = UILabel()
//    private let exportButton = UIButton(type: .system)
//    private let bottomBar = UIView()
//    private let homeButton = UIButton(type: .system)
//    private let calendarButton = UIButton(type: .system)
//    private let savedButton = UIButton(type: .system)
//    private let settingsButton = UIButton(type: .system)
//    private let uploadButton = UIButton(type: .system)
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = UIColor(named: "App_Blue") ?? UIColor(red: 18/255, green: 15/255, blue: 34/255, alpha: 1)
//        setupTopBar()
//        setupPreview()
//        setupExportSettings()
//        setupFileSize()
//        setupExportButton()
//        setupBottomBar()
//    }
//    
//    private func setupTopBar() {
//        topBar.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(topBar)
//        NSLayoutConstraint.activate([
//            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            topBar.heightAnchor.constraint(equalToConstant: 56)
//        ])
//        // Back Button
//        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
//        backButton.tintColor = .white
//        backButton.translatesAutoresizingMaskIntoConstraints = false
//        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
//        topBar.addSubview(backButton)
//        NSLayoutConstraint.activate([
//            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 12),
//            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
//            backButton.widthAnchor.constraint(equalToConstant: 32),
//            backButton.heightAnchor.constraint(equalToConstant: 32)
//        ])
//        // Title
//        titleLabel.text = "Export"
//        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
//        titleLabel.textColor = .white
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        topBar.addSubview(titleLabel)
//        NSLayoutConstraint.activate([
//            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
//            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8)
//        ])
//    }
//    
//    private func setupPreview() {
//        previewImageView.translatesAutoresizingMaskIntoConstraints = false
//        previewImageView.contentMode = .scaleAspectFill
//        previewImageView.clipsToBounds = true
//        previewImageView.layer.cornerRadius = 20
//        previewImageView.backgroundColor = UIColor(white: 0.2, alpha: 1)
//        view.addSubview(previewImageView)
//        NSLayoutConstraint.activate([
//            previewImageView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 24),
//            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor, multiplier: 0.56)
//        ])
//        // Show video thumbnail if available
//        if let url = videoURL {
//            let asset = AVAsset(url: url)
//            let imageGenerator = AVAssetImageGenerator(asset: asset)
//            imageGenerator.appliesPreferredTrackTransform = true
//            if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
//                previewImageView.image = UIImage(cgImage: cgImage)
//            }
//        } else {
//            previewImageView.image = UIImage(systemName: "video")
//            previewImageView.tintColor = .white
//        }
//    }
//    
//    private func setupExportSettings() {
//        exportSettingLabel.text = "Export Setting"
//        exportSettingLabel.font = UIFont.boldSystemFont(ofSize: 18)
//        exportSettingLabel.textColor = .white
//        exportSettingLabel.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(exportSettingLabel)
//        NSLayoutConstraint.activate([
//            exportSettingLabel.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 32),
//            exportSettingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24)
//        ])
//        // Segmented control
//        exportSegment.selectedSegmentIndex = 0
//        exportSegment.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.boldSystemFont(ofSize: 16)], for: .selected)
//        exportSegment.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.7), .font: UIFont.systemFont(ofSize: 16)], for: .normal)
//        exportSegment.backgroundColor = UIColor(white: 0.2, alpha: 1)
//        exportSegment.selectedSegmentTintColor = UIColor(named: "AppButton_Pink") ?? .systemPink
//        exportSegment.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(exportSegment)
//        NSLayoutConstraint.activate([
//            exportSegment.centerYAnchor.constraint(equalTo: exportSettingLabel.centerYAnchor),
//            exportSegment.leadingAnchor.constraint(equalTo: exportSettingLabel.trailingAnchor, constant: 16),
//            exportSegment.widthAnchor.constraint(equalToConstant: 140),
//            exportSegment.heightAnchor.constraint(equalToConstant: 36)
//        ])
//        // Export setting detail
//        exportSettingDetail.text = "720/30fps"
//        exportSettingDetail.font = UIFont.systemFont(ofSize: 16)
//        exportSettingDetail.textColor = .white
//        exportSettingDetail.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(exportSettingDetail)
//        NSLayoutConstraint.activate([
//            exportSettingDetail.topAnchor.constraint(equalTo: exportSettingLabel.bottomAnchor, constant: 8),
//            exportSettingDetail.leadingAnchor.constraint(equalTo: exportSettingLabel.leadingAnchor)
//        ])
//    }
//    
//    private func setupFileSize() {
//        fileSizeLabel.text = "Estimated File Size"
//        fileSizeLabel.font = UIFont.boldSystemFont(ofSize: 18)
//        fileSizeLabel.textColor = .white
//        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(fileSizeLabel)
//        NSLayoutConstraint.activate([
//            fileSizeLabel.topAnchor.constraint(equalTo: exportSettingDetail.bottomAnchor, constant: 24),
//            fileSizeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24)
//        ])
//        fileSizeValue.text = "24.82 MB"
//        fileSizeValue.font = UIFont.systemFont(ofSize: 16)
//        fileSizeValue.textColor = .white
//        fileSizeValue.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(fileSizeValue)
//        NSLayoutConstraint.activate([
//            fileSizeValue.topAnchor.constraint(equalTo: fileSizeLabel.bottomAnchor, constant: 8),
//            fileSizeValue.leadingAnchor.constraint(equalTo: fileSizeLabel.leadingAnchor)
//        ])
//    }
//    
//    private func setupExportButton() {
//        exportButton.setTitle("Export", for: .normal)
//        exportButton.setTitleColor(.white, for: .normal)
//        exportButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
//        exportButton.backgroundColor = UIColor(named: "AppButton_Pink") ?? .systemPink
//        exportButton.layer.cornerRadius = 28
//        exportButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(exportButton)
//        NSLayoutConstraint.activate([
//            exportButton.topAnchor.constraint(greaterThanOrEqualTo: fileSizeValue.bottomAnchor, constant: 40),
//            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            exportButton.widthAnchor.constraint(equalToConstant: 280),
//            exportButton.heightAnchor.constraint(equalToConstant: 56),
//            exportButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120)
//        ])
//    }
//    
//    private func setupBottomBar() {
//        bottomBar.backgroundColor = UIColor(white: 0.1, alpha: 1)
//        bottomBar.layer.cornerRadius = 24
//        bottomBar.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(bottomBar)
//        NSLayoutConstraint.activate([
//            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
//            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
//            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
//            bottomBar.heightAnchor.constraint(equalToConstant: 80)
//        ])
//        // Home
//        homeButton.setImage(UIImage(systemName: "house"), for: .normal)
//        homeButton.tintColor = .white
//        homeButton.translatesAutoresizingMaskIntoConstraints = false
//        bottomBar.addSubview(homeButton)
//        // Calendar
//        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
//        calendarButton.tintColor = .white
//        calendarButton.translatesAutoresizingMaskIntoConstraints = false
//        bottomBar.addSubview(calendarButton)
//        // Saved
//        savedButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
//        savedButton.tintColor = .white
//        savedButton.translatesAutoresizingMaskIntoConstraints = false
//        bottomBar.addSubview(savedButton)
//        // Settings
//        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
//        settingsButton.tintColor = UIColor(named: "AppButton_Pink") ?? .systemPink
//        settingsButton.translatesAutoresizingMaskIntoConstraints = false
//        bottomBar.addSubview(settingsButton)
//        // Upload (floating)
//        uploadButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
//        uploadButton.tintColor = UIColor(named: "AppButton_Pink") ?? .systemPink
//        uploadButton.backgroundColor = .white
//        uploadButton.layer.cornerRadius = 32
//        uploadButton.layer.shadowColor = UIColor(named: "AppButton_Pink")?.cgColor ?? UIColor.systemPink.cgColor
//        uploadButton.layer.shadowOpacity = 0.4
//        uploadButton.layer.shadowRadius = 12
//        uploadButton.layer.shadowOffset = CGSize(width: 0, height: 4)
//        uploadButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(uploadButton)
//        // Layout tab bar icons
//        NSLayoutConstraint.activate([
//            homeButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
//            homeButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 32),
//            calendarButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
//            calendarButton.leadingAnchor.constraint(equalTo: homeButton.trailingAnchor, constant: 48),
//            savedButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
//            savedButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -48),
//            settingsButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
//            settingsButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -32),
//            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            uploadButton.centerYAnchor.constraint(equalTo: bottomBar.topAnchor),
//            uploadButton.widthAnchor.constraint(equalToConstant: 64),
//            uploadButton.heightAnchor.constraint(equalToConstant: 64)
//        ])
//    }
//    
//    @objc private func backTapped() {
//        navigationController?.popViewController(animated: true)
//    }
//}
