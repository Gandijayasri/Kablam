//
//  UploadMediaViewController.swift
//  kablam-iOS-native-app
//
//  Created by Vamsi Thiruveedula on 17/07/25.
//

import UIKit
import MobileCoreServices
import AVFoundation

class UploadMediaViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let newProjectLabel = UILabel()
    private let selectVideoCard = SelectionCardView(
        title: "Select Video",
        iconName: "video",
        gradientColors: [
            UIColor(named: "AppButton_Pink") ?? .systemPink,
            UIColor.systemBlue
        ],
        startPoint: CGPoint(x: 0, y: 0),
        endPoint: CGPoint(x: 1, y: 1)
    )
    private let selectThumbnailCard = SelectionCardView(
        title: "Select Thumbnail",
        iconName: "photo",
        gradientColors: [
            UIColor(named: "AppButton_Pink") ?? .systemPink,
            UIColor.systemBlue
        ],
        startPoint: CGPoint(x: 0, y: 0),
        endPoint: CGPoint(x: 1, y: 1)
    )
    private let videoRecommendedLabel: UILabel = {
        let label = UILabel()
        label.text = "Recommended:\n1080p Video"
        label.textColor = UIColor(white: 1, alpha: 0.6)
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    private let thumbRecommendedLabel: UILabel = {
        let label = UILabel()
        label.text = "Recommended:\n1080px x1080px"
        label.textColor = UIColor(white: 1, alpha: 0.6)
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    private let draftsLabel = UILabel()
    private let seeAllButton = UIButton(type: .system)
    private let draftsStack = UIStackView()
    private let nextButton = GradientButton()
    private var selectedVideoURL: URL?
    private var selectedThumbnail: UIImage?
    private var uploadedDrafts: [(thumbnail: UIImage, title: String, date: String, duration: String)] = []
    private let loader = UIActivityIndicatorView(style: .large)

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "App_Blue") ?? .black
        setupScrollView()
        setupHeader()
        setupSelectionCards()
        setupDraftsSection()
        setupNextButton()
        addCardTapHandlers()
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        setupLoader()
    }

    // MARK: - Setup Methods
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        // Use safeAreaLayoutGuide for scrollView
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // Add height constraint so contentView is at least as tall as scrollView
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        ])
    }

    private func setupHeader() {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24).isActive = true
        backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 32).isActive = true

        titleLabel.text = "Upload Media"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8)
        ])

        newProjectLabel.text = "New Project"
        newProjectLabel.font = UIFont.boldSystemFont(ofSize: 16)
        newProjectLabel.textColor = .white
        newProjectLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(newProjectLabel)
        NSLayoutConstraint.activate([
            newProjectLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 64),
            newProjectLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
    }

    private func setupSelectionCards() {
        let cardsStack = UIStackView(arrangedSubviews: [selectVideoCard, selectThumbnailCard])
        cardsStack.axis = .horizontal
        cardsStack.distribution = .fillEqually
        cardsStack.spacing = 20
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardsStack)
        NSLayoutConstraint.activate([
            cardsStack.topAnchor.constraint(equalTo: newProjectLabel.bottomAnchor, constant: 24),
            cardsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardsStack.heightAnchor.constraint(equalToConstant: 140)
        ])
        // Recommended labels under each card
        videoRecommendedLabel.translatesAutoresizingMaskIntoConstraints = false
        thumbRecommendedLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(videoRecommendedLabel)
        contentView.addSubview(thumbRecommendedLabel)
        NSLayoutConstraint.activate([
            videoRecommendedLabel.topAnchor.constraint(equalTo: cardsStack.bottomAnchor, constant: 8),
            videoRecommendedLabel.leadingAnchor.constraint(equalTo: selectVideoCard.leadingAnchor, constant: 8),
            videoRecommendedLabel.widthAnchor.constraint(equalTo: selectVideoCard.widthAnchor, multiplier: 1.0),
            thumbRecommendedLabel.topAnchor.constraint(equalTo: cardsStack.bottomAnchor, constant: 8),
            thumbRecommendedLabel.leadingAnchor.constraint(equalTo: selectThumbnailCard.leadingAnchor, constant: 8),
            thumbRecommendedLabel.widthAnchor.constraint(equalTo: selectThumbnailCard.widthAnchor, multiplier: 1.0)
        ])
    }

    private func setupDraftsSection() {
        draftsLabel.text = "Drafts"
        draftsLabel.font = UIFont.boldSystemFont(ofSize: 16)
        draftsLabel.textColor = .white
        draftsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(draftsLabel)
        NSLayoutConstraint.activate([
            draftsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            draftsLabel.topAnchor.constraint(equalTo: videoRecommendedLabel.bottomAnchor, constant: 20)
        ])

        seeAllButton.setTitle("See all", for: .normal)
        seeAllButton.setTitleColor(.white, for: .normal)
        seeAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        seeAllButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(seeAllButton)
        NSLayoutConstraint.activate([
            seeAllButton.centerYAnchor.constraint(equalTo: draftsLabel.centerYAnchor),
            seeAllButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])

        draftsStack.axis = .vertical
        draftsStack.spacing = 12
        draftsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(draftsStack)
        NSLayoutConstraint.activate([
            draftsStack.topAnchor.constraint(equalTo: draftsLabel.bottomAnchor, constant: 12),
            draftsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            draftsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])

        // Demo Drafts
        // draftsStack.addArrangedSubview(DraftCardView(
        //     image: UIImage(named: "thumbnail"),
        //     title: "Demo Video",
        //     date: "06/11/2024",
        //     duration: "01:50",
        //     description: nil
        // ))
        // draftsStack.addArrangedSubview(DraftCardView(
        //     image: UIImage(named: "thumbnail"),
        //     title: "Demo Video 2",
        //     date: "02/11/2024",
        //     duration: "00:50",
        //     description: "This is a demo..."
        // ))
    }

    private func setupNextButton() {
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        nextButton.tintColor = .white
        nextButton.semanticContentAttribute = .forceRightToLeft
        contentView.addSubview(nextButton)
        NSLayoutConstraint.activate([
            nextButton.topAnchor.constraint(greaterThanOrEqualTo: draftsStack.bottomAnchor, constant: 40),
            nextButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 250),
            // Use minimum height instead of fixed height
            nextButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            // Use safe area for bottom constraint
            nextButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func addCardTapHandlers() {
        let videoTap = UITapGestureRecognizer(target: self, action: #selector(selectVideoTapped))
        selectVideoCard.isUserInteractionEnabled = true
        selectVideoCard.addGestureRecognizer(videoTap)
        let thumbTap = UITapGestureRecognizer(target: self, action: #selector(selectThumbnailTapped))
        selectThumbnailCard.isUserInteractionEnabled = true
        selectThumbnailCard.addGestureRecognizer(thumbTap)
    }

    @objc private func selectVideoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.videoQuality = .typeHigh
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @objc private func selectThumbnailTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = [kUTTypeImage as String]
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            selectedVideoURL = videoURL
        } else if let image = info[.originalImage] as? UIImage {
            selectedThumbnail = image
        }
        picker.dismiss(animated: true) {
            self.updateNextButtonState()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func updateNextButtonState() {
        if let videoURL = selectedVideoURL, let thumbnail = selectedThumbnail {
            self.addDraft(videoURL: videoURL, thumbnail: thumbnail)
        }
        let enabled = selectedVideoURL != nil && selectedThumbnail != nil
        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.5
    }

    @objc private func nextTapped() {
        guard let videoURL = selectedVideoURL, let thumbnail = selectedThumbnail else { return }
        uploadMedia(videoURL: videoURL, thumbnail: thumbnail)
    }

    private func setupLoader() {
        loader.color = .white
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func uploadMedia(videoURL: URL, thumbnail: UIImage) {
        print("🔄 Starting upload...")
        // Bring loader to front and show
        view.bringSubviewToFront(loader)
        loader.startAnimating()
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
        let url = URL(string: "https://d285u8trpbevz4.cloudfront.net/api/media/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()
        // Video
        if let videoData = try? Data(contentsOf: videoURL) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(videoURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            data.append(videoData)
            data.append("\r\n".data(using: .utf8)!)
        }
        // Thumbnail
        if let imageData = thumbnail.jpegData(compressionQuality: 0.8) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"thumbnail\"; filename=\"thumbnail.jpg\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            data.append(imageData)
            data.append("\r\n".data(using: .utf8)!)
        }
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let session = URLSession.shared
        let task = session.uploadTask(with: request, from: data) { [weak self] responseData, response, error in
            DispatchQueue.main.async {
                self?.loader.stopAnimating()
                self?.nextButton.isEnabled = true
                self?.nextButton.alpha = 1.0
                
                if let error = error {
                    print("❌ Upload failed with error: \(error.localizedDescription)")
                    self?.showAlert("Upload Failed", error.localizedDescription)
                    return
                }
                
                print("✅ Upload completed successfully!")
                print("📱 Navigation controller: \(String(describing: self?.navigationController))")
                
                // Navigate to EditorViewController with the uploaded video
                print("🚀 Navigating to EditorViewController...")
                let editorVC = EditorViewController()
                editorVC.videoURL = videoURL
                self?.present(editorVC, animated: true)
                print("✅ Navigation completed")
            }
        }
        task.resume()
    }

    private func addDraft(videoURL: URL, thumbnail: UIImage) {
        let title = videoURL.lastPathComponent
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let duration = getVideoDurationString(url: videoURL)
        uploadedDrafts.append((thumbnail, title, date, duration))
        reloadDrafts()
    }

    private func reloadDrafts() {
        for view in draftsStack.arrangedSubviews { draftsStack.removeArrangedSubview(view); view.removeFromSuperview() }
        for draft in uploadedDrafts {
            draftsStack.addArrangedSubview(DraftCardView(
                image: draft.thumbnail,
                title: draft.title,
                date: draft.date,
                duration: draft.duration,
                description: nil
            ))
        }
    }

    private func getVideoDurationString(url: URL) -> String {
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        return String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func navigateToExportScreen() {
        // After upload, navigate to EditorViewController with the uploaded video
        guard let videoURL = selectedVideoURL else { return }
        let editorVC = EditorViewController()
        editorVC.videoURL = videoURL
        navigationController?.pushViewController(editorVC, animated: true)
    }
}

// MARK: - SelectionCardView
class SelectionCardView: UIView {
    private let gradient: CAGradientLayer
    init(title: String, iconName: String, gradientColors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        self.gradient = CAGradientLayer()
        super.init(frame: .zero)
        layer.cornerRadius = 20
        layer.masksToBounds = true
        clipsToBounds = true
        gradient.colors = gradientColors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.locations = [0, 1]
        layer.insertSublayer(gradient, at: 0)

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - DraftCardView
class DraftCardView: UIView {
    init(image: UIImage?, title: String, date: String, duration: String, description: String?) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        layer.cornerRadius = 12
        // Use minimum height instead of fixed height
        heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        let descLabel = UILabel()
        descLabel.text = description ?? ""
        descLabel.textColor = .lightGray
        descLabel.font = UIFont.systemFont(ofSize: 12)
        let metaLabel = UILabel()
        metaLabel.text = "\(date)\n\(duration)"
        metaLabel.textColor = .lightGray
        metaLabel.font = UIFont.systemFont(ofSize: 11)
        metaLabel.numberOfLines = 2
        let vStack = UIStackView(arrangedSubviews: [titleLabel, descLabel, metaLabel])
        vStack.axis = .vertical
        vStack.spacing = 2
        let menuButton = UIButton(type: .system)
        menuButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        menuButton.tintColor = .white
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        let hStack = UIStackView(arrangedSubviews: [imageView, vStack, menuButton])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            menuButton.widthAnchor.constraint(equalToConstant: 32)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - GradientButton
class GradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    private func setupGradient() {
        gradientLayer.colors = [
            (UIColor(named: "AppButton_Pink") ?? .systemPink).cgColor,
            UIColor.systemPurple.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 26
        layer.insertSublayer(gradientLayer, at: 0)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

