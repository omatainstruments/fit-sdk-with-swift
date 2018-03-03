//
//  SwiftThatUsesWrapperForSwift.swift
//  exampleios
//
//  Created by Julian Bleecker on 2/23/17.
//
//

import Foundation
import XCGLogger
//extension String {
//    
//    var RFC3986UnreservedEncoded:String {
//        let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
//        let unreservedCharsSet: CharacterSet = CharacterSet(charactersIn: unreservedChars)
//        let encodedString: String = self.addingPercentEncoding(withAllowedCharacters: unreservedCharsSet)!
//        return encodedString
//    }
//}

struct RecordMessage {
    var altitude : Double? = 0
    var distance : Double? = 0
    var speed : Double? = 0
    var gpsAccuracy : Double = 0
    var positionLatitude : Double = 0
    var positionLongitude : Double = 0
    var location : CLLocation!
    var temperature : Double = 0
    var timestamp : NSDate?
    var bearingToNext : Double? = 0
    
    mutating func fromDictionary(d : NSDictionary) {
        altitude = d.value(forKey: "altitude") as? Double
        distance = d.value(forKey: "distance") as? Double
        speed = d.value(forKey: "speed") as? Double
        gpsAccuracy = d.value(forKey: "gps_accuracy") as! Double
        positionLatitude = d.value(forKey: "position_lat") as! Double
        positionLongitude = d.value(forKey: "position_lon") as! Double
        temperature = d.value(forKey: "temperature") as! Double
        timestamp = d.value(forKey: "timestamp") as? NSDate
        let coord : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: positionLatitude, longitude: positionLongitude)
        if let alt = altitude {
            location = CLLocation(coordinate: coord, altitude: alt, horizontalAccuracy: gpsAccuracy, verticalAccuracy: 0, timestamp: timestamp! as Date)
        } else {
            location = CLLocation(coordinate: coord, altitude: 0, horizontalAccuracy: gpsAccuracy, verticalAccuracy: 0, timestamp: timestamp! as Date)
        }
        
    }
    
    mutating func computeBearingToNext(recordMessage next : RecordMessage) {
        bearingToNext = getBearingBetweenTwoPoints1(point1: location, point2: next.location)
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
}

@objc class SwiftThatUsesWrapperForSwift:NSObject {
    
    var recordMessages : Array<Any> = Array()
    var sessionMessages: Array<Any> = Array()
    var eventMessages: Array<NSDictionary> = Array()
    var fileIDMessages: Array<Any> = Array()
    let log = XCGLogger.default

    func callback(timestamp: UInt32) -> Void {
        log.debug("Timestamp \(timestamp)")
    }
    
    @objc func callback(eventMesg: NSDictionary) -> Void {
        eventMessages.append(eventMesg)
    }
    
    @objc func callback(sessionMesg: NSDictionary) -> Void {
        sessionMessages.append(sessionMesg)
        //NSLog("\(sessionMessages)")
        //log.debug(sessionMessages)
    }
    
    @objc func callback(recordMesg: NSDictionary) -> UInt8 {
        //NSLog("%@", recordMesg)
        //log.debug(recordMesg)
        recordMessages.append(recordMesg)
        //recordMesgs.append(recordMesg as! Dictionary<String, Any>)
        return 0;
    }
    
    @objc func callback(fileIDMesg: NSDictionary) -> Void {
        fileIDMessages.append(fileIDMesg)
        log.debug(fileIDMesg)
    }
    
