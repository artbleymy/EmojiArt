//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Stanislav on 13.03.2019.
//  Copyright © 2019 Stanislav Kozlov. All rights reserved.
//

import UIKit

extension EmojiArt.EmojiInfo {
    //failable initializer - return nil if problem with creation
    init?(label: UILabel) {
        if let attributedText = label.attributedText, let font = attributedText.font {
            x = Int(label.center.x)
            y = Int(label.center.y)
            text  = attributedText.string
            size = Int(font.pointSize)
        } else {
            return nil
        }
    }
}

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    //MARK: - Model
    
    var emojiArt: EmojiArt?{
        get{
            if let url = emojiArtBackgroundImage.url{
                let emojis = emojiArtView.subviews.compactMap{ $0 as? UILabel}.compactMap{EmojiArt.EmojiInfo(label: $0)}
                
                return EmojiArt(url: url, emojis: emojis)

            }
            return nil
        }
        set{
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.compactMap{$0 as? UILabel}.forEach{ $0.removeFromSuperview()}
            if let url = newValue?.url {
                imageFetcher = ImageFetcher(fetch: url, handler: { (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func save(_ sender: Any) {
        if let json = emojiArt?.json{
            if let jsonString = String(data: json, encoding: .utf8){
                print(jsonString)
            }
            //find a Document Directory
            if let url = try? FileManager.default.url(for: .documentDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: true
                ).appendingPathComponent("Untitled.json"){
                do {
                    try json.write(to: url)
                    print("save succesfully")
                } catch let error{
                    print("couldn't save a file \(error.localizedDescription)")
                }
                
            }
            
            

        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let url = try? FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true
            ).appendingPathComponent("Untitled.json"){
            if let jsonData = try? Data(contentsOf: url) {
                emojiArt = EmojiArt(json: jsonData)
            }
        }
    }
    
    //MARK: - Storyboard
    var imageFetcher: ImageFetcher!
    
    @IBOutlet weak var dropZone: UIView! {
        didSet {
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    var emojiArtView = EmojiArtView()
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
            
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight?.constant = scrollView.contentSize.height
        scrollViewWidth?.constant = scrollView.contentSize.width
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    private var _emojiArtBackgroundImageURL: URL?
    
    var emojiArtBackgroundImage:(url: URL?, image: UIImage?) {
        get {
            return (_emojiArtBackgroundImageURL, emojiArtView.backgoundImage)
        }
        set {
            _emojiArtBackgroundImageURL = newValue.url
            scrollView?.zoomScale = 1.0
            emojiArtView.backgoundImage = newValue.image
            let size  = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
        }
    }
    
    
    
    
    
    //MARK: - Drop Interation Methods
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher(){(url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
            }
        }
        session.loadObjects(ofClass: NSURL.self, completion: {nsurls in
            if let url = nsurls.first as? URL {
                self.imageFetcher.fetch(url)
            }
            
        })
        
        session.loadObjects(ofClass: UIImage.self, completion: {images in
            if let image = images.first as? UIImage{
                self.imageFetcher.backup = image
            }
            
        })
    }
    //MARK: - Collection view delegate methods
    
    var emojis = "😇🤬💩👎👅👁💂‍♀️👩‍🎤👨‍✈️🧛‍♂️⛑🐯🦄🐙🕷🍏🍔🍻🏀🥌🎽🤺".map{ String($0) }
    
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
        }
    }
    //MARK: - UICollectionViewDelegate methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return emojis.count
        default: return 0
        }
    }
    
    private var font: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
            if let emojiCell = cell as? EmojiCollectionViewCell{
                let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font:font])
                emojiCell.label.attributedText = text
            }
            return cell
        } else if addingEmoji {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell{
                inputCell.resignationHandler = {[weak self, unowned inputCell] in
                    if let text = inputCell.textField.text {
                        self?.emojis = (text.map { String($0) } + self!.emojis).uniquified
                    }
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData()
                    inputCell.textField?.text = ""
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
            return cell

        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell {
            inputCell.textField.becomeFirstResponder()
        }
    }
    
    //MARK: -UICollectionViewDelegateFlowLayout methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0{
            return CGSize(width: 300, height: 80)
        } else {
            return CGSize(width: 80, height: 80)
        }
    }
    
    
    //MARK: - Drag interactions on collectionView
    private func dragItems(at indexPath: IndexPath) ->[UIDragItem]{
        if !addingEmoji, let arttributedString = (emojiCollectionView.cellForItem(at: indexPath) as?
            EmojiCollectionViewCell)?.label.attributedText {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: arttributedString))
            dragItem.localObject = arttributedString
            return [dragItem]
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    //move item by dragging
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                if let attributedString = item.dragItem.localObject as? NSAttributedString {
                    //обязательно использовать для нескольких одновременных действий в collection view
                    collectionView.performBatchUpdates({
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                    
                }
            } else {
                let placeholderContext = coordinator.drop(item.dragItem,
                                                          to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString{
                            placeholderContext.commitInsertion(dataSourceUpdates: { (insetrionIndexPath) in
                                self.emojis.insert(attributedString.string, at: insetrionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                        
                    }
                }
                
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1{
            let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
        
    }
    
    
    //MARK: - add new emoji to collection
    private var addingEmoji = false
    
    @IBAction func addEmoji(_ sender: UIButton) {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
        
    }
    
    //MARK: - UICollectionViewDataSource
   
    
    //MARK: - View Did Load method
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }
    

    

}
