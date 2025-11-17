import SwiftUI
import Combine

extension String {
    func localized(_ locale: Locale) -> String {
        let translations: [String: [String: String]] = [
            "en": [
                "game_title": "Snakes & Ladders",
                "start_game": "Start Game",
                "roll_dice": "Roll Dice",
                "player_turn": "'s Turn",
                "winner": "Winner",
                "play_again": "Play Again",
                "game_history": "Game History",
                "player_name": "Player",
                "board_size": "Board Size",
                "players_count": "Players",
                "game_duration": "Duration",
                "date": "Date",
                "snakes_and_ladders": "Snakes and Ladders",
                "back": "Back",
                "done": "Done",
                "settings": "Settings",
                "language": "Language",
                "english": "English",
                "russian": "Russian",
                "no_games_played": "No games played yet",
                "play_game_to_see_history": "Play a game to see history here",
                "snake": "Snake!",
                "ladder": "Ladder!",
                "current_turn": "Current Turn",
                "position": "Position"
            ],
            "ru": [
                "game_title": "Змеи и Лестницы",
                "start_game": "Начать Игру",
                "roll_dice": "Бросить Кубик",
                "player_turn": "ходит",
                "winner": "Победитель",
                "play_again": "Играть Снова",
                "game_history": "История Игр",
                "player_name": "Игрок",
                "board_size": "Размер поля",
                "players_count": "Игроки",
                "game_duration": "Продолжительность",
                "date": "Дата",
                "snakes_and_ladders": "Змеи и Лестницы",
                "back": "Назад",
                "done": "Готово",
                "settings": "Настройки",
                "language": "Язык",
                "english": "Английский",
                "russian": "Русский",
                "no_games_played": "Пока нет сыгранных игр",
                "play_game_to_see_history": "Сыграйте в игру, чтобы увидеть историю",
                "snake": "Змея!",
                "ladder": "Лестница!",
                "current_turn": "Текущий ход",
                "position": "Позиция"
            ]
        ]
        
        let languageCode = locale.identifier.prefix(2)
        return translations[String(languageCode)]?[self] ?? self
    }
}

class LocalizationManager: ObservableObject {
    @Published var currentLocale: Locale = .current
    
    func setLocale(_ locale: Locale) {
        currentLocale = locale
    }
}

struct LocalizedStrings {
    static func localizedString(_ key: String, locale: Locale) -> String {
        key.localized(locale)
    }
    
