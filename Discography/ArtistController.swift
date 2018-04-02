//
//  ArtistController.swift
//  Discography
//
//  Created by Antonio Strijdom on 20/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import Foundation
import UIKit


/// Artist model object
public struct Artist {
    var id: String
    var name: String
    var url: URL?
    
    init(fromData artistData: ArtistData) {
        id = artistData.id ?? ""
        name = artistData.attributes?.name ?? ""
        url = artistData.href
    }
}

/// Album model object
public struct Album {
    var id: String
    var name: String
    var releaseDate: Date
    var artwork: UIImage
}


/// Controller class for retrieving artist information from LibraryController
public class ArtistController {
    
    
    /// Search for artists
    ///
    /// - Parameters:
    ///   - searchTerm: artist search term
    ///   - store: the home store
    ///   - complete: block executed when artist information arrives
    func SearchForArtists(searchTerm: String, inStore store: String,
                          completionHandler complete: (([Artist]?, Error?) -> Void)?) {
        guard complete != nil else {
            return
        }
        // call library controller on a background queue
        DispatchQueue.global().async {
            let libraryController = LibraryController()
            var searchResult: SearchResult? = nil
            do {
                // search store for artist information
                searchResult = try libraryController.SearchStore(forArtist: searchTerm,
                                                                 inStore: store)
                if let searchData = searchResult!.results?.artists?.data {
                    // transform
                    let artists = searchData.map({ (data) -> Artist in
                        return Artist(fromData: data)
                    })
                    // call back on the main queue
                    DispatchQueue.main.async {
                        complete!(artists, nil)
                    }
                }
            } catch let searchError {
                DispatchQueue.main.async {
                    complete!(nil, searchError)
                }
            }
        }
    }
    
    
    /// Gets the albums in the artist's catalog
    ///
    /// - Parameters:
    ///   - forArtist: artist to retreive albums for
    ///   - store: the home store
    ///   - complete: block executed when album information arrives
    func GetAlbums(forArtist: Artist, inStore store: String,
                   completionHandler complete: (([Album]?, Error?) -> Void)?) {
        guard complete != nil else {
            return
        }
        // call library controller on a background queue
        DispatchQueue.global().async {
            let libraryController = LibraryController()
            var details: Artists? = nil
            do {
                // get extended artist information (includes albums)
                details = try libraryController.GetArtist(withId: forArtist.id, inStore: store)
                if let albumData = details!.data?.first?.relationships?.albums?.data {
                    // transform
                    let albumIds = albumData.map({ (album) -> String in
                        return album.id ?? ""
                    })
                    // get album information for artist albums
                    let albumResults = try libraryController.GetAlbums(withIds: albumIds, inStore: store)
                    // transform
                    var albums: [Album] = albumResults.data!.map({ (resource) -> Album in
                        let id = resource.id ?? ""
                        var name = ""
                        var date = Date()
                        var image = UIImage()
                        if let attributes = resource.attributes {
                            name = attributes.name ?? ""
                            if let dateString = attributes.releaseDate {
                                date = DateFormatter().date(from: dateString) ?? Date()
                            }
                            // get the album artwork
                            // should probably do this separately from a prefetch datasource
                            if var urlString = attributes.artwork.url {
                                urlString = urlString.replacingOccurrences(of: "{w}", with: "200")
                                urlString = urlString.replacingOccurrences(of: "{h}", with: "200")
                                if let url = URL(string: urlString) {
                                    do {
                                        let data = try Data(contentsOf: url)
                                        image = UIImage(data: data) ?? UIImage()
                                    } catch _ {
                                        
                                    }
                                }
                            }
                        }
                        return Album(id: id,
                                     name: name,
                                     releaseDate: date,
                                     artwork: image)

                    })
                    // finally, sort the albums by release date
                    albums = albums.sorted(by: { (album1, album2) -> Bool in
                        let year1 = Calendar.current.component(.year, from: album1.releaseDate)
                        let year2 = Calendar.current.component(.year, from: album2.releaseDate)
                        return year2 > year1
                    })
                    // call back on the main queue
                    DispatchQueue.main.async {
                        complete!(albums, nil)
                    }
                }
            } catch let searchError {
                DispatchQueue.main.async {
                    complete!(nil, searchError)
                }
            }
        }
    }
}
