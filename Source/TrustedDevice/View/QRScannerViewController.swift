//
//  QRScannerViewController.swift
//  Cotter
//
//  Created by Albert Purnama on 3/26/20.
//

import Foundation
import UIKit
import AVFoundation

/// Delegate callback for the QRScannerView.
protocol QRScannerViewDelegate: class {
    func qrScanningDidFail()
    func qrScanningSucceededWithCode(_ str: String?)
    func qrScanningDidStop()
}

class QRScannerView: UIView {
    
    weak var delegate: QRScannerViewDelegate?
    
    /// capture settion which allows us to start and stop scanning.
    var captureSession: AVCaptureSession?
    
    // Init methods..
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        doInitialSetup()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        doInitialSetup()
    }
    
    //MARK: overriding the layerClass to return `AVCaptureVideoPreviewLayer`.
    override class var layerClass: AnyClass  {
        return AVCaptureVideoPreviewLayer.self
    }
    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
}

extension QRScannerView {
    
    var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }
    
    func startScanning() {
       captureSession?.startRunning()
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        delegate?.qrScanningDidStop()
    }
    
    /// Does the initial setup for captureSession
    private func doInitialSetup() {
        clipsToBounds = true
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch let error {
            print(error)
            return
        }
        
        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            scanningDidFail()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession?.canAddOutput(metadataOutput) ?? false) {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417]
        } else {
            scanningDidFail()
            return
        }
        
        self.layer.session = captureSession
        self.layer.videoGravity = .resizeAspectFill
        
        captureSession?.startRunning()
    }
    func scanningDidFail() {
        delegate?.qrScanningDidFail()
        captureSession = nil
    }
    
    func found(code: String) {
        delegate?.qrScanningSucceededWithCode(code)
    }
    
}

extension QRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        stopScanning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
}

class QRScannerViewController: UIViewController, QRScannerViewDelegate {
    @IBOutlet weak var navBarItem: UINavigationBar!
    
    let successImage = CotterImages.instance.getImage(for: VCImageKey.pinSuccessImg)
    let failImage = CotterImages.instance.getImage(for: VCImageKey.nonTrustedPhoneTapFail)
    
    var userID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let crossButton = UIBarButtonItem(title: "\u{2717}", style: UIBarButtonItem.Style.plain, target: self, action: #selector(close))
        crossButton.tintColor = UIColor.black
        self.navigationItem.leftBarButtonItem = crossButton
        
        self.navigationItem.title = "Scan QR Code"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        // assign delegate
        let view = self.view as! QRScannerView
        view.delegate = self
    }
    
    @objc
    func close() {
        self.navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func qrScanningDidFail() {
        let img = UIImage(named: failImage, in: Cotter.resourceBundle, compatibleWith: nil)!
        let popup = BottomPopupModal(vc: self, img: img, title: "Unable to Register New Device", body: "Please try again later.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            popup.dismiss()
            self.close()
        }
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        guard let userID = self.userID else { return }
        guard let qrData = str else { return }
        print("qrScan: \(qrData)")

        func callback(resp: CotterResult<CotterEvent>) {
            switch resp {
            case .success(let evt):
                if evt.approved {
                    // if successful
                    let img = UIImage(named: successImage, in: Cotter.resourceBundle, compatibleWith: nil)!
                    let popup = BottomPopupModal(vc: self, img: img, title: "Success Registering New Device", body: "You can now use the new device to access your account without approval")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        popup.dismiss()
                    }
                } else {
                    // failure
                    self.qrScanningDidFail()
                }
            case .failure(let err):
                print("API Failure: \(err.localizedDescription)")
                self.qrScanningDidFail()
            }
        }
        
        CotterAPIService.shared.registerOtherDevice(qrData: qrData, userID: userID, cb: callback)
    }
    
    func qrScanningDidStop() {
        self.close()
        print("stop scanning")
    }
}
