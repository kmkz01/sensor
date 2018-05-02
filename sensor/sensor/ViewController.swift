//
//  ViewController.swift
//  sensor
//
//  Created by nishimoto_noboru on 2017/10/11.
//  Copyright © 2017年 nishimoto_noboru. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    //パルス
    var pulsePlayer: AVAudioPlayerNode!
    var pulseEngine: AVAudioEngine!
    var pulseFile: AVAudioFile!
    var pulseBuffer: AVAudioPCMBuffer!
    var timer : Timer!
    var timePitch: AVAudioUnitTimePitch!
    
    //パルス音のセットアップのための関数
    func pulseSetup(){
        let path = Bundle.main.path(forResource: "hb", ofType: "mp3")
        let url = NSURL.fileURL(withPath: path!)
        
        //タイマーを利用するために保持
        timer = Timer()
        timePitch = AVAudioUnitTimePitch()
        //エンジン及びノードを用意する
        pulseEngine = AVAudioEngine()
        pulsePlayer = AVAudioPlayerNode()
        pulseFile = try! AVAudioFile(forReading: url)
        pulseBuffer = AVAudioPCMBuffer(pcmFormat: pulseFile.processingFormat,
                                       frameCapacity: AVAudioFrameCount(pulseFile.length))
        
        do {
            //Do it
            try pulseFile.read(into: pulseBuffer)
        } catch _ {
        }
        
        //エンジンアタッチ
        pulseEngine.attach(pulsePlayer)
        pulseEngine.attach(timePitch)
        pulseEngine.connect(pulsePlayer, to: pulseEngine.mainMixerNode, format: pulseBuffer.format)
        
        //音の高さを変更するためにNodeを繋ぐ
        pulseEngine.connect(pulsePlayer, to: timePitch, format: nil)
        pulseEngine.connect(timePitch, to: pulseEngine.mainMixerNode, format: nil)
        
        pulseEngine.prepare()
        do{
            try pulseEngine.start()
        }catch _{
        }
    }
    
    //パルス音再生のための関数（時間間隔を変更するものとする）
    //０:心拍数０、１:心拍数２０、２:心拍数７０、３:心拍数１２０、４:心拍数１６０
    func pulseSoundPlay(i: Int){
        switch(i){
        case 0:
            stopTimer()
            break
        case 20:
            stopTimer()
            startTimer(i: 3)
            break
            
        case 70:
            stopTimer()
            startTimer(i: 0.88)
            
            break
        case 80:
            stopTimer()
            startTimer(i: 0.75)
            
        case 120:
            stopTimer()
            startTimer(i: 0.5)
            break
            
        case 160:
            stopTimer()
            startTimer(i: 0.38)
            break
            
        default:
            break
        }
    }
    
    //音楽再生を開始する
    func startTimer(i: Float){
        if timer == nil {
            timer = Timer.scheduledTimer(
                timeInterval: TimeInterval(i),
                target: self,
                selector: #selector(self.update),
                userInfo: nil, repeats: true)
        }
    }
    
    //音楽再生を停止する
    func stopTimer(){
        if timer != nil{
            timer.invalidate()
            timer = nil
        }
    }
    
    
    //パルス音ループのためのアップデート関数
    func update(tm: Timer){
        pulsePlayer.scheduleBuffer(pulseBuffer, at: nil,  completionHandler: nil)
        
        //聴診判定
        Konashi.analogReadRequest(KonashiAnalogIOPin.IO0)
        if(Konashi.analogRead(KonashiAnalogIOPin.IO0) < 500){
            pulsePlayer.play()
        }else{
            pulsePlayer.stop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pulseSetup()
        
        Konashi.shared().readyHandler = {() -> Void in
            Konashi.pinMode(KonashiDigitalIOPin.LED2, mode: KonashiPinMode.output)
            Konashi.digitalWrite(KonashiDigitalIOPin.LED2, value: KonashiLevel.high)
            
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func find(_ sender: Any) {
        Konashi.find()
        pulseSoundPlay(i: 70)
    }
    

    @IBAction func read(_ sender: Any) {
        Konashi.analogReadRequest(KonashiAnalogIOPin.IO0)
        print(Konashi.analogRead(KonashiAnalogIOPin.IO0))
    }
}

