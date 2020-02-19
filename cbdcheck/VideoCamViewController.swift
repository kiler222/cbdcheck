//
//  VideoCamViewController.swift
//  cbdcheck
//
//  Created by kiler on 25/11/2019.
//  Copyright © 2019 kiler. All rights reserved.
//

/**
 * Copyright 2019 Google ML Kit team
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import AVFoundation
import Firebase
import GTMSessionFetcher
import MaterialComponents
import SafariServices
import SwiftUI


/**
 * The camera mode view controller that displays a rear facing live feed.
 */


private let videoDataOutputQueueLabel = "com.google.firebaseml.visiondetector.VideoDataOutputQueue"
private let videoSessionQueueLabel = "com.google.firebaseml.visiondetector.VideoSessionQueue"
//* Duration for presenting the bottom sheet.
private let kBottomSheetAnimationDurationInSec: CGFloat = 0.25
//* Duration for confirming stage.
private let kConfirmingDurationInSec: CGFloat = 1.0
// Constants for alpha values.
private let kOpaqueAlpha: CGFloat = 1.0
private let kTransparentAlpha: CGFloat = 0.0
//*  Radius of the searching indicator.
private let kSearchingIndicatorRadius: CGFloat = 24.0
//* Target height of the thumbnail when it sits on top of the bottom sheet.
private let kThumbnailbottomSheetTargetHeight: CGFloat = 200.0
//* Padding around the thumbnail when it sits on top of the bottom sheet.
private let kThumbnailPaddingAround: CGFloat = 24.0
//* The thumbnail will fade out when it reaches this threshhold from screen edge.
private let kThumbnailFadeOutEdgeThreshhold: CGFloat = 200.0
//* Number of faked product search results.
private let kFakeProductSearchResultCount = 10
// Chip message related values.
private let kChipBackgroundAlpha: CGFloat = 0.6
private let kChipCornerRadius: CGFloat = 8.0
private let kChipFadeInDuration: CGFloat = 0.075
private let kChipScaleDuration: CGFloat = 0.15
private let kChipScaleFromRatio: CGFloat = 0.8
private let kChipScaleToRatio: CGFloat = 1.25
private let kChipBottomPadding: CGFloat = 36.0
//* The message shown in detecting stage.
private let kDetectingStageMessage = "Point your camera at the barcode"
//* The Message shown in confirming stage.
private let kConfirmingStageMessage = "Keep camera still for a moment"
//* The message shown in searching stage.
private let kSearchingMessage = "Searching"
// Strings for fake search results.
private let kFakeProductNameFormat = "Fake product name: %li"
private let kFakeProductTypeName = "Fashion"
private let kFakeProductPriceText = "$10"
private let kFakeProductItemNumberText = "12345678"

private let kKeyFileName = "key"
private let kKeyFileType = "plist"

class VideoCamViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, MDCBottomSheetControllerDelegate {
  // Views to be added as subviews of current view.
  private var previewView: UIView!
  private var overlayView: DetectionOverlayView!
  private var detectingReticle: CameraReticle!
  private var confirmingSpinner: ConfirmationSpinner!
  private var searchingIndicator: MDCActivityIndicator!
  // Video capture related properties.
  private var session = AVCaptureSession()
  private var videoDataOutput: AVCaptureVideoDataOutput!
  private var videoDataOutputQueue = DispatchQueue(label: videoDataOutputQueueLabel)
  private var sessionQueue = DispatchQueue(label: videoSessionQueueLabel)
  private var previewLayer: AVCaptureVideoPreviewLayer!
  // Vision server to generate `VisionObjectDetector`.
  private let vision = Vision.vision()
  // Current status in object detection.

    
    
    
  var status = ODTStatus.notStarted {
    didSet {
      switch status {
      case .notStarted:
        print("PJ set status noStarted")
        hideMessage()
        confirmingSpinner.isHidden = true
        detectingReticle.isHidden = true
        showSearchingIndicator(false)
      case .presenting:
        print("PJ set status presenting")
        hideMessage()
        confirmingSpinner.isHidden = true
        detectingReticle.isHidden = true
        showSearchingIndicator(false)
      case .detecting:
                print("PJ set status detecting")
        showMessage(kDetectingStageMessage)
        detectingReticle.isHidden = false
        confirmingSpinner.isHidden = true
        showSearchingIndicator(false)
      case .confirming:
                print("PJ set status confirming")
        showMessage(kConfirmingStageMessage)
        detectingReticle.isHidden = true
        confirmingSpinner.isHidden = false
        showSearchingIndicator(false)
      case .searching:
                print("PJ set status searching")
        showMessage(kSearchingMessage)
        confirmingSpinner.isHidden = true
        detectingReticle.isHidden = true
        showSearchingIndicator(true)
      case .searched:
                print("PJ set status searched")
        hideMessage()
        confirmingSpinner.isHidden = true
        detectingReticle.isHidden = true
        showSearchingIndicator(false)
      }
    }
  }

  // View to show message during different stages.
  private var messageView: MDCChipView!
  // Properties to record latest detected results.
  private var lastDetectedObject: VisionObject!
  private var lastDetectedBarcode: String!
  private var lastDetectedBarcodeFrame: CGRect!
    private var lastScannedProduct: ScannedProduct!
    
    
    private var lastDetectedSampleBuffer: SampleBuffer!
  // Width to height ratio of the thumbnail.
  private var thumbnailWidthHeightRatio: CGFloat = 0.0
  // Target height of the bottom sheet.
  private var bottomSheetTargetHeight: CGFloat = 0.0
  // Array of timers scheduled before confirmation.
  private var timers = [AnyHashable]()
    private var timerPresentingProduct: Timer!
  // Used to fetch product search results.
  private var fetcherService = GTMSessionFetcherService()
    let barcodes = ["5700002143709", "5700002143716", "638317357120", "638317357182", "8470001914552", "8718819550488"]
    var rootViewController: UIViewController!
// let barcodes = ["5411188115366", "850684006924", "858947007985"]
    
    
  deinit {
//    clearLastDetectedObject()
    clearLastDetectedBarcode()
    fetcherService.stopAllFetchers()
  }

