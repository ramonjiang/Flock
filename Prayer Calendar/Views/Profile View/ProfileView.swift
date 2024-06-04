//
//  ProfileView.swift
//  PrayerCalendar
//
//  Created by Matt Lam on 10/6/23.
//
// Description: ProfileView with conditional statements changing the view depending on whether it is your profile you are viewing or someone else's.

import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var showSubmit: Bool = false
    @State private var showEditView: Bool = false
    @State var person: Person
    @State var viewModel: FeedViewModel = FeedViewModel(profileOrFeed: "profile")
    @Environment(UserProfileHolder.self) var userHolder
    
    var body: some View {
        NavigationStack() {
            ScrollView {
                VStack {
                    HStack {
                        VStack (alignment: .leading) {
                            if person.username == "" {
                                Text("private profile")
                                Text("@\(userHolder.person.username.capitalized)").bold()
                            } else {
                                Text("public profile")
                                Text("@\(person.username.capitalized)").bold()
                            }
                        }
                        Spacer()
                    }
                    .padding([.leading, .trailing], 20)
                    .font(.system(size: 14))
                    
                    Spacer()
                    
                    LazyVStack {
                        HStack{
                            // Only show this if you are the owner of profile.
                            if person.username == userHolder.person.username {
                                Text("My Posts")
                                    .font(.title3)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 20)
                            } else {
                                Text("\(person.firstName)'s Posts")
                                    .font(.title3)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 20)
                            }
                            Spacer()
                            
                            HStack {
                                if viewModel.selectedStatus == .noLongerNeeded {
                                    Text("No Longer\nNeeded")
                                        .font(.system(size: 14))
                                        .multilineTextAlignment(.trailing)
                                } else {
                                    Text(viewModel.selectedStatus.rawValue.capitalized)
                                        .font(.system(size: 16))
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                StatusPicker(viewModel: viewModel)
                                    .onChange(of: viewModel.selectedStatus, {
                                        Task {
                                            if !viewModel.isFetching || !viewModel.isLoading {
                                                await viewModel.getPrayerRequests(user: userHolder.person, person: person)
                                            }
                                        }
                                    })
                            }
                            .padding(.trailing, 20)
                        }
                        Divider()
                        
                        FeedRequestsRowView(viewModel: viewModel, person: person, profileOrFeed: "profile")
                        //                    if userHolder.person.username == person.username {
                        //                        ProfileFeed(viewModel: viewModel, person: userHolder.person) // Leaving as a separate view for now in case need to implement tab view.
                        //                            .frame(maxHeight: .infinity)
                        //                            .padding(.top, 20)
                        //                    } else {
                        //                        ProfileFeed(viewModel: viewModel, person: person) // Leaving as a separate view for now in case need to implement tab view.
                        //                            .frame(maxHeight: .infinity)
                        //                            .padding(.top, 20)
                        //                    }
                    }
                }
            }
            .task {
                do {
                    person = try await PrayerPersonHelper().retrieveUserInfoFromUsername(person: person, userHolder: userHolder)
                } catch {
                    print(error)
                }
            }
            .refreshable {
                Task {
                    if viewModel.isFinished {
                        await viewModel.getPrayerRequests(user: userHolder.person, person: person)
                    }
                }
            }
            .navigationTitle(person.firstName + " " + person.lastName)
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showSubmit, onDismiss: {
                Task {
                    do {
                        if viewModel.prayerRequests.isEmpty || userHolder.refresh == true {
                            self.person = try await PrayerPersonHelper().retrieveUserInfoFromUsername(person: person, userHolder: userHolder) // retrieve the userID from the username submitted only if username is not your own. Will return user's userID if there is a valid username. If not, will return user's own.
                            await viewModel.getPrayerRequests(user: userHolder.person, person: person)
                        } else {
                            self.viewModel.prayerRequests = viewModel.prayerRequests
                            //                            self.height = height
                        }
                        print("Success retrieving prayer requests for \(person.userID)")
                    }
                }
            }, content: {
                SubmitPostForm(person: person)
            })
            .toolbar {
                // Only show this if the account has been created under your userID. Aka, can be your profile or another that you have created for someone.
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HStack {
                            if person.username == userHolder.person.username {
                                NavigationLink(value: "Settings") {
                                    Image(systemName: "gear")
                                }
                                .id(UUID())
                                .padding(.trailing, -10)
                                .padding(.top, 2)
                            }
                            Button(action: {
                                showSubmit.toggle()
                            }) {
                                Image(systemName: "square.and.pencil")
                            }
                        }
                    }
            }
            .navigationDestination(for: String.self) { value in
                if value == "Settings" {
                    ProfileSettingsView()
                }
            }
        }
    }
    
    func usernameDisplay() -> String {
        if person.username == "" {
            return "private profile"
        }
        return "@\(person.username.capitalized)"
    }
}

//#Preview {
//    ProfileView(person: Person(userID: "aMq0YdteGEbYXWlSgxehVy7Fyrl2", username: "lammylol"))
//        .environment(UserProfileHolder())
//}
