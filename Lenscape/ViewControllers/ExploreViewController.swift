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
import ReactiveCocoa

class ExploreViewController: UIViewController {
    
    //MARK: - UI Components
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var uploadPreviewImage: UIImageView!
    @IBOutlet weak var cancelUploadButton: ShadowView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var showMapButton: UIView!
    @IBOutlet weak var progressViewWrapper: UIView!
    @IBOutlet weak var seasoningScrollView: CircularInfiniteScroll!
    private lazy var refreshControl = UIRefreshControl()
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerTitleSection: UIView!
    @IBOutlet weak var filterWrapper: UIView!
    @IBOutlet weak var seasonFilterLabel: UILabel!
    @IBOutlet weak var partOfDayFilterWrapper: UIStackView!
    @IBOutlet weak var seasonFilterWrapper: UIStackView!
    @IBOutlet weak var partOfDayFilterLabel: UILabel!
    @IBOutlet weak var showFilterDialogButton: GradientView!
    @IBOutlet weak var removeFilterButton: UIView!
    @IBOutlet weak var uploadedWrapper: UIView!
    @IBOutlet weak var uploadedUIImageView: UIImageView!
    @IBOutlet weak var goToLatestPlaceButton: RoundedBorderButton!
    var indicator = UIActivityIndicatorView()
    
