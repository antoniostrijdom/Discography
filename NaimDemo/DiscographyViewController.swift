//
//  DiscographyViewController.swift
//  NaimDemo
//
//  Created by Antonio Strijdom on 21/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import UIKit

/// View controller for presenting an artists' discography
class DiscographyViewController: UIViewController {

    // MARK: - Private
    
    // reuse ids
    fileprivate let headerReuseID = "Header"
    fileprivate let footerReuseID = "Footer"
    fileprivate let cellReuseID = "Cell"
    
    /// the artist's album list
    fileprivate var albums: [Album]? = nil

    // outlets
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    /// the user's home store
    public var homeStore: String? = nil
    /// the artist we are displaying albums for
    public var artist: Artist? = nil
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // register views
        collectionView.register(TimelineHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: headerReuseID)
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                                withReuseIdentifier: footerReuseID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // initialise
        self.artistLabel.text = nil
        self.albums = nil
        
        // if an artist is set
        if let artistDetails = artist {
            // display details
            self.artistLabel.text = artistDetails.name
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // if an artist and home store is set
        if let artistDetails = artist, let store = homeStore {
            // kick off retrieving album information
            activityIndicator.startAnimating()
            let controller = ArtistController()
            controller.GetAlbums(forArtist: artistDetails,
                                 inStore: store,
                                 completionHandler: { (artistAlbums, error) in
                                    // update album information
                                    self.albums = artistAlbums
                                    // and display them
                                    self.collectionView.reloadData()
                                    // stop the spinner
                                    self.activityIndicator.stopAnimating()
            })
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.collectionView.setNeedsLayout()
//        self.collectionView.reloadData()
    }

}

// MARK: - UICollectionViewDataSource

extension DiscographyViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // display the album
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseID, for: indexPath)
        
        if let albumCell = cell as? AlbumCollectionViewCell, let album = self.albums?[indexPath.section] {
            // just show the artwork for now
            albumCell.artworkImageView.image = album.artwork
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // display the year
        // note that this is only displayed when the year changes
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: kind == UICollectionElementKindSectionHeader ? headerReuseID : footerReuseID,
                                                                   for: indexPath)
        if let headerView = view as? TimelineHeaderReusableView {
            // get the release year of the album
            if let releaseDate = self.albums?[indexPath.section].releaseDate {
                let releaseYear = Calendar.current.component(.year, from: releaseDate)
                headerView.headerLabel.text = "\(releaseYear)"
            }
        }
        return view
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let albums = self.albums {
            return albums.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
}

// MARK: - UICollectionViewDelegate

extension DiscographyViewController: UICollectionViewDelegate {
    
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DiscographyViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // get the layout
        let timelineLayout = collectionViewLayout as? TimelineFlowLayout
        // should always be a TimelineFlowLayout, but just in case
        guard timelineLayout != nil else {
            return UIEdgeInsets.zero
        }
        // only display alternating rows if we have space
        if self.traitCollection.verticalSizeClass == .regular {
            // alternate top/bottom
            let heightInset = collectionView.frame.size.height - timelineLayout!.cellHeight
            // even rows on bottom, odd rows on top
            if section % 2 == 0 {
                return UIEdgeInsets(top: heightInset,
                                    left: 0.0,
                                    bottom: 0.0,
                                    right: 0.0)
            } else {
                return UIEdgeInsets(top: 0.0,
                                    left: 0.0,
                                    bottom: heightInset,
                                    right: 0.0)
            }
        } else {
            // not enough space, just display in a single line
            return UIEdgeInsets.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let flowLayout = collectionViewLayout as? TimelineFlowLayout {
            // determine if we should display section header
            if section == 0 {
                // always display the first section header
                return flowLayout.headerReferenceSize
            } else {
                // compare this release year to the previous release year
                let previousIndex = max(0, section - 1)
                if let releaseDate = self.albums?[section].releaseDate,
                    let previousReleaseDate = self.albums?[previousIndex].releaseDate {
                    let releaseYear = Calendar.current.component(.year, from: releaseDate)
                    let previousReleaseYear = Calendar.current.component(.year, from: previousReleaseDate)
                    if releaseYear != previousReleaseYear {
                        // only display header whtn the year changes
                        return flowLayout.headerReferenceSize
                    }
                }
            }
        }
        // default to not displaying the header
        return CGSize.zero
    }
}
