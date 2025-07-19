//
//  ContentView.swift
//  Mainven
//
//  Created by Areydra Desfikriandre on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeTab()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            ProductsTab()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Products")
                }
            ContactsTab()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Contacts")
                }
            TransactionsTab()
                .tabItem {
                    Image(systemName: "dollarsign.square.fill")
                    Text("Transactions")
                }
        }
    }
}

#Preview {
    ContentView()
}
