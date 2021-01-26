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
    
    var rowCount: Int = 0
    var pieceSize: CGSize = .zero
    
    //
    var dragIndexPath: IndexPath?
    
    private var tipsFrames: [UIView] = []
    private var lastHightlightFV: UIView?
    
    
    @IBOutlet weak var puzzleContainerView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commonInit()
        setupPuzzleRect()
    }
    
    
    private func commonInit() {
        collectionView.register(UINib(nibName: "PuzzlePieceCell", bundle: nil),
                                forCellWithReuseIdentifier: "PuzzlePieceCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // drag
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.reorderingCadence = .slow
//        // drop
//        collectionView.dropDelegate = self
        
        collectionView.collectionViewLayout = flowLayout(margin: 0)
        
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
        
        let dragInteraction = UIDragInteraction(delegate: self)
        view.addInteraction(dragInteraction)
        
        
    }
    
    func flowLayout(margin: CGFloat) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        layout.itemSize = pieceSize
        
        layout.minimumLineSpacing = margin
        layout.minimumInteritemSpacing = 0 //最小item间距
        
        return layout;
    }

    
    private func setupPuzzleRect() {
        for i in 0..<pieceImages.count {
            let r = i / rowCount
            let c = i % rowCount
            let frameV = UIView(frame: CGRect(x: c * 50, y: r * 50, width: 50, height: 50))
            frameV.layer.borderWidth = 4
            frameV.layer.borderColor = UIColor.lightGray.cgColor
            
            frameV.isHidden = true
            tipsFrames.append(frameV)
            
            puzzleContainerView.addSubview(frameV)
        }
    }
    
    private func currentHighlightRect(oriPt: CGPoint) -> CGRect {
        let pieceWidth = puzzleContainerView.frame.width / CGFloat(rowCount)
        if let highFrame = lastHightlightFV?.frame {
            let margin: CGFloat = PieceSlicer.radiusByWidth(pieceWidth) * 2
            // 扩展边缘
            let relFrame = CGRect(x: highFrame.origin.x - margin,
                                  y: highFrame.origin.y - margin,
                                  width: highFrame.width + margin*2,
                                  height: highFrame.height + margin*2)
            return relFrame
        } else {
            return CGRect(x: oriPt.x, y: oriPt.y, width: pieceWidth, height: pieceWidth)
        }
    }
}

extension PuzzlePlayController: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        return []
    }
}


extension PuzzlePlayController: UIDropInteractionDelegate {
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        let pt = session.location(in: self.view)
        session.loadObjects(ofClass: UIImage.self) { (image) in
            guard let img = image.first as? UIImage else { return }
            
            if self.puzzleContainerView.frame.contains(pt) {
                print("在区域内")
                let imageV = UIImageView(image: img)
                imageV.frame = self.currentHighlightRect(oriPt: pt)
                self.puzzleContainerView.addSubview(imageV)
                
                if let dragIdx = self.dragIndexPath?.item {
                    self.collectionView.performBatchUpdates {
                        self.pieceImages.remove(at: dragIdx)
                        self.collectionView.deleteItems(at: [IndexPath(item: dragIdx, section: 0)])
                    } completion: { (done) in
                        
                    }
                }
            } else {
                print("不在区域内")
            }
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, item: UIDragItem, willAnimateDropWith animator: UIDragAnimating) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        // Propose to the system to copy the item from the source app
        let pt = session.location(in: self.view)
        print("ori pt = \(pt)")
        if self.puzzleContainerView.frame.contains(pt) {
            let retPt = view.convert(pt, to: self.puzzleContainerView)
            print(retPt)
            
            // 确定在哪个方格
            let rectWidth = puzzleContainerView.frame.width / CGFloat(rowCount)
            let column = floor(retPt.x / rectWidth)
            let row = floor(retPt.y / rectWidth)
            
            let idx = Int(column + row * CGFloat(rowCount))
            
            print("当前落在格子\(column)-\(row)， 对应方格-\(idx)")
            
            lastHightlightFV?.isHidden = true
            tipsFrames[idx].isHidden = false
            lastHightlightFV = tipsFrames[idx]
        }
        
        return UIDropProposal(operation: .move)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return UIDragPreviewParameters()
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

extension PuzzlePlayController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        print("performDropWith coordinator")
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let itemProvider = NSItemProvider(object: pieceImages[indexPath.item])
        let item = UIDragItem(itemProvider: itemProvider)
        self.dragIndexPath = indexPath
        
        return [item]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        print("dragSessionWillBegin")
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        print("dragSessionDidEnd")
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        return true
    }
}

extension PuzzlePlayController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        print("dropSessionDidEnter \(session)")
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
//        print("dropSessionDidUpdate \(session)")
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .forbidden)
        } else {
            return UICollectionViewDropProposal(operation: .move)
        }
    }
    
}
