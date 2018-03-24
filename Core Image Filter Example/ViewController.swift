//
//  ViewController.swift
//  Core Image Filter Example
//
//  Created by Owen Thomas on 3/23/18.
//  Copyright © 2018 Owen Thomas. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var imageView: UIImageView!
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let imageURL = Bundle.main.url(forResource: "image", withExtension: "png"),
      let originalImage = CIImage(contentsOf: imageURL),
      let sepiaFilter = CIFilter(name: "CISepiaTone") else { return }
    
    sepiaFilter.setValue(originalImage, forKey: kCIInputImageKey)
    sepiaFilter.setValue(0.5, forKey: kCIInputIntensityKey)
    
    guard let outputImage = sepiaFilter.outputImage else { return }
    imageView.image = UIImage(ciImage: outputImage)
    
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

