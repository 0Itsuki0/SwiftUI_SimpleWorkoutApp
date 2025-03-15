//
//  HKStatistic+Utils.swift
//  ItsukiWorkoutApp
//
//  Created by Itsuki on 2025/03/03.
//

import HealthKit

extension HKStatistics {
    static var heartRateUnit: HKUnit {
        HKUnit.count().unitDivided(by: HKUnit.minute())
    }
    
    static var energyUnit: HKUnit {
        HKUnit.kilocalorie()
    }
    
    static var distanceUnit: HKUnit {
        HKUnit.meter()
    }
    
    static var speedUnit: HKUnit {
        HKUnit.meter().unitDivided(by: HKUnit.second())
    }
    
    static  var countUnit: HKUnit {
        HKUnit.count()
    }

    var heartRate: Double {
        if self.quantityType == HKQuantityType(.heartRate) {
            return self.mostRecentQuantity()?.doubleValue(for: Self.heartRateUnit) ?? 0
        }
        return 0
    }
    
    var averageHeartRate: Double {
        if self.quantityType == HKQuantityType(.heartRate) {
            return self.averageQuantity()?.doubleValue(for: Self.heartRateUnit) ?? 0
        }
        return 0
    }
    
    var activeEnergyBurned: Double {
        if self.quantityType == HKQuantityType(.activeEnergyBurned) {
            return self.sumQuantity()?.doubleValue(for: Self.energyUnit) ?? 0
        }
        return 0
    }
    
    var totalDistance: Double {
        if self.quantityType == HKQuantityType(.distanceWalkingRunning) ||
            self.quantityType == HKQuantityType(.distanceCycling) ||
            self.quantityType == HKQuantityType(.distanceSwimming) {
            return self.sumQuantity()?.doubleValue(for: Self.distanceUnit) ?? 0
        }
        return 0
    }
    
    var speed: Double {
        if self.quantityType == HKQuantityType(.walkingSpeed) ||
            self.quantityType == HKQuantityType(.runningSpeed) ||
            self.quantityType == HKQuantityType(.cyclingSpeed) {
            return self.mostRecentQuantity()?.doubleValue(for: Self.speedUnit) ?? 0
        }
        return 0
    }
    
    var averageSpeed: Double {
        if self.quantityType == HKQuantityType(.walkingSpeed) ||
            self.quantityType == HKQuantityType(.runningSpeed) ||
            self.quantityType == HKQuantityType(.cyclingSpeed) {
            return self.averageQuantity()?.doubleValue(for: Self.speedUnit) ?? 0
        }
        return 0
    }
    
    var stepCount: Double {
        if self.quantityType == HKQuantityType(.stepCount) {
            return self.sumQuantity()?.doubleValue(for: Self.countUnit) ?? 0
        }
        return 0
    }
    
    var strokeCount: Double {
        if self.quantityType == HKQuantityType(.swimmingStrokeCount) {
            return self.sumQuantity()?.doubleValue(for: Self.countUnit) ?? 0
        }
        return 0
    }
}
