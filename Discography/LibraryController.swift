//
//  LibraryController.swift
//  Discography
//
//  Created by Antonio Strijdom on 18/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import Foundation
import StoreKit

// MARK: - Errors

/// LibraryController error type
///
/// - InvalidURLError: the url generated for the request is somehow invalid
/// - CommsError: could not communicate with Apple Music
/// - HTTPError: an unexpected HTTP result code was returned
/// - NoDataError: no data was returned
/// - NoTokenError: no user token could be generated
enum LibraryControllerError: Error {
    case InvalidURLError
    case CommsError
    case HTTPError
    case NoDataError
    case NoTokenError
}

// MARK: - Temporary deserialisation structs

/// generic resource result
public struct ResourceResult: Decodable {
    var data: [Resource]? = nil
}

/// generic resource
public struct Resource: Decodable {
    var id: String? = nil
    var type: String? = nil
    var href: URL? = nil
    var attributes: Dictionary<String, Any>? = nil
    var relationships: Dictionary<String, Any>? = nil
    var meta: Dictionary<String, Any>? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case href
        case attributes
        case relationships
        case meta
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        href = try container.decode(URL.self, forKey: .href)
        if let stringValue = try? container.decode(Dictionary<String, String>.self, forKey: .attributes) {
            attributes = stringValue
        } else if let arrayValue = try? container.decode(Dictionary<String, [String]>.self, forKey: .attributes) {
            attributes = arrayValue
        } else if let boolValue = try? container.decode(Dictionary<String, Bool>.self, forKey: .attributes) {
            attributes = boolValue
        } else if let intValue = try? container.decode(Dictionary<String, Int>.self, forKey: .attributes) {
            attributes = intValue
        }
        if let stringValue = try? container.decode(Dictionary<String, String>.self, forKey: .relationships) {
            relationships = stringValue
        } else if let arrayValue = try? container.decode(Dictionary<String, [String]>.self, forKey: .relationships) {
            relationships = arrayValue
        } else if let boolValue = try? container.decode(Dictionary<String, Bool>.self, forKey: .relationships) {
            relationships = boolValue
        } else if let intValue = try? container.decode(Dictionary<String, Int>.self, forKey: .relationships) {
            relationships = intValue
        }
        if let stringValue = try? container.decode(Dictionary<String, String>.self, forKey: .meta) {
            meta = stringValue
        } else if let arrayValue = try? container.decode(Dictionary<String, [String]>.self, forKey: .meta) {
            meta = arrayValue
        } else if let boolValue = try? container.decode(Dictionary<String, Bool>.self, forKey: .meta) {
            meta = boolValue
        } else if let intValue = try? container.decode(Dictionary<String, Int>.self, forKey: .meta) {
            meta = intValue
        }
    }
}

/// artist search result
public struct SearchResult: Decodable {
    var results: Results? = nil
}

/// artist results
public struct Results: Decodable {
    var artists: Artists? = nil
}

/// artists
public struct Artists: Decodable {
    var data: [ArtistData]? = nil
    var href: String? = nil
    var next: String? = nil
}

/// artist data
public struct ArtistData: Decodable {
    var id: String? = nil
    var type: String? = nil
    var href: URL? = nil
    var attributes: ArtistAttributes? = nil
    var relationships: ArtistRelationships? = nil
}

/// artist attributes
public struct ArtistAttributes: Decodable {
    var genreNames: [String]? = nil
    var name: String? = nil
    var url: URL? = nil
}

/// artist relationships
public struct ArtistRelationships: Decodable {
    var albums: ResourceResult? = nil
}

/// album search result
public struct AlbumResult: Decodable {
    var data: [AlbumData]? = nil
}

/// album data
public struct AlbumData: Decodable {
    var attributes: AlbumAttributes? = nil
    var id: String? = nil
}

/// album attributes
public struct AlbumAttributes: Decodable {
    var name: String? = nil
    var artwork: AlbumArtwork
    var releaseDate: String? = nil
}

/// album artwork
public struct AlbumArtwork: Decodable {
    var url: String? = nil
}

