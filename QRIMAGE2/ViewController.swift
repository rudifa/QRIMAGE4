//
//  ViewController.swift
//  QRIMAGE2
//
//  Created by Rudolf Farkas on 02.03.20.
//  Copyright © 2020 Rudolf Farkas. All rights reserved.
//

// FROM UIImageWriteToSavedPhotosAlbum not working
// https://stackoverflow.com/questions/48535524/uiimagewritetosavedphotosalbum-not-working

/*
 2020-03-02 22:08:24.614840+0100 QRIMAGE2[55027:14402870] Metal API Validation Enabled
 2020-03-02 22:08:28.263513+0100 QRIMAGE2[55027:14402974] [access] This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSPhotoLibraryAddUsageDescription key with a string value explaining to the user how the app uses this data.

 // added ...
     <key>NSPhotoLibraryAddUsageDescription</key>
     <string>APP WANTS TO STORE IMAGE TO YOUR PHOTO LIBRARY</string>
 </dict>
 </plist>

 */

import UIKit

import Foundation
import UIKit

class QRCodeGenerator {
    class func generateQRCodeFromString(_ strQR: String) -> CIImage {
        let dataString = strQR.data(using: String.Encoding.isoLatin1)

        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter?.setValue(dataString, forKey: "inputMessage")
        return (qrFilter?.outputImage)!
    }

    class func convert(_ cmage: CIImage) -> UIImage {
        let context: CIContext = CIContext(options: nil)
        let cgImage: CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image: UIImage = UIImage(cgImage: cgImage)
        return image
    }
}

class ViewController: UIViewController {
    // from original code
    @IBOutlet var imageView: UIImageView!
    var imgQrCode: UIImage!

    // from FlashViewController
    @IBOutlet var tagImageView: UIImageView!
    var tagImage: UIImage?
    let privateUrl = "corona"
    let selectedCalendarTitle = "october"

    override func viewDidLoad() {
        super.viewDidLoad()

        // from original code
        generateQRCodeFromString()

        // from FlashViewController
        tagImage = generateQrImage(from: "\(privateUrl):// \(selectedCalendarTitle)")
        tagImageView.image = tagImage
    }

    func generateQRCodeFromString() {
        let id: String = "QRCODE TEXT IN HERE"

        let ciImageFromQRCode = QRCodeGenerator.generateQRCodeFromString(id)

        // Scale according to imgViewQRCode. So, image is not blurred.
        let scaleX = (imageView.frame.size.width / ciImageFromQRCode.extent.size.width)
        let scaleY = (imageView.frame.size.height / ciImageFromQRCode.extent.size.height)

        let imgTransformed = ciImageFromQRCode.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        imageView.image = QRCodeGenerator.convert(imgTransformed)
        imgQrCode = QRCodeGenerator.convert(imgTransformed)
    }

    @IBAction func saveQRcode(_: Any) {
        UIImageWriteToSavedPhotosAlbum(imageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    @IBAction func actionShare(_: Any) {
        // image to share

        let myShare = "My beautiful photo! <3 <3"
        let image = imageView.image!

        // set up activity view controller
        let imageToShare = [image, myShare] as [AnyObject] // [ image! ]

        print("imageToShare \(imageToShare)")

        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view // so that iPads won't crash

        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: from FlashViewController

    @IBAction func exportBtnPressed(_: Any) {

        saveQRCodeImage()
    }

    @objc func saveQRCodeImage() {
        guard tagImage != nil else { return }

        UIImageWriteToSavedPhotosAlbum(tagImage!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image2(_ image: UIImage, didFinishSavingWithError err: Error?, contextInfo: UnsafeRawPointer) {
        if let err = err {
            // we got back an error !
            presentAlert(title: "Error", message: err.localizedDescription)
        } else {
            presentAlert(title: "QR Code Image exported", message: "Check your Photo Library")
            print("QR Code saved successfully")
        }
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func generateQrImage(from text: String) -> UIImage? {
        // Core Image Filter Reference says:
        // To create a QR code from a string or URL, convert it to an NSData object using NSISOLatin1StringEncoding.

        let data = text.data(using: .isoLatin1)
        // let data = "\(privateUrl)://\(encodedCalendarTitle)"

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")

        let scale = CGFloat(17.29) // aiming at ~300 dpi when printed unscaled
        let transform = CGAffineTransform(scaleX: scale, y: scale)

        guard let output = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        return UIImage(ciImage: output)
    }
}
