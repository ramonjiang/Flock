//
//  PrayerNameInputView.swift
//  PrayerCalendar
//
//  Created by Matt Lam on 10/2/23.
//

import SwiftUI
import Observation
import FirebaseFirestore

struct PrayerNameInputView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var dataHolder: PrayerListHolder

    @State var prayStartDate: Date = Date()
    @State var prayerList: String = ""
    @State var date: Date = Date()
    @State var saved: String = ""
    
    init(dataHolder: PrayerListHolder) {
        self.dataHolder = dataHolder
//        _email = State(initialValue: dataHolder.email)
        _prayerList = State(initialValue: dataHolder.prayerList)
        _prayStartDate = State(initialValue: dataHolder.prayStartDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack{
                DatePicker(
                    "Start Date",
                    selection: $prayStartDate,
                    displayedComponents: [.date]
                )
                .padding([.leading, .trailing], 90)
                Divider()
                TextEditor(text: $prayerList)
                    .padding([.leading, .trailing], 20)
                    .padding([.top], 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
                Text(saved)
                    .font(Font.system(size: 12))
                Spacer()
            }
            .navigationTitle("Input Your Prayer List")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {submitList(inputText: prayerList)}) {
                        Text("Save")
                            .offset(x: -4)
                            .font(.system(size: 14))
                            .padding([.leading, .trailing], 5)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.blue)
                    }
                    .foregroundStyle(.white)
                }
            }
    }
    }
    
    func submitList(inputText: String) {
        let inputList = inputText.split(separator: "\n").map(String.init)
        dataHolder.prayerList = inputList.joined(separator: "\n")
        dataHolder.prayStartDate = prayStartDate

        let db = Firestore.firestore()
        let ref = db.collection("users").document(dataHolder.email).collection("prayerList").document("prayerList1")
        
        ref.setData(["email": dataHolder.email, "prayStartDate": prayStartDate, "prayerList": prayerList])
        
        saved = "Saved"
        dismiss()
    }
                           
}

struct PrayerNameInputView_Previews: PreviewProvider {
    static var previews: some View {
        PrayerNameInputView(dataHolder: PrayerListHolder())
            .environment(PrayerListHolder())
    }
}
