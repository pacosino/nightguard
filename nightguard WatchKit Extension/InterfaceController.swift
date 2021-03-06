//
//  InterfaceController.swift
//  scoutwatch WatchKit Extension
//
//  Created by Dirk Hermanns on 20.11.15.
//  Copyright © 2015 private. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {

    @IBOutlet var bgLabel: WKInterfaceLabel!
    @IBOutlet var deltaLabel: WKInterfaceLabel!
    @IBOutlet var deltaArrowLabel: WKInterfaceLabel!
    @IBOutlet var timeLabel: WKInterfaceLabel!
    @IBOutlet var batteryLabel: WKInterfaceLabel!
    @IBOutlet var chartImage: WKInterfaceImage!
    
    override func didAppear() {
        assureThatBaseUriIsExisting()
    }
    
    @IBAction func doInfoMenuAction() {
        self.presentControllerWithName("InfoInterfaceController", context: nil)
    }
    
    @IBAction func doRefreshMenuAction() {
        willActivate()
    }
    
    @IBAction func doCloseMenuAction() {
        // nothing to do - closes automatically
    }
    
    var historicBgData : [BloodSugar] = []
    var currentNightscoutData : NightscoutData = NightscoutData()
    
    // timer to check continuously for new bgValues
    var timer = NSTimer()
    // check every 30 Seconds whether new bgvalues should be retrieved
    let timeInterval : NSTimeInterval = 30.0
    
    // check whether new Values should be retrieved
    func timerDidEnd(timer:NSTimer){
        assureThatBaseUriIsExisting()
        checkForNewValuesFromNightscoutServer()
    }
    
    private func assureThatBaseUriIsExisting() {
        
        if UserDefaultsRepository.readBaseUri().isEmpty {
            AppMessageService.singleton.requestBaseUri()
        }
    }
    
    private func checkForNewValuesFromNightscoutServer() {
        
        if currentNightscoutData.isOlderThan5Minutes() {
            
            readNewValuesFromNightscoutServer()
        }
    }
    
    private func readNewValuesFromNightscoutServer() {
        NightscoutService.singleton.readCurrentDataForPebbleWatch({(currentNightscoutData) -> Void in
            self.currentNightscoutData = currentNightscoutData
            self.paintCurrentBgData(self.currentNightscoutData)
            NightscoutDataRepository.singleton.storeCurrentNightscoutData(currentNightscoutData)
        })
        NightscoutService.singleton.readLastTwoHoursChartData({(historicBgData) -> Void in
            self.historicBgData = historicBgData
            self.paintChart(UnitsConverter.toDisplayUnits(self.historicBgData),
                yesterdayValues: YesterdayBloodSugarService.singleton.getYesterdaysValuesTransformedToCurrentDay(
                    BloodSugar.getMinimumTimestamp(historicBgData),
                    to: BloodSugar.getMaximumTimestamp(historicBgData)))
            NightscoutDataRepository.singleton.storeHistoricBgData(self.historicBgData)
        })
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // load old values that have been stored before
        self.currentNightscoutData = NightscoutDataRepository.singleton.loadCurrentNightscoutData()
        self.historicBgData = NightscoutDataRepository.singleton.loadHistoricBgData()
    
        // update values immediately if necessary
        checkForNewValuesFromNightscoutServer()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // Start the timer to retrieve new bgValues
        createNewTimerSingleton()
        timer.fire()
        
        paintChart(historicBgData, yesterdayValues:
            YesterdayBloodSugarService.singleton.getYesterdaysValuesTransformedToCurrentDay(
                BloodSugar.getMinimumTimestamp(historicBgData),
                to: BloodSugar.getMaximumTimestamp(historicBgData)))
        paintCurrentBgData(currentNightscoutData)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    private func createNewTimerSingleton() {
        if !timer.valid {
            timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval,
                                                       target: self,
                                                       selector: #selector(InterfaceController.timerDidEnd(_:)),
                                                       userInfo: nil,
                                                       repeats: true)
            // allow WatchOs to call this timer 30 seconds later as requested
            timer.tolerance = timeInterval
        }
    }
    
    private func paintChart(bgValues : [BloodSugar], yesterdayValues : [BloodSugar]) {
        
        let chartPainter : ChartPainter = ChartPainter(canvasWidth: 165, canvasHeight: 125)
        
        let defaults = NSUserDefaults(suiteName: AppConstants.APP_GROUP_ID)
        
        guard let chartImage = chartPainter.drawImage(
                [UnitsConverter.toDisplayUnits(bgValues), UnitsConverter.toDisplayUnits(yesterdayValues)],
                upperBoundNiceValue: UnitsConverter.toDisplayUnits(defaults!.floatForKey("alertIfAboveValue")),
                lowerBoundNiceValue: UnitsConverter.toDisplayUnits(defaults!.floatForKey("alertIfBelowValue"))
        ) else {
            return
        }
        self.chartImage.setImage(chartImage)
    }
    
    private func paintCurrentBgData(currentNightscoutData : NightscoutData) {
        self.bgLabel.setText(currentNightscoutData.sgv)
        self.bgLabel.setTextColor(UIColorChanger.getBgColor(currentNightscoutData.sgv))
        
        self.deltaLabel.setText(currentNightscoutData.bgdeltaString.cleanFloatValue)
        self.deltaArrowLabel.setText(currentNightscoutData.bgdeltaArrow)
        self.deltaLabel.setTextColor(UIColorChanger.getDeltaLabelColor(currentNightscoutData.bgdelta))
        
        self.timeLabel.setText(currentNightscoutData.timeString)
        self.timeLabel.setTextColor(UIColorChanger.getTimeLabelColor(currentNightscoutData.time))
        
        self.batteryLabel.setText(currentNightscoutData.battery)
    }
}
