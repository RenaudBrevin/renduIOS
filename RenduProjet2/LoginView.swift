//
//  LoginView.swift
//  RenduProjet2
//
//  Created by RENAUD Brévin on 16/10/2024.
//

import SwiftUI


struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    var body: some View {
        VStack(spacing: 20) {
            Text("Connexion à notes")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 30)
            TextField("Nom d'utilisateur", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            SecureField("Mot de passe", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Button(action: {
                if checkCredentials() {
                    isLoggedIn = true
                } else {
                    showAlert = true
                }
            }) {
                Text("Se connecter")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Erreur"), message: Text("Nom d'utilisateur ou mot de passe incorrect"), dismissButton: .default(Text("Ok")))
        }
    }
    // Verifier la connexion
    private func checkCredentials() -> Bool {
        let user = "User"
        let psw = "user"
        
        return username == user && password == psw
    }
}
