//
//  ExploreViewController.swift
//  Lenscape
//
//  Created by TAWEERAT CHAIMAN on 6/3/2561 BE.
//  Copyright © 2561 Lenscape. All rights reserved.
//

import UIKit
import Kingfisher
import SwiftCarousel
import Hero

class ExploreViewController: UIViewController {
    
    //MARK: - UI Components
    @IBOutlet weak var tableView: UITableView!
    //    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var showMapButton: UIView!
    @IBOutlet weak var progressViewWrapper: UIView!
    //    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var seasoningScrollView: CircularInfiniteScroll!
    private lazy var refreshControl = UIRefreshControl()
    
    var items = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var itemsViews: [CircularScrollViewItem]?
    let colors = [#colorLiteral(red: 0.4274509804, green: 0.8039215686, blue: 1, alpha: 1),#colorLiteral(red: 0.6823529412, green: 0.6823529412, blue: 0.6588235294, alpha: 1),#colorLiteral(red: 0.7882352941, green: 0.631372549, blue: 0.4352941176, alpha: 1),#colorLiteral(red: 0.8980392157, green: 0.5803921569, blue: 0.2156862745, alpha: 1),#colorLiteral(red: 1, green: 0.5333333333, blue: 0, alpha: 1),#colorLiteral(red: 1, green: 0.6196078431, blue: 0.1882352941, alpha: 1),#colorLiteral(red: 1, green: 0.7215686275, blue: 0.4117647059, alpha: 1),#colorLiteral(red: 1, green: 0.8431372549, blue: 0.6823529412, alpha: 1),#colorLiteral(red: 0.8823529412, green: 0.8352941176, blue: 0.7450980392, alpha: 1),#colorLiteral(red: 0.7725490196, green: 0.8274509804, blue: 0.8078431373, alpha: 1),#colorLiteral(red: 0.6588235294, green: 0.8196078431, blue: 0.8705882353, alpha: 1),#colorLiteral(red: 0.5490196078, green: 0.8117647059, blue: 0.9333333333, alpha: 1),#colorLiteral(red: 0.4274509804, green: 0.8039215686, blue: 1, alpha: 1)]
    let photoUploader = PhotoUploader()
    var images: [Image] = []
    let itemsPerRow: Int = 3
    var numberOfPhotos = 0 {
        didSet {
            //            self.descriptionLabel.text = "\(self.numberOfPhotos) Photos"
        }
    }
    var page = 1
    var shouldFetchMore = false
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoUploader.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        setupUI()
        setupShowMapButton()
        
        //Make ExploreViewController as observer for LocationManager (this vc will be notify from MainTabBarController (CLLocationManagerDelegate))
        NotificationCenter.default.addObserver(self, selector: #selector(fetchInitImageFromAPI), name: .DidUpdateLocation, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startUploadPhoto()
    }
    
    // Adjust height of Header every time subview has been changed
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        let size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            UIView.animate(withDuration: 0.5, animations: {
                self.tableView.layoutIfNeeded()
                self.scrollToTop()
            })
        }
    }
    
    // MARK: - Private Methods
    
    private func startUploadPhoto() {
        if let picture = UserDefaults.standard.dictionary(forKey: "uploadPhotoInfo") {
            let locationManager = LocationManager.getInstance()
            photoUploader.upload(picture: picture, location: locationManager.getCurrentLocation())
            UserDefaults.standard.removeObject(forKey: "uploadPhotoInfo")
        }
    }
    
    private func scrollToTop() {
        //Scroll table to top
        tableView.setContentOffset(CGPoint(x: 0, y: -20), animated: true)
    }
    
    @objc private func fetchInitImageFromAPI() {
        print("FetchInitImageFromAPI")
        page = 1
        fetchImagesFromAPI(page: page) {
            images in
            self.images = images
        }
    }
    
    private func isDisplayAllInOnePage() -> Bool {
        return self.images.count < 9
    }
    
    private func fetchImagesFromAPI(page: Int = 1, modifyImageFunction: @escaping ([Image]) -> Void = { _ in }) {
        Api.fetchExploreImages(page: page, location: LocationManager.getInstance().getCurrentLocation()!).done {
            fulfill in
            
            let images = fulfill["images"] as! [Image]
            let pagination = fulfill["pagination"] as! Pagination
            modifyImageFunction(images)
            self.numberOfPhotos = pagination.totalNumberOfEntities
            self.shouldFetchMore = pagination.hasMore
            }.catch {
                error in
                print("error: \(error)")
            }.finally {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
        }
    }
    
    private func setupUI() {
        // MARK: Seasoning Scroll View
        do {
            try seasoningScrollView.carousel.itemsFactory(itemsCount: 12, factory: labelForMonthItem)
        } catch  {
            
        }
        seasoningScrollView.carousel.delegate = self
        seasoningScrollView.carousel.resizeType = .visibleItemsPerPage(9)
        seasoningScrollView.carousel.defaultSelectedIndex = 6
        
        progressViewWrapper.isHidden = true
        
        // Initialize Refresh Control (Pull to refresh)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(fetchInitImageFromAPI), for: .valueChanged)
    }
    
    private func setupShowMapButton() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMapsViewController))
        showMapButton.addGestureRecognizer(tap)
        showMapButton.isUserInteractionEnabled = true
    }
    
    @objc private func showPhotoInfoVC(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: tapLocation)
        let cell = tableView.cellForRow(at: indexPath!) as! FeedTableViewCell
        let index = indexPath!.row
        let image = images[index]
        let vc = self.storyboard?.instantiateViewController(withIdentifier: Identifier.PhotoInfoViewController.rawValue) as! PhotoInfoViewController
        vc.image = image
        vc.uiImage = cell.uiImageView.image
        Hero.shared.defaultAnimation = .fade
        present(vc, animated: true)
    }
    
    func labelForMonthItem(index: Int) -> CircularScrollViewItem {
        let string = items[index]
        let viewContainer = CircularScrollViewItem()
        viewContainer.label.text = string
        viewContainer.label.font = .systemFont(ofSize: 14.0)
        viewContainer.contentView.startColor = colors[index]
        viewContainer.contentView.endColor = colors[index+1]
        viewContainer.contentView.sizeToFit()
        return viewContainer
    }
    
    @objc private func showMapsViewController() {
        print("showMapsViewController")
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: Identifier.ExploreMapViewController.rawValue) else {
            fatalError("\(Identifier.ExploreMapViewController.rawValue) is not exist")
        }
        Hero.shared.defaultAnimation = .zoom
        present(vc, animated: true)
    }
    
    // MARK: - unwind
    @IBAction func unwindToGridView(sender: UIStoryboardSegue) {
        
    }
    
    
}