  // MARK: - UIViewController
  override func loadView() {
    super.loadView()

    view.clipsToBounds = true

    setUpPreviewView()
    setUpOverlayView()
  }


    
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.white


   
//    let randomBarcode = barcodes.randomElement()!
    
/*
    FirebaseManager.sharedInstance.checkBarcode(barcode: randomBarcode) { result in

       let imageURL = result["images"] as! Array<String>
       let title = result["product_name"] as! String
       let brand = result["brand"] as! String
        let score = result["score"] as! String
        let status = result["status"] as! String
        let url = URL(string: imageURL.first!)
        let ingredients = result["ingredients"] as! NSDictionary
        
        var ingredientList: [Ingredient] = []
        
        ingredients.forEach { (i) in
            let tempIngredient = Ingredient(id: UUID(), name: i.key as! String, status: i.value as! String)
            ingredientList.append(tempIngredient)
        }
        
        let tempProd = Product(productName: title, score: score, itemNo: self.lastDetectedBarcode, imageURL: "", url: url, priceFullText: "tysiąc pięćset", productTypeName: "Książka", brand: brand, status: status)
       let products = [tempProd]
        
        
    
        var statusColor: Color!
        
            switch status {
            case "good":
               statusColor = Color.green
            case "moderate":
               statusColor = Color.orange
            default:
               statusColor = Color.red
            }
        
      
        let contentView = ContentView(product: tempProd, color: statusColor, ingredientList: ingredientList) // swiftUIView is View
                let vc = UIHostingController(rootView: contentView)
        self.showDetailViewController(vc, sender: self)
    }
  */
    
    setCameraSelection()

    // Set up video processing pipeline.
    setUpVideoProcessing()

    // Set up camera preview.
    #if !TARGET_IPHONE_SIMULATOR
    setUpCameraPreviewLayer()
    #endif

    setUpDetectingReticle()
    setUpConfirmingSpinner()
    setUpSearchingIndicator()
    setUpMessageView()
    startToDetect()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    previewLayer.frame = view.frame
    previewLayer.position = CGPoint(x: previewLayer.frame.midX, y: previewLayer.frame.midY)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    print("PJ viewDiDISAppear")
    weak var weakSelf = self
    #if !TARGET_IPHONE_SIMULATOR
    sessionQueue.async(execute: {
      weakSelf?.session.stopRunning()
    })
    #endif
  }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        rootViewController = VideoCamViewController()
        
    }
    

    
  // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
  func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    let buffer = SampleBuffer(sampleBuffer: sampleBuffer)