/// Controller class for accessing the Apple Music API
public class LibraryController
{
    /*
 
    {
        "alg": "HS256",
        "kid": "XU3627XZP4"
    }
 
    {
        "iss": "3WR52V3W6H",
        "iat": 1518957066,
        "exp": 1521376262
    }
 
    */
    fileprivate let kDeveloperToken = "((supply a developer token))"
    
    
    /// the user's token
    /// used to access user specific methods
    fileprivate lazy var userToken: String? = {[weak self] in
        if let weakSelf = self {
            return GetUserToken()
        } else {
            return nil
        }
    }()
    
    /// Synchronously sends a request to Apple Music and returns the response
    ///
    /// - Parameter request: URLRequest to send
    /// - Returns: a tuple containing the URLResponse (as an HTTPURLResponse) and the raw Data
    /** - Throws: `CommsError` - the server could not be reached.
                  `HTTPError` - an HTTP result code other than 200 was received.
                  `NoDataError` - no data was returned.
    */
    fileprivate func sendRequestSync(request: URLRequest) throws -> (HTTPURLResponse, Data) {
        var response: URLResponse? = nil
        var data: Data? = nil
        var error: Error? = nil
        // start network indicator
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        // use a semaphore to block while waiting for a response
        let semaphore = DispatchSemaphore.init(value: 0)
        // initiate the data task
        URLSession.shared.dataTask(with: request, completionHandler: { (taskData, taskResponse, taskError) in
            data = taskData
            response = taskResponse
            error = taskError
            semaphore.signal()
        }).resume()
        semaphore.wait()
        // start network indicator
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        // basic error checking
        guard nil != data else {
            throw LibraryControllerError.NoDataError
        }
        guard nil != response else {
            throw LibraryControllerError.CommsError
        }
        guard nil == error else {
            throw error!
        }
        // cast URLResponse to HTTPURLResponse
        if let httpResponse = response as? HTTPURLResponse {
            return (httpResponse, data!)
        } else {
            throw LibraryControllerError.HTTPError
        }
    }
    
    
    /// Gets the user's token from StoreKit
    ///
    /// - Returns: the user token or nil
    fileprivate func GetUserToken() -> String? {
        var userToken: String? = nil
        var tokenError: Error? = nil
        let semaphore = DispatchSemaphore.init(value: 0)
        SKCloudServiceController().requestUserToken(forDeveloperToken: kDeveloperToken) { (token, error) in
            userToken = token
            tokenError = error
            semaphore.signal()
        }
        semaphore.wait()
        guard tokenError == nil else {
            return nil
        }
        return userToken
    }
    
