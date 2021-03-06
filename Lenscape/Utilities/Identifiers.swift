//
//  Identifiers.swift
//  Lenscape
//
//  Created by TAWEERAT CHAIMAN on 10/3/2561 BE.
//  Copyright © 2561 Lenscape. All rights reserved.
//

import Foundation

enum Identifier: String {
    case SigninViewController = "SigninViewController"
    case MainTabBarController = "MainTabBarController"
    case ExploreMapViewController = "ExploreMapViewController"
    case ExploreViewController = "ExploreViewController"
    case PhotoPostViewController = "PhotoPostViewController"
    case OpenCameraViewController = "OpenCameraViewController"
    case OpenCameraViewControllerModal = "OpenCameraViewControllerModal"
    case ImageCollectionViewCell = "ImageCollectionViewCell"
    case ExploreHeaderTableViewCell = "ExploreHeaderTableViewCell"
    case PhotoInfoViewController = "PhotoInfoViewController"
    case FullImageViewController = "FullImageViewController"
    case TrendCollectionReusableView = "TrendCollectionReusableView"
    case SettingsViewController = "SettingsViewController"
    case SettingsNavigationController = "SettingsNavigationController"
    case PhotoPreviewViewController = "PhotoPreviewViewController"
    case FeedItemTableViewCell = "FeedItemTableViewCell"
    case GooglePlacesAutoCompleteViewController = "GooglePlacesAutoCompleteViewController"
    case SearchItemTableViewCell = "SearchItemTableViewCell"
    case AddNewPlaceTableViewCell = "AddNewPlaceTableViewCell"
    case AddNewPlaceViewController = "AddNewPlaceViewController"
    case PlaceViewController = "PlaceViewController"
    case PlaceListViewController = "PlaceListViewController"
    case PlaceVCFeedItemTableViewCell = "PlaceVCFeedItemTableViewCell"
    case ListTableViewCell = "ListTableViewCell"
    case ListTableViewController = "ListTableViewController"
    case MyPlacesViewController = "MyPlacesViewController"
    case MyPlaceTableViewCell = "MyPlaceTableViewCell"
    case MyPlaceSeeMoreCollectionViewCell = "MyPlaceSeeMoreCollectionViewCell"
    case PhotoGridViewController = "PhotoGridViewController"
    case FilterViewController = "FilterViewController"
}

enum SegueIdentifier: String {
    case UnwindToGooglePlacesAutoCompleteAndDismiss = "unwindToGooglePlacesAutoCompleteAndDismiss"
    case UnwindToCameraAndDismiss = "unwindToCameraAndDismiss"
}
