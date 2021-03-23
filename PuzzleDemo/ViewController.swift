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
    
    private let rowCountConfig: Int = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    @IBAction func cutAction(_ sender: Any) {
        let rowCount: Int = rowCountConfig
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
        dest.rowCount = rowCountConfig
        
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