//    print("PJ captureOutpu - ? czy to jest odplanae na każddej klatce??? \(Date())")
//    detectObject(in: buffer)
    
    detectBarcode(in: buffer)
  }

  // MARK: - MDCBottomSheetControllerDelegate
  func bottomSheetControllerDidDismissBottomSheet(_ controller: MDCBottomSheetController) {
    
    print("PJ bottomSheetControllerDidDismissBottomSheet")
    bottomSheetTargetHeight = 0
    startToDetect()
  }

  func bottomSheetControllerDidChangeYOffset(_ controller: MDCBottomSheetController, yOffset: CGFloat) {
    let imageStartY = yOffset - kThumbnailbottomSheetTargetHeight - kThumbnailPaddingAround
    let rect = CGRect(x: kThumbnailPaddingAround,
                      y: imageStartY,
                      width: kThumbnailbottomSheetTargetHeight * thumbnailWidthHeightRatio,
                      height: kThumbnailbottomSheetTargetHeight) // Height

    guard let currentWindow = UIApplication.shared.keyWindow else { return }

    let safeInsets = UIUtilities.safeAreaInsets()
    let screenHeight = currentWindow.bounds.size.height
    let topFadeOutOffsetY = safeInsets.top + kThumbnailFadeOutEdgeThreshhold
    let bottomFadeOutOffsetY = screenHeight - safeInsets.bottom - kThumbnailFadeOutEdgeThreshhold

    let imageAlpha = ratioOfCurrentValue(yOffset,
                                         from: (yOffset > bottomSheetTargetHeight) ?
                                          bottomFadeOutOffsetY : topFadeOutOffsetY,
                                         to: bottomSheetTargetHeight)
//    overlayView.showImage(in: rect, alpha: imageAlpha)
  }

  // MARK: - Private

  //* Prepares camera session for video processing.
  func setUpVideoProcessing() {
    weak var weakSelf = self
    sessionQueue.async(execute: {
      guard let strongSelf = weakSelf else {
        return
      }
      strongSelf.videoDataOutput = AVCaptureVideoDataOutput()
      let rgbOutputSettings = [
        kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
      ]
      strongSelf.videoDataOutput.videoSettings = rgbOutputSettings

      if let videoDataOutput = strongSelf.videoDataOutput {
        if !strongSelf.session.canAddOutput(videoDataOutput) {
          if strongSelf.videoDataOutput != nil {
            strongSelf.session.removeOutput(videoDataOutput)
            strongSelf.videoDataOutput = nil
          }
          print("Failed to set up video output")
          return
        }
      }
      strongSelf.videoDataOutput.alwaysDiscardsLateVideoFrames = true
      strongSelf.videoDataOutput.setSampleBufferDelegate(strongSelf, queue: strongSelf.videoDataOutputQueue)
      if let videoDataOutput = strongSelf.videoDataOutput {
        strongSelf.session.addOutput(videoDataOutput)
      }
    })
  }

  //* Prepares preview view for camera session.
  func setUpPreviewView() {
    previewView = UIView(frame: view.frame)
    previewView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(previewView)
  }

  //* Initiates and prepares camera preview layer for later video capture.
  func setUpCameraPreviewLayer() {
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.backgroundColor = UIColor.black.cgColor
    previewLayer.videoGravity = .resizeAspectFill
    let rootLayer = previewView.layer
    rootLayer.masksToBounds = true
    previewLayer.frame = rootLayer.bounds
    rootLayer.addSublayer(previewLayer)
  }

  //* Prepares camera for later video capture.
  func setCameraSelection() {
    weak var weakSelf = self
    sessionQueue.async(execute: {
      guard let strongSelf = weakSelf else {
        return
      }

      strongSelf.session.beginConfiguration()
      strongSelf.session.sessionPreset = .hd1280x720

      let oldInputs = strongSelf.session.inputs
      for oldInput in oldInputs {
        strongSelf.session.removeInput(oldInput)
      }

      let input = strongSelf.pickCamera(.back)
      if input == nil {
        // Failed, restore old inputs
        for oldInput in oldInputs {
          strongSelf.session.addInput(oldInput)
        }
      } else {
        // Succeeded, set input and update connection states
        if let input = input {
          strongSelf.session.addInput(input)
        }
      }
      strongSelf.session.commitConfiguration()
    })
  }

  //* Determines camera for later video capture. Here only rear camera is picked.
  func pickCamera(_ desiredPosition: AVCaptureDevice.Position) -> AVCaptureDeviceInput? {
    var hadError = false
    for device in AVCaptureDevice.devices(for: .video) where device.position == desiredPosition {
      do {
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
          return input
        }
      } catch {
        hadError = true
        print("Could not initialize for AVMediaTypeVideo for device \(device)")
      }
    }
    if !hadError {
      print("No camera found for requested orientation")
    }
    return nil
  }

  //* Initiates and prepares overlay view for later video capture.
  func setUpOverlayView() {
    overlayView = DetectionOverlayView(frame: view.frame)
    overlayView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(overlayView)
  }

  //* Clears up the overlay view. Caller must make sure this runs on the main thread.
  func cleanUpOverlayView() {
    assert(Thread.current.isEqual(Thread.main), "cleanUpOverlayView is not running on the main thread")

    overlayView.hideSubviews()
    overlayView.frame = view.frame
  }

  //* Initiates and prepares detecting reticle for later video capture.
  func setUpDetectingReticle() {
    detectingReticle = CameraReticle()
    detectingReticle.translatesAutoresizingMaskIntoConstraints = false
    let size = detectingReticle.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                     height: CGFloat.greatestFiniteMagnitude))
    detectingReticle.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    if let detectingReticle = detectingReticle {
      view.addSubview(detectingReticle)
    }
    NSLayoutConstraint.activate([
      detectingReticle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      detectingReticle.centerYAnchor.constraint(equalTo: view.centerYAnchor)
      ].compactMap { $0 })
  }

  //* Initiates and prepares confirming spinner for later video capture.
  func setUpConfirmingSpinner() {
    confirmingSpinner = ConfirmationSpinner(duration: CFTimeInterval(kConfirmingDurationInSec))
    confirmingSpinner.translatesAutoresizingMaskIntoConstraints = false
    
    let size = confirmingSpinner.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                      height: CGFloat.greatestFiniteMagnitude))
    confirmingSpinner.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    if let confirmingSpinner = confirmingSpinner {
      view.addSubview(confirmingSpinner)
    }
    NSLayoutConstraint.activate([
      confirmingSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      confirmingSpinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
      ].compactMap { $0 })
  }

  //* Initiates and prepares searching indicator for later video capture.
  func setUpSearchingIndicator() {
    searchingIndicator = MDCActivityIndicator()
    searchingIndicator.radius = kSearchingIndicatorRadius
    searchingIndicator.cycleColors = [UIColor(rgb: 0x53B88E)]
    let size = confirmingSpinner.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                      height: CGFloat.greatestFiniteMagnitude))
    let centerX = view.frame.midX
    let centerY = view.frame.midY
    searchingIndicator.frame = CGRect(x: centerX, y: centerY, width: size.width, height: size.height)
    view.addSubview(searchingIndicator)
    NSLayoutConstraint.activate([
      searchingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      searchingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
      ].compactMap { $0 })
  }

  //* Initiates and prepares message view for later video capture.
  func setUpMessageView() {
    messageView = MDCChipView()
    messageView.backgroundColor = UIColor.black.withAlphaComponent(0.9) // (kChipBackgroundAlpha)
    messageView.isUserInteractionEnabled = false
    messageView.clipsToBounds = true
    messageView.titleLabel.textColor = UIColor.black
    messageView.layer.cornerRadius = kChipCornerRadius
    view.addSubview(messageView)
    messageView.alpha = 0.5 //kTransparentAlpha
  }

  /**
   * Clears last detected object. Caller must make sure that this method runs on the main thread.
   */
