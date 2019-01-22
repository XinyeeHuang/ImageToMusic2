//
//  CameraPickerViewController.swift
//  ImageToMusic
//
//  Created by Iris on 2019/1/15.
//  Copyright © 2019 HuangXinyi. All rights reserved.
//
//加入相机取色功能

import UIKit
import  AVFoundation

class CameraPickerViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {

    
    @IBOutlet weak var anchorButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    let previewLayer = CALayer()
    
    internal func setupUI() {
        previewLayer.bounds = view.bounds
        previewLayer.position = view.center
        previewLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
        previewLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)))
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    //
    let session = AVCaptureSession()
    
    // 相机数据帧接收队列
    let queue = DispatchQueue(label: "com.camera.video.queue")
    
    // 取色位置
    var center: CGPoint = .zero
    internal func setupParameter() {
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
        if let captureDevice = AVCaptureDevice.default(for: .video),let deviceInput = try? AVCaptureDeviceInput(device: captureDevice){
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: NSNumber(value: kCMPixelFormat_32BGRA)] as? [String : Any]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            session.commitConfiguration()
            
        } else {
            return
        }
        
       
        
       
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        // 获取用户点击位置在图像上的相对位置
        let point = touch.location(in: self.view)
        center = point
        anchorButton.frame = CGRect(x: point.x - 20, y: point.y - 20 / 2, width: 40, height: 40)
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        guard let baseAddr = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            return
        }
        let width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bimapInfo: CGBitmapInfo = [
            .byteOrder32Little,
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
        
        guard let content = CGContext(data: baseAddr, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bimapInfo.rawValue) else {
            return
        }
        
        // 如果是从像素数据中获取特定位置像素，则是按以下被注释的这部分代码进行获取
        // 其中像素排序为：BGRA，index 需要进行要应的变换
        //        let data = baseAddr.assumingMemoryBound(to: UInt8.self)
        //        let index = width * height * 2
        //        let b = CGFloat(data.advanced(by: index + 0).pointee) / 255
        //        let g = CGFloat(data.advanced(by: index + 1).pointee) / 255
        //        let r = CGFloat(data.advanced(by: index + 2).pointee) / 255
        //        let a = CGFloat(data.advanced(by: index + 3).pointee) / 255
        //        let color = UIColor(red: r, green: g, blue: b, alpha: a)
        
        guard let cgImage = content.makeImage() else {
            return
        }
        
        DispatchQueue.main.async {
            self.previewLayer.contents = cgImage
            // self.previewLayer.pickColor 为 CALayer 的一个扩展
            self.view.layer.backgroundColor = (self.previewLayer.pickColor(at: self.center) as! CGColor)
        }
    }

}

public extension CALayer {
    
    /// 获取特定位置的颜色
    ///
    /// - parameter at: 位置
    ///
    /// - returns: 颜色
    public func pickColor(at position: CGPoint) -> UIColor? {
        
        // 用来存放目标像素值
        var pixel = [UInt8](repeatElement(0, count: 4))
        // 颜色空间为 RGB，这决定了输出颜色的编码是 RGB 还是其他（比如 YUV）
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // 设置位图颜色分布为 RGBA
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }
        // 设置 context 原点偏移为目标位置所有坐标
        context.translateBy(x: -position.x, y: -position.y)
        // 将图像渲染到 context 中
        render(in: context)
        
        return UIColor(red: CGFloat(pixel[0]) / 255.0,
                       green: CGFloat(pixel[1]) / 255.0,
                       blue: CGFloat(pixel[2]) / 255.0,
                       alpha: CGFloat(pixel[3]) / 255.0)
    }
}