    @objc func decodeFitFile(file : URL)
    {
        let wrapper:WrapperForSwift = WrapperForSwift(self)
        
        wrapper.setSupervisor(self)
        wrapper.decode(file.path)
    }
    

    
    func recordMessagesToSomething() {
        var foo : [RecordMessage] = recordMessages.map {
            
            //let (index, element) = arg
            //log.debug($0)
            var message : RecordMessage = RecordMessage()
            if let dictionary = $0 as? NSDictionary {
                //log.debug(dictionary)
                message.fromDictionary(d: dictionary)
            }
            return message
        }
        log.debug(foo.count)
        
        foo = foo.enumerated().map { (arg) in
            var (index, message) = arg
            if index < foo.count - 2 {
                message.computeBearingToNext(recordMessage: foo[index+1])
            }
            return message
        }
        
        typealias tupe = (record : RecordMessage, distance : Double, bearingAvg : Double, bearingChange : Double)
        log.debug("Start Computing Average Bearings")
        var vectors : [ tupe ] = foo.chunks(10).map { (chunk) in
            //log.debug(chunk)
            let r = chunk.reduce(0, { x, y  in
                return x + y.bearingToNext!
            })
            //log.debug("Avg Bearing = \(r / Double(chunk.count))")
            
            let distance = chunk[chunk.count-1].distance! - chunk[0].distance!
            //let bearingChange = chunk[chunk.count-1].bearingToNext! - chunk[0].bearingToNext!
            return (chunk[0], distance : distance , bearingAvg : r / Double(chunk.count), 0 )
        }
        log.debug("Done Computing Average Bearings")
        
        let bearingAverages = vectors.map {
            return $0.bearingAvg
        }
        
        let bearingChanges : [Double] = bearingAverages.map {
            if let after : Double = bearingAverages.item(after: $0) {
            let this : Double = $0
            return after - this
            } else {
                return 0
            }
        }
        
        vectors = vectors.enumerated().map {
            return ($0.element.record, $0.element.distance, $0.element.bearingAvg, bearingChanges[$0.offset])
        }
        
        for element in vectors {
            log.debug("(\(element.record.location.coordinate.latitude) \(element.record.location.coordinate.longitude)) \(element.bearingChange)")
        }
        
//        for message in foo {
//            log.debug("Bearing=\(String(describing: message.bearingToNext))")
//        }
        
        //foo.sorted(by: { $0.positionLatitude > $1.positionLatitude})
    }
    

    
    @objc func doSomething() {
        log.setup(level: .debug, showThreadName: false, showLevel: false, showFileNames: false, showLineNumbers: true)

        
        let wrapper:WrapperForSwift = WrapperForSwift(self)
        
        wrapper.setSupervisor(self)
        
        log.debug("Starting decode")
        wrapper.decode("/Users/julian/Downloads/180224212708.fit")
        log.debug("Decoded ended")
        
        var count = recordMessages.count
        log.debug("recordMessages.count=\(count)")
        
        count = eventMessages.count
        log.debug("eventMessages.count=\(count)")
        
        recordMessagesToSomething()
        /*
         let fm: FileManager = FileManager()
         
         var files:[String]
         do {
         let path = "/Users/"
         
         
         files = try fm.contentsOfDirectory(atPath: path.appending("/"))
         //            let paren = "("
         for file in files {
         // let _:Data = wrapper.decode(path.appending(file).replacingOccurrences(of: "(", with: paren, options: .literal, range: nil))
         //path = path.appending("/")
         
         if !(file.lowercased() .hasSuffix("fit"))   {
         continue
         }
         
         
         let _:Data = wrapper.decode(path.appending("/").appending(file))
         
         let filename = file.components(separatedBy: ".").first!
         let path_json = URL(fileURLWithPath: path.appending("/").appending("\(filename)-summary.json"))
         let event_json = URL(fileURLWithPath: path.appending("/").appending("\(filename)-event.json"))
         let record_json = URL(fileURLWithPath: path.appending("/").appending("\(filename)-record.json"))
         
         //                let path_fit =  dir.appendingPathComponent("170301154226.fit")
         //                let path_json = dir.appendingPathComponent("170301154226-summary.json")
         //                let event_json = dir.appendingPathComponent("170301154226-event.json")
         do {
         let file_data : Data
         
         
         var withFileIDMessages : Array = [ [self.fileIDMessages, "file_id_messages"], [self.sessionMessages, "session_messages"] ]
         try file_data = JSONSerialization.data(withJSONObject: withFileIDMessages)
         
         let event_data : Data
         withFileIDMessages = [self.fileIDMessages, self.eventMessages]
         try event_data = JSONSerialization.data(withJSONObject: withFileIDMessages)
         
         var record_data : Data
         withFileIDMessages = [self.fileIDMessages, self.recordMessages]
         try record_data = JSONSerialization.data(withJSONObject: withFileIDMessages)
         
         //                    var file_id_data : Data
         //                    withFileIDMessages = [self.fileIDMessages, self.]
         //                    try file_id_data = JSONSerialization.data(withJSONObject: self.fileIDMessages)
         
         try file_data.write(to: path_json)
         
         try event_data.write(to: event_json)
         
         try record_data.write(to: record_json)
         
         self.sessionMessages = []
         self.eventMessages = []
         self.recordMessages = []
         self.fileIDMessages = []
         
         }
         catch {/* error handling here */
         NSLog("ERROR WRITING FILE")
         
         }
         }
         
         } catch {
         print(error)
         }
         */
        
        /*
         
         if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
         
         let path_fit = dir.appendingPathComponent("170301154226.fit")
         let path_json = dir.appendingPathComponent("170301154226-summary.json")
         let event_json = dir.appendingPathComponent("170301154226-event.json")
         
         NSLog("\(path_json)")
         
         //writing
         do {
         var file_data : Data
         try file_data = JSONSerialization.data(withJSONObject: self.sessionMessages)
         var event_data : Data
         try event_data = JSONSerialization.data(withJSONObject: self.eventMessages)
         
         try data.write(to: path_fit, options: [])
         try file_data.write(to: path_json)
         try event_data.write(to: event_json)
         
         
         }
         catch {/* error handling here */
         NSLog("ERROR WRITING FILE")
         
         }
         
         decodeFitFile(file: path_fit)
         
         }
         */
        //wrapper.decode()
        //wrapper.encode()
        
        
        
        
        
    }
    
    
}

extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension Collection where Iterator.Element: Equatable {
    typealias Element = Self.Iterator.Element
    
    func safeIndex(after index: Index) -> Index? {
        let nextIndex = self.index(after: index)
        return (nextIndex < self.endIndex) ? nextIndex : nil
    }
    
    func index(afterWithWrapAround index: Index) -> Index {
        return self.safeIndex(after: index) ?? self.startIndex
    }
    
    func item(after item: Element) -> Element? {
        return self.index(of: item)
            .flatMap(self.safeIndex(after:))
            .map{ self[$0] }
    }
    
    func item(afterWithWrapAround item: Element) -> Element? {
        return self.index(of: item)
            .map(self.index(afterWithWrapAround:))
            .map{ self[$0] }
    }
}

extension BidirectionalCollection where Iterator.Element: Equatable {
    typealias Element = Self.Iterator.Element
    
    func safeIndex(before index: Index) -> Index? {
        let previousIndex = self.index(before: index)
        return (self.startIndex <= previousIndex) ? previousIndex : nil
    }
    
    func index(beforeWithWrapAround index: Index) -> Index {
        return self.safeIndex(before: index) ?? self.index(before: self.endIndex)
    }
    
    func item(before item: Element) -> Element? {
        return self.index(of: item)
            .flatMap(self.safeIndex(before:))
            .map{ self[$0] }
    }
    
    
    func item(beforeWithWrapAround item: Element) -> Element? {
        return self.index(of: item)
            .map(self.index(beforeWithWrapAround:))
            .map{ self[$0] }
    }
}
