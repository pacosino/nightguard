//
//  StatisticsRepository.swift
//  nightguard
//
//  Created by Dirk Hermanns on 07.07.16.
//  Copyright © 2016 private. All rights reserved.
//

import Foundation

class StatisticsRepository {
    
    static let singleton = StatisticsRepository()

    var lastSave : NSDate?
    
    var cachedDays : [[BloodSugar]] = [[], [], [], [], [], []]
    
    
    // Reads the day starting with day 0 (current day).
    // If the day is not available or older than 30 Minutes, nil will be returned
    func readDay(nr : Int) -> [BloodSugar]? {
        
        if lastSave == nil || TimeService.isOlderThan30Minutes(lastSave!) {
            return nil
        }
        
        if nr > cachedDays.count {
            return []
        }
        
        if cachedDays[nr].count == 0 {
            // no values have been read so far => signal with nil that they have to be read once more
            return nil
        }
        return cachedDays[nr]
    }
    
    
    func saveDay(nr : Int, bloodSugarArray : [BloodSugar]) {
        
        lastSave = TimeService.getToday()
        
        cachedDays[nr] = bloodSugarArray
    }
}