//
//  PuzzlePieceAutomatic.swift
//  PuzzleDemo
//
//  Created by kino on 2021/3/23.
//

import UIKit


protocol PuzzleMakeable {
    mutating func construct() -> [PieceSlicer]
}

struct PuzzleGenerator {
    var makeable: PuzzleMakeable?
    
//    static func createPieceImage(slicer: PieceSlicer) -> UIImage {
//
//    }
}


/// 构造2X2的拼图
struct PuzzlePiece4: PuzzleMakeable {
    var slicers: [PieceSlicer] = []
    
    mutating func construct() -> [PieceSlicer] {
        return [
            PieceSlicer(left: .line, top: .line, right: .outside, bottom: .inner),
            PieceSlicer(left: .inner, top: .line, right: .line, bottom: .outside),
            PieceSlicer(left: .line, top: .outside, right: .inner, bottom: .line),
            PieceSlicer(left: .outside, top: .inner, right: .line, bottom: .line),
        ]
    }
}

/// 构造3X3的拼图
struct PuzzlePiece9: PuzzleMakeable {
    mutating func construct() -> [PieceSlicer] {
        return []
    }
}


/// 搜索生成
struct PuzzlePieceAutomatic: PuzzleMakeable {
    
    var row: Int = 0 {
        didSet {
            map = Array(repeating: Array(repeating: PieceSlicer(left: .none, top: .none, right: .none, bottom: .none),
                                         count: row), count: row)
        }
    }
    var pieceWidth: CGFloat = 0
    
    // n x n 的方阵
    var map: [[PieceSlicer]] = []
    
    // 规则1：最外层的边都是平面
    // 规则2：没有约束的情况下随机凹凸
    // 规则3：一个碎片凹或凸的边不能超过3个
    // 规则4：相邻碎片的凹凸需要契合
    mutating func construct() -> [PieceSlicer] {
        var pieceList: [PieceSlicer] = []
        
        let raduis: CGFloat = PieceSlicer.radiusByWidth(pieceWidth)
        
        for i in 0..<row {
            for j in 0..<row {
                var slicer = PieceSlicer(left: .none, top: .none, right: .none, bottom: .none)
                slicer.holeRadius = raduis
                var lineBox: [PieceSlicer.PathDrawType] = [.inner, .outside]
                
                // 根据前置位 匹配凹凸类型
                if j == 0 {
                    slicer.leftDraw = .line
                } else {
                    // 左边有方块 直接取反
                    let leftSilce = map[i][j-1]
                    slicer.leftDraw = leftSilce.rightDraw.oppose
                }
                
                if j == row - 1 { slicer.rightDraw = .line }
                if i == 0 {
                    slicer.topDraw = .line
                } else {
                    let topSilce = map[i-1][j]
                    slicer.topDraw = topSilce.bottomDraw.oppose
                }
                
                if i == row - 1 { slicer.bottomDraw = .line }
                
                // 填充剩余边
                slicer.randomSetDirections(box: &lineBox)
                
                print(slicer.description())
                pieceList.append(slicer)
                map[i][j] = slicer
            }
        }
        
        return pieceList
    }
}





