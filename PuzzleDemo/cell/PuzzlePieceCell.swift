//
//  PuzzlePieceCell.swift
//  PuzzleDemo
//
//  Created by kino on 2021/1/22.
//

import UIKit

class PuzzlePieceCell: UICollectionViewCell {

    @IBOutlet weak var pieceView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        let dragGesture = (target: self, action: #selector(dragAction))
//
//        self.addGestureRecognizer(dragGesture)
    }
    
    @objc func dragAction() {
        
    }
}
