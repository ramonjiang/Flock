//
//  PrayerRequestHelper.swift
//  Prayer Calendar
//
//  Created by Matt Lam on 11/19/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFunctions

enum PrayerRequestRetrievalError: Error {
    case noUserID
    case noPrayerRequestID
    case noPrayerRequest
    case errorRetrievingFromFirebase
}

class PostHelper {
    let db = Firestore.firestore()

    func togglePinned(person: Person, post: Post, toggle: Bool) {
        let ref = db.collection("prayerFeed").document(person.userID).collection("prayerRequests").document(post.id)
        ref.updateData([
            "isPinned": toggle
        ])
        
        if person.userID == post.userID {
            let ref2 = db.collection("users").document(person.userID).collection("prayerList").document("\(person.firstName.lowercased())_\(person.lastName.lowercased())").collection("prayerRequests").document(post.id)
            ref2.updateData([
                "isPinned": toggle
            ])
        } // update data to personal profile feed if this is under your profile as well.
    }
}
