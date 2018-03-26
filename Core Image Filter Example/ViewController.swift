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
  var orientation = UIImageOrientation.up

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
  private func updateImage(skipThrottle: Bool = false, completion: (() -> Void)? = nil) {
    let updateFilteredImage = {
      self.sepiaImage { (image) in
        guard let cgImage = image else { return }
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: self.orientation)
        self.imageView.image = uiImage
        completion?()
      }
    }
    if skipThrottle {
      updateFilteredImage()
      return
    }
    throttleTimer?.invalidate()
    throttleTimer = Timer.scheduledTimer(withTimeInterval: max(throttleTimerLastFire.timeIntervalSinceNow + throttleInterval, 0), repeats: false) { (timer) in
      self.throttleTimerLastFire = Date(timeIntervalSinceNow: 0)
      updateFilteredImage()
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
    guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform", withInputParameters: [
        kCIInputImageKey: originalImage,
        kCIInputScaleKey: thumbnailScale,
        kCIInputAspectRatioKey: 1.0
        ]),
      let scaled = scaleFilter.outputImage
      else {
        thumbnailImage = originalImage
        return
    }
    thumbnailImage = scaled
  }
  
  var thumbnailScale: CGFloat {
    let narrowestPartOfOriginalImage = min(originalImage.extent.width, originalImage.extent.height)
    return min(view.bounds.width / narrowestPartOfOriginalImage, 1.0)
  }
  
  private func animateNewImageAspectRatio() {
    guard let aspect = imageViewAspectRatio else { return }
    imageAspectRatioConstraint.isActive = false
    imageAspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspect)
    imageAspectRatioConstraint.isActive = true
    UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseInOut, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  private var imageViewAspectRatio: CGFloat? {
    guard let size = imageView.image?.size else { return nil }
    return min(max(size.width / size.height, 2/3), 3/2)
  }
}

// MARK: UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
      orientation = image.imageOrientation
      originalImage = CIImage(image: image)
    }
    updateImage(skipThrottle: true) {
      self.dismiss(animated: true) {
        self.animateNewImageAspectRatio()
      }
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
  }
}
