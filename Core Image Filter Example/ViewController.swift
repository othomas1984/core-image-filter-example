//
//  ViewController.swift
//  Core Image Filter Example
//
//  Created by Owen Thomas on 3/23/18.
//  Copyright © 2018 Owen Thomas. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  var context: CIContext = CIContext(options: nil)
  var originalImage: CIImage! {
    didSet {
      createThumbnail()
    }
  }
  var thumbnailImage: CIImage!
  var filterIntensity: Float = 0.5
  var throttleTimer: Timer?
  var throttleTimerLastFire: Date = Date(timeIntervalSinceNow: 0)
  var throttleInterval = 0.07
  var originalImageStats = (orientation: UIImageOrientation.up, scale: CGFloat(1), size: CGSize.zero)

  func sepiaImage(completion: @escaping (CGImage?) -> Void) {
    guard let sepiafilter = CIFilter(name: "CISepiaTone", withInputParameters: [
      kCIInputImageKey: thumbnailImage,
      kCIInputIntensityKey: filterIntensity]),
      let outputImage = sepiafilter.outputImage,
      let filterExtent = sepiafilter.outputImage?.extent else { completion(nil); return }
    DispatchQueue.global(qos: .userInteractive).async {
      let image = self.context.createCGImage(outputImage, from: filterExtent)
      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
  
  @IBOutlet weak var imageAspectRatioConstraint: NSLayoutConstraint!
  @IBOutlet weak var intensitySlider: UISlider!
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupInitialView()
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}

// MARK: Actions
extension ViewController {
  @IBAction func intensitySliderDidChangeValue(_ sender: UISlider) {
    filterIntensity = sender.value
    updateImage()
  }
  @IBAction func photoAlbumButtonTapped(_ sender: UIButton) {
    let imagePickerVC = UIImagePickerController()
    imagePickerVC.delegate = self
    present(imagePickerVC, animated: true)
  }
}

// MARK: Private
extension ViewController {
  private func updateImage() {
    throttleTimer?.invalidate()
    throttleTimer = Timer.scheduledTimer(withTimeInterval: max(throttleTimerLastFire.timeIntervalSinceNow + throttleInterval, 0), repeats: false) { (timer) in
      self.throttleTimerLastFire = Date(timeIntervalSinceNow: 0)
      self.sepiaImage { (image) in
        guard let cgImage = image else { return }
        let uiImage = UIImage(cgImage: cgImage, scale: self.originalImageStats.scale, orientation: self.originalImageStats.orientation)
        self.imageView.image = uiImage
      }
    }
  }
  
  private func setupInitialView() {
    imageView.clipsToBounds = true
    guard let imageURL = Bundle.main.url(forResource: "image", withExtension: "png"),
      let image = CIImage(contentsOf: imageURL) else { return }
    originalImage = image
    updateImage()
  }
  
  private func createThumbnail() {
    let scale = max(min(Double(view.bounds.width / originalImageStats.size.width), 1.0), 0.20)
    guard scale != 1,
      let scaleFilter = CIFilter(name: "CILanczosScaleTransform", withInputParameters: [
        kCIInputImageKey: originalImage,
        kCIInputScaleKey: scale,
        kCIInputAspectRatioKey: 1.0
        ]),
      let scaled = scaleFilter.outputImage
      else {
        thumbnailImage = originalImage
        return
    }
    thumbnailImage = scaled
  }
}

// MARK: UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
      originalImageStats = (image.imageOrientation, image.scale, image.size)
      originalImage = CIImage(image: image)
    }
    updateImage()
    dismiss(animated: true) {
      self.animateNewImageAspectRatio()
    }
  }
  
  private func animateNewImageAspectRatio() {
    let imageAspectMultiplier = min(max(originalImageStats.size.width / originalImageStats.size.height, 2/3), 3/2)
    imageAspectRatioConstraint.isActive = false
    imageAspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: imageAspectMultiplier)
    imageAspectRatioConstraint.isActive = true
    UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseInOut, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
  }
}
