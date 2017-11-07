//
//  ViewController.swift
//  CaptureObjectIdentifier
//
//  Created by Shuchita Krishnani on 04/11/17.
//  Copyright © 2017 Shuchita Krishnani. All rights reserved.
//

import UIKit
import AVFoundation
import  CoreML
import Vision

enum FlashState
{
    case off
    case on
    
}

class ViewController: UIViewController {
    
    var cameraSession  : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var photoData :Data?
    
    var flashMode:FlashState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var labelView: RoundedShadowView!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var captureImgView: RoundedShadowImageView!
    @IBOutlet weak var FlashBtn: RoundedShadowButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
    
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        let tap = UITapGestureRecognizer(target: self , action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        cameraSession = AVCaptureSession()
        cameraSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if cameraSession .canAddInput(input) == true
            {
                cameraSession.addInput(input)
                
            }
             cameraOutput = AVCapturePhotoOutput()
            if cameraSession.canAddOutput(cameraOutput) ==  true
            {
                cameraSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session : cameraSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                cameraSession.startRunning()
            }
            
            
        }catch{
            
            debugPrint(error)
            
        }
        
    }
    
    @objc func didTapCameraView(){
        
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        
//        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
//        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String : previewPixelType, kCVPixelBufferWidthKey as String : 160, kCVPixelBufferHeightKey as String: 160] as [String : Any]
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashMode == .off
        {
            settings.flashMode = .off
        }else{
            settings.flashMode = .on
        }
        
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
        
        
    }
    func resultMethod(request: VNRequest ,error: Error?)
    {
        guard let results = request.results as? [VNClassificationObservation] else { return}
        for classification in results{
            
            if classification.confidence < 0.5
            {
                let notSureMesage = "I am not sure whet it is, please try again"
                self.identificationLbl.text  = notSureMesage
                synthesizespeech(fromString: notSureMesage)
                self.confidenceLbl.text = ""
                break
                
            }
            else{
                let identification  = classification.identifier
                let confidence = classification.confidence
                 self.identificationLbl.text = identification
                self.confidenceLbl.text = "Confidence : \(confidence)%"
                let completeMessage = "This is a \(identification), and I am \(confidence) percent sure"
                synthesizespeech(fromString: completeMessage)
                break
            }
        }
        
        
    }
    
    func synthesizespeech(fromString string :String)
    {
        let speechutterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechutterance)
        
        
    }
    
   
    @IBAction func flashBtnPressed(_ sender: Any) {
        
        switch flashMode {
        case .off:
            self.FlashBtn.setTitle("FLASH ON", for: .normal)
            flashMode = .on
        case .on:
            self.FlashBtn.setTitle("FLASH OFF", for: .normal)
            flashMode = .off
        }
        
        
    }
    
    
    
    
}

extension ViewController: AVCapturePhotoCaptureDelegate
{
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error{
            
            debugPrint(error)
        }else{
            
            photoData = photo.fileDataRepresentation()
            do{
                
                let model =  try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultMethod)
                
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            }catch{
                
                debugPrint(error)
                
            }
            
            
            
            let image = UIImage.init(data: photoData!)
            self.captureImgView.image = image
            
        }
    }
    
    
}
extension ViewController:AVSpeechSynthesizerDelegate{
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
    
    
}
