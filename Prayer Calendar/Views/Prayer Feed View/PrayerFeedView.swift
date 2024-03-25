//
//  PrayerFeedView.swift
//  Prayer Calendar
//
//  Created by Matt Lam on 1/2/24.
//

import SwiftUI

struct PrayerFeedView: View {
    @State private var showSubmit: Bool = false
    @State private var showEdit: Bool = false
    @State private var selectedPage: Int = 1
    
//    @State var pinnedPrayerRequests: [PrayerRequest] = []
    @State var prayerRequestVar: PrayerRequest = PrayerRequest.blank
    
    @Environment(UserProfileHolder.self) var userHolder
    var person: Person
    @State private var height: CGFloat = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Picker("", selection: $selectedPage) {
                        if userHolder.pinnedPrayerRequests.isEmpty == false {
                            Text("Pinned").tag(0)
                        }
                        Text("Current").tag(1)
                        Text("Testimonies").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 10)
                    
                    TabView(selection: $selectedPage) {
                        Group {
                            if userHolder.pinnedPrayerRequests.isEmpty == false {
                                PrayerFeedPinnedView(person: person, height: $height)
                                    .tag(0)
                            }
                            PrayerFeedCurrentView(person: person, height: $height)
                                .tag(1)
                            PrayerFeedAnsweredView(person: person, height: $height)
                                .tag(2)
                        }
                        .onAppear() {
                            self.height = height
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: self.height)
                    //                .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    .sheet(isPresented: $showSubmit, onDismiss: {
                    }, content: {
                        SubmitPrayerRequestForm(person: person)
                    })
                }
    //
    //                .task {
    //                    if userHolder.pinnedPrayerRequests.isEmpty {
    //                        selectedPage = 1
    //                    } else {
    //                        selectedPage = 1
    //                    }
    //                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showSubmit.toggle()
                        }) {
                            Image(systemName: "plus")
                        }
                        .padding(.trailing, 15)
                    }
                }
                .navigationTitle("prayer feed")
                .navigationBarTitleDisplayMode(.automatic)
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct FeedRequestsRowView: View {
    @State private var showEdit: Bool = false
//    @Binding var height: CGFloat
    
    @State var prayerRequests: [PrayerRequest] = []
    @State var prayerRequestVar: PrayerRequest = PrayerRequest.blank
    
    @Environment(UserProfileHolder.self) var userHolder
    var person: Person
    var answeredFilter: String
    
    var body: some View {
        VStack {
            ForEach($prayerRequests) { prayerRequest in
                LazyVStack {
                    PrayerRequestRow(prayerRequest: prayerRequest, profileOrPrayerFeed: "feed")
                    Divider()
                }
            }
            Spacer()
        }
        .task {
            do {
                prayerRequests = try await PrayerFeedHelper().retrievePrayerRequestFeed(userID: person.userID, answeredFilter: answeredFilter)
            } catch {
                print("error retrieving prayerfeed")
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: {
            Task {
                do {
                    prayerRequests = try await PrayerFeedHelper().retrievePrayerRequestFeed(userID: person.userID, answeredFilter: answeredFilter)
                }
            }
        }, content: {
            PrayerRequestFormView(person: userHolder.person, prayerRequest: $prayerRequestVar)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PrayerFeedAnsweredView: View {
    // view to only see 'answered' prayers
    var person: Person
    @Binding var height: CGFloat
    
    var body: some View {
        FeedRequestsRowView(person: person, answeredFilter: "answered")
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: HeightPreferenceKey.self,
                        value: geo.size.height
                    )
            }
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                self.height = height
            }
        )
    }
}

struct PrayerFeedCurrentView: View {
    // view to see 'current' prayers
    var person: Person
    @Binding var height: CGFloat
    
    var body: some View {
        FeedRequestsRowView(person: person, answeredFilter: "current")
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: HeightPreferenceKey.self,
                        value: geo.size.height
                    )
            }
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                self.height = height
            }
        )
    }
}

struct PrayerFeedPinnedView: View {
    // view to only see 'pinned' prayers
    var person: Person
    @Binding var height: CGFloat
    
    var body: some View {
        FeedRequestsRowView(person: person, answeredFilter: "pinned")
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: HeightPreferenceKey.self,
                        value: geo.size.height
                    )
            }
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                self.height = height
            }
        )
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    PrayerFeedView(person: Person(username: ""))
}
