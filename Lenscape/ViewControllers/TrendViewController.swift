//
//  TrendViewController.swift
//  Lenscape
//
//  Created by TAWEERAT CHAIMAN on 8/3/2561 BE.
//  Copyright © 2561 Lenscape. All rights reserved.
//

import UIKit
import Hero

class TrendViewController: UIViewController {

    // MARK: - Attributes
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private lazy var refreshControl = UIRefreshControl()
    
    var images: [Image] = []
    let itemsPerRow = 3
    var page = 1
    var shouldFetchMore = false
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        setupRefreshControl()
        fetchInitImagesFromAPI()
    }
    
    // MARK: - Private Methods
    
    @objc private func fetchInitImagesFromAPI() {
        page = 1
        fetchImagesFromAPI(page: page) {
            images in
            self.images = images
        }
    }
    
    private func isDisplayAllInOnePage() -> Bool {
        return self.images.count < 9
    }
    
    private func fetchImagesFromAPI(page: Int, modifyImageFunction: @escaping ([Image]) -> Void = { _ in }) {
        Api.fetchTrendImages(page: page).done {
            fulfill in
            
            let images = fulfill["images"] as! [Image]
            let pagination = fulfill["pagination"] as! Pagination
            modifyImageFunction(images)
            self.shouldFetchMore = pagination.hasMore && !self.isDisplayAllInOnePage()
            }.catch {
                error in
                print("error: \(error)")
            }.finally {
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
        }
    }
    
    @objc private func showFullPhoto(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: tapLocation)
        let cell = collectionView.cellForItem(at: indexPath!) as! ImageCollectionViewCell
        let index = indexPath!.row
        let image = images[index]
        let vc = self.storyboard?.instantiateViewController(withIdentifier: Identifier.FullImageViewController.rawValue) as! FullImageViewController
        vc.image = image
        vc.placeHolderImage = cell.imageView.image
        Hero.shared.defaultAnimation = .fade
        present(vc, animated: true)
    }
    
    private func setupRefreshControl() {
        //Initialize Refresh Control (Pull to refresh)
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(fetchInitImagesFromAPI), for: .valueChanged)
    }
    
}

// MARK: - UICollectionViewDataSource

extension TrendViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.ImageCollectionViewCell.rawValue, for: indexPath) as! ImageCollectionViewCell
        let index = indexPath.row
        // If scroll before last 4 rows then fetch the next images
        if images.count > itemsPerRow*3, index >= images.count - (itemsPerRow*4), shouldFetchMore {
            page += 1
            fetchImagesFromAPI(page: page) {
                images in
                self.images += images
            }
        }
        let image = images[index]
        let url = URL(string: image.thumbnailLink!)
        
        cell.imageView.hero.id = image.thumbnailLink!
        cell.imageView.kf.indicatorType = .activity
        cell.imageView.kf.setImage(with: url, options: [.transition(.fade(0.5))])
        
        addTapGesture(for: cell.imageView, with: #selector(showFullPhoto(sender:)))
        
        return cell
    }
    
    // CollectionView's supplementary (used as header)
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Identifier.TrendCollectionReusableView.rawValue, for: indexPath)
            guard let tabHeader = headerView.subviews[0] as? TabHeader else {
                fatalError("No header exists")
            }
            tabHeader.titleLabel.text = "Trending"
            return headerView
            
        default:
            assert(false, "Unexpected element kind")
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrendViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.frame.size.width - CGFloat(itemsPerRow+1)
        let widthPerItem = availableWidth / CGFloat(itemsPerRow)
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    // Space between column
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
    
    // Space between row
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    // Remove margin of UICollectionView not cell.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}


