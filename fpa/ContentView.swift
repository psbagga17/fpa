//
//  ContentView.swift
//  fpa
//
//  Created by Puneet Singh Bagga on 9/9/24.
//

import ConfettiSwiftUI
import SwiftUI

let globalTimeRemaining: Double = 3

struct ContentView: View {
    @State private var score = 0
    @State private var timeRemaining = globalTimeRemaining
    @State private var gameState: GameState = .start
    @State private var timer: Timer?
    @State private var confettiCounter = 0  // Confetti counter

    enum GameState {
        case start
        case inGame
        case endGame
    }

    var body: some View {
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
            
            Text(String(format: "Time: %.2f", timeRemaining))
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
            
            Button(action: startGame) {
                Text("Play Again")
                    .font(.title)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            ConfettiCannon(counter: $confettiCounter, repetitions: 2, repetitionInterval: 0.5)
        }
        .onAppear {
            confettiCounter += 1 // for triggering confetti
        }
    }

    private func startGame() {
        score = 0
        timeRemaining = globalTimeRemaining
        gameState = .inGame
        confettiCounter = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 0.01
            } else {
                gameState = .endGame
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private func incrementScore() {
        score += 1
    }

    // private func resetGame() {
    //     gameState = .start
    // }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
