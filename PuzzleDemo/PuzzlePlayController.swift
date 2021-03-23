//
//  PuzzlePlayController.swift
//  PuzzleDemo
//
//  Created by kino on 2021/1/22.
//

import UIKit

class PieceDataModel: NSObject {
    var loc: CGPoint = .zero
    var image = UIImage()
}

class PuzzlePlayController: UIViewController {
    var originImage = UIImage()
    var pieceImages: [UIImage] = []
    
    var rowCount: Int = 0
    var pieceSize: CGSize = .zero
    
    
    private var pieceDatas: [PieceDataModel] = []
    
    //
    var dragIndexPath: IndexPath?
    var dragingModel: PieceDataModel?
    
    private var tipsFrames: [UIView] = []
    private var lastHightlightFV: UIView?
    private var lastHighlightPt: CGPoint = .zero
    
    private var pieceAdapters: [PieceDragableAdapter] = []
    
    // 拼图摆放记录 n*n
    private var completeStates: [[Int]] = []
    
    
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
        
        collectionView.collectionViewLayout = flowLayout(margin: 0)
        
        // view drog
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
    }
    
    func flowLayout(margin: CGFloat) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        layout.itemSize = pieceSize
        
        layout.minimumLineSpacing = margin
        layout.minimumInteritemSpacing = 0 //最小item间距
        
        return layout;
    }

    
    private func setupPuzzleRect() {
        let pieceSize: CGFloat = 300.0 / CGFloat(rowCount)
        for r in 0..<rowCount {
            for c in 0..<rowCount {
                let frameV = UIView(frame: CGRect(x: CGFloat(c) * pieceSize,
                                                  y: CGFloat(r) * pieceSize,
                                                  width: pieceSize, height: pieceSize))
                frameV.layer.borderWidth = 4
                frameV.layer.borderColor = UIColor.lightGray.cgColor
                
                frameV.isHidden = true
                tipsFrames.append(frameV)
                
                puzzleContainerView.addSubview(frameV)
                
                let model = PieceDataModel()
                model.image = pieceImages[r*rowCount + c]
                model.loc = CGPoint(x: c, y: r)
                pieceDatas.append(model)
            }
        }
        
        completeStates = Array(repeating: Array(repeating: 0, count: rowCount), count: rowCount)
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
    
    private func adapterByLoc(pt: CGPoint) -> PieceDragableAdapter? {
        return pieceAdapters.filter{ $0.bindPt == pt }.first
    }
    
    /// 判断当前绑定是否正确
    /// - Parameter adapter: PieceDragableAdapter
    private func checkAdapterBindCorrect(adapter: PieceDragableAdapter) {
        // 判断是否落在了正确的格子
        if let dragingLoc = self.dragingModel?.loc, dragingLoc.equalTo(adapter.bindPt) {
            adapter.bindView?.alpha = 1.0
            // 如果正确 则锁定
            completeStates[Int(adapter.bindPt.x)][Int(adapter.bindPt.y)] = 1
        } else {
            adapter.bindView?.alpha = 0.5
            completeStates[Int(adapter.bindPt.x)][Int(adapter.bindPt.y)] = 0
        }
    }
    
    private func checkAllComplete() -> Bool {
        for list in completeStates {
            for state in list {
                if state == 0 { return false }
            }
        }
        return true
    }
    
    private func showCompleteAlert() {
        let alert = UIAlertController(title: "恭喜🎇", message: "拼图已完成", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "👌", style: .default, handler: { [unowned self] _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension PuzzlePlayController: UIDropInteractionDelegate {
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        let pt = session.location(in: self.view)
        session.loadObjects(ofClass: UIImage.self) { [weak self] (image) in
            guard let self = self else { return }
            guard let img = image.first as? UIImage else { return }
            
            if self.puzzleContainerView.frame.contains(pt) {
                print("在区域内")
                // 判断来源 如果是移动铺面的
                if let context = session.localDragSession?.localContext as? (String, CGPoint) {
                    let fromPt = context.1
                    // 移动到新方块
                    let newFrame = self.currentHighlightRect(oriPt: pt)
                    if let adapter = self.adapterByLoc(pt: fromPt) {
                        adapter.bindView?.frame = newFrame
                        
                        // 更新pt
                        adapter.bindPt = self.lastHighlightPt
                        // 隐藏方块
                        self.lastHightlightFV?.isHidden = true
                        
                        self.checkAdapterBindCorrect(adapter: adapter)
                        // 判断游戏是否结束
                        if self.checkAllComplete() {
                            self.showCompleteAlert()
                        }
                    }
                    return
                }
                
                
                // 如果当前放置的位置已经有了正确答案 则直接取消
                if self.completeStates[Int(self.lastHighlightPt.x)][Int(self.lastHighlightPt.y)] == 1 {
                    // 隐藏方块
                    self.lastHightlightFV?.isHidden = true
                    return
                }
                
                let imageV = UIImageView(image: img)
                imageV.frame = self.currentHighlightRect(oriPt: pt)
                self.puzzleContainerView.addSubview(imageV)
                // 隐藏方块
                self.lastHightlightFV?.isHidden = true
                
                
                let adapter = PieceDragableAdapter(view: imageV, image: img, loc: self.lastHighlightPt)
                self.pieceAdapters.append(adapter)
                
                if let dragIdx = self.dragIndexPath?.item {
                    self.collectionView.performBatchUpdates {
                        self.pieceDatas.remove(at: dragIdx)
                        self.collectionView.deleteItems(at: [IndexPath(item: dragIdx, section: 0)])
                    } completion: { (done) in
                        
                    }
                }
                
                // 判断是否正确
                self.checkAdapterBindCorrect(adapter: adapter)
                // 判断游戏是否结束
                if self.checkAllComplete() {
                    self.showCompleteAlert()
                }
            } else {
                print("不在区域内")
                
            }
            
            self.dragIndexPath = nil
            self.dragingModel = nil
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, item: UIDragItem, willAnimateDropWith animator: UIDragAnimating) {
        
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
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
            
            lastHighlightPt = CGPoint(x: column, y: row)
        } else {
            lastHightlightFV?.isHidden = true
            lastHighlightPt = .zero
        }
        
        return UIDropProposal(operation: .move)
    }
}

extension PuzzlePlayController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pieceDatas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PuzzlePieceCell", for: indexPath) as! PuzzlePieceCell
        
        cell.pieceView.image = pieceDatas[indexPath.row].image
        
        return cell
    }
}

extension PuzzlePlayController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        self.dragingModel = pieceDatas[indexPath.item]
        self.dragIndexPath = indexPath
        
        let itemProvider = NSItemProvider(object: pieceDatas[indexPath.item].image)
        let item = UIDragItem(itemProvider: itemProvider)
        
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
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let params = UIDragPreviewParameters()
        params.backgroundColor = .clear
        
        return params
    }
}
