//
//  fpaApp.swift
//  fpa
//
//  Created by Puneet Singh Bagga on 9/9/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct fpaApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
