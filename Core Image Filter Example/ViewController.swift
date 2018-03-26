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
  var sepiafilter: CIFilter? = CIFilter(name: "CISepiaTone")
  var originalImage: CIImage!
  var originalScaledImage: CIImage!
  var filterIntensity: Float = 0.5
  var throttleTimer: Timer?
  var throttleTimerLastFire: Date = Date(timeIntervalSinceNow: 0)
  var throttleInterval = 0.07
  var originalImageStats = (orientation: UIImageOrientation.up, scale: CGFloat(1), size: CGSize.zero)

  @IBOutlet weak var imageAspectRatioConstraint: NSLayoutConstraint!
  var sepiaImage: CGImage? {
    guard let outputImage = sepiafilter?.outputImage,
      let filterExtent = sepiafilter?.outputImage?.extent else { return nil }
    return context.createCGImage(outputImage, from: filterExtent)
  }
  
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
      DispatchQueue.global(qos: .userInteractive).async {
        self.sepiafilter?.setValue(self.filterIntensity, forKey: kCIInputIntensityKey)
        guard let cgImage = self.sepiaImage else { return }
        DispatchQueue.main.async {
          let uiImage = UIImage(cgImage: cgImage, scale: self.originalImageStats.scale, orientation: self.originalImageStats.orientation)
          self.imageView.image = uiImage
        }
      }
    }
  }
  
  private func setupInitialView() {
    imageView.clipsToBounds = true

    guard let imageURL = Bundle.main.url(forResource: "image", withExtension: "png"),
      let image = CIImage(contentsOf: imageURL) else { return }
    self.originalImage = image
    sepiafilter?.setValue(originalImage, forKey: kCIInputImageKey)
    sepiafilter?.setValue(filterIntensity, forKey: kCIInputIntensityKey)
    guard let cgImage = sepiaImage else { return }
    imageView.image = UIImage(cgImage: cgImage)
  }
}

// MARK: UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
      originalImageStats = (image.imageOrientation, image.scale, image.size)
      originalImage = CIImage(image: image)
    }
    scaleOriginalIfNecessary()
    sepiafilter?.setValue(originalScaledImage, forKey: kCIInputImageKey)

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
  
  private func scaleOriginalIfNecessary() {
    originalScaledImage = originalImage
    let scale = max(min(Double(view.bounds.width / originalImageStats.size.width), 1.0), 0.20)
    if scale != 1 {
      let scaleFilter = CIFilter(name: "CILanczosScaleTransform")
      scaleFilter?.setValue(originalImage, forKey: kCIInputImageKey)
      scaleFilter?.setValue(scale, forKey: "inputScale")
      scaleFilter?.setValue(1.0, forKey: "inputAspectRatio")
      if let scaled = scaleFilter?.outputImage {
        originalScaledImage = scaled
      }
    }
  }
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
  }
}
