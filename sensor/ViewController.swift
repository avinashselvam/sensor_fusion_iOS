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
    
//    filter choice
    @IBOutlet weak var filterName: UISegmentedControl!
    
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
    
//  <----- CODE STARTS FROM HERE ----->
    
    let motionManager = CMMotionManager()
    var timer = Timer()
    
    let kalmanFilters = [Kalman(), Kalman(), Kalman()]
    
    var g = float3(0,0,0) { didSet{ setLabels([Gx, Gy, Gz], with: g) } }
    var a = float3(0,0,0) { didSet{ setLabels([Ax, Ay, Az], with: a) } }
    var m = float3(0,0,0) { didSet{ setLabels([Mx, My, Mz], with: m) } }
    
    var gOffset = float3(-0.02,0.2,-0.02)
    
    var ge = float3(0,0,0) { didSet{ setLabels([GEx, GEy, GEz], with: ge.toDegree()) } }
    var ame = float3(0,0,0) { didSet{ setLabels([AMEx, AMEy, AMEz], with: ame.toDegree()) } }
    
    var fe = float3(0,0,0) { didSet{ setLabels([Fx, Fy, Fz], with: fe.toDegree()) } }
    
//    app's state i.e if sensor data is being received
    var isRunning = true
    
//    the two buttons in the app
    @IBAction func calibrate(_ sender: UIButton) {
        initGyro()
    }
    
    @IBAction func start(_ sender: UIButton) {
        isRunning = !isRunning
        if isRunning {
            stopUpdates()
            sender.setTitle("Start", for: .normal)
            sender.setTitleColor(UIColor(red: 0, green: 0.478431, blue: 1, alpha: 1), for: .normal)
        }
        else {
            startUpdates()
            sender.setTitle("Stop", for: .normal)
            sender.setTitleColor(UIColor.red, for: .normal)
        }
    }
    
    func initGyro(){
        //  gyro needs initial values since it measures only angular velocity.
        //  So we init its estimate with acc + mag estimate
        ge = ame
    }
    
    func setLabels(_ labels: [UILabel], with values: float3){
        for i in 0..<3 {
            labels[i].text = "\(values[i])"
        }
    }
    
    func getsetSensorValues(){
        if let accValues = motionManager.getAcc() { a = accValues }
        if let magValues = motionManager.getMag() { m = magValues }
        if let gyroValues = motionManager.getGyro() { g = gyroValues - gOffset }
    }
    
    func calcEstimates(){
        //        angle = 0.98 *(angle+gyro*dt) + 0.02*acc
        //       x -> pitch, y -> roll, z -> yaw
        let dt = timer.timeInterval.f(2)
        ge += float3(g.x*dt, g.y*dt, g.z*dt)
        
        ame = float3(atan2(a.y, a.z), atan2(a.x, a.z), atan2(m.z, m.x))
    }
    
    func complimentaryFilter(withFactor f: Float){
        fe = float3(f*ge.x + (1-f)*ame.x, f*ge.y + (1-f)*ame.y, f*ge.z + (1-f)*ame.z)
    }
    
    func kalmanFilter(){
        let x = kalmanFilters[0].applyFilter(Double(ame.x), Double(g.x))
        let y = kalmanFilters[1].applyFilter(Double(ame.y), Double(g.y))
        let z = kalmanFilters[2].applyFilter(Double(ame.z), Double(g.z))
        
        fe = float3(x, y, z)
    }
    
    
    
    func filterEstimates(){
        switch filterName.selectedSegmentIndex
        {
        case 0: complimentaryFilter(withFactor: 0.4)
        case 1: kalmanFilter()
        default: break
        }
    }
    
    func startUpdates() {
        motionManager.startSensors(withFrequency: 1.0/60.0)
        timer = Timer(fire: Date(), interval: 1.0/60.0, repeats: true, block:{ (timer) in
            self.getsetSensorValues()
            self.calcEstimates()
            self.filterEstimates()
        })
        //        adds timer to current thread so that it's executed at constant frequency
        RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
    }
    
    func stopUpdates() {
        timer.invalidate()
        motionManager.stopSensors()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initGyro()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


}

extension Double {
    func f(_ decimalPlaces: Int) -> Float {
        let formattedString = String(format: "%.\(decimalPlaces)f", self)
        return Float(formattedString)!
    }
}

extension float3 {
    func toDegree() -> float3{
        let f = 180/Float.pi
        return float3(self.x*f, self.y*f, self.z*f)
    }
}

extension CMMotionManager {
    
    func getGyro() -> float3?{
        guard let data = self.gyroData else { return nil }
        let x = data.rotationRate.x, y = data.rotationRate.y, z = data.rotationRate.z
        return float3(x: x.f(2), y: y.f(2), z: z.f(2))
    }
    
    func getAcc() -> float3?{
        guard let data = self.accelerometerData else { return nil }
        let x = data.acceleration.x, y = data.acceleration.y, z = data.acceleration.z
        return float3(x: x.f(2), y: y.f(2), z: z.f(2))
    }
    
    func getMag() -> float3?{
        guard let data = self.magnetometerData else { return nil }
        let x = data.magneticField.x, y = data.magneticField.y, z = data.magneticField.z
        return float3(x: x.f(2), y: y.f(2), z: z.f(2))
    }
    
    func stopSensors(){
        self.stopGyroUpdates()
        self.stopAccelerometerUpdates()
        self.stopMagnetometerUpdates()
    }
    
    func startSensors(withFrequency seconds: Double){
        if self.isAccelerometerAvailable{
            self.accelerometerUpdateInterval = seconds
            self.startAccelerometerUpdates()
        }
        
        if self.isMagnetometerAvailable{
            self.magnetometerUpdateInterval = seconds
            self.startMagnetometerUpdates()
        }
        
        if self.isGyroAvailable{
            self.gyroUpdateInterval = seconds
            self.startGyroUpdates()
        }
    }

}