// Mark: - UITableViewDataSource
extension ExploreViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.FeedTableCell.rawValue, for: indexPath) as! FeedTableViewCell
        let image = images[indexPath.row]
        let profileImageUrl = URL(string: image.owner.profilePictureLink)
        cell.profileImage.kf.setImage(with: profileImageUrl, options: [.transition(.fade(0.5))])
        
        cell.ownerNameLabel.text = image.owner.name
        
        let imageUrl = URL(string: image.thumbnailLink!)
        cell.uiImageView.kf.indicatorType = .activity
        cell.uiImageView.kf.setImage(with: imageUrl, options: [.transition(.fade(0.5))], completionHandler: {
            (downloadedImage, error, cacheType, imageUrl) in
            // Show the original image from cache only
            ImageCache.default.retrieveImage(forKey: image.link!, options: nil) {
                (image, cacheType) in
                if let image = image {
                    cell.uiImageView.image = image
                }
            }
        })
        
        // Used for animation between this and PhotoInfoViewController
        cell.uiImageView.hero.id = image.thumbnailLink!
        
        cell.numberOfLikeLabel.text = "\(image.likes!)"
        cell.imageNameLabel.text = image.name!
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showPhotoInfoVC(sender:)))
        cell.uiImageView.addGestureRecognizer(tap)
        cell.uiImageView.isUserInteractionEnabled = true
        return cell
    }
}

extension ExploreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = images.count - 1
        if indexPath.row == lastElement, shouldFetchMore {
            page += 1
            fetchImagesFromAPI(page: page) {
                images in
                self.images += images
            }
        }
    }
}

// MARK: - PhotoUploadingDelegate

extension ExploreViewController: PhotoUploadingDelegate {
    
    func didUpload() {
        progressViewWrapper.isHidden = true
        UserDefaults.standard.removeObject(forKey: "uploadPhotoInfo")
        fetchInitImageFromAPI()
        print("didUpload")
    }
    
    func uploading(completedUnit: Double, totalUnit: Double) {
        progressViewWrapper.isHidden = false
        UIView.animate(withDuration: 3, delay: 0.0, options: .curveLinear, animations: {
            self.progressView.setProgress(Float(completedUnit/totalUnit), animated: true)
        }, completion: nil)
        print("uploading \(completedUnit)/\(totalUnit)")
    }
    
    func willUpload() {
        progressViewWrapper.isHidden = false
        progressView.progress = 0
        print("willUpload")
    }
}

// MARK: - SwiftCarouselDelegate

extension ExploreViewController: SwiftCarouselDelegate {
    
    func didSelectItem(item: UIView, index: Int, tapped: Bool) -> UIView? {
        return item
    }
    
    func didDeselectItem(item: UIView, index: Int) -> UIView? {
        return item
    }
}