//  func clearLastDetectedObject() {
//    assert(Thread.current.isEqual(Thread.main), "clearLastDetectedObject is not running on the main thread")
//    print("PJ clearLast Detected Object")
//    lastDetectedObject = nil
//    lastDetectedSampleBuffer = nil
//    for timer in timers {
//      guard let timer = timer as? Timer else {
//        continue
//      }
//      timer.invalidate()
//    }
//  }

    func clearLastDetectedBarcode() {
      assert(Thread.current.isEqual(Thread.main), "clearLastDetectedObject is not running on the main thread")
        print("PJ clearLast Detected Barcode")
      lastDetectedBarcode = nil
      lastScannedProduct = nil
      lastDetectedBarcodeFrame = nil
      lastDetectedSampleBuffer = nil
      for timer in timers {
        guard let timer = timer as? Timer else {
          continue
        }
        timer.invalidate()
      }
    }
    

  // MARK: - Object detection and tracking.

  /**
   * Called to detect objects in the given sample buffer.
   *
   * @param sampleBuffer The `SampleBuffer` for object detection.
   */
//  func detectObject(in sampleBuffer: SampleBuffer) {
//    let orientation = UIUtilities.imageOrientation(from: UIDevice.current.orientation, withCaptureDevicePosition: .back)
//
//    let image = VisionImage(buffer: sampleBuffer.data)
//    let metadata = VisionImageMetadata()
//    metadata.orientation = orientation
//    // metadata.orientation = FIRVisionDetectorImageOrientationRightTop;
//    image.metadata = metadata
//    let options = VisionObjectDetectorOptions()
//
//    options.shouldEnableMultipleObjects = false
//    options.shouldEnableClassification = false
//    options.detectorMode = .stream
//
//
//    let objectDetector = vision.objectDetector(options: options)
//
//
//
//
//    do {
//      let objects = try objectDetector.results(in: image)
//      weak var weakSelf = self
//      DispatchQueue.main.async(execute: {
//        weakSelf?.onDetectedObjects(objects, in: sampleBuffer)
//      })
//    } catch {
//    }
//  }
    
    
    
      func detectBarcode(in sampleBuffer: SampleBuffer){
          
          let format = VisionBarcodeFormat.all
          let barcodeOptions = VisionBarcodeDetectorOptions(formats: format)
          let barcodeDetector = vision.barcodeDetector(options: barcodeOptions)
          
          let cameraPosition = AVCaptureDevice.Position.back  // Set to the capture device you used.
          let metadata = VisionImageMetadata()
          metadata.orientation = imageOrientation(
              deviceOrientation: UIDevice.current.orientation,
              cameraPosition: cameraPosition
          )
          
          let image = VisionImage(buffer: sampleBuffer.data)
          image.metadata = metadata
          
          
          barcodeDetector.detect(in: image) { features, error in
            guard error == nil, let features = features, !features.isEmpty else {
              // ...
//              print("PJ nie ma w tym obrazie barcodu")
                
                //TODO a moze wstawic tutaj warunek ze jesli barcodeFrame == nil to tez return????
                
              return
            }

              let resultsText
                = features.map { feature in
                  return "DisplayValue: \(feature.displayValue ?? ""), RawValue: "
                    + "\(feature.rawValue ?? ""), Frame: \(feature.frame)"
                }.joined(separator: "\n")
            
            print("PJ wykryty jakis barcode \(resultsText)")
            
            print("PJ vc presented: \(self.presentedViewController)")
            let barcode = features.map {feature in
                return feature.rawValue
            }
            let barcodeFrame = features.map {feature in
                return feature.frame
            }
            
            let sampleBufferSize = self.sampleBufferSize(sampleBuffer.data)
              
            print("PJ barcodeFrame: \(barcodeFrame)")
            print("PJ barcodeFrame count: \(barcodeFrame.count)")
            
            switch self.status {
            case .detecting:
                self.cleanUpOverlayView()
                
                
              let convertedRect = self.convertedRectOfObjectFrame(barcodeFrame[0], inSampleBufferFrameSize: sampleBufferSize)
              print("PJ .detecting i zaraz startBarcode(toConfirmBarcode = \(barcode[0]) a barcodeFrame jest = \(barcodeFrame)")
//              self.overlayView.showBox(in: convertedRect)
                self.startBarcode(toConfirmBarcode: barcode[0]!, sampleBuffer: sampleBuffer, barcodeFrame: barcodeFrame[0])
            case .confirming:
                print("PJ .confirming i barcodeFrame[0] = \(barcodeFrame[0])")
                let convertedRect = self.convertedRectOfObjectFrame(barcodeFrame[0], inSampleBufferFrameSize: sampleBufferSize)
//                self.overlayView.showBox(in: convertedRect)
                self.lastDetectedBarcode = barcode[0]!
                self.lastDetectedBarcodeFrame = barcodeFrame[0]
//                print("PJ last detectedBardoceFrame: \(self.lastDetectedBarcodeFrame)")
              self.lastDetectedSampleBuffer = sampleBuffer
            case .searching, .searched, .notStarted, .presenting:
              break
            }
            
            
            
//              print("PJ odczytane z barcodu: \(resultsText)")

          }
          
          
      }

      func imageOrientation(
          deviceOrientation: UIDeviceOrientation,
          cameraPosition: AVCaptureDevice.Position
          ) -> VisionDetectorImageOrientation {
          switch deviceOrientation {
          case .portrait:
              return cameraPosition == .front ? .leftTop : .rightTop
          case .landscapeLeft:
              return cameraPosition == .front ? .bottomLeft : .topLeft
          case .portraitUpsideDown:
              return cameraPosition == .front ? .rightBottom : .leftBottom
          case .landscapeRight:
              return cameraPosition == .front ? .topRight : .bottomRight
          case .faceDown, .faceUp, .unknown:
              return .leftTop
          }
      }
    
    
    
    

  /**
   * Call when objects are detected in the given sample buffer. Caller must make sure that this method
   * runs on the main thread.
   *
   * @param objects The list of objects that is detected in the given sample buffer.
   * @param sampleBuffer The given sampleBuffer.
   */
