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
  
  var sepiaImage: CGImage? {
    guard let outputImage = sepiafilter?.outputImage,
      let filterExtent = sepiafilter?.outputImage?.extent else { return nil }
    return context.createCGImage(outputImage, from: filterExtent)
  }
  
  @IBOutlet weak var intensitySlider: UISlider!
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let imageURL = Bundle.main.url(forResource: "image", withExtension: "png"),
      let image = CIImage(contentsOf: imageURL) else { return }
    
    self.originalImage = image
    
    sepiafilter?.setValue(originalImage, forKey: kCIInputImageKey)
    sepiafilter?.setValue(0.5, forKey: kCIInputIntensityKey)

    guard let cgImage = sepiaImage else { return }
    
    imageView.image = UIImage(cgImage: cgImage)
    
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  @IBAction func intensitySliderDidChangeValue(_ sender: UISlider) {
    sepiafilter?.setValue(sender.value, forKey: kCIInputIntensityKey)
    guard let cgImage = sepiaImage else { return }
    
    imageView.image = UIImage(cgImage: cgImage)
  }
}
