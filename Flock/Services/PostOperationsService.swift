// Handles essential post CRUD operations

import Foundation
import FirebaseFirestore

class PostOperationsService {
    private let db = Firestore.firestore()

    //Retrieve prayer requests from Firestore
    func getPosts(userID: String, person: Person, status: String?, fetchOnlyPublic: Bool) async throws -> [Post] {
        var prayerRequests = [Post]()
        
        guard userID != "" else {
            throw PrayerRequestRetrievalError.noUserID
        }
        
        var profiles: Query
        
        do {
            if fetchOnlyPublic {
                profiles = db.collection("users").document(userID).collection("prayerList").document("\(person.firstName.lowercased())_\(person.lastName.lowercased())").collection("prayerRequests")
                    .whereField("status", isEqualTo: status!)
                    .whereField("privacy", isEqualTo: "public")
                    .order(by: "latestUpdateDatePosted", descending: true)
            } else {
                if status == "isPinned" {
                    profiles = db.collection("users").document(userID).collection("prayerList").document("\(person.firstName.lowercased())_\(person.lastName.lowercased())").collection("prayerRequests").whereField("isPinned", isEqualTo: true).order(by: "latestUpdateDatePosted", descending: true)
                } else if status != nil { // if a status is passed, retrieve prayer list with status filtered.
                    profiles = db.collection("users").document(userID).collection("prayerList").document("\(person.firstName.lowercased())_\(person.lastName.lowercased())").collection("prayerRequests").whereField("status", isEqualTo: status!).order(by: "latestUpdateDatePosted", descending: true)
                } else { // if a status is not passed, retrieve all prayers.
                    profiles = db.collection("users").document(userID).collection("prayerList").document("\(person.firstName.lowercased())_\(person.lastName.lowercased())").collection("prayerRequests").order(by: "latestUpdateDatePosted", descending: true)
                }
            }
            
            let querySnapshot = try await profiles.getDocuments()
            
            for document in querySnapshot.documents {
                let timestamp = document.data()["datePosted"] as? Timestamp ?? Timestamp()
                let datePosted = timestamp.dateValue()
                
                let latestTimestamp = document.data()["latestUpdateDatePosted"] as? Timestamp ?? Timestamp()
                let latestUpdateDatePosted = latestTimestamp.dateValue()
                
                let firstName = document.data()["firstName"] as? String ?? ""
                let lastName = document.data()["lastName"] as? String ?? ""
                let postTitle = document.data()["prayerRequestTitle"] as? String ?? ""
                let postText = document.data()["prayerRequestText"] as? String ?? ""
                let postType = document.data()["postType"] as? String ?? ""
                let status = document.data()["status"] as? String ?? ""
                let userID = document.data()["userID"] as? String ?? ""
                let username = document.data()["username"] as? String ?? ""
                let privacy = document.data()["privacy"] as? String ?? "private"
                let isPinned = document.data()["isPinned"] as? Bool ?? false
                let documentID = document.documentID as String
                let latestUpdateText = document.data()["latestUpdateText"] as? String ?? ""
                let latestUpdateType = document.data()["latestUpdateType"] as? String ?? ""
                
                let prayerRequest = Post(id: documentID, 
                                         date: datePosted,
                                         userID: userID,
                                         username: username,
                                         firstName: firstName,
                                         lastName: lastName,
                                         postTitle: postTitle,
                                         postText: postText,
                                         postType: postType,
                                         status: status,
                                         latestUpdateText: latestUpdateText,
                                         latestUpdateDatePosted: latestUpdateDatePosted,
                                         latestUpdateType: latestUpdateType,
                                         privacy: privacy,
                                         isPinned: isPinned)
                
                prayerRequests.append(prayerRequest)
            }
        } catch {
            print("Error getting documents: \(error)")
        }
        return prayerRequests
    }

