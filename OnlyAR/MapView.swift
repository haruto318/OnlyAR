//
//  MapView.swift
//  OnlyAR
//
//  Created by Haruto Hamano on 2024/07/09.
//


import UIKit

class MapView: UIView {
    var path: [Node] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Ensure there is a path to draw
        guard let context = UIGraphicsGetCurrentContext(), !path.isEmpty else { return }
        
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.red.cgColor)
        
        // Define the coordinates and order
        let coordinates: [(x: CGFloat, y: CGFloat)] = [
            (x: 127, y: 361),
            (x: 145, y: 361),
            (x: 165, y: 361),
            (x: 145, y: 387.5),///
            (x: 145, y: 414),///
            (x: 127, y: 442),
            (x: 145, y: 442),
            (x: 165, y: 442),
            (x: 145, y: 468.5),///
            (x: 145, y: 495),///
            (x: 127, y: 527),
            (x: 145, y: 527),
            (x: 165, y: 527),
            (x: 145, y: 553.5),///
            (x: 145, y: 580),///
            (x: 127, y: 609),
            (x: 145, y: 609),
            (x: 145, y: 635.5),///
            (x: 145, y: 662),///
            (x: 127, y: 688),
            (x: 145, y: 688),
            (x: 145, y: 714.5),///
            (x: 145, y: 741),///
            (x: 127, y: 771),
            (x: 145, y: 771),
            (x: 165, y: 771),
            (x: 145, y: 797.5),///
            (x: 145, y: 824),///
            (x: 127, y: 850),
            (x: 145, y: 850),
            (x: 165, y: 850)
        ]
        
        let order = ["G", "s", "H", "r", "q", "F", "p", "I", "o", "n", "E", "m", "J", "l", "k", "D", "j", "i", "h", "C", "g", "f", "e", "B", "d", "M", "c", "b", "A", "a", "N"]
        
//        let order = ["G", "m", "H", "l", "F", "k", "I", "j", "E", "i", "J", "h", "D", "g", "f", "C", "e", "d", "B", "c", "M", "b", "A", "a", "N"]
        
        // Create a dictionary to map letters to coordinates
        var coordinatesDict = [String: (x: CGFloat, y: CGFloat)]()
        for (index, letter) in order.enumerated() {
            coordinatesDict[letter] = coordinates[index]
        }
        
        print(coordinatesDict)
        
        // Update nodes' coordinates based on the given path
        for node in path {
            if let coord = coordinatesDict[String(node.id)] {
                node.x = Int(coord.x)
                node.y = Int(coord.y)
            }
        }
        
        // Draw the path
        let firstNode = path[0]
        context.move(to: CGPoint(x: firstNode.x, y: firstNode.y))
        
        for node in path.dropFirst() {
            context.addLine(to: CGPoint(x: node.x, y: node.y))
        }
        
        context.strokePath()
    }
}

