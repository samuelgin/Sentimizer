//
//  ContentView.swift
//  Sentimizer
//
//  Created by Samuel Ginsberg, 2022.
//

import SwiftUI
import CoreData

struct MainActivityView: View {
//    @EnvironmentObject private var model: Model
    @Environment(\.managedObjectContext) var viewContext
    
    @StateObject private var persistenceController = PersistenceController()
    
    @State private var addActivitySheetOpened = false
    
    @State private var selectedMonth = Date()
    
    @State private var entryDays: [String] = []
    @State private var entryContent: [[[String]]] = [[]]
    
    @State private var showLastMonth = false
    
    @FetchRequest var entries: FetchedResults<Entry>
    
    var body: some View {
        ScrollView {
            MonthSwitcher(selectedMonth: $selectedMonth, allowFuture: false)
                .padding(.bottom)
            
            Group {
                VStack(alignment: .leading) {
                    SentiButton(icon: "plus.circle", title: "Add Activity")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .onTapGesture {
                            addActivitySheetOpened = true
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
                    
                    if persistenceController.getEntryData(entries: entries, month: selectedMonth).0.count < 1  {
                        Text(" \(Image(systemName: "list.bullet.below.rectangle")) There are no entries in the chosen month.")
                            .font(.senti(size: 15))
                            .bold()
                            .padding()
                        
                        let lastMonth = Date.appendMonths(to: selectedMonth, count: -1)
                        if persistenceController.getEntryData(entries: entries, month: lastMonth).0.count > 0 {
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
                            Text(entryDays[day])
                                .font(.senti(size: 25))
                                .padding()
                            
                            ForEach(0 ..< entryContent[day].count, id: \.self) { i in
                                let c = entryContent[day][i]
                                NavigationLink { ActivityDetailView(activity: c[0], icon: persistenceController.getActivityIcon(activityName: c[0], viewContext), description: c[3], day: entryDays[day], time: c[1], duration: c[2], sentiment: c[4], id: c[5]) } label: {
                                    ActivityBar(activity: c[0], description: c[3], time: (c[1], c[2]), sentiment: c[4], id: c[5], icon: persistenceController.getActivityIcon(activityName: c[0], viewContext))
                                        .padding([.bottom, .trailing], 10)
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.dayViewBgColor).shadow(color: .gray.opacity(0.7), radius: 10))
                        .padding(.vertical, 5)
                        .padding(.bottom)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .sheet(isPresented: $addActivitySheetOpened) {
            AddActivityView()
                .environment(\.managedObjectContext, self.viewContext)
        }
        .onAppear() {
            (entryDays, entryContent) = persistenceController.getEntryData(entries: entries)
        }
        .onChange(of: addActivitySheetOpened) { _ in
            (entryDays, entryContent) = persistenceController.getEntryData(entries: entries)
        }
        .onChange(of: selectedMonth) { newValue in
            showLastMonth = false
            (entryDays, entryContent) = persistenceController.getEntryData(entries: entries, month: newValue)
        }
        .onChange(of: showLastMonth) { newValue in
            if newValue {
                var dateComponent = DateComponents()
                dateComponent.month = -1
                (entryDays, entryContent) = persistenceController.getEntryData(entries: entries, month: Calendar.current.date(byAdding: dateComponent, to: selectedMonth)!)
            }
        }
    }
    
    init() {
        let f:NSFetchRequest<Entry> = Entry.fetchRequest()
        f.fetchLimit = 100
        f.sortDescriptors = [NSSortDescriptor(key: #keyPath(Entry.date), ascending: false)]
        _entries = FetchRequest(fetchRequest: f)
    }
}

struct MainActivityView_Previews: PreviewProvider {
    static var previews: some View {
        MainActivityView()
//            .environmentObject(Model())
    }
}
