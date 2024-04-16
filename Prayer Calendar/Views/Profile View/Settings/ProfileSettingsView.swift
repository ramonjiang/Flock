//
//  ProfileSettingsView.swift
//  Prayer Calendar
//
//  Created by Matt Lam on 2/9/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Settings page for user to edit profile information.
struct ProfileSettingsView: View {
    @Environment(UserProfileHolder.self) var userHolder
    @Environment(PrayerListHolder.self) var prayerListHolder
    
    var body: some View {
            Form {
                Section {
                    HStack (alignment: .center) {
                        Spacer()
                        VStack {
                            ProfilePictureAvatar(firstName: userHolder.person.firstName, lastName: userHolder.person.lastName, imageSize: 40, fontSize: 20)
                            Text(userHolder.person.firstName + " " + userHolder.person.lastName)
                        }
                        Spacer()
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 } // extends automatic separator divider. If not, it looks weird.
                    
                    NavigationStack {
                        NavigationLink(destination: AccountSettings()){
                            Text("Account Settings")
                        }
                    }
                }
                Section{
                    Button(action: {
                        self.signOut()
                    }) {Text("Sign Out")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                }.frame(alignment: .center)
        }.navigationTitle("Settings")
    }
    
    func signOut() {
        // Sign out from firebase and change loggedIn to return to SignInView.
        try? Auth.auth().signOut()
        resetInfo()
    }

    func resetInfo() {
        userHolder.friendsList = []
        userHolder.isLoggedIn = false

        userHolder.person.userID = ""
        prayerListHolder.prayerList = ""
        prayerListHolder.prayStartDate = Date()
    }
}

struct DeleteButton: View {
    @Environment(UserProfileHolder.self) var userHolder
    @State private var isPresentingConfirm: Bool = false

    var body: some View {
        Button("Delete Account", role: .destructive) {
            isPresentingConfirm = true
        }
        .confirmationDialog("Are you sure?",
                            isPresented: $isPresentingConfirm) {
            Button("Delete Account and Sign Out", role: .destructive) {
                Task {
                    do {
                        try await PrayerPersonHelper().deletePerson(userID: userHolder.person.userID, friendsList: userHolder.friendsList)
                        ProfileSettingsView().signOut()
                        ProfileSettingsView().resetInfo()
                    } catch {
                        print(error)
                    }
                }
            }
        } message: {
            Text("Are you sure you would like to delete your account? Deleting account will remove all history of prayer requests both in your account and in any friend feeds, and will not be able to be restored.")
        }
    }
}

struct AccountSettings: View {
    @Environment(UserProfileHolder.self) var userHolder
    
    var body: some View {
        Form {
            Section {
                NavigationStack {
                    NavigationLink(destination: ProfileSettingsChangePasswordView()){
                        Text("Change Password")
                    }
                }
            }
            Section {
                DeleteButton()
            }
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileSettingsView()
        .environment(UserProfileHolder.Blank())
}
//
//#Preview {
//    ProfileSettingsSignIn(userHolder: UserProfileHolder())
//        .environment(UserProfileHolder())
//}
