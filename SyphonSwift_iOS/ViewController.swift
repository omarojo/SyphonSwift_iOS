//
//  ViewController.swift
//  SyphonSwift_iOS
//
//  Created by Omar Juarez Ortiz on 2017-02-13.
//  Copyright © 2017 Omar Juarez Ortiz. All rights reserved.
//

import UIKit
import TL_INetSyphonSDK

class ViewController: UIViewController {
    var syphonServer : TL_INetTCPSyphonSDK? = nil
    var thePixelBuffer : CVPixelBuffer?
    let testImage : UIImage = UIImage.init(named: "twdEnds.png")!
    var invert  : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notifCenter =  NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(startSyphonServer), name: .UIApplicationDidBecomeActive, object: nil)
        
        syphonServer = TL_INetTCPSyphonSDK.init()
        syphonServer?.setEncodeType(TCPUDPSyphonEncodeType(rawValue: 0)!)
        syphonServer?.setEncodeQuality(0.5)
        
        //Make the pixelbuffer
        self.thePixelBuffer = self.pixelBufferFromImage(image: testImage)
        self.sendVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func sendVideo(){
        
        syphonServer?.setSendImage(thePixelBuffer, flipHorizontal: invert, flipVertical: false)
        invert = !invert
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
            self.sendVideo()
        }
    }
    
    @objc func startSyphonServer() {
        syphonServer?.startServer("iPhoneSwiftSample_Server")
    
    }
    func pixelBufferFromImage(image: UIImage) -> CVPixelBuffer {
        
        
        let ciimage = CIImage(image: image)
        //let cgimage = convertCIImageToCGImage(inputImage: ciimage!)
        let tmpcontext = CIContext(options: nil)
        let cgimage =  tmpcontext.createCGImage(ciimage!, from: ciimage!.extent)
        
        /*
         NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
         (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
         */
        // stupid CFDictionary stuff
        let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
        let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
        let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
        let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        keysPointer.initialize(to: keys)
        valuesPointer.initialize(to: values)
        
        let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
        
        
        let width = cgimage!.width
        let height = cgimage!.height
        
        //        let pxbuffer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
        var pxbuffer: CVPixelBuffer?
        // if pxbuffer = nil, you will get status = -6661
        var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, options, &pxbuffer)
        //debugPrint("status = \(status)")
        //        status = CVPixelBufferLockBaseAddress(pxbuffer.pointee!, CVPixelBufferLockFlags(rawValue: 0));
        status = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
        
        //        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer.pointee!);
        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer!);
        //        debugPrint("pxbuffer.memory = \(pxbuffer.pointee)")
        //debugPrint("pxbuffer.memory = \(pxbuffer)")
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        //debugPrint("rgbColorSpace = \(rgbColorSpace)")
        //        let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer.pointee!)
        let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer!)
        let context = CGContext(data: bufferAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesperrow,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue);
        context?.concatenate(CGAffineTransform(rotationAngle: 0))
        context?.concatenate(__CGAffineTransformMake( 1, 0, 0, -1, 0, CGFloat(height) )) //Flip Vertical
//        context?.concatenate(__CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGFloat(width), 0.0)) //Flip Horizontal
        

        //debugPrint("context = \(context.debugDescription)")
        context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)));
        //        status = CVPixelBufferUnlockBaseAddress(pxbuffer.pointee!, CVPixelBufferLockFlags(rawValue: 0));
        status = CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
        return pxbuffer!;
        
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidBecomeActive,
                                                  object: nil)
    }
}

