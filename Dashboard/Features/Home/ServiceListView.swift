//
//  ServiceListView.swift
//  Dashboard
//
//  Created by Patrick Gatewood on 9/11/19.
//  Copyright © 2019 Patrick Gatewood. All rights reserved.
//

import SwiftUI
import WatchConnectivity

struct ServiceListView: View {
    @Environment(\.managedObjectContext) var moc
    
    @EnvironmentObject var network: NetworkService
    @EnvironmentObject var database: PersistenceClient
    
    @FetchRequest(fetchRequest: PersistenceClient.allServicesFetchRequest()) var services: FetchedResults<ServiceModel>

    // State variables are owned & managed by this view
    @State private var showingAddServices = false
    @State private var serviceToEdit: ServiceModel?
    @State private var editMode: EditMode = .inactive
        
    var addServiceButton: some View {
        Button(action: { self.showingAddServices.toggle() }) {
            Image(systemName: "plus.circle")
                .scaledToFit()
                .accessibility(label: Text("Add Service"))
                .imageScale(.large)
                .frame(width: 25, height: 25)
        }
    }
    
    var serviceList: some View {
        List {
            ForEach(services) { service in
                /* 🚨 If you don't pass each property individually, the view won't update. This feels wrong and could be a bug with
                 @FetchRequest. See comments: https://www.andrewcbancroft.com/blog/ios-development/data-persistence/how-to-use-fetchrequest-swiftui/ */
                
                ServiceRow(service: service, name: service.name, url: service.url, image: service.image, isOnline: service.wasOnlineRecently)
                    // Note that the environment modifier must go before these other modifiers, otherwise only the modifer will get the environment
                    // object. The order matters!
                    .environment(\.editMode, self.$editMode)
                    .simultaneousGesture(self.serviceRowTappedGesture(service))
                    .contextMenu {
                        Button(action: {
                            self.editService(service)
                        }) {
                            Text("Edit Service")
                        }
                }
            }
            .onMove(perform: moveService)
            .onDelete(perform: deleteService)
        }
        .listStyle(GroupedListStyle())
    }
    
    private func serviceRowTappedGesture(_ service: ServiceModel) -> some Gesture {
        TapGesture()
            .onEnded { _ in
                guard self.editMode == .active else {
                    print("not editing")
                    return
                }
                
                self.editService(service)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if services.isEmpty {
                    EmptyStateView()
                        .padding(.top, 100)
                    Spacer()
                } else {
                    serviceList
                }
            }
                // The conditional view above is wrapped in a VStack only to wrap it into a common ancenstor so that either conditional view may share the same modifiers.
                // I'd rather use a custom view modifier, but no views seem to render if a custom ViewModifier has a `.navigationBarItems` modifier.
                // It seems like this could be accomplished without needing to wrap the conditional views.
                .navigationBarTitle("My Services", displayMode: .large)
                
                // ⚠️ Note that for the editMode environment variable to work correctly with the EditButton, the environment modifier must come AFTER
                // the navigationBarItems modifier!
                .navigationBarItems(leading: EditButton(), trailing: addServiceButton)
                .environment(\.editMode, $editMode)
                .sheet(isPresented: $showingAddServices) {
                    AddServiceHostView(serviceToEdit: self.serviceToEdit)
                        .onDisappear() {
                            self.serviceToEdit = nil
                    }
            }
        }
    }
    
    private func editService(_ service: ServiceModel) {
        self.serviceToEdit = service
        self.showingAddServices.toggle()
    }
    
    /// TODO: There's an interesting animation that happens during this transition: I believe it comes from the view moving the elements, and then the backing data changing, which then re-animates the move
    private func moveService(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else {
            return // show error?
        }
        
        // Destination is an offset rather than an index, so massage it into an index
        let destinationIndex = sourceIndex > destination ? destination : destination - 1
        
        database.swap(service: services[sourceIndex], with: services[destinationIndex])
    }
    
    private func deleteService(at offsets: IndexSet) {
        guard let deletionIndex = offsets.first else {
            return
        }
        
        let service = services[deletionIndex]
        database.delete(service)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceListView() // Need to mock environmentObjects to see a good preview
    }
}
#endif
