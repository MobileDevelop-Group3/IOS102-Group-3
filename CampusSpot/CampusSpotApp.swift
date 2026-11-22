//
//  CampusSpotApp.swift
//  CampusSpot
//
//  Created by Jherson Hernandez on 11/15/26.
//


import SwiftUI
import ParseSwift

@main
struct CampusSpotApp: App {
    @State private var isAuthenticated = false

    init() {
        ParseSwift.initialize(
            applicationId: "vb7iaWsPs3bLzBfCIrRS3k3oNraWMbjh1IdnUpay",
            clientKey: "I7fsdF3yr7AaLBsf7sa7yQVUKAoI4oXq7JO6GUTf",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    MainTabView(onLogout: {
                        Task {
                            try? await User.logout()
                            await MainActor.run {
                                isAuthenticated = false
                            }
                        }
                    })
                } else {
                    AuthFlowView(onAuthenticated: {
                        isAuthenticated = true
                    })
                }
            }
            .onAppear {
                isAuthenticated = User.current != nil
            }
        }
    }
}

struct AuthFlowView: View {
    var onAuthenticated: () -> Void
    @State private var authScreen = "welcome"

    var body: some View {
        NavigationStack {
            switch authScreen {
            case "login":
                LoginView(
                    onSignUp: { authScreen = "signup" },
                    onBack: { authScreen = "welcome" },
                    onLogin: { onAuthenticated() }
                )
            case "signup":
                SignUpView(
                    onLogin: { authScreen = "login" },
                    onBack: { authScreen = "login" },
                    onSignedUp: { onAuthenticated() }
                )
            default:
                WelcomeView {
                    authScreen = "login"
                }
            }
        }
    }
}
