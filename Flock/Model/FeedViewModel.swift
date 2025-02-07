//
//  PrayerRequestViewModel.swift
//  Prayer Calendar
//
//  Created by Matt Lam on 4/15/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore

@Observable final class FeedViewModel {
    var prayerRequests: [Post] = []
    var lastDocument: DocumentSnapshot? = nil
    var selectedStatus: statusFilter = .current
    var person: Person = Person()
    var scrollViewID = UUID()
    var progressStatus: Bool = false
    var refresh: Bool = false
    var viewState: ViewState?
    var queryCount: Int = 0
    var profileOrFeed: String = ""
    
    var feedService = FeedService()
    
    init(profileOrFeed: String = "") {
        self.profileOrFeed = profileOrFeed
    }
    
    var isLoading: Bool {
        viewState == .loading
    }
    
    var isFetching: Bool {
        viewState == .fetching
    }
    
    var isFinished: Bool {
        viewState == .finished
    }
    
    enum statusFilter: String, CaseIterable {
        case answered = "answered"
        case current = "current"
        case noLongerNeeded = "no longer needed"
        case pinned = "pinned"
        case none
        
        var statusKey: String {
            return self.rawValue.description
        }
    }
    
    func statusFilter(option: statusFilter, user: Person, person: Person, profileOrFeed: String) async throws {
//        self.selectedStatus = option
        self.lastDocument = nil
        self.prayerRequests = []
        await self.getPrayerRequests(user: user, person: person)
    }
    
    func getPrayerRequests(user: Person, person: Person) async {
        do {
            viewState = .loading
            defer { viewState = .finished }
            
            let (newPrayerRequests, lastDocument) = try await feedService.getPostFeed(user: user, person: person, answeredFilter: selectedStatus.statusKey, count: 10, lastDocument: nil, profileOrFeed: profileOrFeed)
            
            self.prayerRequests = newPrayerRequests
            self.queryCount = newPrayerRequests.count
            
            if lastDocument != nil {
                self.lastDocument = lastDocument
            }
            
            print("last document: " + String(lastDocument?.documentID ?? ""))
        } catch {
            print(error)
        }
    }
    
    func getNextPrayerRequests(user: Person, person: Person, profileOrFeed: String) async {
        
        guard queryCount == 10 else { return }
            
        viewState = .fetching
        defer { viewState = .finished }
        
        do {
            let (newPrayerRequests, lastDocument) = try await feedService.getPostFeed(user: user, person: person, answeredFilter: selectedStatus.statusKey, count: 10, lastDocument: lastDocument, profileOrFeed: profileOrFeed)
            
            self.queryCount = newPrayerRequests.count
            self.prayerRequests.append(contentsOf: newPrayerRequests)
            
            if lastDocument != nil {
                self.lastDocument = lastDocument
            }
            
            print("last document: " + String(lastDocument?.documentID ?? ""))

        } catch {
            print(error.localizedDescription)
        }
    }
    
    func hasReachedEnd(of prayerRequest: Post) -> Bool {
        prayerRequests.last?.id == prayerRequest.id
    }
}

extension FeedViewModel {
    enum ViewState {
        case fetching
        case loading
        case finished
    }
}