    // Computed properties that use current locale
    static func gameTitle(_ locale: Locale) -> String { localizedString("game_title", locale: locale) }
    static func startGame(_ locale: Locale) -> String { localizedString("start_game", locale: locale) }
    static func rollDice(_ locale: Locale) -> String { localizedString("roll_dice", locale: locale) }
    static func playerTurn(_ locale: Locale) -> String { localizedString("player_turn", locale: locale) }
    static func winner(_ locale: Locale) -> String { localizedString("winner", locale: locale) }
    static func playAgain(_ locale: Locale) -> String { localizedString("play_again", locale: locale) }
    static func gameHistory(_ locale: Locale) -> String { localizedString("game_history", locale: locale) }
    static func playerName(_ locale: Locale) -> String { localizedString("player_name", locale: locale) }
    static func boardSize(_ locale: Locale) -> String { localizedString("board_size", locale: locale) }
    static func playersCount(_ locale: Locale) -> String { localizedString("players_count", locale: locale) }
    static func gameDuration(_ locale: Locale) -> String { localizedString("game_duration", locale: locale) }
    static func date(_ locale: Locale) -> String { localizedString("date", locale: locale) }
    static func snakesAndLadders(_ locale: Locale) -> String { localizedString("snakes_and_ladders", locale: locale) }
    static func back(_ locale: Locale) -> String { localizedString("back", locale: locale) }
    static func done(_ locale: Locale) -> String { localizedString("done", locale: locale) }
    static func settings(_ locale: Locale) -> String { localizedString("settings", locale: locale) }
    static func language(_ locale: Locale) -> String { localizedString("language", locale: locale) }
    static func english(_ locale: Locale) -> String { localizedString("english", locale: locale) }
    static func russian(_ locale: Locale) -> String { localizedString("russian", locale: locale) }
    static func noGamesPlayed(_ locale: Locale) -> String { localizedString("no_games_played", locale: locale) }
    static func playGameToSeeHistory(_ locale: Locale) -> String { localizedString("play_game_to_see_history", locale: locale) }
    static func snake(_ locale: Locale) -> String { localizedString("snake", locale: locale) }
    static func ladder(_ locale: Locale) -> String { localizedString("ladder", locale: locale) }
    static func currentTurn(_ locale: Locale) -> String { localizedString("current_turn", locale: locale) }
    static func position(_ locale: Locale) -> String { localizedString("position", locale: locale) }
}

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
    let id = UUID()
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
        let size = 100 // 10x10 board
        let edge = Int(sqrt(Double(size)))
        
        var snakes: [Snake] = []
        var ladders: [Ladder] = []
        
        // Generate 5-8 snakes
        let snakeCount = Int.random(in: 5...8)
        for _ in 0..<snakeCount {
            let head = Int.random(in: (edge * 2)...(size - 2))
            let tail = Int.random(in: 1...(head - edge))
            snakes.append(Snake(head: head, tail: tail))
        }
        
        // Generate 5-8 ladders
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
        
        // Dice rolling animation
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
            // Player wins
            players[currentPlayerIndex].position = gameBoard.size - 1
            endGame()
        } else {
            players[currentPlayerIndex].position = newPosition
            gameState = .moving
            moveAnimation = true
            
            // Check for snakes and ladders after move animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkSpecialCells()
            }
        }
    }
    
    private func checkSpecialCells() {
        let currentPosition = players[currentPlayerIndex].position
        
        // Check for snakes
        if let snake = gameBoard.snakes.first(where: { $0.head == currentPosition }) {
            showSnakeAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.players[self.currentPlayerIndex].position = snake.tail
                self.showSnakeAnimation = false
                self.nextTurn()
            }
            return
        }
        
        // Check for ladders
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

struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    @StateObject private var localizationManager = LocalizationManager()
    @State private var showingSetup = true
    @State private var playerNames: [String] = ["", "", "", "", "", ""]
    @State private var showingHistory = false
    @State private var showingSettings = false
    
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
                        },
                        localizationManager: localizationManager
                    )
                } else {
                    GameView(gameManager: gameManager, localizationManager: localizationManager)
                }
            }
            .navigationTitle(LocalizedStrings.gameTitle(localizationManager.currentLocale))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showingSetup {
                        HStack {
                            Button(LocalizedStrings.gameHistory(localizationManager.currentLocale)) {
                                showingHistory = true
                            }
                            Button(LocalizedStrings.settings(localizationManager.currentLocale)) {
                                showingSettings = true
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showingSetup {
                        Button(LocalizedStrings.back(localizationManager.currentLocale)) {
                            showingSetup = true
                            gameManager.resetGame()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                GameHistoryView(gameManager: gameManager, localizationManager: localizationManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(localizationManager: localizationManager)
            }
        }
    }
}

struct GameSetupView: View {
    @Binding var playerNames: [String]
    let onStart: () -> Void
    @ObservedObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStrings.snakesAndLadders(localizationManager.currentLocale))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("2-6 \(LocalizedStrings.playersCount(localizationManager.currentLocale))")
                .font(.title2)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(0..<6, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text("\(LocalizedStrings.playerName(localizationManager.currentLocale)) \(index + 1)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("\(LocalizedStrings.playerName(localizationManager.currentLocale)) \(index + 1)", text: $playerNames[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .padding()
            
            Button(action: onStart) {
                Text(LocalizedStrings.startGame(localizationManager.currentLocale))
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
    @ObservedObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Current player info
            if gameManager.gameState != .gameOver {
                VStack {
                    Text(LocalizedStrings.currentTurn(localizationManager.currentLocale))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(gameManager.currentPlayer.name) \(LocalizedStrings.playerTurn(localizationManager.currentLocale))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gameManager.currentPlayer.color)
                }
            }
            
            // Game board
            BoardView(gameManager: gameManager)
                .padding()
            
            // Player info and controls
            VStack(spacing: 15) {
                if gameManager.gameState == .gameOver, let winner = gameManager.winner {
                    VStack {
                        Text("🎉 \(LocalizedStrings.winner(localizationManager.currentLocale))!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(winner.color)
                        
                        Text(winner.name)
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        Button(LocalizedStrings.playAgain(localizationManager.currentLocale)) {
                            gameManager.resetGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    HStack {
                        ForEach(gameManager.players) { player in
                            PlayerIndicatorView(
                                player: player,
                                isCurrent: player.id == gameManager.currentPlayer.id,
                                localizationManager: localizationManager
                            )
                        }
                    }
                    
                    DiceView(
                        value: gameManager.diceValue,
                        isRolling: gameManager.isRollingDice
                    )
                    
                    Button(action: gameManager.rollDice) {
                        Text(LocalizedStrings.rollDice(localizationManager.currentLocale))
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
                SnakeAnimationView(localizationManager: localizationManager)
            }
            
            if gameManager.showLadderAnimation {
                LadderAnimationView(localizationManager: localizationManager)
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
    @ObservedObject var localizationManager: LocalizationManager
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(player.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.caption)
                    .fontWeight(isCurrent ? .bold : .regular)
                Text("\(LocalizedStrings.position(localizationManager.currentLocale)): \(player.position + 1)")
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

// MARK: - Animation Views
struct SnakeAnimationView: View {
    @ObservedObject var localizationManager: LocalizationManager
    @State private var scale = 0.1
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                Text("🐍")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                
                Text(LocalizedStrings.snake(localizationManager.currentLocale))
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
    @ObservedObject var localizationManager: LocalizationManager
    @State private var scale = 0.1
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                Text("🪜")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                
                Text(LocalizedStrings.ladder(localizationManager.currentLocale))
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
    @ObservedObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if gameManager.gameHistory.isEmpty {
                    VStack {
                        Text(LocalizedStrings.noGamesPlayed(localizationManager.currentLocale))
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.playGameToSeeHistory(localizationManager.currentLocale))
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
                                Text("\(result.players) \(LocalizedStrings.playersCount(localizationManager.currentLocale))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("\(LocalizedStrings.boardSize(localizationManager.currentLocale)): \(result.boardSize)")
                                    .font(.caption)
                                Spacer()
                                Text("\(LocalizedStrings.gameDuration(localizationManager.currentLocale)): \(String(format: "%.1fs", result.duration))")
                                    .font(.caption)
                            }
                            
                            Text("\(LocalizedStrings.date(localizationManager.currentLocale)): \(result.date, style: .date)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(LocalizedStrings.gameHistory(localizationManager.currentLocale))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.done(localizationManager.currentLocale)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedStrings.language(localizationManager.currentLocale))) {
                    Button(action: {
                        localizationManager.setLocale(Locale(identifier: "en"))
                    }) {
                        HStack {
                            Text(LocalizedStrings.english(localizationManager.currentLocale))
                            Spacer()
                            if localizationManager.currentLocale.identifier == "en" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Button(action: {
                        localizationManager.setLocale(Locale(identifier: "ru"))
                    }) {
                        HStack {
                            Text(LocalizedStrings.russian(localizationManager.currentLocale))
                            Spacer()
                            if localizationManager.currentLocale.identifier == "ru" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStrings.settings(localizationManager.currentLocale))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.done(localizationManager.currentLocale)) {
                        dismiss()
                    }
                }
            }
        }
    }
}
