import SwiftUI
import Combine

struct Player: Identifiable {
    let id: Int
    var position: Int
    let color: Color
    var name: String
    
    init(id: Int, color: Color, name: String) {
        self.id = id
        self.position = 0
        self.color = color
        self.name = name
    }
}

struct Snake {
    let head: Int
    let tail: Int
}

struct Ladder {
    let bottom: Int
    let top: Int
}

struct GameBoard {
    let size: Int
    let snakes: [Snake]
    let ladders: [Ladder]
    
    var edge: Int {
        Int(sqrt(Double(size)))
    }
}

struct GameResult: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let winner: String
    let players: Int
    let boardSize: Int
    let duration: TimeInterval
}

class GameManager: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayerIndex = 0
    @Published var diceValue = 0
    @Published var isRollingDice = false
    @Published var gameState: GameState = .waiting
    @Published var gameBoard: GameBoard
    @Published var moveAnimation = false
    @Published var showSnakeAnimation = false
    @Published var showLadderAnimation = false
    @Published var gameHistory: [GameResult] = []
    
    private var startTime: Date?
    private var timer: Timer?
    
    enum GameState {
        case waiting, rolling, moving, gameOver
    }
    
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }
    
    var winner: Player? {
        players.first { $0.position >= gameBoard.size - 1 }
    }
    
    init() {
        self.gameBoard = GameManager.generateRandomBoard()
        loadGameHistory()
    }
    
    static func generateRandomBoard() -> GameBoard {
        let size = 25
        let edge = Int(sqrt(Double(size)))
        
        var snakes: [Snake] = []
        var ladders: [Ladder] = []
        
        let snakeCount = Int.random(in: 5...8)
        for _ in 0..<snakeCount {
            let head = Int.random(in: (edge * 2)...(size - 2))
            let tail = Int.random(in: 1...(head - edge))
            snakes.append(Snake(head: head, tail: tail))
        }
        
        let ladderCount = Int.random(in: 5...8)
        for _ in 0..<ladderCount {
            let bottom = Int.random(in: 1...(size - edge * 2))
            let top = Int.random(in: (bottom + edge)...(size - 1))
            ladders.append(Ladder(bottom: bottom, top: top))
        }
        
        return GameBoard(size: size, snakes: snakes, ladders: ladders)
    }
    
    func startGame(playerNames: [String]) {
        players = playerNames.enumerated().map { index, name in
            let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
            return Player(id: index, color: colors[index], name: name)
        }
        currentPlayerIndex = 0
        gameState = .waiting
        startTime = Date()
    }
    
    func rollDice() {
        guard gameState == .waiting else { return }
        
        gameState = .rolling
        isRollingDice = true
        diceValue = 0
        
        var rollCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            rollCount += 1
            self.diceValue = Int.random(in: 1...6)
            
            if rollCount >= 8 {
                timer.invalidate()
                self.isRollingDice = false
                self.processMove()
            }
        }
    }
    
    private func processMove() {
        let newPosition = players[currentPlayerIndex].position + diceValue
        
        if newPosition >= gameBoard.size - 1 {
            players[currentPlayerIndex].position = gameBoard.size - 1
            endGame()
        } else {
            players[currentPlayerIndex].position = newPosition
            gameState = .moving
            moveAnimation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkSpecialCells()
            }
        }
    }
    
    private func checkSpecialCells() {
        let currentPosition = players[currentPlayerIndex].position
        
        if let snake = gameBoard.snakes.first(where: { $0.head == currentPosition }) {
            showSnakeAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.players[self.currentPlayerIndex].position = snake.tail
                self.showSnakeAnimation = false
                self.nextTurn()
            }
            return
        }
        
        if let ladder = gameBoard.ladders.first(where: { $0.bottom == currentPosition }) {
            showLadderAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.players[self.currentPlayerIndex].position = ladder.top
                self.showLadderAnimation = false
                self.nextTurn()
            }
            return
        }
        
        nextTurn()
    }
    
    private func nextTurn() {
        moveAnimation = false
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        gameState = .waiting
    }
    
    private func endGame() {
        gameState = .gameOver
        saveGameResult()
    }
    
    func resetGame() {
        for i in 0..<players.count {
            players[i].position = 0
        }
        currentPlayerIndex = 0
        gameState = .waiting
        diceValue = 0
        gameBoard = GameManager.generateRandomBoard()
    }
    
    private func saveGameResult() {
        guard let startTime = startTime, let winner = winner else { return }
        
        let result = GameResult(
            date: Date(),
            winner: winner.name,
            players: players.count,
            boardSize: gameBoard.size,
            duration: Date().timeIntervalSince(startTime)
        )
        
        gameHistory.insert(result, at: 0)
        
        if let encoded = try? JSONEncoder().encode(gameHistory) {
            UserDefaults.standard.set(encoded, forKey: "gameHistory")
        }
    }
    
    private func loadGameHistory() {
        guard let data = UserDefaults.standard.data(forKey: "gameHistory"),
              let history = try? JSONDecoder().decode([GameResult].self, from: data) else { return }
        gameHistory = history
    }
}

