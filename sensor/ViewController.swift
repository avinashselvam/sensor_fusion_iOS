//
//  ViewController.swift
//  sensor
//
//  Created by Avinash on 27/09/18.
//  Copyright © 2018 eightyfive. All rights reserved.
//

import UIKit
import CoreMotion
import SceneKit

class ViewController: UIViewController {
    
    var alreadyRunning = true
    
    var a = 0.0, b = 0.0, c = 0.0
    
    var blue : UIColor!
    
    var ame = SCNVector3(0.0, 0.0, 0.0)
    var ge = SCNVector3(0.0, 0.0, 0.0)
    
    var calibOffset = SCNVector3(0.0, 0.0, 0.0)
    
    @IBOutlet weak var startBtn: UILabel!
    
    @objc func onTap(){
        if alreadyRunning {
            stopUpdates()
            startBtn.text = "Start"
            startBtn.textColor = self.blue
            self.alreadyRunning = false
        }
        else{
            startUpdates()
            startBtn.text = "Stop"
            startBtn.textColor = UIColor.red
            self.alreadyRunning = true
        }
    }
    @IBAction func calibrate(_ sender: UIButton) {
        if let data = self.motionManager.gyroData {
            
            let x = data.rotationRate.x
            let y = data.rotationRate.y
            let z = data.rotationRate.z
            
            self.calibOffset = SCNVector3(x, y, z)
            
        }
    }
    
//    filtered estimate
    @IBOutlet weak var Fz: UILabel!
    @IBOutlet weak var Fy: UILabel!
    @IBOutlet weak var Fx: UILabel!
    
//    gyro estimate
    @IBOutlet weak var GEz: UILabel!
    @IBOutlet weak var GEy: UILabel!
    @IBOutlet weak var GEx: UILabel!
    
    
//    Accelerometer + Magnetometer estimate
    @IBOutlet weak var AMEz: UILabel!
    @IBOutlet weak var AMEy: UILabel!
    @IBOutlet weak var AMEx: UILabel!
    
//    gyro
    @IBOutlet weak var Gz: UILabel!
    @IBOutlet weak var Gy: UILabel!
    @IBOutlet weak var Gx: UILabel!
    
//    accelerometer
    @IBOutlet weak var Az: UILabel!
    @IBOutlet weak var Ay: UILabel!
    @IBOutlet weak var Ax: UILabel!
    
//    magnetometer
    @IBOutlet weak var Mz: UILabel!
    @IBOutlet weak var My: UILabel!
    @IBOutlet weak var Mx: UILabel!
    
    let motionManager = CMMotionManager()
    var timer = Timer()
    
    func compFilter(factor f: Float) {
        
        let ge = self.ge, ame = self.ame
        
        let x = f*ge.x + (1-f)*ame.x
        let y = f*ge.y + (1-f)*ame.y
        let z = f*ge.z + (1-f)*ame.z
        
        self.Fx.text = String(format: "%.3f", x)
        self.Fy.text = String(format: "%.3f", y)
        self.Fz.text = String(format: "%.3f", z)
        
    }
    
    func kalmanFilter(){
        
    }
    
    func stopUpdates() {
        self.timer.invalidate()
        self.motionManager.stopGyroUpdates()
        self.motionManager.stopAccelerometerUpdates()
        self.motionManager.stopMagnetometerUpdates()
    }
    
    func startUpdates() {
        if motionManager.isAccelerometerAvailable{
            self.motionManager.accelerometerUpdateInterval = 1.0/60
            self.motionManager.startAccelerometerUpdates()
        }
        
        if motionManager.isMagnetometerAvailable{
            self.motionManager.magnetometerUpdateInterval = 1.0/60
            self.motionManager.startMagnetometerUpdates()
        }
        
        if motionManager.isGyroAvailable{
            self.motionManager.gyroUpdateInterval = 1.0/60
            self.motionManager.startGyroUpdates()
        }
        
        self.timer = Timer(fire: Date(), interval: 1.0/60.0, repeats: true, block:{ (timer) in
            
            if let data = self.motionManager.gyroData {
                
                let x = data.rotationRate.x - Double(self.calibOffset.x)
                let y = data.rotationRate.y - Double(self.calibOffset.y)
                let z = data.rotationRate.z - Double(self.calibOffset.z)
                
                self.Gx.text = String(format: "%.3f", x)
                self.Gy.text = String(format: "%.3f", y)
                self.Gz.text = String(format: "%.3f", z)
                
//                update alpha, beta, gamma
                self.a += x*(timer.timeInterval)
                self.b += y*(timer.timeInterval)
                self.c += z*(timer.timeInterval)
                
                self.GEx.text = String(format: "%.3f", self.a)
                self.GEy.text = String(format: "%.3f", self.b)
                self.GEz.text = String(format: "%.3f", self.c)
                
                self.ge = SCNVector3(self.a, self.b, self.c)
                
                
            }
            
            if let data = self.motionManager.magnetometerData {
                
                let x = data.magneticField.x
                let y = data.magneticField.y
                let z = data.magneticField.z
                
                self.Mx.text = String(format: "%.2f", x)
                self.My.text = String(format: "%.2f", y)
                self.Mz.text = String(format: "%.2f", z)
                
                let yaw = atan(y/x)
                
                self.AMEy.text = String(format: "%.3f", yaw)
                
                self.ame.y = Float(yaw)
            }
            
            if let data = self.motionManager.accelerometerData {
                
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                
                self.Ax.text = String(format: "%.3f", x)
                self.Ay.text = String(format: "%.3f", y)
                self.Az.text = String(format: "%.3f", z)
                
                let pitch = atan(y/pow(pow(x, 2) + pow(z,2), 0.5))
                let roll = atan(-x/z)
                
                self.AMEx.text = String(format: "%.3f", pitch)
                self.AMEz.text = String(format: "%.3f", roll)
                
                self.ame.x = Float(pitch)
                self.ame.z = Float(roll)
                
            }
            
            self.compFilter(factor: 0.3)
            
        })
        
        RunLoop.current.add(self.timer, forMode: RunLoop.Mode.default)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.blue = startBtn.textColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tap.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tap)
    }


}
