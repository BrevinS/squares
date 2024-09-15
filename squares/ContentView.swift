//
//  ContentView.swift
//  squares
//
//  Created by Brevin Simon on 9/12/24.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                VStack {
                    Text("Notes")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    SubjectsPage()
                    
                }
                .tag(0)
                
                VStack {
                    Text("Squares")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    SquaresView()
                }
                .tag(1)

                VStack {
                    Text("Add Activity")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            

            HStack {
                Button(action: {
                    selectedTab = 0
                }) {
                    VStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 30))
                            .foregroundColor(Color(.systemOrange))
                        if selectedTab == 0 {
                            // WHEN SELECTED
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    selectedTab = 1
                }) {
                    VStack {
                        Image(systemName: "square.3.stack.3d.middle.filled")
                            .font(.system(size: 30))
                            .foregroundColor(Color(.systemOrange))
                        if selectedTab == 1 {
                            // WHEN SELECTED
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    selectedTab = 2
                }) {
                    VStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 30))
                            .foregroundColor(Color(.systemOrange))
                        if selectedTab == 2 {
                            // WHEN SELECTED
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
    }
}