    /// Gets all store fronts
    ///
    /// - Returns: an array of resources
    /** - Throws: `InvalidURLError` - the url called was invalid.
                  `CommsError` - the server could not be reached.
                  `HTTPError` - an HTTP result code other than 200 was received.
                  `NoDataError` - no data was returned.
    */
    public func GetStorefronts() throws -> ResourceResult {
        // build the url
        if let url = URL(string: "https://api.music.apple.com/v1/storefronts") {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            // add the developer token header
            request.setValue("Bearer \(kDeveloperToken)", forHTTPHeaderField: "Authorization")
            // send request
            let (requestResult, data) = try sendRequestSync(request: request)
            // expecting a 200...
            if 200 == requestResult.statusCode {
                return try JSONDecoder().decode(ResourceResult.self, from: data)
            } else {
                throw LibraryControllerError.HTTPError
            }
        } else {
            throw LibraryControllerError.InvalidURLError
        }
    }
    
    
    /// Gets the user's home store
    ///
    /// - Returns: an array of resources
    /** - Throws: `InvalidURLError` - the url called was invalid.
                  `CommsError` - the server could not be reached.
                  `HTTPError` - an HTTP result code other than 200 was received.
                  `NoDataError` - no data was returned.
                  `NoTokenError` - user token could not be retrieved.
    */
    public func GetUserStoreFront() throws -> ResourceResult {
        // need a user token for this request, so get that now
        if let userToken = self.userToken {
            // build the url
            if let url = URL(string: "https://api.music.apple.com/v1/me/storefront") {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                // add the developer token header
                request.setValue("Bearer \(kDeveloperToken)", forHTTPHeaderField: "Authorization")
                // add the user token header
                request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
                // send the request
                let (requestResult, data) = try sendRequestSync(request: request)
                // expecting a 200...
                if 200 == requestResult.statusCode {
                    return try JSONDecoder().decode(ResourceResult.self, from: data)
                } else {
                    throw LibraryControllerError.HTTPError
                }
            } else {
                throw LibraryControllerError.InvalidURLError
            }
        } else {
            throw LibraryControllerError.NoTokenError
        }
    }
    
    
    /// Searches the store for the artist specified.
    ///
    /// - Parameters:
    ///   - forArtist: The artist to search for.
    ///   - storefront: The store to search.
    /// - Returns: A search result containing matches for the artist search term.
    /** - Throws: `InvalidURLError` - the url called was invalid.
                  `CommsError` - the server could not be reached.
                  `HTTPError` - an HTTP result code other than 200 was received.
                  `NoDataError` - no data was returned.
    */
    public func SearchStore(forArtist: String, inStore storefront: String) throws -> SearchResult {
        // format the search term by replacing spaces with '+'
        let searchTerm = forArtist.replacingOccurrences(of: " ", with: "+")
        // build the url
        let urlString =
            "https://api.music.apple.com/v1/catalog/\(storefront)/search" +
            "?term=\(searchTerm)&limit=25&types=artists"
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            // add the developer token header
            request.setValue("Bearer \(kDeveloperToken)", forHTTPHeaderField: "Authorization")
            // send the request
            let (requestResult, data) = try sendRequestSync(request: request)
            // expecting a 200...
            if 200 == requestResult.statusCode {
                return try JSONDecoder().decode(SearchResult.self, from: data)
            } else {
                throw LibraryControllerError.HTTPError
            }
        } else {
            throw LibraryControllerError.InvalidURLError
        }
    }
    
    /// Gets artist details for an id
    ///
    /// - Parameters:
    ///   - id: artist id to retrieve data for
    ///   - storefront: the store to search
    /// - Returns: Artist information (only one is returned)
    /** - Throws: `InvalidURLError` - the url called was invalid.
                  `CommsError` - the server could not be reached.
                  `HTTPError` - an HTTP result code other than 200 was received.
                  `NoDataError` - no data was returned.
     */
    public func GetArtist(withId id: String, inStore storefront: String) throws -> Artists {
        // build the url
        let urlString =
            "https://api.music.apple.com/v1/catalog/\(storefront)/artists/\(id)"
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            // add the developer token header
            request.setValue("Bearer \(kDeveloperToken)", forHTTPHeaderField: "Authorization")
            // send the request
            let (requestResult, data) = try sendRequestSync(request: request)
            // expecting a 200...
            if 200 == requestResult.statusCode {
                return try JSONDecoder().decode(Artists.self, from: data)
            } else {
                throw LibraryControllerError.HTTPError
            }
        } else {
            throw LibraryControllerError.InvalidURLError
        }
    }
    
    
    /// Gets album information for a list of ids
    ///
    /// - Parameters:
    ///   - albumIds: an array of album ids
    ///   - storefront: the store to search
    /// - Returns: Album details
    /** - Throws: `InvalidURLError` - the url called was invalid.
                  `CommsError` - the server could not be reached.
                  `HTTPError` - an HTTP result code other than 200 was received.
                  `NoDataError` - no data was returned.
     */
    public func GetAlbums(withIds albumIds: [String], inStore storefront: String) throws -> AlbumResult {
        // build the album id list
        let ids = albumIds.reduce("") { (result, album) -> String in
            return album + "," + result
        }
        // build the url
        let urlString =
        "https://api.music.apple.com/v1/catalog/\(storefront)/albums?ids=\(ids.dropLast())"
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            // add the developer token header
            request.setValue("Bearer \(kDeveloperToken)", forHTTPHeaderField: "Authorization")
            // send the request
            let (requestResult, data) = try sendRequestSync(request: request)
            // expecting a 200...
            if 200 == requestResult.statusCode {
                return try JSONDecoder().decode(AlbumResult.self, from: data)
            } else {
                throw LibraryControllerError.HTTPError
            }
        } else {
            throw LibraryControllerError.InvalidURLError
        }
    }
}
