//
//  PrayerFeedRowView.swift
//  Prayer Calendar
//
//  Created by Matt Lam on 4/28/24.
//

import SwiftUI

struct FeedRequestsRowView: View {
    @State private var showEdit: Bool = false
//    @State var prayerRequests: [PrayerRequest] = []
    @State var prayerRequestVar: PrayerRequest = PrayerRequest.blank
    
    @State var viewModel: PrayerRequestViewModel
    @Environment(UserProfileHolder.self) var userHolder
    @Binding var height: CGFloat
    
    var person: Person
    @State var profileOrFeed: String = "feed"
    
    var body: some View {
        ZStack {
            if viewModel.isLoading || userHolder.refresh {
                if userHolder.refresh == true { // only if refreshable is activated, then task must run, but progress is hidden
                    Text("")
                        .task {
                            if userHolder.refresh == true {
                                await viewModel.getPrayerRequests(user: userHolder.person, person: person, profileOrFeed: profileOrFeed) // activate on refreshable
                                userHolder.refresh = false
                            }
                        }
                } else {
                    ProgressView()
                }
            } else {
                LazyVStack {
                    ForEach(viewModel.prayerRequests) { prayerRequest in
                        VStack {
                            PrayerRequestRow(prayerRequest: prayerRequest, profileOrPrayerFeed: profileOrFeed)
                            Divider()
                        }
                        .task {
                            //   print("prayerRequest ID: "+prayerRequest.id)
                            //   print("viewModel.lastDocument: "+String(viewModel.lastDocument?.documentID ?? ""))
                            if viewModel.hasReachedEnd(of: prayerRequest) && !viewModel.isFetching {
                                await viewModel.getNextPrayerRequests(user: userHolder.person, person: person, profileOrFeed: profileOrFeed)
                            }
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollContentBackground(.hidden)
        .task {
            if viewModel.prayerRequests.isEmpty {
                await viewModel.getPrayerRequests(user: userHolder.person, person: person, profileOrFeed: profileOrFeed)
            } else {
                self.viewModel.prayerRequests = viewModel.prayerRequests
                self.height = height
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: {
            Task {
                await viewModel.getPrayerRequests(user: userHolder.person, person: person, profileOrFeed: profileOrFeed)
            }
        }, content: {
            PrayerRequestFormView(person: userHolder.person, prayerRequest: $prayerRequestVar)
        })
        
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

//#Preview {
//    PrayerFeedRowView()
//}
