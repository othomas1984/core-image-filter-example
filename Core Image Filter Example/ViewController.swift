//
//  ViewController.swift
//  Core Image Filter Example
//
//  Created by Owen Thomas on 3/23/18.
//  Copyright © 2018 Owen Thomas. All rights reserved.
//

import UIKit
import Photos

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

  func sepiaImage(originalImage: CIImage? = nil, completion: @escaping (CGImage?) -> Void) {
    let image: CIImage! = originalImage ?? self.thumbnailImage
    guard let sepiafilter = CIFilter(name: "CISepiaTone", withInputParameters: [
      kCIInputImageKey: image,
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
  
  @IBAction func saveButtonTapped(_ sender: UIButton) {
    let spinner = blockViewWithSpinner(view: view)
    trySaveImage {
      spinner.removeFromSuperview()
    }
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
  
  private var thumbnailScale: CGFloat {
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
  
  private func blockViewWithSpinner(view: UIView) -> UIActivityIndicatorView {
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    spinner.startAnimating()
    spinner.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(spinner)
    spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    spinner.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    spinner.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    spinner.backgroundColor = UIColor(displayP3Red: 204/255, green: 204/255, blue: 204/255, alpha: 0.5)
    return spinner
  }
  
  private func trySaveImage(_ completion: @escaping () -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
      if status == .authorized {
        self.saveImage {
          completion()
        }
      } else {
        self.photosAccessError() {
          completion()
        }
      }
    }
  }
  
  private func saveImage(completion: @escaping () -> Void) {
    sepiaImage(originalImage: originalImage) { image in
      guard let image = image else { return }
      let uiImage = UIImage(cgImage: image, scale: 1, orientation: self.orientation)
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
      }, completionHandler: { (complete, error) in
        DispatchQueue.main.async {
          if let error = error {
            self.imageSaveError(error, completion: completion)
          } else {
            self.imageSaveSuccess(completion)
          }
        }
      })
    }
  }
  
  private func imageSaveSuccess(_ completion: @escaping () -> Void) {
    let ac = UIAlertController(title: "Success!", message: "The modified image has been saved to your photo library", preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    present(ac, animated: true, completion: completion)
  }
  
  private func imageSaveError(_ error: Error, completion: @escaping () -> Void) {
    let ac = UIAlertController(title: "Error Saving Image", message: error.localizedDescription, preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    present(ac, animated: true, completion: completion)
  }
  
  private func photosAccessError(_ completion: @escaping () -> Void) {
    let ac = UIAlertController(title: "Need Photos Access", message: "Please enable access to photo library in System Privacy Settings", preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    present(ac, animated: true, completion: completion)
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
