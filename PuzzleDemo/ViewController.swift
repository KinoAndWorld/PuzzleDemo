//
//  ViewController.swift
//  PuzzleDemo
//
//  Created by kino on 2020/12/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var pieceImages: [UIImage] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    @IBAction func cutAction(_ sender: Any) {
        let rowCount: Int = 6
        let canverWidth: CGFloat = imageView.frame.width / CGFloat(rowCount)
        
        var pieceStructor = PuzzlePieceAutomatic()
        pieceStructor.row = rowCount
        pieceStructor.pieceWidth = canverWidth
        
        var generator = PuzzleGenerator(makeable: pieceStructor)
        let slicers = generator.makeable!.construct()
        
        pieceImages.removeAll()
        
        for (idx, item) in slicers.enumerated() {
            let row: Int = idx / rowCount
            let column: Int = idx % rowCount
            
            let image = imageView.asImage(rect: CGRect(x: canverWidth * CGFloat(column) - item.holeRadius * 2,
                                                       y: canverWidth * CGFloat(row) - item.holeRadius * 2,
                                                       width: canverWidth + item.holeRadius * 4,
                                                       height: canverWidth + item.holeRadius * 4))
                .createPiece(slicer: item)
            
            pieceImages.append(image!)
            
            
            let imageV = UIImageView(image: image)
            imageV.backgroundColor = .lightGray
            imageV.contentMode = .scaleAspectFill
            view.addSubview(imageV)
            
//            imageV.frame = CGRect(x: (canverWidth + pieceStructor.pieceFillRadius * 3) * CGFloat(column),
//                                  y: (canverWidth + pieceStructor.pieceFillRadius * 3) * CGFloat(row) + 500,
//                                  width: imageView.frame.width / CGFloat(rowCount) + item.holeRadius * 2,
//                                  height: imageView.frame.height / CGFloat(rowCount) + item.holeRadius * 2)
            
            imageV.frame = CGRect(x: (canverWidth + item.holeRadius * 2) * CGFloat(column),
                                  y: (canverWidth + item.holeRadius * 2) * CGFloat(row) + 500,
                                  width: imageView.frame.width / CGFloat(rowCount) + item.holeRadius * 2,
                                  height: imageView.frame.height / CGFloat(rowCount) + item.holeRadius * 2)
        }
    }
    
    @IBAction func playAction(_ sender: Any) {
        let dest = PuzzlePlayController()
        dest.pieceSize = pieceImages.first!.size
        dest.originImage = imageView.image!
        dest.pieceImages = pieceImages
        dest.rowCount = 6
        
        self.navigationController?.pushViewController(dest, animated: true)
    }
    
}

protocol PuzzleSlice {
    var desc: String { get }
    
    func generSliceImage(image: UIImage) -> UIImage?
}

struct PuzzleSliceTopLeft: PuzzleSlice {
    var desc: String {
        return "PuzzleSliceTopLeft"
    }
    
    func generSliceImage(image: UIImage) -> UIImage? {
        return nil
    }
}

extension UIImage {
    
    func createPiece(slicer: PieceSlicer) -> UIImage? {
        // 扩展画布
        let startX = slicer.holeRadius * 2
        let startY = slicer.holeRadius * 2
        
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: self.size.width, height: self.size.height))
        let outImage = renderer.image { (ctx) in
            ctx.cgContext.translateBy(x: 0, y: self.size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            
            let width = self.size.width - slicer.holeRadius * 2
            let height = self.size.height - slicer.holeRadius * 2
            
            let path = slicer.draw(in: CGRect(x: startX, y: startY, width: width, height: height))
            path?.addClip()
            
            ctx.cgContext.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            
            ctx.cgContext.restoreGState()
        }
        return outImage
    }
}

extension UIView {
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension CGFloat {
    func toRadians() -> CGFloat {
        return self * CGFloat.pi / 180.0
    }
}


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

