//
//  PieceSlicer.swift
//  PuzzleDemo
//
//  Created by kino on 2021/3/23.
//

import UIKit

/// 拼图切片机
struct PieceSlicer {
    enum PathDrawType: Int {
        case line
        case outside
        case inner
        case none
        
        var desc: String {
            switch self {
            case .line:
                return "平面"
            case .inner:
                return "凹"
            case .outside:
                return "凸"
            default:
                return "未设置"
            }
        }
        
        var oppose: PathDrawType {
            switch self {
            case .inner:
                return .outside
            case .outside:
                return .inner
            default:
                return .line
            }
        }
    }
    
    enum Direction: Int {
        case left
        case right
        case top
        case bottom
    }
    
    
    var leftDraw: PathDrawType = .line
    var topDraw: PathDrawType = .line
    var rightDraw: PathDrawType = .line
    var bottomDraw: PathDrawType = .line
    
    var holeRadius: CGFloat = 6.0
    
    static func radiusByWidth(_ width: CGFloat) -> CGFloat {
        return width / 8.0
    }
    
    mutating func randomSetDirections( box: inout [PieceSlicer.PathDrawType]) {
        var list = [leftDraw, topDraw, rightDraw, bottomDraw]
        for i in 0..<list.count {
            let item = list[i]
            if item == .none, let ele = box.randomElement() {
                list[i] = ele
                box = box.filter{ $0 != ele }
            }
        }
        
        leftDraw = list[0]
        topDraw = list[1]
        rightDraw = list[2]
        bottomDraw = list[3]
    }
    
    func description() -> String {
        return "当前切片状态：\n左--\(leftDraw.desc)\n上--\(topDraw.desc)\n右--\(rightDraw.desc)\n下--\(bottomDraw.desc)"
    }
    
    init(left: PathDrawType, top: PathDrawType, right: PathDrawType, bottom: PathDrawType) {
        // 绘图区域上下颠倒
        leftDraw = left
        topDraw = top
        rightDraw = right
        bottomDraw = bottom
    }
    
    func draw(in rect: CGRect) -> UIBezierPath? {
        let startX = rect.origin.x
        let startY = rect.origin.y
        let width = rect.size.width
        let height = rect.size.height
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: startX, y: startY))
        
        // 因为绘图区域上下颠倒，这里我们直接把上和下的配置交换赋值
        // top
        path.addLine(to: CGPoint(x: (width + startX) / 2  - holeRadius, y: startY))
        if bottomDraw == .outside {
            path.addArc(withCenter: CGPoint(x: (width+startX) / 2, y: startY - holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(180.0).toRadians(),
                        endAngle: CGFloat(0.0).toRadians(),
                        clockwise: true)
        } else if bottomDraw == .inner {
            path.addArc(withCenter: CGPoint(x: (width+startX) / 2, y: startY + holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(180.0).toRadians(),
                        endAngle: CGFloat(0.0).toRadians(),
                        clockwise: false)
        }
        path.addLine(to: CGPoint(x: (width+startX) / 2 + holeRadius, y: startY))
        path.addLine(to: CGPoint(x: width, y: startY))
        
        // right
        path.addLine(to: CGPoint(x: width, y: height / 2))
        if rightDraw == .outside {
            path.addArc(withCenter: CGPoint(x: width + holeRadius, y: height / 2 + holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(270.0).toRadians(),
                        endAngle: CGFloat(90.0).toRadians(),
                        clockwise: true)
        } else if rightDraw == .inner {
            path.addArc(withCenter: CGPoint(x: width - holeRadius, y: height / 2 + holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(270.0).toRadians(),
                        endAngle: CGFloat(90.0).toRadians(),
                        clockwise: false)
        }
        path.addLine(to: CGPoint(x: width, y: height / 2 + holeRadius * 2))
        path.addLine(to: CGPoint(x: width, y: height))
        
        
        // bottom
        path.addLine(to: CGPoint(x: (width+startX) / 2 + holeRadius, y: height))
        if topDraw == .outside {
            path.addArc(withCenter: CGPoint(x: (width+startX) / 2, y: height + holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(0.0).toRadians(),
                        endAngle: CGFloat(180.0).toRadians(),
                        clockwise: true)
        } else if topDraw == .inner {
            path.addArc(withCenter: CGPoint(x: (width+startX) / 2, y: height - holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(0.0).toRadians(),
                        endAngle: CGFloat(180.0).toRadians(),
                        clockwise: false)
        }
        path.addLine(to: CGPoint(x: (width+startX) / 2.0 - holeRadius, y: height))
        path.addLine(to: CGPoint(x: startX, y: height))
        
        
        // left
        path.addLine(to: CGPoint(x: startX, y: height / 2 + startY))
        if leftDraw == .outside {
            path.addArc(withCenter: CGPoint(x: startX - holeRadius, y: height / 2 + holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(90.0).toRadians(),
                        endAngle: CGFloat(270.0).toRadians(),
                        clockwise: true)
        } else if leftDraw == .inner {
            path.addArc(withCenter: CGPoint(x: startX + holeRadius, y: height / 2 + holeRadius),
                        radius: holeRadius,
                        startAngle: CGFloat(90.0).toRadians(),
                        endAngle: CGFloat(270.0).toRadians(),
                        clockwise: false)
        }
        path.addLine(to: CGPoint(x: startX, y: height / 2))
        // done
        path.close()
        path.usesEvenOddFillRule = true
        
        return path
    }
}