    func getPost(prayerRequest: Post) async throws -> Post {
        guard prayerRequest.id != "" else {
            throw PrayerRequestRetrievalError.noPrayerRequestID
        }
        
        let ref = db.collection("prayerRequests").document(prayerRequest.id)
        let isPinned = prayerRequest.isPinned // Need to save separately because isPinned is not stored in larger 'prayer requests' collection. Only within a user's feed.
        var prayerRequest = Post.blank
        
        do {
            let document = try await ref.getDocument()
            
            guard document.exists else {
                throw PrayerRequestRetrievalError.noPrayerRequest
            }

            if document.exists {
                let timestamp = document.data()?["datePosted"] as? Timestamp ?? Timestamp()
                let datePosted = timestamp.dateValue()
                
                let latestTimestamp = document.data()?["latestUpdateDatePosted"] as? Timestamp ?? Timestamp()
                let latestUpdateDatePosted = latestTimestamp.dateValue()
                
                let firstName = document.data()?["firstName"] as? String ?? ""
                let lastName = document.data()?["lastName"] as? String ?? ""
                let postTitle = document.data()?["prayerRequestTitle"] as? String ?? ""
                let postText = document.data()?["prayerRequestText"] as? String ?? ""
                let postType = document.data()?["postType"] as? String ?? ""
                let status = document.data()?["status"] as? String ?? ""
                let userID = document.data()?["userID"] as? String ?? ""
                let username = document.data()?["username"] as? String ?? ""
                let privacy = document.data()?["privacy"] as? String ?? "private"
                let documentID = document.documentID as String
                let latestUpdateText = document.data()?["latestUpdateText"] as? String ?? ""
                let latestUpdateType = document.data()?["latestUpdateType"] as? String ?? ""
            
                prayerRequest = Post(id: documentID, 
                                     date: datePosted,
                                     userID: userID,
                                     username: username,
                                     firstName: firstName,
                                     lastName: lastName,
                                     postTitle: postTitle,
                                     postText: postText,
                                     postType: postType,
                                     status: status,
                                     latestUpdateText: latestUpdateText,
                                     latestUpdateDatePosted: latestUpdateDatePosted,
                                     latestUpdateType: latestUpdateType,
                                     privacy: privacy,
                                     isPinned: isPinned)
            }
        } catch {
            throw error
        }
        
        return prayerRequest
    }

    // this function enables the creation and submission of a new prayer request. It does three things: 1) add to user collection of prayer requests, 2) add to prayer requests collection, and 3) adds the prayer request to all friends of the person only if the prayer request is the user's main profile.
    func createPost(userID: String, datePosted: Date, person: Person, postText: String, postTitle: String, privacy: String, postType: String, friendsList: [Person]) async throws {
        
        let postTitle = postTitle.capitalized
        
        // Create new PrayerRequestID to users/{userID}/prayerList/{person}/prayerRequests
        let ref = db.collection("users").document(userID).collection("prayerList").document("\(person.firstName.lowercased())_\(person.lastName.lowercased())").collection("prayerRequests").document()

        try await ref.setData([
            "datePosted": datePosted,
            "firstName": person.firstName,
            "lastName": person.lastName,
            "status": "Current",
            "prayerRequestText": postText,
            "postType": postType,
            "userID": userID,
            "username": person.username,
            "privacy": privacy,
            "prayerRequestTitle": postTitle,
            "latestUpdateText": "",
            "latestUpdateDatePosted": datePosted,
            "latestUpdateType": ""
        ])
        
        let prayerRequestID = ref.documentID
        
        // Add PrayerRequestID to prayerFeed/{userID}
        if privacy == "public" && !friendsList.isEmpty {
            for friend in friendsList {
                let ref2 = db.collection("prayerFeed").document(friend.userID).collection("prayerRequests").document(prayerRequestID)
                print(friend.username)
                print(friend.userID)
                try await ref2.setData([
                    "datePosted": datePosted,
                    "firstName": person.firstName,
                    "lastName": person.lastName,
                    "status": "Current",
                    "prayerRequestText": postText,
                    "postType": postType,
                    "userID": userID,
                    "username": person.username,
                    "privacy": privacy,
                    "prayerRequestTitle": postTitle,
                    "latestUpdateText": "",
                    "latestUpdateDatePosted": datePosted,
                    "latestUpdateType": ""
                ])
            } // If you have friends and have set privacy to public, this will update all friends feeds.
        }
        let ref2 = db.collection("prayerFeed").document(userID).collection("prayerRequests").document(prayerRequestID)
        try await ref2.setData([
            "datePosted": datePosted,
            "firstName": person.firstName,
            "lastName": person.lastName,
            "status": "Current",
            "prayerRequestText": postText,
            "postType": postType,
            "userID": userID,
            "username": person.username,
            "privacy": privacy,
            "prayerRequestTitle": postTitle,
            "latestUpdateText": "",
            "latestUpdateDatePosted": datePosted,
            "latestUpdateType": ""
        ]) // if the prayer is for a local user, it will update your own feed.
        
        // Add PrayerRequestID and Data to prayerRequests/{prayerRequestID}
        let ref3 =
        db.collection("prayerRequests").document(prayerRequestID)
        
        try await ref3.setData([
            "datePosted": datePosted,
            "firstName": person.firstName,
            "lastName": person.lastName,
            "status": "Current",
            "prayerRequestText": postText,
            "postType": postType,
            "userID": userID,
            "username": person.username,
            "privacy": privacy,
            "prayerRequestTitle": postTitle,
            "latestUpdateText": "",
            "latestUpdateDatePosted": datePosted,
            "latestUpdateType": ""
        ])
    }

