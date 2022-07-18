//
//  ContentView.swift
//  Sentimizer
//
//  Created by Samuel Ginsberg, 2022.
//

import SwiftUI
import CoreData

struct MainActivityView: View {
    @Environment(\.managedObjectContext) var viewContext
    @AppStorage(K.userNickname) var userNickname: String = ""
    
    @StateObject private var persistenceController = PersistenceController()
    
    @State private var welcomeScreenPresented = false
    @State private var addActivitySheetPresented = false
    
    @State private var selectedMonth = Date()
    
    @State private var entryDays: [String] = []
    @State private var entryContent: [[ActivityData]] = []
    
    @State private var showLastMonth = false
    
    @FetchRequest private var entries: FetchedResults<Entry>
    
    @State private var brandColor2 = Color.brandColor2
    @State private var brandColor2Light = Color.brandColor2Light
    
    let haptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ScrollView {
            MonthSwitcher(selectedMonth: $selectedMonth, allowFuture: false)
                .padding(.bottom)
            
            HStack {
                let tOD = Date.getTimeOfDay()
                Text("\(Image(systemName: K.symbolForTimeOfDay(tOD))) Good \(K.stringForTimeOfDay(tOD)), \(userNickname)")
                    .font(.senti(size: 25))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .gradientForeground(colors: [brandColor2, brandColor2Light])
                    .padding(.horizontal)
                    .padding(.bottom)
                Spacer()
            }
            
            Group {
                VStack(alignment: .leading) {
                    SentiButton(icon: "plus.circle", title: "Add Activity")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .onTapGesture {
                            addActivitySheetPresented = true
                            
                            haptic.impactOccurred()
                        }
                }
                .padding(.horizontal, 5)
                .padding(.bottom)
                
                if entries.count < 1 {
                    VStack {
                        HStack {
                            Image(systemName: "figure.walk")
                            Image(systemName: "fork.knife")
                            Image(systemName: "briefcase.fill")
                        }
                        .font(.title)
                        Text("Create Your First Activity Above")
                            .font(.senti(size: 15))
                            .bold()
                            .padding()
                    }
                    .padding(.top, 50)
                } else {
                    WhatNext(activity: "Walking")
                        .padding(.bottom, 15)
                        .padding(.horizontal, 5)
                    
                    if persistenceController.getEntryData(entries: entries, month: selectedMonth, viewContext).0.count < 1  {
                        Text("\(Image(systemName: "list.bullet.below.rectangle")) There are no entries in the chosen month.")
                            .font(.senti(size: 15))
                            .bold()
                            .padding()
                        
                        let lastMonth = Date.appendMonths(to: selectedMonth, count: -1)
                        if persistenceController.getEntryData(entries: entries, month: lastMonth, viewContext).0.count > 0 {
                            Text(Calendar.current.monthSymbols[Calendar.current.component(.month, from: selectedMonth)-2] + " \(Calendar.current.component(.year, from: selectedMonth))")
                                .font(.senti(size: 20))
                                .minimumScaleFactor(0.8)
                                .padding()
                                .onAppear {
                                    showLastMonth = true
                                }
                        }
                    }
                    
                    ForEach(0..<entryDays.count, id: \.self) { day in
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(entryDays[day]))
                                .font(.senti(size: 25))
                                .padding()
                            
                            ForEach(0 ..< entryContent[day].count, id: \.self) { i in
                                let activity = entryContent[day][i]
                                let time = DateFormatter.formatDate(date: activity.date, format: "HH:mm")
                                
                                NavigationLink { ActivityDetailView(activity: activity, day: LocalizedStringKey(entryDays[day]), time: time) } label: {
                                    ActivityBar(activity: activity, time: time)
                                        .padding([.bottom, .trailing], 10)
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.dayViewBgColor).shadow(color: .gray.opacity(0.3), radius: 5))
                        .padding(.vertical, 5)
                        .padding(.bottom)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .sheet(isPresented: $addActivitySheetPresented) {
            AddActivityView()
                .environment(\.managedObjectContext, self.viewContext)
        }
        .onAppear {
            print("APPEARED_")
            K.rnn.saveModels()
            Task {
                do {
                    print("DO_")
                    var db = DataBridge()
                    try await db.getAndPost(userId: UserDefaults.standard.string(forKey: K.userId) ?? "")
                    try await db.registerUser(urlString: "http://127.0.0.1:8000/api/register")
                    print("AFTER_")
                    print("time_", Date().timeIntervalSince1970)
                    // let defaults = UserDefaults.standard
                    
                    // K.rnn = RNN(inN: PersistenceController().getAllActivities(PersistenceController.context).count + K.defaultActivities.0.count, hsN: 100)
                    
                    // print("RNN_", K.rnn.inN)
                    
                    // try await K.rnn.ichhabkeineverzweiflungsmethoden()
                    
                    // K.rnn.saveModels()
//                    K.rnn.fetchMNets()
                    
                    // rnn.trainNets()
                    
                    // rnn.fetchMNets()
                    // rnn.sendTNets()
                    
                    // print("VALID_", K.rnn.validNets())
                    
                    // MachineLearning.getModel()
                    
                    // MachineLearning.getTorch()
                    
                    // print("HELP ME", MachineLearning.feedforward(ip: [0.1, 0.2, 0.3, 0.4]))
                } catch {
                    print(error)
                }
            }
            
            fillEntryData()
            welcomeScreenPresented = !UserDefaults.standard.bool(forKey: K.welcomeScreenShown)
            
            brandColor2 = Color.brandColor2
            brandColor2Light = Color.brandColor2Light
        }
        .onChange(of: addActivitySheetPresented) { newValue in
            if !newValue {
                if persistenceController.getEntryData(entries: entries, month: selectedMonth, viewContext).0.count > 0 {
                    showLastMonth = false
                }
                
                fillEntryData()
            }
        }
        .onChange(of: selectedMonth) { newValue in
            showLastMonth = false
            fillEntryData()
        }
        .onChange(of: showLastMonth) { newValue in
            fillEntryData()
        }
        .fullScreenCover(isPresented: $welcomeScreenPresented) {
            WelcomeView()
        }
    }
    
    init() {
        let f:NSFetchRequest<Entry> = Entry.fetchRequest()
        f.sortDescriptors = [NSSortDescriptor(key: #keyPath(Entry.date), ascending: false)]
        _entries = FetchRequest(fetchRequest: f)
    }
    
    func fillEntryData() {
        var dateComponent = DateComponents()
        if showLastMonth {
            dateComponent.month = -1
        } else {
            dateComponent.month = 0
        }
        
        (entryDays, entryContent) = persistenceController.getEntryData(entries: entries, month: Calendar.current.date(byAdding: dateComponent, to: selectedMonth) ?? Date.distantPast, viewContext)
    }
}

struct MainActivityView_Previews: PreviewProvider {
    static var previews: some View {
        MainActivityView()
    }
}