//  func onDetectedObjects(_ objects: [VisionObject]?, in sampleBuffer: SampleBuffer) {
//    assert(Thread.current.isEqual(Thread.main), "onDetectedObjects:inSampleBuffer is not running on the main thread")
//
//    guard let objects = objects, objects.count == 1, let object = objects.first, object.trackingID != nil else {
//      startToDetect()
//      return
//    }
//
//    let sampleBufferSize = self.sampleBufferSize(sampleBuffer.data)
//    let isFocusInsideObjectFrame = object.frame.contains(CGPoint(x: sampleBufferSize.width / 2,
//                                                                 y: sampleBufferSize.height / 2))
//
//
//    if !isFocusInsideObjectFrame {
//      startToDetect()
//      return
//    }
//
//    switch status {
//    case .detecting:
//      cleanUpOverlayView()
//      let convertedRect = convertedRectOfObjectFrame(object.frame, inSampleBufferFrameSize: sampleBufferSize)
//
//      overlayView.showBox(in: convertedRect)
//      start(toConfirmObject: object, sampleBuffer: sampleBuffer)
//    case .confirming:
//      let convertedRect = convertedRectOfObjectFrame(object.frame, inSampleBufferFrameSize: sampleBufferSize)
//      overlayView.showBox(in: convertedRect)
//      lastDetectedObject = object
//      lastDetectedSampleBuffer = sampleBuffer
//    case .searching, .searched, .notStarted:
//      break
//    }
//  }

  // MARK: - Status Handling

  /**
   * Called when it needs to start the detection. Caller must make sure that this method runs on the
   * main thread.
   */
  func startToDetect() {
    assert(Thread.current.isEqual(Thread.main), "startToDetect is not running on the main thread")

    status = .detecting
//            print("PJ status: \(status)")
    cleanUpOverlayView()
//    clearLastDetectedObject()
    clearLastDetectedBarcode()
    weak var weakSelf = self
    sessionQueue.async(execute: {
      guard let strongSelf = weakSelf else {
        return
      }
      #if !TARGET_IPHONE_SIMULATOR
      if !strongSelf.session.isRunning {
        strongSelf.session.startRunning()
      }
      #endif
    })
  }

  /**
   * Starts a product search with last detected object. Caller must make sure that this method runs on
   * the main thread.
   */