struct LocalizedStrings {
    static func localizedString(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
    
    static let startGame = localizedString("Начать игру")
    static let rollDice = localizedString("Сделать ход")
    static let playerTurn = localizedString("player_turn")
    static let winner = localizedString("Победил")
    static let playAgain = localizedString("Играть снова")
    static let gameHistory = localizedString("История")
    static let playerName = localizedString("Имя")
    static let boardSize = localizedString("Размер карты")
    static let playersCount = localizedString("количество игроков")
    static let date = localizedString("date")
    static let snakesAndLadders = localizedString("Змеи и лестницы")
}

struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    @State private var showingSetup = true
    @State private var playerNames: [String] = ["", "", "", "", "", ""]
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showingSetup {
                    GameSetupView(
                        playerNames: $playerNames,
                        onStart: {
                            let validNames = playerNames.prefix(6).filter { !$0.isEmpty }
                            if validNames.count >= 2 {
                                gameManager.startGame(playerNames: validNames)
                                showingSetup = false
                            }
                        }
                    )
                } else {
                    GameView(gameManager: gameManager)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showingSetup {
                        Button(LocalizedStrings.gameHistory) {
                            showingHistory = true
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showingSetup {
                        Button("Back") {
                            showingSetup = true
                            gameManager.resetGame()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                GameHistoryView(gameManager: gameManager)
            }
        }
    }
}

struct GameSetupView: View {
    @Binding var playerNames: [String]
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStrings.snakesAndLadders)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("2-6 \(LocalizedStrings.playersCount)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(0..<6, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text("\(LocalizedStrings.playerName) \(index + 1)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Player \(index + 1)", text: $playerNames[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .padding()
            
            Button(action: onStart) {
                Text(LocalizedStrings.startGame)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(playerNames.filter { !$0.isEmpty }.count < 2)
            
            Spacer()
        }
        .padding()
    }
}

struct GameView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 20) {
            BoardView(gameManager: gameManager)
                .padding()
            
