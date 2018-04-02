//
//  ViewController.swift
//  Discography
//
//  Created by Antonio Strijdom on 18/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import UIKit
import StoreKit

/// View controller for searching for artists
class ViewController: UITableViewController {
    
    /// view controller for setting up Apple Music
    var setupViewController: SKCloudServiceSetupViewController! = nil
    /// the user's home store
    var store: String? = nil
    /// the current list of artists
    var artists: [Artist]? = nil
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController = SKCloudServiceSetupViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // get authorization status
        SKCloudServiceController.requestAuthorization { (status) in
            if status == .authorized {
                // make sure the user is subscribed to Apple Music
                SKCloudServiceController().requestCapabilities(completionHandler: { (capabilities, error) in
                    if error == nil {
                        if capabilities.contains(.musicCatalogSubscriptionEligible) &&
                            !capabilities.contains(.musicCatalogPlayback) {
                            // not subscribed, present setup
                            DispatchQueue.main.async {
                                self.setupViewController.modalPresentationStyle = .overCurrentContext
                                self.setupViewController.modalTransitionStyle = .coverVertical
                                self.setupViewController.load(options: [SKCloudServiceSetupOptionsKey.action: SKCloudServiceSetupAction.subscribe], completionHandler: { (result, error) in
                                    if result {
                                        self.present(self.setupViewController, animated: true, completion: nil)
                                    }
                                })
                            }
                        } else {
                            // subscribed already, just get user token
                            if let result = try? LibraryController().GetUserStoreFront() {
                                self.store = result.data?.first?.id
                                print("Your home store is \(self.store ?? "UNKNOWN")")
                            }
                        }
                    }
                })
            }
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        // configure the cell with artist information
        if let artist = artists?[indexPath.row], let artistCell = cell as? ArtistCell {
            configureCell(artistCell, withArtist:artist)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    /// Configure the cell with artist information
    ///
    /// - Parameters:
    ///   - cell: the cell to update
    ///   - artist: the artist information to display in this cell
    func configureCell(_ cell: ArtistCell, withArtist artist: Artist) {
        cell.nameLabel!.text = artist.name
        // indicate to the user that they can tap this row
        cell.accessoryType = .disclosureIndicator
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // only one segue right now
        if let indexPath = tableView.indexPathForSelectedRow {
            // get the selected artist information
            if let artist = artists?[indexPath.row] {
                // make sure this artist is presented
                if let vc = segue.destination as? DiscographyViewController {
                    vc.homeStore = self.store
                    vc.artist = artist
                }
            }
            // deselect the current artist
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }

}


// MARK: - UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchBar.text = ""
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        artists = nil
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // if an artist has been entered and we have a home store
        if let searchText = searchBar.text, let store = self.store {
            // kick off the search
            ArtistController().SearchForArtists(searchTerm: searchText, inStore: store,
                                                completionHandler: { [weak self] (searchArtists, error) in
                if let weakSelf = self {
                    // update the view controller with the results
                    weakSelf.artists = searchArtists
                    weakSelf.tableView.reloadData()
                }
            })
        }
    }
}