//  func startToSearch() {
//    assert(Thread.current.isEqual(Thread.main),
//           "startToSearchWithImage:originalWidth:originalHeight is not running on the main thread")
//
//    status = .searching
////        print("PJ status: \(status)")
//    let originalSampleBufferSize = sampleBufferSize(lastDetectedSampleBuffer.data)
//
//    let croppedImage = self.croppedImage(from: lastDetectedSampleBuffer.data, in: lastDetectedObject.frame)
//    let convertedRect = convertedRectOfObjectFrame(lastDetectedObject.frame,
//                                                   inSampleBufferFrameSize: originalSampleBufferSize)
//    thumbnailWidthHeightRatio = lastDetectedObject.frame.size.height / lastDetectedObject.frame.size.width
//    overlayView.image.image = croppedImage
//    cleanUpOverlayView()
//    overlayView.showImage(in: convertedRect, alpha: 1)
//
//    guard let productSearchRequest = productSearchRequest(from: croppedImage) else {
//      processSearchResponse(nil, for: croppedImage, originalWidth: size_t(originalSampleBufferSize.width),
//                            originalHeight: size_t(originalSampleBufferSize.height), useFakeResponse: true)
//      clearLastDetectedObject()
//      return
//    }
//    let fetcher = fetcherService.fetcher(with: productSearchRequest)
//    weak var weakSelf = self
//    DispatchQueue.global(qos: .default).async(execute: {
//      fetcher.beginFetch { data, error in
//        guard let strongSelf = weakSelf else {
//          return
//        }
//        if error != nil {
//          if let error = error {
//            print("error in fetching: \(error)")
//          }
//          strongSelf.clearLastDetectedObject()
//          return
//        }
//        DispatchQueue.main.async(execute: {
//          guard let strongSelf = weakSelf else {
//            return
//          }
//          strongSelf.processSearchResponse(data, for: croppedImage,
//                                            originalWidth: size_t(originalSampleBufferSize.width),
//                                            originalHeight: size_t(originalSampleBufferSize.height),
//                                            useFakeResponse: false)
//          strongSelf.clearLastDetectedObject()
//        })
//      }
//    })
//  }

    
    func startToSearchBarcode() {
       assert(Thread.current.isEqual(Thread.main),
              "startToSearchWithImage:originalWidth:originalHeight is not running on the main thread")
//        print("PJ Start To Search Barcode")
       
        status = .searching
//        print("PJ status: \(status)")
       let originalSampleBufferSize = sampleBufferSize(lastDetectedSampleBuffer.data)

        print("PJ lastDetectedBarcodeFrame = \(lastDetectedBarcodeFrame)")
       let croppedImage = self.croppedImage(from: lastDetectedSampleBuffer.data, in: lastDetectedBarcodeFrame)
       let convertedRect = convertedRectOfObjectFrame(lastDetectedBarcodeFrame,
                                                      inSampleBufferFrameSize: originalSampleBufferSize)
        thumbnailWidthHeightRatio = lastDetectedBarcodeFrame.size.height / lastDetectedBarcodeFrame.size.width

        
//       overlayView.image.image = croppedImage
       cleanUpOverlayView()
//       overlayView.showImage(in: convertedRect, alpha: 1)
//        print("PJ detectedbarcodeframe: \(lastDetectedBarcodeFrame)")
//        print("PJ convertedRect: \(convertedRect)")
        
//        guard let url = URL(string: "https://www.google.com/search?q=\(lastDetectedBarcode!)") else { return }
//        print("PJ barcode do google: \(url)")

        
        var barcode = ""
        if barcodes.contains(lastDetectedBarcode){
            barcode =  lastDetectedBarcode! //barcodes.randomElement()!
        } else {
            var tempBarcodes = barcodes
            tempBarcodes.append("1234567890")
            barcode = tempBarcodes.randomElement()! //"1234567890"
        }
        
        
        
        FirebaseManager.sharedInstance.checkBarcode(barcode: barcode) { result in

            if let error = result["error"] as? String {
                print("PJ error '\(error)' z checkBarcode i robimy return")
                self.startToDetect()
                return
            }
            
            print("wynik: \(result)")
            
           let imageURL = result["images"] as! Array<String>
           let title = result["product_name"] as! String
           let brand = result["brand"] as! String
            let score = result["score"] as! String
            let status = result["status"] as! String
            let url = URL(string: imageURL.first!)
            let ingredients = result["ingredients"] as! NSDictionary
            
            var ingredientList: [Ingredient] = []
            
            ingredients.forEach { (i) in
                let tempIngredient = Ingredient(id: UUID(), name: i.key as! String, status: i.value as! String)
                ingredientList.append(tempIngredient)
            }
            
            let tempProd = Product(productName: title, score: score, itemNo: self.lastDetectedBarcode, imageURL: "", url: url, priceFullText: "tysiąc pięćset", productTypeName: "Książka", brand: brand, status: status)
//           let products = [tempProd]
        
            var statusColor: Color!
            
                switch status {
                case "good":
                   statusColor = Color.green
                case "moderate":
                   statusColor = Color.orange
                default:
                   statusColor = Color.red
                }
            
          
            let contentView = ContentView(product: tempProd, color: statusColor, ingredientList: ingredientList) // swiftUIView is View
                    let vc = UIHostingController(rootView: contentView)
//            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)// (vc, sender: self) //showDetailViewController
            self.status = .presenting
            self.timerPresentingProduct = Timer.scheduledTimer(timeInterval: TimeInterval(kConfirmingDurationInSec/4),
                                                               target: self, selector: #selector(self.presentingProduct),
                                                               userInfo: nil, repeats: true)
//            Timer.scheduledTimer(timeInterval: <#T##TimeInterval#>, target: <#T##Any#>, selector: <#T##Selector#>, userInfo: <#T##Any?#>, repeats: Bool)
//            self.startToDetect() //TODO startToDetect zrobic gdy jest dismiss modalla
            
        }
        
        
        
        //
//       guard let productSearchRequest = productSearchRequest(from: croppedImage) else {
//         processSearchResponse(nil, for: croppedImage, originalWidth: size_t(originalSampleBufferSize.width),
//                               originalHeight: size_t(originalSampleBufferSize.height), useFakeResponse: true)
//         clearLastDetectedObject()
//         return
//       }
//       let fetcher = fetcherService.fetcher(with: productSearchRequest)
//       weak var weakSelf = self
//       DispatchQueue.global(qos: .default).async(execute: {
//         fetcher.beginFetch { data, error in
//           guard let strongSelf = weakSelf else {
//             return
//           }
//           if error != nil {
//             if let error = error {
//               print("error in fetching: \(error)")
//             }
//             strongSelf.clearLastDetectedObject()
//             return
//           }
//           DispatchQueue.main.async(execute: {
//             guard let strongSelf = weakSelf else {
//               return
//             }
//             strongSelf.processSearchResponse(data, for: croppedImage,
//                                               originalWidth: size_t(originalSampleBufferSize.width),
//                                               originalHeight: size_t(originalSampleBufferSize.height),
//                                               useFakeResponse: false)
//             strongSelf.clearLastDetectedObject()
//           })
//         }
//       })
     }

    
    
  /**
   * Processes search response from server. Caller must make sure that this method runs on the main
   * thread.
   *
   * @param response The raw response from server on product search request.
   * @param image The image of the detected object that is to be searched.
   * @param width The width of the original sample buffer.
   * @param height The height of the original sample buffer.
   * @param useFakeResponse Whether to use fake response or send a product search request to the
   * server.
   */
