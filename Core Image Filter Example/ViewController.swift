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
  var filterIntensity: Float = 0.5
  
  var originalImageStats = (orientation: UIImageOrientation.up, scale: CGFloat(1))
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
    sepiafilter?.setValue(filterIntensity, forKey: kCIInputIntensityKey)
    guard let cgImage = sepiaImage else { return }
          let uiImage = UIImage(cgImage: cgImage, scale: self.originalImageStats.scale, orientation: self.originalImageStats.orientation)
          self.imageView.image = uiImage
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
      originalImageStats = (image.imageOrientation, image.scale)
      originalImage = CIImage(image: image)
    }
    sepiafilter?.setValue(originalImage, forKey: kCIInputImageKey)
    updateImage()
    dismiss(animated: true)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
  }
}