    var items = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var itemsViews: [CircularScrollViewItem]?
    let colors = [#colorLiteral(red: 0.4274509804, green: 0.8039215686, blue: 1, alpha: 1),#colorLiteral(red: 0.6823529412, green: 0.6823529412, blue: 0.6588235294, alpha: 1),#colorLiteral(red: 0.7882352941, green: 0.631372549, blue: 0.4352941176, alpha: 1),#colorLiteral(red: 0.8980392157, green: 0.5803921569, blue: 0.2156862745, alpha: 1),#colorLiteral(red: 1, green: 0.5333333333, blue: 0, alpha: 1),#colorLiteral(red: 1, green: 0.6196078431, blue: 0.1882352941, alpha: 1),#colorLiteral(red: 1, green: 0.7215686275, blue: 0.4117647059, alpha: 1),#colorLiteral(red: 1, green: 0.8431372549, blue: 0.6823529412, alpha: 1),#colorLiteral(red: 0.8823529412, green: 0.8352941176, blue: 0.7450980392, alpha: 1),#colorLiteral(red: 0.7725490196, green: 0.8274509804, blue: 0.8078431373, alpha: 1),#colorLiteral(red: 0.6588235294, green: 0.8196078431, blue: 0.8705882353, alpha: 1),#colorLiteral(red: 0.5490196078, green: 0.8117647059, blue: 0.9333333333, alpha: 1),#colorLiteral(red: 0.4274509804, green: 0.8039215686, blue: 1, alpha: 1)]
    let photoUploader = PhotoUploader()
    var images: [Image] = []
    let itemsPerRow: Int = 3
    var numberOfPhotos = 0
    var page = 1
    var shouldFetchMore = false
    var lastContentOffset: CGFloat = 0
    var shouldUpdateHeaderVisibility = true
    var headerHeightConstraint: NSLayoutConstraint?
    var currentFeedLocation: Location?
    var uploadedImage: Image?
    var filterSeason: Season? {
        didSet {
            let isHidden = self.filterSeason == nil
            self.seasonFilterWrapper.isHidden = isHidden
            if !isHidden {
                self.seasonFilterLabel.text = self.filterSeason!.name
            }
        }
    }
    var filterPartOfDay: PartOfDay? {
        didSet {
            let isHidden = self.filterPartOfDay == nil
            self.partOfDayFilterWrapper.isHidden = isHidden
            if !isHidden {
                self.partOfDayFilterLabel.text = self.filterPartOfDay!.name
            }
        }
    }
    var seasons: [Season] = []
    var partsOfDay: [PartOfDay] = []
    
    // Fix tableview row's offset change after call reloadRowsAt... in likeImage()
    // https://stackoverflow.com/questions/27102887/maintain-offset-when-reloadrowsatindexpaths
    fileprivate var heightForIndexPath = [IndexPath: CGFloat]()
    fileprivate let averageRowHeight: CGFloat = 312 //your best estimate
    
    // MARK: - ViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchSeasons()
        fetchPartsOfDay()
        photoUploader.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        setupUI()
        addTapGesture(for: showMapButton, with: #selector(showMapsViewController))
        addTapGesture(for: cancelUploadButton, with: #selector(cancelUploading))
        addTapGesture(for: showFilterDialogButton, with: #selector(showFilterViewController))
        addTapGesture(for: removeFilterButton, with: #selector(removeFilter))
        
        setupActivityIndicator()
        startActivityIndicator()
        
        //Make ExploreViewController as observer for LocationManager (this vc will be notify from MainTabBarController (CLLocationManagerDelegate))
        NotificationCenter.default.addObserver(self, selector: #selector(setAndFetchInitImageFromAPI), name: .DidUpdateLocation, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startUploadPhoto()
    }
    
    // MARK: - Private Methods
    
    func overlayBlurredBackgroundView() {
        
        let blurredBackgroundView = UIVisualEffectView()
        
        blurredBackgroundView.frame = view.frame
        blurredBackgroundView.effect = UIBlurEffect(style: .dark)
        blurredBackgroundView.alpha = 0
        view.addSubview(blurredBackgroundView)
        UIView.animate(withDuration: 0.4, animations: {
            blurredBackgroundView.alpha = 1
        })
    }
    
    func removeBlurredBackgroundView() {
        
        for subview in view.subviews {
            if subview.isKind(of: UIVisualEffectView.self) {
                subview.removeFromSuperview()
            }
        }
    }
    
    @objc private func showFilterViewController() {
        self.definesPresentationContext = true
        self.providesPresentationContextTransitionStyle = true
//        self.overlayBlurredBackgroundView()
        let vc = self.storyboard?.instantiateViewController(withIdentifier: Identifier.FilterViewController.rawValue) as! FilterViewController
        vc.seasons = self.seasons
        vc.partsOfDay = self.partsOfDay
        vc.delegate = self
        vc.season = self.filterSeason
        vc.partOfDay = self.filterPartOfDay
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true)
    }
    
    @IBAction func goToYourLatestPlace(_ sender: UIButton) {
        if let image = uploadedImage {
            let location = Location(latitude: image.place.location.latitude, longitude: image.place.location.longitude)
            self.currentFeedLocation = location
            self.headerLabel.text = "Around \(image.place.name)"
            self.fetchInitImageFromAPI()
        }
        uploadedWrapper.hideWithAnimation(isHidden: true)
    }
    
    @objc private func removeFilter() {
        showFilter(isHidden: true)
        self.filterSeason = nil
        self.filterPartOfDay = nil
        self.fetchInitImageFromAPI()
    }
    
    private func startUploadPhoto() {
        if let picture = UserDefaults.standard.dictionary(forKey: "uploadPhotoInfo") {
            guard let imageData = picture["picture"] as? Data else {
                fatalError("picture is missing")
            }
            
            guard let encodedPlace = picture["place"] as? Data else {
                fatalError("place is missing")
            }
            
            let place = try? JSONDecoder().decode(Place.self, from: encodedPlace)
            
            let image = UIImage(data: imageData)
            uploadPreviewImage.image = image
            
            photoUploader.upload(picture: picture, place: place!)
            UserDefaults.standard.removeObject(forKey: "uploadPhotoInfo")
        }
    }
    
    private func scrollToTop() {
        //Scroll table to top
        tableView.setContentOffset(CGPoint(x: 0, y: -20), animated: true)
    }
    
    private func setupActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.activityIndicatorViewStyle = .gray
        indicator.center = view.center
        view.addSubview(indicator)
    }
    
    private func startActivityIndicator() {
        indicator.startAnimating()
        indicator.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
    }
    
    private func stopActivityIndicator() {
        indicator.stopAnimating()
        indicator.hidesWhenStopped = true
    }
    
    @objc private func setAndFetchInitImageFromAPI() {
        if currentFeedLocation == nil {
            currentFeedLocation = LocationManager.getInstance().getCurrentLocation()
        }
        fetchInitImageFromAPI()
    }
    
    @objc private func fetchInitImageFromAPI() {
        page = 1
        fetchImagesFromAPI(page: page, at: currentFeedLocation!) {
            images in
            self.images = images
            self.stopActivityIndicator()
        }
    }
    
    @objc private func pullDownToRefreshHandler() {
        NotificationCenter.default.post(name: .UpdateLocation, object: nil)
    }
    
    private func fetchImagesFromAPI(page: Int = 1, at location: Location, modifyImageFunction: @escaping ([Image]) -> Void = { _ in }) {
        Api.fetchExploreImages(page: page, location: location, season: self.filterSeason, partOfDay: self.filterPartOfDay).done {
            fulfill in
            
            let images = fulfill["images"] as! [Image]
            let pagination = fulfill["pagination"] as! Pagination
            modifyImageFunction(images)
            self.numberOfPhotos = pagination.totalNumberOfEntities
            self.shouldFetchMore = pagination.hasMore
            }.catch {
                error in
                let nsError = error as NSError
                let message = nsError.userInfo["message"] as? String ?? "Error"
                self.showAlertDialog(title: "Error", message: message)
            }.finally {
                self.tableView.reloadData()
                self.scrollToTop()
                self.showHeader(isShow: true)
                self.refreshControl.endRefreshing()
        }
    }
    
    private func fetchSeasons() {
        Api.getSeasons().done {
            seasons in
            self.seasons = seasons
            }.catch {
                error in
                let nsError = error as NSError
                let message = nsError.userInfo["message"] as? String ?? "Error"
                self.showAlertDialog(title: "Error", message: message)
        }
    }
    
    private func fetchPartsOfDay() {
        Api.getPartsOfDay().done {
            partsOfDay in
            self.partsOfDay = partsOfDay
            }.catch {
                error in
                let nsError = error as NSError
                let message = nsError.userInfo["message"] as? String ?? "Error"
                self.showAlertDialog(title: "Error", message: message)
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
        
        goToLatestPlaceButton.cornerRadius = goToLatestPlaceButton.frame.height / 2
        
        filterWrapper.isHidden = true
        uploadedWrapper.isHidden = true
        progressViewWrapper.isHidden = true
        progressViewWrapper.alpha = 0
        
        // Initialize Refresh Control (Pull to refresh)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(pullDownToRefreshHandler), for: .valueChanged)
    }
    
    @objc private func cancelUploading() {
        photoUploader.cancel()
    }
    
    @objc private func showFullPhoto(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: tapLocation)
        let cell = tableView.cellForRow(at: indexPath!) as! FeedItemTableViewCell
        let feedItem = cell.feedItem
        let index = indexPath!.row
        let image = images[index]
        let vc = self.storyboard?.instantiateViewController(withIdentifier: Identifier.FullImageViewController.rawValue) as! FullImageViewController
        vc.image = image
        vc.placeHolderImage = feedItem?.imageView.image
        Hero.shared.defaultAnimation = .fade
        
        // Observe dismiss event from modal, then notify parent (this) to do something.
        // https://github.com/ReactiveCocoa/ReactiveCocoa
        vc.reactive
            .trigger(for: #selector(vc.viewWillDisappear(_:)))
            .observe { _ in
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        present(vc, animated: true)
    }
    
    @objc private func likeImage(sender: UIButton) {
        let index = sender.tag

        guard index >= 0 && index < images.count else {
            fatalError("sender.tag must be number in range of 0..images.count")
        }
        
        let image = images[index]
        let updateImage = {
            image.is_liked = !image.is_liked
            image.likes! += image.is_liked ? 1 : -1
            sender.setImage(UIImage(named: image.is_liked ? "Red heart": "Gray Heart"), for: .normal)
        }
        updateImage()
        
        // Reload table row immediately with updated image's info
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        
        let _ = Api.likeImage(imageId: image.id, liked: image.is_liked).done {
            image in
            self.images[index] = image
            }.catch {
                error in
                //Update back to state before press
                updateImage()
                let nsError = error as NSError
                let message = nsError.userInfo["message"] as! String
                self.showAlertDialog(title: "Error",  message: "Status code: \(nsError.code). \(message)")
            }.finally {
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
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
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: Identifier.ExploreMapViewController.rawValue) as? ExploreMapViewController else {
            fatalError("\(Identifier.ExploreMapViewController.rawValue) is not exist")
        }
        vc.delegate = self
        vc.currentMapViewLocation = currentFeedLocation
        Hero.shared.defaultAnimation = .zoom
        present(vc, animated: true)
    }
    
    // MARK: - unwind
    @IBAction func unwindToGridView(sender: UIStoryboardSegue) {
        
    }
    
    private func showHeader(isShow: Bool) {
        self.headerTitleSection.hideWithAnimation(isHidden: !isShow)
    }
    
    private func showFilter(isHidden: Bool) {
        if filterSeason != nil || filterPartOfDay != nil {
            self.filterWrapper.hideWithAnimation(isHidden: isHidden)
        }
    }
    
    private func showUploadedNotification(image: Image) {
        let url = URL(string: image.thumbnailLink!)
        self.uploadedUIImageView.kf.indicatorType = .activity
        self.uploadedUIImageView.kf.setImage(with: url, options: [.forceTransition])
        self.uploadedWrapper.hideWithAnimation(isHidden: false)
        
        // Do not hide if there is no image in feed.
        if images.count != 0 {
            ComponentUtil.runThisAfter(second: 5, execute: {
                self.uploadedWrapper.hideWithAnimation(isHidden: true)
            })
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.FeedItemTableViewCell.rawValue, for: indexPath) as! FeedItemTableViewCell
        let image = images[indexPath.row]
        let feedItem: FeedItem = cell.feedItem
        let profileImageUrl = URL(string: image.owner.profilePictureLink)
        feedItem.ownerProfileImageView.kf.setImage(with: profileImageUrl, options: [.transition(.fade(0.5))])
        
        feedItem.ownerNameLabel.text = image.owner.name
        
        let imageUrl = URL(string: image.thumbnailLink!)
        feedItem.imageView.kf.indicatorType = .activity
        feedItem.imageView.kf.setImage(with: imageUrl, options: [.transition(.fade(0.5))], completionHandler: {
            (downloadedImage, error, cacheType, imageUrl) in
            // Show the original image from cache only
            ImageCache.default.retrieveImage(forKey: image.link!, options: nil) {
                (image, cacheType) in
                if let image = image {
                    feedItem.imageView.image = image
                }
            }
        })
        
        // Used for animation between this and PhotoInfoViewController
        feedItem.imageView.hero.id = image.thumbnailLink!
        
        feedItem.numberOfLikeLabel.text = "\(image.likes!)"
        
        addTapGesture(for: feedItem.imageView, with: #selector(showFullPhoto(sender:)))
        
        // Tag like button with row number. use "tag" to get specific image in like()
        feedItem.likeButton.tag = indexPath.row
        feedItem.likeButton.setImage(UIImage(named: image.is_liked ? "Red heart": "Gray Heart"), for: .normal)
        
        feedItem.likeButton.addTarget(self, action: #selector(likeImage(sender:)), for: .touchUpInside)
        return cell
    }
}

extension ExploreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        heightForIndexPath[indexPath] = cell.frame.height
        let lastElement = images.count - 1
        if indexPath.row == lastElement, shouldFetchMore {
            page += 1
            fetchImagesFromAPI(page: page, at: currentFeedLocation!) {
                images in
                self.images += images
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForIndexPath[indexPath] ?? averageRowHeight
    }
}

extension ExploreViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        if lastContentOffset - yOffset > 100, shouldUpdateHeaderVisibility {
            // going up
            showHeader(isShow: true)
            showFilter(isHidden: false)
            shouldUpdateHeaderVisibility = false
        } else if lastContentOffset - yOffset < -100, shouldUpdateHeaderVisibility {
            // going down
            showHeader(isShow: false)
            showFilter(isHidden: true)
            shouldUpdateHeaderVisibility = false
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        shouldUpdateHeaderVisibility = true
    }
}
// MARK: - PhotoUploadingDelegate

extension ExploreViewController: PhotoUploadingDelegate {
    
    func didUpload(image: Image) {
        progressViewWrapper.hideWithAnimation(isHidden: true)
        UserDefaults.standard.removeObject(forKey: "uploadPhotoInfo")
        fetchInitImageFromAPI()
        progressView.progress = 0
        self.showUploadedNotification(image: image)
        self.uploadedImage = image
        print("didUpload")
    }
    
    func uploading(completedUnit: Double, totalUnit: Double) {
        UIView.animate(withDuration: 3, delay: 0.0, options: .curveLinear, animations: {
            self.progressView.setProgress(Float(completedUnit/totalUnit), animated: true)
        }, completion: nil)
        print("uploading \(completedUnit)/\(totalUnit)")
    }
    
    func willUpload() {
        progressView.progress = 0
        progressViewWrapper.hideWithAnimation(isHidden: false)
        print("willUpload")
    }
    
    func cancelledUpload() {
        progressViewWrapper.hideWithAnimation(isHidden: true)
        print("Upload has been cancelled")
    }
    
    func onError(error: NSError) {
//        let message = error.userInfo["message"] as? String ?? "Upload error"
//        self.showAlertDialog(title: "Error", message: message)
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

extension ExploreViewController: ExploreMapViewControllerDelegate {
    func didUpdateLocationName(locationName: String) {
        headerLabel.text = locationName
    }
    
    func didMapChangeLocation(location: Location, locationName: String?) {
        if locationName != nil {
            headerLabel.text = locationName
        } else {
            headerLabel.text = ""
        }
        currentFeedLocation = location
        images = []
        tableView.reloadData()
        startActivityIndicator()
        fetchInitImageFromAPI()
    }
    
}

extension ExploreViewController: FilterViewControllerDelegate {
    func didFilterCreate(season: Season?, partOfDay: PartOfDay?) {
        self.filterSeason = season
        self.filterPartOfDay = partOfDay
        
        if season != nil || partOfDay != nil {
            self.filterWrapper.hideWithAnimation(isHidden: false)
            self.fetchInitImageFromAPI()
        }
    }
}

