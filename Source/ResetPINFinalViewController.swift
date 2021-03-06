//
//  ResetPINFinalViewController.swift
//  Cotter
//
//  Created by Raymond Andrie on 3/22/20.
//

import UIKit

public class ResetPINFinalViewControllerKey {
    // MARK: - Keys for Strings
    static let title = "ResetPINFinalViewController/title"
}

class ResetPINFinalViewController: UIViewController {
    
    typealias VCTextKey = ResetPINFinalViewControllerKey
    
    // MARK: VC Text Definitions
    let successTitle = CotterStrings.instance.getText(for: VCTextKey.title)
    
    // MARK: - VC Image Definitions
    let successImage = CotterImages.instance.getImage(for: VCImageKey.resetPinSuccessImg)
    
    // Auth Service
    let authService = LocalAuthService()
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var successLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("loaded Reset PIN Final View!")
        
        // Add Set-up here
        configureTexts()
        configureNav()
        loadImage()
        
        endFlow()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Private Helper Functions
extension ResetPINFinalViewController {
    private func configureTexts() {
        successLabel.text = successTitle
    }
    
    private func configureNav() {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    private func loadImage() {
        let cotterImages = ImageObject.defaultImages
        
        guard !cotterImages.contains(successImage) else {
            print("Using Default Image...")
            imageView.image = UIImage(named: successImage, in: Cotter.resourceBundle, compatibleWith: nil)
            return
        }
        
        imageView.image = UIImage(named: successImage, in: Bundle.main, compatibleWith: nil)
    }
    
    private func endFlow() {
        // Dismiss VC after 3 seconds, then run callback
        let timer = DispatchTime.now() + 3
        DispatchQueue.main.asyncAfter(deadline: timer) {
            let cbFunc = Config.instance.transactionCb
            cbFunc("Token from Transaction PIN View after resetting PIN!", nil)
            return
        }
    }
}
