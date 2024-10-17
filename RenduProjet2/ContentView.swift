//
//  ContentView.swift
//  RenduProjet2
//
//  Created by RENAUD Brévin on 15/10/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn {
                NotesView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}

#Preview{
    ContentView()
}

