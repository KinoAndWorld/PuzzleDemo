//
//  DragableAdapter.swift
//  PuzzleDemo
//
//  Created by kino on 2021/1/27.
//

import UIKit

class PieceDragableAdapter: NSObject {
    var bindView: UIView?
    var bindImage = UIImage()
    var bindPt: CGPoint = .zero
    
    var isVaild: Bool = true
    
    
    init(view: UIView, image: UIImage, loc: CGPoint) {
        super.init()
        
        self.bindView = view
        self.bindImage = image
        self.bindPt = loc
        
        commonInit()
    }
    
    private func commonInit() {
        bindView?.isUserInteractionEnabled = true
        
        let dragInteract = UIDragInteraction(delegate: self)
        bindView?.addInteraction(dragInteract)
        dragInteract.isEnabled = true
    }
}

extension PieceDragableAdapter: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        if !isVaild { return [] }
        let itemProvider = NSItemProvider(object: bindImage)
        
        let item = UIDragItem(itemProvider: itemProvider)
        session.localContext = ("Piece-Frame", self.bindPt)
        
        // 半透明化原图
        self.bindView?.alpha = 0.5
        
        return [item]
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, sessionAllowsMoveOperation session: UIDragSession) -> Bool {
        return true
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, willEndWith operation: UIDropOperation) {
        
    }
    
//    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
//
//        guard let imageView = bindView as? UIImageView else {
//            return nil
//        }
//
//        let center = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
//        let target = UIDragPreviewTarget(container: imageView, center: center)
//
//        let previewParameters = UIDragPreviewParameters()
//        previewParameters.backgroundColor = UIColor.clear // transparent background
//        return UITargetedDragPreview(view: imageView,
//                                     parameters: previewParameters,
//                                     target: target)
//    }
}
