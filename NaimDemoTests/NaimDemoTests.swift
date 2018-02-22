//
//  NaimDemoTests.swift
//  NaimDemoTests
//
//  Created by Antonio Strijdom on 18/02/2018.
//  Copyright © 2018 Antonio Strijdom. All rights reserved.
//

import XCTest
@testable import NaimDemo

class NaimDemoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testStoreFronts() {
        let controller = LibraryController()
        XCTAssertNoThrow(try controller.GetStorefronts())
    }
    
//    func testUserStoreFront() {
//        let controller = LibraryController()
//        XCTAssertNoThrow(try controller.GetUserStoreFront())
//    }
    
    func testArtistSearch() {
//        let controller = ArtistController()
//        var artists: [Artist]? = nil
//        let semaphore = DispatchSemaphore.init(value: 0)
//        controller.SearchForArtists(searchTerm: "Queen", inStore: "gb") { (searchArtists, _) in
//            artists = searchArtists
//            semaphore.signal()
//        }
//        semaphore.wait()
//        XCTAssert(artists?.count ?? 0 > 0, "No artists returned")
    }
    
    func testArtistDetails() {
        let controller = LibraryController()
        XCTAssertNoThrow(try controller.GetArtist(withId: "3296287", inStore: "gb"))
    }
    
    func testAlbumDetails() {
        let controller = LibraryController()
        XCTAssertNoThrow(try controller.GetAlbums(withIds: ["1288307220", "1288311991"], inStore: "gb"))
    }
}