//  func processSearchResponse(_ response: Data?, for image: UIImage, originalWidth width: size_t,
//                             originalHeight height: size_t, useFakeResponse: Bool) {
//    assert(Thread.current.isEqual(Thread.main), """
//        processSearchRespose:forImage:originalWidth:originalHeight is not running on the main \
//        thread
//        """)
//    status = .searched
////            print("PJ status: \(status)")
//    var products: [Product]
//    if useFakeResponse {
//      products = fakeProductSearchResults()
//    } else {
//      products = Product.products(fromResponse: response) ?? []
//    }
//
//    let productsViewController = ProductListViewController(products: products)
//
//    let bottomSheet = MDCBottomSheetController(contentViewController: productsViewController)
//    bottomSheet.trackingScrollView = productsViewController.collectionView
//
//    bottomSheet.scrimColor = UIColor.clear
//    bottomSheet.dismissOnBackgroundTap = true
//    bottomSheet.delegate = self
//
//    let contentHeight = productsViewController.collectionViewLayout.collectionViewContentSize.height
//    let screenHeight = view.frame.size.height
//
//    let safeInsets = UIUtilities.safeAreaInsets()
//
//    let toOffsetY = contentHeight > screenHeight ?
//      screenHeight / 2.0 - safeInsets.bottom : screenHeight - contentHeight - safeInsets.top - safeInsets.bottom
//    bottomSheetTargetHeight = toOffsetY
//
//    let toFrame = CGRect(x: kThumbnailPaddingAround,
//                         y: toOffsetY - kThumbnailbottomSheetTargetHeight - kThumbnailPaddingAround,
//                         width: thumbnailWidthHeightRatio * kThumbnailbottomSheetTargetHeight,
//                         height: kThumbnailbottomSheetTargetHeight) // Height
//
//    UIView.animate(withDuration: TimeInterval(kBottomSheetAnimationDurationInSec), animations: {
//      self.overlayView.showImage(in: toFrame, alpha: 1)
//    })
//    present(bottomSheet, animated: true)
//  }

    func presentProductInfo(products: Array<Product>){
        
        let productsViewController = ProductListViewController(products: products)

        let bottomSheet = MDCBottomSheetController(contentViewController: productsViewController)
        bottomSheet.trackingScrollView = productsViewController.collectionView

        bottomSheet.scrimColor = UIColor.clear
        bottomSheet.dismissOnBackgroundTap = true
        bottomSheet.delegate = self

        let contentHeight = productsViewController.collectionViewLayout.collectionViewContentSize.height
        let screenHeight = view.frame.size.height

        let safeInsets = UIUtilities.safeAreaInsets()

        let toOffsetY = contentHeight > screenHeight ?
          screenHeight / 2.0 - safeInsets.bottom : screenHeight - contentHeight - safeInsets.top - safeInsets.bottom
        bottomSheetTargetHeight = toOffsetY

        let toFrame = CGRect(x: kThumbnailPaddingAround,
                             y: toOffsetY - kThumbnailbottomSheetTargetHeight - kThumbnailPaddingAround,
                             width: thumbnailWidthHeightRatio * kThumbnailbottomSheetTargetHeight,
                             height: kThumbnailbottomSheetTargetHeight) // Height

        print("PJ toFrame: \(toFrame)")
        
//        UIView.animate(withDuration: TimeInterval(kBottomSheetAnimationDurationInSec), animations: {
//          self.overlayView.showImage(in: toFrame, alpha: 1)
//        })
        
//        present(bottomSheet, animated: true)
        
        let contentView = ContentView(product: products[0], color: Color.black, ingredientList: fakeData) // swiftUIView is View
        let vc = UIHostingController(rootView: contentView)
//        showDetailViewController(vc, sender: Any?)
        present(vc, animated: true)
        
        clearLastDetectedBarcode()
    }
    
    
  /**
   * Calculates the ratio of current value based on `from` and `to` value.
   *
   * @param currentValue The current value.
   * @param fromValue The start point of the range.
   * @param toValue The end point of the range.
   * @return Position of current value in the whole range. It falls into [0,1].
   */
  func ratioOfCurrentValue(_ currentValue: CGFloat, from fromValue: CGFloat, to toValue: CGFloat) -> CGFloat {
    var ratio = (currentValue - fromValue) / (toValue - fromValue)
    ratio = min(ratio, 1)
    return max(ratio, 0)
  }

  /**
   * Called to confirm on the given object.Caller must make sure that this method runs on the main
   * thread.
   *
   * @param object The object to confirm. It will be regarded as the same object if its objectID stays
   *     the same during this stage.
   * @param sampleBuffer The original sample buffer that this object was detected in.
   */
