//
//  ViewController.swift
//  Core Image Filter Example
//
//  Created by Owen Thomas on 3/23/18.
//  Copyright © 2018 Owen Thomas. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var intensitySlider: UISlider!
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let imageURL = Bundle.main.url(forResource: "image", withExtension: "png"),
      let originalImage = CIImage(contentsOf: imageURL),
      let sepiaFilter = CIFilter(name: "CISepiaTone") else { return }
    
    sepiaFilter.setValue(originalImage, forKey: kCIInputImageKey)
    sepiaFilter.setValue(0.5, forKey: kCIInputIntensityKey)
    let context = CIContext(options: nil)

    guard let outputImage = sepiaFilter.outputImage,
      let filterExtent = sepiaFilter.outputImage?.extent,
      let cgImage = context.createCGImage(outputImage, from: filterExtent) else { return }
    
    imageView.image = UIImage(cgImage: cgImage)
    
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  @IBAction func intensitySliderDidChangeValue(_ sender: UISlider) {
  }
}
