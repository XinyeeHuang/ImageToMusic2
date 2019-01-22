//
//  ColorPickerViewController.swift
//  ImageToMusic
//
//  Created by Iris on 2019/1/14.
//  Copyright © 2019 HuangXinyi. All rights reserved.
//

import UIKit
import AudioKit

class ColorPickerViewController: UIViewController {

    
    @IBOutlet weak var userImageView: UIImageView!
    var userImage: UIImage!
    
    //以下为需要变化的UI
    @IBOutlet weak var bgImageView: UIView!
    
    @IBOutlet weak var triad: UILabel!
    @IBOutlet weak var noteC: UILabel!
    @IBOutlet weak var noteD: UILabel!
    @IBOutlet weak var noteE: UILabel!
    @IBOutlet weak var noteF: UILabel!
    @IBOutlet weak var noteG: UILabel!
    @IBOutlet weak var noteA: UILabel!
    @IBOutlet weak var noteB: UILabel!
    @IBOutlet weak var valueHigh: UILabel!
    @IBOutlet weak var valueMid: UILabel!
    @IBOutlet weak var valueLow: UILabel!
    @IBOutlet weak var valueLowLow: UILabel!
    @IBOutlet weak var triadMajor: UILabel!
    @IBOutlet weak var triadMajorColor: UIImageView!
    @IBOutlet weak var triadMinor: UILabel!
    @IBOutlet weak var triadMinorColor: UIImageView!
    var mode = "note"
    @IBOutlet weak var modeNoteButton: UIButton!
    @IBOutlet weak var modeChordButton: UIButton!
    @IBAction func modeNote(_ sender: UIButton) {
        mode = "note"
        modeNoteButton.backgroundColor = #colorLiteral(red: 0.317189838, green: 0.317189838, blue: 0.317189838, alpha: 1)
        modeNoteButton.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for:.normal)
        modeNoteButton.isEnabled = false
        modeChordButton.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        modeChordButton.titleLabel?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        modeChordButton.isEnabled = true
    }
    @IBAction func modeChord(_ sender: UIButton) {
        mode = "chord"
        modeChordButton.backgroundColor = #colorLiteral(red: 0.317189838, green: 0.317189838, blue: 0.317189838, alpha: 1)
        modeChordButton.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for:.normal)
        modeChordButton.isEnabled = false
        modeNoteButton.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        modeNoteButton.titleLabel?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        modeNoteButton.isEnabled = true
    }
    
    //生成振荡器
    var oscillator1 = AKOscillator()
    var oscillator2 = AKOscillator()
    var oscillator3 = AKOscillator()
    var oscillator4 = AKOscillator()
    var envelope1: AKAmplitudeEnvelope!
    var envelope2: AKAmplitudeEnvelope!
    var envelope3: AKAmplitudeEnvelope!
    var envelope4: AKAmplitudeEnvelope!
    var soundOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //显示用户选取的图片
        userImageView.image = userImage
    }
    
    //点击事件
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            if soundOn == false{
                
            resetColor() //将所有UI颜色调回默认值
                
            // 获取用户点击位置在图像上的相对位置
            let point = touch.location(in: userImageView)
            let userColor : UIColor
            userColor = userImageView.pickColor(at: point).touchColor
            bgImageView.backgroundColor = userColor
            
            //根据对应规则发出声音：1.计算HSB->2.对应规则（声音&UI）->3.发出声音
            //1.计算颜色HSB值
            let r = Double(userImageView.pickColor(at: point).red)
            let g = Double(userImageView.pickColor(at: point).green)
            let b = Double(userImageView.pickColor(at: point).blue)
            let maxrgb = Double(max(r,g,b))
            let minrgb = Double(min(r,g,b))
            let h: Double
            let s: Double
            let v: Double
            if maxrgb == minrgb{
                h = 0
            }else if maxrgb == r && g>=b{
                h = 60*(g-b)/(maxrgb-minrgb)
            }else if maxrgb == r && g<b{
                h = 60*(g-b)/(maxrgb-minrgb)+360
            }else if maxrgb == g{
                h = 60*(b-r)/(maxrgb-minrgb)+120
            }else if maxrgb == b{
                h = 60*(r-g)/(maxrgb-minrgb)+240
            }else{
                h = 0
            }
            if maxrgb == 0{
                s = 0
            }else{
                s = 1 - minrgb/maxrgb
            }
            v = maxrgb
            print("hsv:\(h, s, v)")
            
            //2.对应规则（声音&UI）
            var note = [Double]()
            var amplitudeLevel = 1.0
            //value饱和度决定高中低音组
            if v <= 1 && v >= 0.8 {
                valueHigh.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                //note = [0, 1046, 1175, 1318, 1397, 1568, 1760, 1976, 2092, 2350, 2636, 2794]
                note = [0, 523, 554, 587, 622, 659, 698, 740, 784, 830, 880, 932, 988, 1046, 1108, 1175, 1244, 1318, 1397, 1480, 1568]
                amplitudeLevel = 0.5
            }else if v < 0.8 && v >= 0.6 {
                valueMid.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                note = [0, 262, 277, 294, 311, 330, 349, 370, 392, 415, 440, 466, 494, 523, 554, 587, 622, 659, 698, 740, 784]
                amplitudeLevel = 0.7
            }else if v < 0.6 && v >= 0.4 {
                valueLow.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                note = [0, 131, 136, 147, 155, 165, 174, 185, 196, 207, 220, 233, 247, 262, 277, 294, 311, 330, 349, 370, 392]
                amplitudeLevel = 3
            }else{
                valueLowLow.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                //note = [0, 65, 74, 57, 87, 98, 110, 123, 131, 147, 115, 174, 196]
                note = [0, 131, 136, 147, 155, 165, 174, 185, 196, 207, 220, 233, 247, 262, 277, 294, 311, 330, 349, 370, 392]
                amplitudeLevel = 3
            }
            //hue色相决定和弦根音，saturation饱和度决定大三和弦或小三和弦
            if (h >= 0 && h < 23) || (h >= 240 && h <= 360){
                noteC.textColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                triadMajorColor.backgroundColor = #colorLiteral(red: 1, green: 0.1, blue: 0.1, alpha: 1)
                triadMinorColor.backgroundColor = #colorLiteral(red: 1, green: 0.6012146832, blue: 0.6012146832, alpha: 1)
                oscillator1.frequency = note[1]
                if (s > 0.62){
                    oscillator2.frequency = note[5]
                    triadMajor.textColor = #colorLiteral(red: 1, green: 0.1, blue: 0.1, alpha: 1)
                    triad.text = "C"
                }else{
                    oscillator2.frequency = note[4]
                    triadMinor.textColor = #colorLiteral(red: 1, green: 0.6012146832, blue: 0.6012146832, alpha: 1)
                    triad.text = "Cm"
                }
                oscillator3.frequency = note[8]
            }else if h >= 23 && h < 68{
                noteD.textColor = #colorLiteral(red: 1, green: 0.75, blue: 0, alpha: 1)
                triadMajorColor.backgroundColor = #colorLiteral(red: 1, green: 0.7875, blue: 0.15, alpha: 1)
                triadMinorColor.backgroundColor = #colorLiteral(red: 1, green: 0.9, blue: 0.6, alpha: 1)
                oscillator1.frequency = note[3]
                if (s > 0.62){
                    oscillator2.frequency = note[7]
                    triadMajor.textColor = #colorLiteral(red: 1, green: 0.7875, blue: 0.15, alpha: 1)
                    triad.text = "D"
                }else{
                    oscillator2.frequency = note[6]
                    triadMinor.textColor = #colorLiteral(red: 1, green: 0.9, blue: 0.6, alpha: 1)
                    triad.text = "Dm"
                }
                oscillator3.frequency = note[10]
            }else if h >= 68 && h < 105{
                noteE.textColor = #colorLiteral(red: 0.5, green: 1, blue: 0, alpha: 1)
                triadMajorColor.backgroundColor = #colorLiteral(red: 0.575, green: 1, blue: 0.15, alpha: 1)
                triadMinorColor.backgroundColor = #colorLiteral(red: 0.8, green: 1, blue: 0.6, alpha: 1)
                oscillator1.frequency = note[5]
                if (s > 0.62){
                    oscillator2.frequency = note[9]
                    triadMajor.textColor = #colorLiteral(red: 0.575, green: 1, blue: 0.15, alpha: 1)
                    triad.text = "E"
                }else{
                    oscillator2.frequency = note[8]
                    triadMinor.textColor = #colorLiteral(red: 0.8, green: 1, blue: 0.6, alpha: 1)
                    triad.text = "Em"
                }
                oscillator3.frequency = note[12]
            }else if h >= 105 && h < 150{
                noteF.textColor = #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1)
                triadMajorColor.backgroundColor = #colorLiteral(red: 0.15, green: 1, blue: 0.15, alpha: 1)
                triadMinorColor.backgroundColor = #colorLiteral(red: 0.6, green: 1, blue: 0.6, alpha: 1)
                oscillator1.frequency = note[6]
                if (s > 0.62){
                    oscillator2.frequency = note[10]
                    triadMajor.textColor = #colorLiteral(red: 0.15, green: 1, blue: 0.15, alpha: 1)
                    triad.text = "F"
                }else{
                    oscillator2.frequency = note[9]
                    triadMinor.textColor = #colorLiteral(red: 0.6, green: 1, blue: 0.6, alpha: 1)
                    triad.text = "Fm"
                }
                oscillator3.frequency = note[13]
            }else if h >= 150 && h < 213{
                noteG.textColor = #colorLiteral(red: 0, green: 1, blue: 1, alpha: 1)
                triadMajorColor.backgroundColor = #colorLiteral(red: 0.15, green: 1, blue: 1, alpha: 1)
                triadMinorColor.backgroundColor = #colorLiteral(red: 0.6, green: 1, blue: 1, alpha: 1)
                oscillator1.frequency = note[8]
                if (s > 0.62){
                    oscillator2.frequency = note[12]
                    triadMajor.textColor = #colorLiteral(red: 0.15, green: 1, blue: 1, alpha: 1)
                    triad.text = "G"
                }else{
                    oscillator2.frequency = note[11]
                    triadMinor.textColor = #colorLiteral(red: 0.6, green: 1, blue: 1, alpha: 1)
                    triad.text = "Gm"
                }
                oscillator3.frequency = note[15]
            }else if h >= 213 && h < 283{
                noteA.textColor = #colorLiteral(red: 0.08333333333, green: 0, blue: 1, alpha: 1)
                triadMajorColor.backgroundColor = #colorLiteral(red: 0.2208333333, green: 0.15, blue: 1, alpha: 1)
                triadMinorColor.backgroundColor = #colorLiteral(red: 0.6333333333, green: 0.6, blue: 1, alpha: 1)
                oscillator1.frequency = note[10]
                if (s > 0.62){
                    oscillator2.frequency = note[14]
                    triadMajor.textColor = #colorLiteral(red: 0.2208333333, green: 0.15, blue: 1, alpha: 1)
                    triad.text = "A"
                }else{
                    oscillator2.frequency = note[13]
                    triadMinor.textColor = #colorLiteral(red: 0.6333333333, green: 0.6, blue: 1, alpha: 1)
                    triad.text = "Am"
                }
                oscillator3.frequency = note[17]
            }else{
                noteB.textColor = #colorLiteral(red: 1, green: 0, blue: 0.6666666667, alpha: 1)
                triadMajorColor.backgroundColor = #colorLiteral(red: 1, green: 0.15, blue: 0.7166666667, alpha: 1)
                triadMinorColor.backgroundColor = #colorLiteral(red: 1, green: 0.6, blue: 0.8666666667, alpha: 1)
                oscillator1.frequency = note[12]
                if (s > 0.62){
                    oscillator2.frequency = note[16]
                    triadMajor.textColor = #colorLiteral(red: 1, green: 0.15, blue: 0.7166666667, alpha: 1)
                    triad.text = "B"
                }else{
                    oscillator2.frequency = note[15]
                    triadMinor.textColor = #colorLiteral(red: 1, green: 0.6, blue: 0.8666666667, alpha: 1)
                    triad.text = "Bm"
                }
                oscillator3.frequency = note[19]
            }
            
            //3.发出声音
            //音量设置
            oscillator1.amplitude = 1.0 * amplitudeLevel
            oscillator2.amplitude = 1.0 * amplitudeLevel
            oscillator3.amplitude = 1.0 * amplitudeLevel
            //振荡器封包
            envelope1 = AKAmplitudeEnvelope(oscillator1)
            envelope1.attackDuration = 0.01
            envelope1.decayDuration = 0.1
            envelope1.sustainLevel = 0.1
            envelope1.releaseDuration = 0.3
            envelope2 = AKAmplitudeEnvelope(oscillator2)
            envelope2.attackDuration = 0.01
            envelope2.decayDuration = 0.1
            envelope2.sustainLevel = 0.1
            envelope2.releaseDuration = 0.3
            envelope3 = AKAmplitudeEnvelope(oscillator3)
            envelope3.attackDuration = 0.01
            envelope3.decayDuration = 0.1
            envelope3.sustainLevel = 0.1
            envelope3.releaseDuration = 0.3
            
            //将振荡器设置为audiokit的输出
            let oscillatorMix = AKMixer(envelope1, envelope2, envelope3, envelope4)
            AudioKit.output = oscillatorMix
            //开启audiokit
            try? AudioKit.start()
            //振荡器发声
            oscillatorMix.start()
            oscillator1.start()
            oscillator2.start()
            oscillator3.start()
            
            //发声模式：音符演奏
            func playModeNote(){
                let timeLoop : TimeInterval = 0.4
        
                self.soundOn = true
                self.envelope1.start()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeLoop){
                    self.envelope1.stop()
                    self.envelope2.start()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeLoop){
                        self.envelope2.stop()
                        self.envelope3.start()
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeLoop){
                            self.envelope3.stop()
                            self.envelope2.start()
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeLoop){

                                self.envelope2.stop()
                                print("停2")
                                self.soundOn = false
                            }
                        }
                    }
                }
            }
            //发声模式：和弦演奏
            func playModeChord(){
                let timeLoop : TimeInterval = 1.0
                self.soundOn = true
                self.envelope1.start()
                self.envelope2.start()
                self.envelope3.start()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeLoop){
                    self.envelope1.stop()
                    self.envelope2.stop()
                    self.envelope3.stop()
                    print("结束停")
                    self.soundOn = false
                }
            }
            
            //发声
            switch mode{
            case "note": playModeNote()
            case "chord": playModeChord()
            default:playModeNote()
            }
        }
        } else {
            return
        }
        
    }
    
    
    func resetColor(){
        print("resetColor")
        noteC.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        noteD.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        noteE.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        noteF.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        noteG.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        noteA.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        noteB.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        valueHigh.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        valueMid.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        valueLow.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        valueLowLow.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        triadMajor.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        triadMinor.textColor = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    }
}



//获取指定点的颜色信息 🌟🌟🌟 使用layer渲染
public extension UIView {
    // position: 位置, bitmapinfo: 位图颜色信息
    // return: 使用元组，将颜色，rgb值返回
    public func pickColor(at position: CGPoint) -> (touchColor: UIColor, red: Float, green : Float, blue: Float) {
        
        // 用来存放目标像素值
        var pixel = [UInt8](repeatElement(0, count: 4))
        // 颜色空间为 RGB
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // 设置位图颜色分布为 RGBA
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        if let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo) {
            // 设置 context 原点偏移为目标位置所有坐标
            context.translateBy(x: -position.x, y: -position.y)
            // 将图像渲染到 context 中
            layer.render(in: context)
            
            let r = CGFloat(pixel[0]) / 255.0
            let g = CGFloat(pixel[1]) / 255.0
            let b = CGFloat(pixel[2]) / 255.0
            let a = CGFloat(pixel[3]) / 255.0
            print("r: \(r), g: \(g), b: \(b), a: \(a)")
            return (UIColor(red: r, green: g, blue: b, alpha: a),Float(r),Float(g),Float(b))
            
        } else {
            return (UIColor.white,0.0,0.0,0.0)
        }
    }
}
