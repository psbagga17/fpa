//
//  ContentView.swift
//  fpa
//
//  Created by Puneet Singh Bagga on 9/9/24.
//

import ConfettiSwiftUI
import FirebaseAuth
import FirebaseFirestore
import Charts
import SwiftUI


//let globalTimeRemaining: Double = 3

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var loading = false
    
    @State private var score = 0
    @State private var timeRemaining: Double = 3
    @State private var tempTimeRemaining: Double = 3
    @State private var gameState: GameState = .start
    @State private var timer: Timer?
    @State private var confettiCounter = 0  // Confetti counter
    @State private var avgClicksPerSecond: Double = 0.0 // State for average clicks per second

    struct GameData: Identifiable {
        let id = UUID()
        let index: Int
        let clicksPerSecond: Double
    }

    @State private var history: [GameData] = []
    
    private let db = Firestore.firestore()

    enum GameState {
        case start
        case inGame
        case endGame
    }
    
    var body: some View {
        Group {
            if isAuthenticated {
                gameFlowView
            } else {
                authView
            }
        }
        .onAppear {
            isAuthenticated = Auth.auth().currentUser != nil
        }
        .onChange(of: Auth.auth().currentUser) { newUser in
            isAuthenticated = newUser != nil
        }
    }

    // Authentication View
    var authView: some View {
        VStack {
            if loading {
                ProgressView("Loading...")
            } else {
                VStack(spacing: 20) {
                    Text("Login or Sign Up")
                        .font(.largeTitle)
                        .padding()

                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    SecureField("Password", text: $password)
                        .autocapitalization(.none)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    HStack {
                        Button(action: loginUser) {
                            Text("Log In")
                                .font(.title2)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: signUpUser) {
                            Text("Sign Up")
                                .font(.title2)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
    }

    var gameFlowView: some View {
        VStack {
            Spacer()

            switch gameState {
            case .start:
                startScreen

            case .inGame:
                gameScreen

            case .endGame:
                endGameScreen
            }

            Spacer()
        }
    }

    // Start Screen
    var startScreen: some View {
        VStack {
            Text("Click Counter!")
                .font(.largeTitle)
                .padding()
            
            Text("Set Game Duration: \(String(format: "%.0f", timeRemaining)) seconds")
                .font(.title2)
                .padding()

            Slider(value: $timeRemaining, in: 1...10, step: 1)
                .padding()

            Button(action: startGame) {
                Text("Start Game")
                    .font(.title)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    // Game Screen
    var gameScreen: some View {
        VStack {
            Text("Score: \(score)")
                .font(.largeTitle)
                .padding()
            
            Text(String(format: "Time: %.2f", tempTimeRemaining))
                .font(.largeTitle.monospacedDigit())
                .padding()

            Button(action: incrementScore) {
                Text("Tap Me!")
                    .font(.largeTitle)
                    .frame(width: 150, height: 150)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .padding()
            }
        }
    }

    // Game End Screen
    var endGameScreen: some View {
        VStack {
            Text("Final Score: \(score)")
                .font(.system(size: 40, weight: .bold))
                .padding()
            
            Text("Average Clicks per Second: \(String(format: "%.2f", Double(score) / timeRemaining))")
                .font(.title2)
                .padding()
            
            Text("Historical Average (past 10): \(String(format: "%.2f", avgClicksPerSecond))")
                .font(.title2)
                .padding()
            
            Chart(history.reversed()) { play in
                BarMark(
                    x: .value("Play", play.index),
                    y: .value("Clicks per Second", play.clicksPerSecond)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
            .padding()
            
            Spacer()
            
            Button(action: resetGame) {
                Text("Play Again")
                    .font(.title)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Button(action: logoutUser) {
                Text("Log Out")
                    .font(.title)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            ConfettiCannon(counter: $confettiCounter, repetitions: Int(rand(1...4)), repetitionInterval: 0.5)
        }
        .onAppear {
            confettiCounter += 1 // for triggering confetti
            saveScore()
            getAvgCPS()
        }
    }
    
    private func saveScore() {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid
        let clicksPerSecond = Double(score) / timeRemaining
        
        db.collection("scores").addDocument(data: [
            "userId": userId,
            "time":  timeRemaining,
            "score": score,
            "clicksPerSecond": clicksPerSecond,
            "timestamp": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error saving score: \(error.localizedDescription)")
            }
        }
    }

    private func getAvgCPS() {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid
        
        db.collection("scores")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching scores: \(error.localizedDescription)")
                    return
                }
                
                let scores = querySnapshot?.documents ?? []
                let totalClicksPerSecond = scores.reduce(0.0) { (total, document) -> Double in
                    let cps = document.data()["clicksPerSecond"] as? Double ?? 0.0
                    return total + cps
                }
                self.avgClicksPerSecond = scores.isEmpty ? 0.0 : totalClicksPerSecond / Double(scores.count)
                
                self.history = scores.enumerated().map { (index, document) in
                    let cps = document.data()["clicksPerSecond"] as? Double ?? 0.0
                    return GameData(index: index + 1, clicksPerSecond: cps)
                }
            }
    }

    
    
    // auth login logout and signup
    private func loginUser() {
        loading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            loading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isAuthenticated = true
                gameState = .start
            }
        }
    }
    
    private func signUpUser() {
        loading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            loading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isAuthenticated = true
                gameState = .start
            }
        }
    }
    
    private func logoutUser() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    private func startGame() {
        score = 0
        tempTimeRemaining = timeRemaining // Local temporary variable
        gameState = .inGame
        confettiCounter = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if tempTimeRemaining > 0 {
                tempTimeRemaining -= 0.01
            } else {
                gameState = .endGame
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private func incrementScore() {
        score += 1
        if score == 20 {
            score += 2
        }
    }

     private func resetGame() {
         gameState = .start
     }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
