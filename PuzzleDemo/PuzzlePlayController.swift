//
//  PuzzlePlayController.swift
//  PuzzleDemo
//
//  Created by kino on 2021/1/22.
//

import UIKit

class PuzzlePlayController: UIViewController {

    var originImage = UIImage()
    var pieceImages: [UIImage] = []
    
    var pieceSize: CGSize = .zero
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commonInit()
    }
    
    
    private func commonInit() {
        collectionView.register(UINib(nibName: "PuzzlePieceCell", bundle: nil),
                                forCellWithReuseIdentifier: "PuzzlePieceCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.collectionViewLayout = flowLayout(margin: 0)
    }
    
    func flowLayout(margin: CGFloat) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        layout.itemSize = pieceSize
        
        layout.minimumLineSpacing = margin
        layout.minimumInteritemSpacing = 0 //最小item间距
        
        return layout;
    }

}

extension PuzzlePlayController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pieceImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PuzzlePieceCell", for: indexPath) as! PuzzlePieceCell
        
        cell.pieceView.image = pieceImages[indexPath.row]
        
        return cell
    }
    
    
}
