//
//  DrawLinesViewController.swift
//  exampleios
//
//  Created by Julian Bleecker on 3/3/18.
//

import Foundation
import UIKit
import XCGLogger
import GoogleMaps

class DrawLinesViewController : UIViewController {
    
    var vectors : Array<Vector>?
    let rwColor = UIColor(red: 11/255.0, green: 11/255.0, blue: 14/255.0, alpha: 1.0)
    let rwPath = UIBezierPath()
    let rwLayer = CAShapeLayer()
    let log = XCGLogger.default

    var screenDivX : CGFloat?
    var screenDivY : CGFloat?
    
    var maxLat : Double!
    var minLat : Double!
    
    var maxLon : Double!
    var minLon : Double!
    
    var layer: CALayer {
        return self.view.layer
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GMSServices.provideAPIKey("AIzaSyBU2G7DyreurPNwfeg86PWTC8Pf2LlTDH4")
        
        setUpLayer()
        
        let wrapper = SwiftThatUsesWrapperForSwift()
        wrapper.startDecode()
        vectors = wrapper.recordMessagesToSomething()
        //let a = vectors
        
        var sorted = vectors?.sorted(by: { (first, second) -> Bool in
            return first.record.positionLatitude > second.record.positionLatitude
        })
        
//        vectors?.sort(by: { (first, second) -> Bool in
//            return first.record.positionLatitude > second.record.positionLatitude
//        })
        //float screendivx; // = width/(maxlong-minlong);//pixels per degree
        maxLat = (sorted?.first?.record.positionLatitude)!
        minLat = (sorted?.last?.record.positionLatitude)!
        
        //log.debug("\(maxLat) \(minLat)")
        
        // sort longitude
        sorted = vectors?.sorted(by: { (first, second) -> Bool in
            return first.record.positionLongitude > second.record.positionLongitude
        })
        maxLon = (sorted?.first?.record.positionLongitude)!
        minLon = (sorted?.last?.record.positionLongitude)!
        
        screenDivX = self.view.frame.width / CGFloat((maxLon - minLon)) // pixels per degree
        screenDivY = self.view.frame.height / CGFloat((maxLat - minLat)) // pixels per degree
        
        //log.debug("\(maxLon) \(minLon)")
//        log.debug("\(screenDivX) \(screenDivY)")

        //vectors = wrapper.recordMessagesToSomething()
        /*
        for vector in vectors! {
            let lat = CGFloat(vector.record.positionLatitude)
            let lon = CGFloat(vector.record.positionLongitude)
            
            let x = translate(value: lat, min: CGFloat(minLat), max: CGFloat(maxLat), normalMin: 0, normalMax: 100)
            let y = translate(value: lon, min: CGFloat(minLon), max: CGFloat(maxLon), normalMin: 0, normalMax: 100)
            //log.debug("\(lat),\(lon) \(x),\(y)")
        }
        */
        setupRWPath()
        setUpRWLayer()
        view.layer.addSublayer(rwLayer)
    }
    
    func setupRWPath() {
        
        if let points : Array<CGPoint> = vectors?.map({ (element) in
            let lat = element.record.location.coordinate.latitude
            let lon = element.record.location.coordinate.longitude
            let x = Rescale(from: (minLat, maxLat), to: (10, 300)).rescale(lat)
            
            //translate(value: lat, min: CGFloat(minLat), max: CGFloat(maxLat), normalMin: 0, normalMax: 100)
            let y = Rescale(from: (minLon, maxLon), to: (100, 300)).rescale(lon)
            
            //translate(value: lon, min: CGFloat(minLon), max: CGFloat(maxLon), normalMin: 0, normalMax:100)
            
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }) {
            
            rwPath.move(to: CGPoint(x: points.first!.x, y: points.first!.y))
            //points.dropFirst()
            
            
            for point in points.dropFirst() {
                rwPath.addLine(to: point)
                //log.debug(point)
            }
            //rwPath.close()
            //            points.dropFirst().map({ (point) in
            //                rwPath.addLine(to: point)
            //            })
        }
        
    }
    
    func setUpRWLayer() {
        rwLayer.path = rwPath.cgPath
        rwLayer.fillColor = UIColor.clear.cgColor//UIColor.blue.cgColor
        rwLayer.fillRule = kCAFillRuleNonZero
        rwLayer.lineCap = kCALineCapButt
        rwLayer.lineDashPattern = nil
        rwLayer.lineDashPhase = 0.0
        rwLayer.lineJoin = kCALineJoinMiter
        rwLayer.lineWidth = 1.0
        rwLayer.miterLimit = 10.0
        rwLayer.strokeColor = rwColor.cgColor
    }
    
//    func getPoint(lat : Double, lon : Double) -> CGPoint {
//        let x = CGFloat((180.0+lon)) * (self.view.frame.width / 360)
//        let y = CGFloat((90.0-lat)) * (self.view.frame.height / 180)
//        let point : CGPoint = CGPoint(x: x, y: y)
//        log.debug(point)
//        return point
//    }
    
    func setUpLayer() {
        layer.backgroundColor = UIColor.white.cgColor
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 0
    }
}

struct Rescale<Type : BinaryFloatingPoint> {
    typealias RescaleDomain = (lowerBound: Type, upperBound: Type)
    
    var fromDomain: RescaleDomain
    var toDomain: RescaleDomain
    
    init(from: RescaleDomain, to: RescaleDomain) {
        self.fromDomain = from
        self.toDomain = to
    }
    
    func interpolate(_ x: Type ) -> Type {
        return self.toDomain.lowerBound * (1 - x) + self.toDomain.upperBound * x;
    }
    
    func uninterpolate(_ x: Type) -> Type {
        let b = (self.fromDomain.upperBound - self.fromDomain.lowerBound) != 0 ? self.fromDomain.upperBound - self.fromDomain.lowerBound : 1 / self.fromDomain.upperBound;
        return (x - self.fromDomain.lowerBound) / b
    }
    
    func rescale(_ x: Type )  -> Type {
        return interpolate( uninterpolate(x) )
    }
}
