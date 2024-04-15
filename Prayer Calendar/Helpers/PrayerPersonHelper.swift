//
//  PrayerNameHelper.swift
//  Prayer Calendar
//
//  Created by Matt Lam on 11/23/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum PrayerPersonRetrievalError: Error {
    case noUsername
    case incorrectUsername
    case errorRetrievingFromFirebase
}

class PrayerPersonHelper {
    
//    This function retrieves PrayerList data from Firestore.
    func getPrayerList(userHolder: UserProfileHolder, prayerListHolder: PrayerListHolder) async {
            let ref = Firestore.firestore()
            .collection("users").document(userHolder.person.userID)
            
            ref.getDocument{(document, error) in
                if let document = document, document.exists {
                    
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                    print("Document data: " + dataDescription)
                    
                    //Update Dataholder with PrayStartDate from Firestore
                    let startDateTimeStamp = document.get("prayStartDate") as? Timestamp ?? Timestamp(date: Date())
                    prayerListHolder.prayStartDate = startDateTimeStamp.dateValue()
                        
                    //Update Dataholder with PrayerList from Firestore
                    prayerListHolder.prayerList = document.get("prayerList") as? String ?? ""
                    
                } else {
                    print("Document does not exist")
                    prayerListHolder.prayerList = ""
                }
            }
    }

    // The following function returns an array of PrayerPerson's so that the view can grab both the username or name.
    func retrievePrayerPersonArray(prayerList: String) -> [Person] {
        let ref = prayerList.components(separatedBy: "\n")
        var prayerArray: [Person] = []
        var firstName = ""
        var lastName = ""
        var username = ""
        
        for person in ref {
            let array = person.split(separator: ";", omittingEmptySubsequences: true) // Separate name from username
            
            if array.count == 1 {
                username = "" // If the array is only 1, assume that there was no username entered.
            } else {
                username = String(array.last ?? "").trimmingCharacters(in: .whitespaces).lowercased()
            }
            
            let nameArray = array.first?.split(separator: " ", omittingEmptySubsequences: true) // Separate First name from Last. If there is middle name, last name will only grab last of array.
            
            // nameArray?.count == 1 ensures that if user enters only first name, last name will be "", not first name.
            if nameArray?.count == 1 {
                firstName = String(nameArray?.first ?? "").trimmingCharacters(in: .whitespaces)
                lastName = ""
            } else {
                firstName = String(nameArray?.first ?? "").trimmingCharacters(in: .whitespaces)
                lastName = String(nameArray?.last ?? "").trimmingCharacters(in: .whitespaces)
            }
            
            let prayerPerson = Person(username: username, firstName: firstName, lastName: lastName)
            prayerArray.append(prayerPerson)
        }
        
        return prayerArray
    }
    
    // Retrieve requested userID off of username
    func retrieveUserInfoFromUsername(person: Person, userHolder: UserProfileHolder) async throws -> Person {
        var userID = ""
        var firstName = person.firstName
        var lastName = person.lastName
        
        if person.username == "" {
            userID = userHolder.person.userID
        } else {
            do {
                let db = Firestore.firestore()
                
                let ref = try await db.collection("users").whereField("username", isEqualTo: person.username).getDocuments()
                
                for document in ref.documents {
                    //                    print("\(document.documentID) => \(document.data())")
                    if document.exists {
                        let dataDescription = document.data()
                        print("Document data: \(dataDescription)")
                        
                        userID = document.get("userID") as? String ?? ""
                        firstName = document.get("firstName") as? String ?? ""
                        lastName = document.get("lastName") as? String ?? ""
                    } else {
                        throw PrayerPersonRetrievalError.noUsername
                    }
                }
            } catch {
                    print("Error getting document: \(error)")
            }
        }
        print("username: \(person.username); userID: \(userID); firstName: \(firstName); lastName: \(lastName)")
        return Person(userID: userID, username: person.username, firstName: firstName, lastName: lastName)
    }
    
    func checkIfUsernameExists(username: String) async -> Bool {
        var check = Bool()
        
        let db = Firestore.firestore()
        
        do {
            let ref = try await db.collection("users").whereField("username", isEqualTo: username).getDocuments()
            
            if ref.isEmpty {
                check = false
            } else {
                check = true
            }
        } catch {
            print("Error retrieving username ref")
            check = false
        }
        
        return check
    }
    
    func updateUserData(userID: String, prayStartDate: Date, prayerList: String) {
        //Create user data in personal doc.
        let db = Firestore.firestore()
        
        let ref = db.collection("users").document(userID)
        
        ref.updateData([
            "userID": userID,
            "prayStartDate": prayStartDate,
            "prayerList": prayerList
        ])
    }
    
    //Adding a friend - this updates the historical prayer feed
    func updateFriendHistoricalPrayersIntoFeed(userID: String, person: Person) async throws {
        //In this scenario, userID is the userID of the person retrieving data from the 'person'.
        do {
            //user is retrieving prayer requests of the friend: person.userID and person: person.
            let prayerRequests = try await PrayerRequestHelper().getPrayerRequests(userID: person.userID, person: person)
            
            //for each prayer request, user is taking the friend's prayer request and updating them to their own feed. The user becomes the 'friend' of the person.
            for prayer in prayerRequests {
                PrayerRequestHelper().updatePrayerFeed(prayerRequest: prayer, person: person, friendID: userID, updateFriend: true)
                print(prayer.id)
            }
        } catch {
            throw PrayerPersonRetrievalError.errorRetrievingFromFirebase
        }
    }
    
    func deletePerson(userID: String, friendsList: [String]) async throws {
        let db = Firestore.firestore()
        
        do {
            // delete from prayer requests list.
            let prayerRequests = try await db.collection("prayerRequests").whereField("userID", isEqualTo: userID).getDocuments()
            
            for request in prayerRequests.documents {
                try await request.reference.delete()
            }
           
            // delete prayerFeed
            let prayerFeedUser = db.collection("prayerFeed").document(userID)
            try await prayerFeedUser.delete()
            
            let prayerFeedRef = try await db.collection("prayerFeed").document(userID).collection("friendsList").getDocuments()
            for request in prayerFeedRef.documents {
                try await request.reference.delete()
            }
            
            let prayerFeedRef2 = try await db.collection("prayerFeed").document(userID).collection("prayerList").getDocuments()
            for request in prayerFeedRef2.documents {
                try await request.reference.delete()
            }
            
            // delete from friend's feed
            if friendsList.isEmpty == false {
                for friendID in friendsList {
                    let prayerRequests = try await db.collection("prayerFeed").document(friendID).collection("prayerRequests").whereField("userID", isEqualTo: userID).getDocuments()
                    
                    for request in prayerRequests.documents {
                        try await request.reference.delete()
                    }
                }
            }
            
            // delete users info data.
            let ref = db.collection("users").document(userID)
            try await ref.delete()
            
            let userFriendsListRef = try await db.collection("users").document(userID).collection("friendsList").getDocuments()
            for request in userFriendsListRef.documents {
                try await request.reference.delete()
            }
            
            let userPrayerListRef = try await db.collection("users").document(userID).collection("prayerList").getDocuments()
            for request in userPrayerListRef.documents {
                try await request.reference.delete()
            }
            
            // remove firebase account
            try await Auth.auth().currentUser?.delete()
            
        } catch {
            throw error
        }
    }
}
