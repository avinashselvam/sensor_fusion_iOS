//
//  kalman.swift
//  sensor
//
//  Created by Avinash on 02/10/18.
//  Copyright © 2018 eightyfive. All rights reserved.
//

import SceneKit

class Kalman {
    
    var P = [[100.0,0.0],[0.0,100.0]]
    var K = [0.0, 0.0]
    var S = 0.0
    
    var angle = 0.0
    var bias = 0.0
    
    var rate = 0.0
    
    static let Q_angle = 0.001;
    static let Q_gyroBias = 0.003;
    static let R_measure = 0.03;
    
    func applyFilter(_ newAngle: Double, _ newRate: Double) -> Float {
    
        let dt = 1.0/60
        
        rate = newRate - bias
        angle += dt*rate
        
        P[0][0] += dt * (dt*P[1][1] - P[0][1] - P[1][0] + Kalman.Q_angle)
        P[0][1] -= dt * P[1][1]
        P[1][0] -= dt * P[1][1]
        P[1][1] += Kalman.Q_gyroBias * dt
        
        let y = newAngle - angle
        
        S = P[0][0] + Kalman.R_measure
        
        K[0] = P[0][0]/S
        K[1] = P[1][0]/S
        
        angle += K[0]*y
        bias += K[1]*y
        
        let P00_temp = P[0][0]
        let P01_temp = P[0][1]
        
        P[0][0] -= K[0] * P00_temp
        P[0][1] -= K[0] * P01_temp
        P[1][0] -= K[1] * P00_temp
        P[1][1] -= K[1] * P01_temp
        
        return Float(angle)
        
    }
    
//    func applyFilter(ameReading: float3, gyroReading: float3) -> float3{
//        let x = applyFilterOne(Double(ameReading.x), Double(gyroReading.x)).f(2)
//        let y = applyFilterOne(Double(ameReading.y), Double(gyroReading.y)).f(2)
//        let z = applyFilterOne(Double(ameReading.z), Double(gyroReading.z)).f(2)
//
//        return float3(x, y, z)
//    }
    
    
    
    
}