            VStack(spacing: 15) {
                if gameManager.gameState == .gameOver, let winner = gameManager.winner {
                    VStack {
                        Text("🎉 \(LocalizedStrings.winner)!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(winner.color)
                        
                        Text(winner.name)
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        Button(LocalizedStrings.playAgain) {
                            gameManager.resetGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    HStack {
                        ForEach(gameManager.players) { player in
                            PlayerIndicatorView(
                                player: player,
                                isCurrent: player.id == gameManager.currentPlayer.id
                            )
                        }
                    }
                    
                    DiceView(
                        value: gameManager.diceValue,
                        isRolling: gameManager.isRollingDice
                    )
                    
                    Button(action: gameManager.rollDice) {
                        Text(LocalizedStrings.rollDice)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                gameManager.gameState == .waiting ? Color.blue : Color.gray
                            )
                            .cornerRadius(12)
                    }
                    .disabled(gameManager.gameState != .waiting)
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .overlay {
            if gameManager.showSnakeAnimation {
                SnakeAnimationView()
            }
            
            if gameManager.showLadderAnimation {
                LadderAnimationView()
            }
        }
    }
}

struct BoardView: View {
    @ObservedObject var gameManager: GameManager
    let board: GameBoard
    
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.board = gameManager.gameBoard
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<board.edge, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<board.edge, id: \.self) { column in
                        let cellNumber = calculateCellNumber(row: row, column: column)
                        CellView(
                            number: cellNumber,
                            players: gameManager.players.filter { $0.position == cellNumber },
                            snakes: board.snakes,
                            ladders: board.ladders,
                            isWinCell: cellNumber == board.size - 1
                        )
                    }
                }
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func calculateCellNumber(row: Int, column: Int) -> Int {
        if row % 2 == 0 {
            return (board.edge - row - 1) * board.edge + column
        } else {
            return (board.edge - row - 1) * board.edge + (board.edge - column - 1)
        }
    }
}

struct CellView: View {
    let number: Int
    let players: [Player]
    let snakes: [Snake]
    let ladders: [Ladder]
    let isWinCell: Bool
    
    private var hasSnake: Bool {
        snakes.contains { $0.head == number }
    }
    
    private var hasLadder: Bool {
        ladders.contains { $0.bottom == number }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            
            VStack(spacing: 2) {
                if isWinCell {
                    Text("🏁")
                        .font(.title2)
                } else if hasSnake {
                    Text("🐍")
                        .font(.caption)
                } else if hasLadder {
                    Text("🪜")
                        .font(.caption)
                } else {
                    Text("\(number + 1)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if !players.isEmpty {
                    HStack(spacing: 1) {
                        ForEach(players.prefix(3)) { player in
                            Circle()
                                .fill(player.color)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(2)
        }
        .frame(width: 30, height: 30)
    }
    
    private var backgroundColor: Color {
        if isWinCell { return Color.green.opacity(0.3) }
        if hasSnake { return Color.red.opacity(0.2) }
        if hasLadder { return Color.green.opacity(0.2) }
        return Color.white
    }
}

struct PlayerIndicatorView: View {
    let player: Player
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(player.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.caption)
                    .fontWeight(isCurrent ? .bold : .regular)
                Text("\(player.position + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(isCurrent ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isCurrent ? player.color : Color.clear, lineWidth: 2)
        )
    }
}

struct DiceView: View {
    let value: Int
    let isRolling: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .shadow(radius: 5)
            
            if isRolling {
                Text("🎲")
                    .font(.title)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 0.1).repeatCount(5), value: isRolling)
            } else {
                Text("\(value)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .rotationEffect(.degrees(isRolling ? 360 : 0))
        .animation(isRolling ? .easeInOut(duration: 0.5).repeatCount(5) : .default, value: isRolling)
    }
}

struct SnakeAnimationView: View {
    @State private var scale = 0.1
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                Text("🐍")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                
                Text("Змея!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
            }
        }
    }
}

struct LadderAnimationView: View {
    @State private var scale = 0.1
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                Text("🪜")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                
                Text("Лестница!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
            }
        }
    }
}

struct GameHistoryView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if gameManager.gameHistory.isEmpty {
                    VStack {
                        Text("No games played yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Play a game to see history here")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(gameManager.gameHistory) { result in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(result.winner)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(result.players) players")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("\(LocalizedStrings.boardSize): \(result.boardSize)")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.1fs", result.duration))
                                    .font(.caption)
                            }
                            
                            Text(result.date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(LocalizedStrings.gameHistory)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