//  func start(toConfirmObject object: VisionObject, sampleBuffer: SampleBuffer) {
//    assert(Thread.current.isEqual(Thread.main), "startToConfirmObject:sampleBuffer is not running on the main thread")
//    clearLastDetectedObject()
//
//
//    let timer = Timer.scheduledTimer(timeInterval: TimeInterval(kConfirmingDurationInSec),
//                                     target: self, selector: #selector(onTimerFired),
//                                     userInfo: nil, repeats: false)
//    timers.append(timer)
//
//    status = .confirming
//    lastDetectedObject = object
//    lastDetectedSampleBuffer = sampleBuffer
//  }

    func startBarcode(toConfirmBarcode barcode: String, sampleBuffer: SampleBuffer, barcodeFrame: CGRect) {
      assert(Thread.current.isEqual(Thread.main), "startToConfirmObject:sampleBuffer is not running on the main thread")
      clearLastDetectedBarcode()
      
      let timer = Timer.scheduledTimer(timeInterval: TimeInterval(kConfirmingDurationInSec),
                                       target: self, selector: #selector(onTimerFired),
                                       userInfo: nil, repeats: false)
      timers.append(timer)

      status = .confirming
      lastDetectedBarcode = barcode
      lastDetectedSampleBuffer = sampleBuffer
      lastDetectedBarcodeFrame = barcodeFrame
        //TODO - moze tutaj wstawic lastdetectedframe bo moze czasami jest tu nil
    }
    
    
  //* Called when timer is up and the detected object is confirmed.
  @objc func onTimerFired() {
    weak var weakSelf = self
    DispatchQueue.main.async(execute: {
      guard let strongSelf = weakSelf else {
        return
      }
       
      switch strongSelf.status {
      case .confirming, .presenting:
        #if !TARGET_IPHONE_SIMULATOR
        strongSelf.sessionQueue.async(execute: {
          weakSelf?.session.stopRunning()
//            print("PJ session stopRunning")
        })
        #endif
//        strongSelf.startToSearch()
        strongSelf.startToSearchBarcode()
        
      case .detecting, .notStarted, .searched, .searching:
        break
      }
    })
  }
    
    
      @objc func presentingProduct() {
        weak var weakSelf = self
        DispatchQueue.main.async(execute: {
          guard let strongSelf = weakSelf else {
            return
          }
//           print("PJ w timer presentingProduct")
            if (strongSelf.presentedViewController == nil) {
                strongSelf.timerPresentingProduct.invalidate()
//                strongSelf.status = .detecting
                strongSelf.startToDetect()
            }
//          switch strongSelf.status {
//          case .presenting:
//            #if !TARGET_IPHONE_SIMULATOR
//            strongSelf.sessionQueue.async(execute: {
//              weakSelf?.session.stopRunning()
//                print("PJ session stopRunning")
//            })
//            #endif
//    //        strongSelf.startToSearch()
//            strongSelf.startToSearchBarcode()
//
//          case .confirming, .detecting, .notStarted, .searched, .searching:
//            break
//          }
        })
      }

  /**
   * Overrides setter for `status` property. It also shows corresponding indicator/message with the
   * status change. Caller must make sure that this method runs on the main thread.
   *
   * @param status The new status.
   */
  // MARK: - Util methods

  /**
   * Returns size of given `CMSampleBufferRef`.
   *
   * @param sampleBuffer The `CMSampleBufferRef` to get size from.
   * @return The size of the given `CMSampleBufferRef`. It describes its width and height.
   */
  func sampleBufferSize(_ sampleBuffer: CMSampleBuffer) -> CGSize {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return CGSize.zero
    }
    let imageWidth = CVPixelBufferGetWidth(imageBuffer)
    let imageHeight = CVPixelBufferGetHeight(imageBuffer)
    return CGSize(width: CGFloat(imageWidth), height: CGFloat(imageHeight))
  }

  /**
   * Converts given frame of a detected object to a `CGRect` in coordinate system of current view.
   *
   * @param frame The frame of detected object.
   * @param size The frame size of the sample buffer.
   * @return Converted rect.
   */
  func convertedRectOfObjectFrame(_ frame: CGRect, inSampleBufferFrameSize size: CGSize) -> CGRect {
    let normalizedRect = CGRect(x: frame.origin.x / size.width,
                                y: frame.origin.y / size.height,
                                width: frame.size.width / size.width,
                                height: frame.size.height / size.height) // Height
    let convertedRect = previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect)
    return convertedRect.standardized
  }

  /**
   * Crops given `CMSampleBufferRef` with given rect.
   *
   * @param sampleBuffer The sample buffer to be cropped.
   * @param rect The rect of the area to be cropped.
   * @return Returns cropped image to the given rect.
   */
  func croppedImage(from sampleBuffer: CMSampleBuffer, in rect: CGRect) -> UIImage {
    let croppedSampleBuffer = ImageUtilities.croppedSampleBuffer(sampleBuffer, with: rect)
    let croppedImage = ImageUtilities.image(from: croppedSampleBuffer)
    
    //PJ
//    let croppedImage = ImageUtilities.image(from: sampleBuffer)
    
    return UIUtilities.orientedUpImage(from: croppedImage!)
  }

  /**
   * Shows/Hides searching indicator.
   *
   * @param isVisible Whether to show/hide searching indicator. YES to show, NO to hide.
   */
  func showSearchingIndicator(_ isVisible: Bool) {
    if isVisible {
      searchingIndicator.isHidden = false
      searchingIndicator.startAnimating()
    } else {
      searchingIndicator.isHidden = true
      searchingIndicator.stopAnimating()
    }
  }

  func showMessage(_ message: String) {
    if messageView.titleLabel.text == message {
      return
    }
    messageView.titleLabel.text = message
    messageView.sizeToFit()
    let size = messageView.sizeThatFits(view.frame.size)
    let startX = (view.frame.size.width - size.width) / 2.0
    let startY = view.frame.size.height - kChipBottomPadding - size.height
    messageView.frame = CGRect(x: startX, y: startY, width: size.width, height: size.height)

    if messageView.alpha != kTransparentAlpha {
      return
    }
    messageView.alpha = kTransparentAlpha
    UIView.animate(withDuration: TimeInterval(kChipFadeInDuration), animations: {
      self.messageView?.alpha = kOpaqueAlpha
    })

    let messageCenter = CGPoint(x: messageView.frame.midX, y: messageView.frame.midY)

    messageView.transform = messageView.transform.scaledBy(x: kChipScaleFromRatio, y: kChipScaleFromRatio)
    messageView.sizeToFit()

    UIView.animate(withDuration: TimeInterval(kChipScaleDuration), animations: {
      self.messageView.center = messageCenter
      self.messageView.transform = self.messageView.transform.scaledBy(x: kChipScaleToRatio, y: kChipScaleToRatio)
    })
  }

  func hideMessage() {
    UIView.animate(withDuration: TimeInterval(kChipFadeInDuration), animations: {
      self.messageView.alpha = kTransparentAlpha
    })
  }

  /**
   * Generates fake product search results for demo when there are no real backend server hooked up.
   */
  func fakeProductSearchResults() -> [Product] {
    var fakeProductSearchResults: [Product] = []
    for index in 0..<kFakeProductSearchResultCount {
      let product = Product.init(productName: String(format: kFakeProductNameFormat, index + 1),
                                 score: nil, itemNo: kFakeProductPriceText, imageURL: nil,
                                 priceFullText: kFakeProductPriceText, productTypeName: kFakeProductTypeName)
      fakeProductSearchResults.append(product)
    }
    return fakeProductSearchResults
  }
}

/**
 * A wrapper class that holds a reference to `CMSampleBufferRef` to let ARC take care of its
 * lifecyle for this `CMSampleBufferRef`.
 */
class SampleBuffer: NSObject {
  // The encapsulated `CMSampleBufferRed` data.
  var data: CMSampleBuffer!

  // MARK: - Public
  init(sampleBuffer: CMSampleBuffer) {
    super.init()
    self.data = sampleBuffer
  }
}


extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}
