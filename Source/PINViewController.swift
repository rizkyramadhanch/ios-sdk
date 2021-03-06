//
//  PINViewController.swift
//  CotterIOS
//
//  Created by Albert Purnama on 2/2/20.
//

import Foundation
import UIKit

public class PINViewControllerKey {
    // MARK: - Keys for Strings
    public static let navTitle = "PINViewController/navTitle"
    public static let showPin = "PINViewController/showPin"
    public static let hidePin = "PINViewController/hidePin"
    public static let title = "PINViewController/title"
}

class PINViewController : UIViewController {
    // since PINViewController is too long to type
    // we can getaway with typealias here
    typealias VCTextKey = PINViewControllerKey
    
    var hideCloseButton: Bool = false
    
    // MARK: - Alert Service Text Definition
    let navBackTitle = CotterStrings.instance.getText(for: AuthAlertMessagesKey.navBackTitle)
    let navBackBody = CotterStrings.instance.getText(for: AuthAlertMessagesKey.navBackBody)
    let navBackAction = CotterStrings.instance.getText(for: AuthAlertMessagesKey.navBackActionButton)
    let navBackCancel = CotterStrings.instance.getText(for: AuthAlertMessagesKey.navBackCancelButton)
    
    // MARK: - VC Text Definitions
    let navTitle = CotterStrings.instance.getText(for: VCTextKey.navTitle)
    let showPinText = CotterStrings.instance.getText(for: VCTextKey.showPin)
    let hidePinText = CotterStrings.instance.getText(for: VCTextKey.hidePin)
    let titleText = CotterStrings.instance.getText(for: VCTextKey.title)
    
    lazy var alertService: AlertService = {
        let alert = AlertService(vc: self, title: navBackTitle, body: navBackBody, actionButtonTitle: navBackAction, cancelButtonTitle: navBackCancel)
        alert.delegate = self
        return alert
    }()
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // Code Text Field
    @IBOutlet weak var codeTextField: OneTimeCodeTextField!
    
    // PIN Visibility Toggle Button
    @IBOutlet weak var pinVisibilityButton: UIButton!
    
    // Error Label
    @IBOutlet weak var errorLabel: UILabel!
    
    // Keyboard
    @IBOutlet weak var keyboardView: KeyboardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("loaded PIN Cotter Enrollment View")
        
        // Set-up
        addConfigs()
        addDelegates()
        instantiateCodeTextFieldFunctions()
        setCotterStatusBarStyle()
    }
    
    @IBAction func onClickPinVis(_ sender: UIButton) {
        codeTextField.togglePinVisibility()
        if sender.title(for: .normal) == showPinText {
            sender.setTitle(hidePinText, for: .normal)
        } else {
            sender.setTitle(showPinText, for: .normal)
        }
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - PINBaseController
extension PINViewController : PINBaseController {
    func instantiateCodeTextFieldFunctions() {
        // Instantiate Function to run when user enters wrong PIN code
        codeTextField.removeErrorMsg = {
            // Remove error msg if it is present
            if !self.errorLabel.isHidden {
                self.toggleErrorMsg(msg: nil)
            }
        }
        
        // Instantiate Function to run when PIN is fully entered
        codeTextField.didEnterLastDigit = { code in
            print("PIN Code Entered: ", code)
            
            // If code has repeating digits or is a straight number, show error.
            let pattern = "\\b(\\d)\\1+\\b"
            let result = code.range(of: pattern, options: .regularExpression)
            
            // Ensure consecutive PIN number is rejected
            if result != nil || self.findSequence(sequenceLength: code.count, in: code) {
                if self.errorLabel.isHidden {
                    self.toggleErrorMsg(msg: CotterStrings.instance.getText(for: PinErrorMessagesKey.badPin))
                }
                return false
            }

            // Clear Code text Field before continuing
            self.codeTextField.clear()
            
            // Go to PIN Confirmation Page
            let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "PINConfirmViewController") as! PINConfirmViewController
            confirmVC.prevCode = code
            self.navigationController?.pushViewController(confirmVC, animated: true)
            return true
        }
    }
    
    func addConfigs() {
        // Implement Custom Back Button instead of default in Nav controller
        self.navigationItem.hidesBackButton = true
        
        // if close
        if !self.hideCloseButton {
            let crossButton = UIBarButtonItem(title: "\u{2717}", style: UIBarButtonItem.Style.plain, target: self, action: #selector(promptClose(sender:)))
            crossButton.tintColor = UIColor.black
            self.navigationItem.leftBarButtonItem = crossButton
        }
        
        // Remove default Nav controller styling
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        codeTextField.configure()
        configureText()
        configureErrorLabel()
        configureButtons()
    }
    
    func addDelegates() {
        self.keyboardView.delegate = self
    }
    
    func configureText() {
        self.navigationItem.title = navTitle
        self.titleLabel.text = titleText
    }
    
    func configureButtons() {
        pinVisibilityButton.setTitle(showPinText, for: .normal)
        pinVisibilityButton.setTitleColor(Config.instance.colors.primary, for: .normal)
    }
    
    func configureErrorLabel() {
        errorLabel.isHidden = true
        errorLabel.textColor = Config.instance.colors.danger
    }
    
    func toggleErrorMsg(msg: String?) {
        errorLabel.isHidden.toggle()
        if !errorLabel.isHidden {
            errorLabel.text = msg
        }
    }
  
    @objc private func promptClose(sender: UIBarButtonItem) {
        alertService.show()
    }
}

// MARK: - KeyboardViewDelegate
extension PINViewController : KeyboardViewDelegate {
    func keyboardButtonTapped(buttonNumber: NSInteger) {
        // If backspace tapped, remove last char. Else, append new char.
        if buttonNumber == -1 {
            codeTextField.removeNumber()
        } else {
            codeTextField.appendNumber(buttonNumber: buttonNumber)
        }
    }
}

// MARK: - AlertServiceDelegate
extension PINViewController : AlertServiceDelegate {
    func cancelHandler() {
        alertService.hide()
    }
    
    func actionHandler() {
        alertService.hide()
        Config.instance.pinEnrollmentCb("PIN enrollment cancelled - no token", nil)
    }
}
