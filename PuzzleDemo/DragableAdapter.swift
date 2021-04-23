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
    
    // 判断格子是否还可以拖动
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
}
