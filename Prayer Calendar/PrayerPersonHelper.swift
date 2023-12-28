//
//  PrayerNameHelper.swift
//  Prayer Calendar
//
//  Created by Matt Lam on 11/23/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class PrayerPersonHelper {
    
//    This function retrieves PrayerList data from Firestore.
    func getFirestoreData(userHolder: UserProfileHolder, dataHolder: PrayerListHolder) async {
            let ref = Firestore.firestore()
                .collection("users")
                .document(userHolder.userID).collection("prayerList").document("prayerList1")
            
            ref.getDocument{(document, error) in
                if let document = document, document.exists {
                    
                        let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                        print("Document data: " + dataDescription)
                        
                        //Update Dataholder with PrayStartDate from Firestore
                        let startDateTimeStamp = document.get("prayStartDate") as! Timestamp
                        dataHolder.prayStartDate = startDateTimeStamp.dateValue()
                        
                        
                        //Update Dataholder with PrayerList from Firestore
                        dataHolder.prayerList = document.get("prayerList") as! String
                    
                } else {
                    print("Document does not exist")
                    dataHolder.prayerList = ""
                }
            }
    }

    // The following function returns an array of PrayerPerson's so that the view can grab both the username or name.
    func retrievePrayerPersonArray(prayerList: String) -> [PrayerPerson] {
        let ref = prayerList.components(separatedBy: "\n")
        var prayerArray: [PrayerPerson] = []
        
        for person in ref {
            let array = person.split(separator: "; ", omittingEmptySubsequences: true)
            /*.map(String.init)*/
            let prayerPerson = PrayerPerson(username: String(array.last ?? ""), firstName: String(array.first ?? ""))
            prayerArray.append(prayerPerson)
            print(prayerPerson.firstName)
        }
        
        return prayerArray
    }
}