    // This function enables an edit to a prayer requests off of a selected prayer request.
    func editPost(post: Post, person: Person, friendsList: [Person]) async throws {
        do {
            let ref = db.collection("users").document(person.userID).collection("prayerList").document("\(post.firstName.lowercased())_\(post.lastName.lowercased())").collection("prayerRequests").document(post.id)
            
            try await ref.updateData([
                "datePosted": post.date,
                "status": post.status,
                "postType": post.postType,
                "prayerRequestText": post.postText,
                "privacy": post.privacy,
                "prayerRequestTitle": post.postTitle
            ])
            
            // Add PrayerRequestID to prayerFeed/{userID}
            if post.status == "No Longer Needed" {
                try await FeedService().deleteFromFeed(post: post, person: person, friendsList: friendsList) // If it is no longer needed, remove from all feeds. If not, update all feeds.
            } else {
                if post.privacy == "public" && friendsList.isEmpty == false {
                    for friend in friendsList {
                        try await FeedService().updateFriendsFeed(post: post, person: person, friend: friend, updateFriend: true)
                    }
                }
                try await FeedService().updateFriendsFeed(post: post, person: person, friend: Person(), updateFriend: false)
                
                // Add PrayerRequestID and Data to prayerRequests/{prayerRequestID}
                try await updatePostsDataCollection(prayerRequest: post, person: person)
                print(post.postText)
            }
        } catch {
            print(error)
        }
    }

    //person passed in for the feed is the user. prayer passed in for the profile view is the person being viewed.
    func deletePost(post: Post, person: Person, friendsList: [Person]) async throws {
        let ref = db.collection("users").document(person.userID).collection("prayerList").document("\(post.firstName.lowercased())_\(post.lastName.lowercased())").collection("prayerRequests").document(post.id)
        
        try await ref.delete()
        
        // Delete PrayerRequest from all feeds: friend feeds and user's feed.
        try await FeedService().deleteFromFeed(post: post, person: person, friendsList: friendsList)
        
        // Delete PrayerRequestID and Data from prayerRequests/{prayerRequestID}
        let ref3 =
        db.collection("prayerRequests").document(post.id)
        
        try await ref3.delete()
    }

    // this function updates the prayer requests collection carrying all prayer requests. Takes in the prayer request being updated, and the person who is being updated for.
    func updatePostsDataCollection(prayerRequest: Post, person: Person) async throws {
        let ref =
        db.collection("prayerRequests").document(prayerRequest.id)
        
        try await ref.updateData([
            "datePosted": prayerRequest.date,
            "firstName": prayerRequest.firstName,
            "lastName": prayerRequest.lastName,
            "status": prayerRequest.status,
            "postType": prayerRequest.postType,
            "prayerRequestText": prayerRequest.postText,
            "userID": person.userID,
            "username": person.username,
            "privacy": prayerRequest.privacy,
            "prayerRequestTitle": prayerRequest.postTitle
        ])
    }
}
