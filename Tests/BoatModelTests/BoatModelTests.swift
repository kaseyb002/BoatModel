import Foundation
import Testing
@testable import BoatModel

@Test func initialState() throws {
    let round: Round = try .init(
        players: [
            .fake(id: "p1", name: "Player 1"),
            .fake(id: "p2", name: "Player 2"),
        ]
    )
    #expect(round.dice.count == 5)
    #expect(round.rollsRemaining == 3)
    #expect(round.currentPlayerID == "p1")
    #expect(round.turnPhase == .needsToRoll)
    #expect(round.isComplete == false)
    #expect(round.players.count == 2)
    for player in round.players {
        #expect(player.scorecard.scores.isEmpty)
    }
}

@Test func playerCountValidation() throws {
    #expect(throws: BoatError.notEnoughPlayers) {
        _ = try Round(players: [.fake()])
    }
    #expect(throws: BoatError.tooManyPlayers) {
        _ = try Round(players: (0 ..< 7).map { .fake(id: "\($0)") })
    }
    _ = try Round(players: [.fake(id: "a"), .fake(id: "b")])
    _ = try Round(players: (0 ..< 6).map { .fake(id: "\($0)") })
}

@Test func rollDice() throws {
    let cookedRolls: [DieValue] = [.three, .five, .two, .six, .one]
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    #expect(round.dice.map(\.value) == [.three, .five, .two, .six, .one])
    #expect(round.rollsRemaining == 2)
    #expect(round.turnPhase == .canRollOrScore)
}

@Test func cannotKeepDiceOnFirstRoll() throws {
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")]
    )
    #expect(throws: BoatError.cannotKeepDiceOnFirstRoll) {
        try round.rollDice(keeping: [0, 1])
    }
}

@Test func keepDiceOnReroll() throws {
    let cookedRolls: [DieValue] = [
        // First roll: all dice
        .three, .three, .three, .two, .one,
        // Second roll: only dice 3 and 4 re-rolled
        .four, .five,
    ]
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    #expect(round.dice.map(\.value) == [.three, .three, .three, .two, .one])

    try round.rollDice(keeping: [0, 1, 2])
    #expect(round.dice[0].value == .three)
    #expect(round.dice[1].value == .three)
    #expect(round.dice[2].value == .three)
    #expect(round.dice[3].value == .four)
    #expect(round.dice[4].value == .five)
    #expect(round.rollsRemaining == 1)
}

@Test func cannotRollAfterThreeRolls() throws {
    let cookedRolls: [DieValue] = Array(repeating: DieValue.one, count: 15)
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    try round.rollDice(keeping: [])
    try round.rollDice(keeping: [])
    #expect(round.rollsRemaining == 0)
    #expect(round.turnPhase == .mustScore)
    #expect(throws: BoatError.cannotRollInCurrentState) {
        try round.rollDice(keeping: [])
    }
}

@Test func cannotScoreBeforeRolling() throws {
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")]
    )
    #expect(throws: BoatError.cannotScoreInCurrentState) {
        try round.score(category: .ones)
    }
}

@Test func scoreCategory() throws {
    let cookedRolls: [DieValue] = [.three, .three, .three, .six, .six]
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    try round.score(category: .fullHouse)
    #expect(round.players[0].scorecard.scores[.fullHouse] == 25)
    #expect(round.currentPlayerID == "p2")
    #expect(round.turnPhase == .needsToRoll)
    #expect(round.rollsRemaining == 3)
}

@Test func cannotScoreSameCategoryTwice() throws {
    let cookedRolls: [DieValue] = Array(repeating: DieValue.one, count: 15)
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    try round.score(category: .ones)

    try round.rollDice()
    try round.score(category: .ones)

    try round.rollDice()
    #expect(throws: BoatError.categoryAlreadyScored) {
        try round.score(category: .ones)
    }
}

// MARK: - Scoring Calculations

@Test func upperSectionScoring() throws {
    let dice: [Die] = [
        .init(id: 0, value: .three),
        .init(id: 1, value: .three),
        .init(id: 2, value: .three),
        .init(id: 3, value: .five),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: dice, for: .ones) == 0)
    #expect(Round.calculateScore(dice: dice, for: .threes) == 9)
    #expect(Round.calculateScore(dice: dice, for: .fives) == 5)
    #expect(Round.calculateScore(dice: dice, for: .sixes) == 6)
}

@Test func threeOfAKindScoring() throws {
    let dice: [Die] = [
        .init(id: 0, value: .four),
        .init(id: 1, value: .four),
        .init(id: 2, value: .four),
        .init(id: 3, value: .two),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: dice, for: .threeOfAKind) == 20)

    let nope: [Die] = [
        .init(id: 0, value: .one),
        .init(id: 1, value: .two),
        .init(id: 2, value: .three),
        .init(id: 3, value: .four),
        .init(id: 4, value: .five),
    ]
    #expect(Round.calculateScore(dice: nope, for: .threeOfAKind) == 0)
}

@Test func fourOfAKindScoring() throws {
    let dice: [Die] = [
        .init(id: 0, value: .five),
        .init(id: 1, value: .five),
        .init(id: 2, value: .five),
        .init(id: 3, value: .five),
        .init(id: 4, value: .three),
    ]
    #expect(Round.calculateScore(dice: dice, for: .fourOfAKind) == 23)
    #expect(Round.calculateScore(dice: dice, for: .threeOfAKind) == 23)

    let nope: [Die] = [
        .init(id: 0, value: .five),
        .init(id: 1, value: .five),
        .init(id: 2, value: .five),
        .init(id: 3, value: .three),
        .init(id: 4, value: .three),
    ]
    #expect(Round.calculateScore(dice: nope, for: .fourOfAKind) == 0)
}

@Test func fullHouseScoring() throws {
    let valid: [Die] = [
        .init(id: 0, value: .three),
        .init(id: 1, value: .three),
        .init(id: 2, value: .three),
        .init(id: 3, value: .six),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: valid, for: .fullHouse) == 25)

    // Five of a kind is NOT a full house (without joker)
    let fiveOfKind: [Die] = [
        .init(id: 0, value: .four),
        .init(id: 1, value: .four),
        .init(id: 2, value: .four),
        .init(id: 3, value: .four),
        .init(id: 4, value: .four),
    ]
    #expect(Round.calculateScore(dice: fiveOfKind, for: .fullHouse) == 0)

    // With joker, five of a kind scores as full house
    #expect(Round.calculateScore(dice: fiveOfKind, for: .fullHouse, isJoker: true) == 25)
}

@Test func smallStraightScoring() throws {
    let valid1: [Die] = [
        .init(id: 0, value: .one),
        .init(id: 1, value: .two),
        .init(id: 2, value: .three),
        .init(id: 3, value: .four),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: valid1, for: .smallStraight) == 30)

    let valid2: [Die] = [
        .init(id: 0, value: .two),
        .init(id: 1, value: .three),
        .init(id: 2, value: .four),
        .init(id: 3, value: .five),
        .init(id: 4, value: .five),
    ]
    #expect(Round.calculateScore(dice: valid2, for: .smallStraight) == 30)

    let valid3: [Die] = [
        .init(id: 0, value: .three),
        .init(id: 1, value: .four),
        .init(id: 2, value: .five),
        .init(id: 3, value: .six),
        .init(id: 4, value: .one),
    ]
    #expect(Round.calculateScore(dice: valid3, for: .smallStraight) == 30)

    let nope: [Die] = [
        .init(id: 0, value: .one),
        .init(id: 1, value: .two),
        .init(id: 2, value: .three),
        .init(id: 3, value: .five),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: nope, for: .smallStraight) == 0)
}

@Test func largeStraightScoring() throws {
    let valid1: [Die] = [
        .init(id: 0, value: .one),
        .init(id: 1, value: .two),
        .init(id: 2, value: .three),
        .init(id: 3, value: .four),
        .init(id: 4, value: .five),
    ]
    #expect(Round.calculateScore(dice: valid1, for: .largeStraight) == 40)
    #expect(Round.calculateScore(dice: valid1, for: .smallStraight) == 30)

    let valid2: [Die] = [
        .init(id: 0, value: .two),
        .init(id: 1, value: .three),
        .init(id: 2, value: .four),
        .init(id: 3, value: .five),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: valid2, for: .largeStraight) == 40)

    let nope: [Die] = [
        .init(id: 0, value: .one),
        .init(id: 1, value: .two),
        .init(id: 2, value: .three),
        .init(id: 3, value: .four),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: nope, for: .largeStraight) == 0)
}

@Test func boatScoring() throws {
    let valid: [Die] = [
        .init(id: 0, value: .six),
        .init(id: 1, value: .six),
        .init(id: 2, value: .six),
        .init(id: 3, value: .six),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: valid, for: .boat) == 50)
    #expect(Round.calculateScore(dice: valid, for: .threeOfAKind) == 30)
    #expect(Round.calculateScore(dice: valid, for: .fourOfAKind) == 30)
    #expect(Round.calculateScore(dice: valid, for: .sixes) == 30)

    let nope: [Die] = [
        .init(id: 0, value: .six),
        .init(id: 1, value: .six),
        .init(id: 2, value: .six),
        .init(id: 3, value: .six),
        .init(id: 4, value: .five),
    ]
    #expect(Round.calculateScore(dice: nope, for: .boat) == 0)
}

@Test func chanceScoring() throws {
    let dice: [Die] = [
        .init(id: 0, value: .one),
        .init(id: 1, value: .three),
        .init(id: 2, value: .four),
        .init(id: 3, value: .five),
        .init(id: 4, value: .six),
    ]
    #expect(Round.calculateScore(dice: dice, for: .chance) == 19)
}

@Test func jokerStraightScoring() throws {
    let fiveOfKind: [Die] = [
        .init(id: 0, value: .three),
        .init(id: 1, value: .three),
        .init(id: 2, value: .three),
        .init(id: 3, value: .three),
        .init(id: 4, value: .three),
    ]
    #expect(Round.calculateScore(dice: fiveOfKind, for: .smallStraight, isJoker: true) == 30)
    #expect(Round.calculateScore(dice: fiveOfKind, for: .largeStraight, isJoker: true) == 40)
}

// MARK: - Scorecard

@Test func upperBonus() throws {
    var scorecard: Scorecard = .init()
    scorecard.scores[.ones] = 3
    scorecard.scores[.twos] = 6
    scorecard.scores[.threes] = 9
    scorecard.scores[.fours] = 12
    scorecard.scores[.fives] = 15
    scorecard.scores[.sixes] = 18
    #expect(scorecard.upperSectionTotal == 63)
    #expect(scorecard.upperBonus == 35)
}

@Test func noUpperBonus() throws {
    var scorecard: Scorecard = .init()
    scorecard.scores[.ones] = 2
    scorecard.scores[.twos] = 6
    scorecard.scores[.threes] = 9
    scorecard.scores[.fours] = 12
    scorecard.scores[.fives] = 15
    scorecard.scores[.sixes] = 18
    #expect(scorecard.upperSectionTotal == 62)
    #expect(scorecard.upperBonus == 0)
}

@Test func grandTotal() throws {
    var scorecard: Scorecard = .init()
    scorecard.scores[.ones] = 3
    scorecard.scores[.twos] = 6
    scorecard.scores[.threes] = 9
    scorecard.scores[.fours] = 12
    scorecard.scores[.fives] = 15
    scorecard.scores[.sixes] = 18
    scorecard.scores[.threeOfAKind] = 20
    scorecard.scores[.fourOfAKind] = 25
    scorecard.scores[.fullHouse] = 25
    scorecard.scores[.smallStraight] = 30
    scorecard.scores[.largeStraight] = 40
    scorecard.scores[.chance] = 22
    scorecard.scores[.boat] = 50
    #expect(scorecard.isComplete)
    #expect(scorecard.grandTotal == 63 + 35 + 212)
}

@Test func boatBonusInScorecard() throws {
    var scorecard: Scorecard = .init()
    scorecard.scores[.boat] = 50
    scorecard.boatBonusCount = 2
    #expect(scorecard.boatBonus == 200)
    #expect(scorecard.grandTotal == 50 + 200)
}

// MARK: - Joker Rules

@Test func jokerForcesMatchingUpper() throws {
    let cookedRolls: [DieValue] = [
        // P1 turn 1: boat (score as boat)
        .four, .four, .four, .four, .four,
        // P2 turn 1
        .one, .two, .three, .four, .five,
        // P1 turn 2: another boat with 4s → joker, must score fours
        .four, .four, .four, .four, .four,
    ]
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )

    try round.rollDice()
    try round.score(category: .boat)
    #expect(round.players[0].scorecard.scores[.boat] == 50)

    try round.rollDice()
    try round.score(category: .largeStraight)

    try round.rollDice()
    let available: [ScoreCategory] = round.availableCategories(for: "p1")
    #expect(available == [.fours])
    try round.score(category: .fours)
    #expect(round.players[0].scorecard.scores[.fours] == 20)
    #expect(round.players[0].scorecard.boatBonusCount == 1)
}

@Test func jokerFallsToLowerWhenUpperFilled() throws {
    var player: Player = .fake(id: "p1")
    player.scorecard.scores[.boat] = 50
    player.scorecard.scores[.threes] = 9

    let cookedRolls: [DieValue] = [
        .three, .three, .three, .three, .three,
        // P2 rolls
        .one, .one, .one, .one, .one,
    ]
    var round: Round = try .init(
        players: [player, .fake(id: "p2")],
        cookedRolls: cookedRolls
    )

    try round.rollDice()
    let available: [ScoreCategory] = round.availableCategories(for: "p1")
    for cat in available {
        #expect(cat.isLowerSection)
    }
    #expect(!available.contains(.boat))
}

@Test func noBoatBonusWhenScoredZero() throws {
    var player: Player = .fake(id: "p1")
    player.scorecard.scores[.boat] = 0
    player.scorecard.scores[.fours] = 12

    let cookedRolls: [DieValue] = [
        .four, .four, .four, .four, .four,
        .one, .one, .one, .one, .one,
    ]
    var round: Round = try .init(
        players: [player, .fake(id: "p2")],
        cookedRolls: cookedRolls
    )

    try round.rollDice()
    let available: [ScoreCategory] = round.availableCategories(for: "p1")
    #expect(!available.contains(.fours))
    #expect(!available.contains(.boat))

    try round.score(category: available.first!)
    #expect(round.players[0].scorecard.boatBonusCount == 0)
}

// MARK: - Full Round Playthrough

@Test func playFullRound() throws {
    let cookedRolls: [DieValue] = [
        // Turn 1 (P1): fullHouse [3,3,3,6,6]
        .three, .three, .three, .six, .six,
        // Turn 2 (P2): fourOfAKind [4,4,4,4,2]
        .four, .four, .four, .four, .two,
        // Turn 3 (P1): largeStraight [1,2,3,4,5]
        .one, .two, .three, .four, .five,
        // Turn 4 (P2): largeStraight [2,3,4,5,6]
        .two, .three, .four, .five, .six,
        // Turn 5 (P1): ones [1,1,1,5,6]
        .one, .one, .one, .five, .six,
        // Turn 6 (P2): twos [2,2,2,3,4]
        .two, .two, .two, .three, .four,
        // Turn 7 (P1): threes [3,3,3,5,5]
        .three, .three, .three, .five, .five,
        // Turn 8 (P2): threes [3,3,3,1,5]
        .three, .three, .three, .one, .five,
        // Turn 9 (P1): boat [4,4,4,4,4]
        .four, .four, .four, .four, .four,
        // Turn 10 (P2): boat [1,1,1,1,1]
        .one, .one, .one, .one, .one,
        // Turn 11 (P1): fives [5,5,5,2,3]
        .five, .five, .five, .two, .three,
        // Turn 12 (P2): fours [4,4,4,1,6]
        .four, .four, .four, .one, .six,
        // Turn 13 (P1): sixes [6,6,6,1,2]
        .six, .six, .six, .one, .two,
        // Turn 14 (P2): sixes [6,6,6,6,3]
        .six, .six, .six, .six, .three,
        // Turn 15 (P1): fours [4,4,4,3,2]
        .four, .four, .four, .three, .two,
        // Turn 16 (P2): ones [1,1,1,2,6]
        .one, .one, .one, .two, .six,
        // Turn 17 (P1): twos [2,2,2,1,1]
        .two, .two, .two, .one, .one,
        // Turn 18 (P2): fives [5,5,5,1,2]
        .five, .five, .five, .one, .two,
        // Turn 19 (P1): smallStraight [1,2,3,4,6]
        .one, .two, .three, .four, .six,
        // Turn 20 (P2): smallStraight [1,2,3,4,5]
        .one, .two, .three, .four, .five,
        // Turn 21 (P1): chance [5,6,3,2,1]
        .five, .six, .three, .two, .one,
        // Turn 22 (P2): chance [6,5,4,3,2]
        .six, .five, .four, .three, .two,
        // Turn 23 (P1): fourOfAKind [6,6,6,6,1]
        .six, .six, .six, .six, .one,
        // Turn 24 (P2): threeOfAKind [5,5,5,2,3]
        .five, .five, .five, .two, .three,
        // Turn 25 (P1): threeOfAKind [5,5,5,2,1]
        .five, .five, .five, .two, .one,
        // Turn 26 (P2): fullHouse [2,2,3,3,3]
        .two, .two, .three, .three, .three,
    ]

    let p1Categories: [ScoreCategory] = [
        .fullHouse, .largeStraight, .ones, .threes, .boat,
        .fives, .sixes, .fours, .twos, .smallStraight,
        .chance, .fourOfAKind, .threeOfAKind,
    ]
    let p2Categories: [ScoreCategory] = [
        .fourOfAKind, .largeStraight, .twos, .threes, .boat,
        .fours, .sixes, .ones, .fives, .smallStraight,
        .chance, .threeOfAKind, .fullHouse,
    ]

    var round: Round = try .init(
        players: [
            .fake(id: "p1", name: "Player 1"),
            .fake(id: "p2", name: "Player 2"),
        ],
        cookedRolls: cookedRolls
    )

    for turn in 0 ..< 13 {
        #expect(round.currentPlayerID == "p1")
        try round.rollDice()
        try round.score(category: p1Categories[turn])

        #expect(round.currentPlayerID == "p2")
        try round.rollDice()
        try round.score(category: p2Categories[turn])
    }

    #expect(round.isComplete)

    // P1: upper 63 + bonus 35 + lower 205 = 303
    #expect(round.players[0].scorecard.upperSectionTotal == 63)
    #expect(round.players[0].scorecard.upperBonus == 35)
    #expect(round.players[0].scorecard.grandTotal == 303)

    // P2: upper 69 + bonus 35 + lower 203 = 307
    #expect(round.players[1].scorecard.upperSectionTotal == 69)
    #expect(round.players[1].scorecard.upperBonus == 35)
    #expect(round.players[1].scorecard.grandTotal == 307)

    #expect(round.winner?.id == "p2")
}

// MARK: - AI Engine

@Test func aiCanCompleteRound() throws {
    let engine: AIEngine = .init(difficulty: .medium)
    var round: Round = try .init(
        players: [
            .fake(id: "ai1", name: "AI One"),
            .fake(id: "ai2", name: "AI Two"),
        ]
    )

    var moveCount: Int = 0
    let maxMoves: Int = 1000
    while !round.isComplete && moveCount < maxMoves {
        round = engine.makeMove(round: round)
        moveCount += 1
    }

    #expect(round.isComplete)
    #expect(round.players[0].scorecard.isComplete)
    #expect(round.players[1].scorecard.isComplete)
    #expect(round.winner != nil)
}

@Test func aiEasyCanCompleteRound() throws {
    let engine: AIEngine = .init(difficulty: .easy)
    var round: Round = try .init(
        players: [
            .fake(id: "ai1", name: "AI Easy 1"),
            .fake(id: "ai2", name: "AI Easy 2"),
        ]
    )

    var moveCount: Int = 0
    let maxMoves: Int = 1000
    while !round.isComplete && moveCount < maxMoves {
        round = engine.makeMove(round: round)
        moveCount += 1
    }

    #expect(round.isComplete)
}

@Test func aiHardCanCompleteRound() throws {
    let engine: AIEngine = .init(difficulty: .hard)
    var round: Round = try .init(
        players: [
            .fake(id: "ai1", name: "AI Hard 1"),
            .fake(id: "ai2", name: "AI Hard 2"),
        ]
    )

    var moveCount: Int = 0
    let maxMoves: Int = 1000
    while !round.isComplete && moveCount < maxMoves {
        round = engine.makeMove(round: round)
        moveCount += 1
    }

    #expect(round.isComplete)
}

@Test func aiSixPlayerGame() throws {
    let engine: AIEngine = .init(difficulty: .medium)
    var round: Round = try .init(
        players: (1 ... 6).map { .fake(id: "p\($0)", name: "Player \($0)") }
    )

    var moveCount: Int = 0
    let maxMoves: Int = 5000
    while !round.isComplete && moveCount < maxMoves {
        round = engine.makeMove(round: round)
        moveCount += 1
    }

    #expect(round.isComplete)
    for player in round.players {
        #expect(player.scorecard.isComplete)
    }
}

// MARK: - Log

@Test func logTracksActions() throws {
    let cookedRolls: [DieValue] = [.one, .two, .three, .four, .five]
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    try round.score(category: .largeStraight)
    #expect(round.log.actions.count == 2)

    if case .roll(_, let result) = round.log.actions[0].decision {
        #expect(result == [.one, .two, .three, .four, .five])
    } else {
        Issue.record("Expected roll decision")
    }

    if case .score(let category, let points) = round.log.actions[1].decision {
        #expect(category == .largeStraight)
        #expect(points == 40)
    } else {
        Issue.record("Expected score decision")
    }
}

@Test func logCapsAtMaxActions() throws {
    var log: Round.Log = .init()
    for i in 0 ..< 150 {
        log.addAction(
            .init(
                playerID: "p1",
                decision: .score(category: .chance, points: i)
            )
        )
    }
    #expect(log.actions.count == 100)
}

// MARK: - Fakes

@Test func fakes() throws {
    let die: Die = .fake()
    #expect(die.id >= 0)

    let player: Player = .fake()
    #expect(!player.id.isEmpty)
    #expect(!player.name.isEmpty)

    let scorecard: Scorecard = .fake()
    #expect(scorecard.scores.isEmpty)

    let round: Round = try .fake()
    #expect(round.players.count == 2)
    #expect(!round.isComplete)
}

// MARK: - Codable

@Test func roundCodable() throws {
    let cookedRolls: [DieValue] = [.one, .two, .three, .four, .five]
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    try round.score(category: .largeStraight)

    let encoder: JSONEncoder = .init()
    encoder.dateEncodingStrategy = .iso8601
    let data: Data = try encoder.encode(round)

    let decoder: JSONDecoder = .init()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let decoded: Round = try decoder.decode(Round.self, from: data)

    #expect(decoded.players[0].scorecard.scores[.largeStraight] == 40)
    #expect(decoded.currentPlayerID == "p2")
    #expect(decoded.dice.count == 5)
}

// MARK: - Edge Cases

@Test func roundCompleteState() throws {
    let cookedRolls: [DieValue] = Array(repeating: DieValue.one, count: 200)
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )

    let allCategories: [ScoreCategory] = ScoreCategory.allCases
    for i in 0 ..< 13 {
        try round.rollDice()
        try round.score(category: allCategories[i])
        if i < 12 {
            try round.rollDice()
            try round.score(category: allCategories[i])
        }
    }
    // P2 scores last category
    try round.rollDice()
    try round.score(category: allCategories[12])

    #expect(round.isComplete)
    #expect(round.ended != nil)

    #expect(throws: BoatError.roundAlreadyComplete) {
        try round.rollDice()
    }
}

@Test func scorecardCompletion() throws {
    var scorecard: Scorecard = .init()
    #expect(!scorecard.isComplete)
    #expect(scorecard.unscoredCategories.count == 13)

    for category in ScoreCategory.allCases {
        scorecard.scores[category] = 0
    }
    #expect(scorecard.isComplete)
    #expect(scorecard.unscoredCategories.isEmpty)
}

@Test func invalidDieID() throws {
    let cookedRolls: [DieValue] = Array(repeating: DieValue.one, count: 10)
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    #expect(throws: BoatError.invalidDieID) {
        try round.rollDice(keeping: [99])
    }
}

@Test func scoreCategoryDisplayNames() throws {
    #expect(ScoreCategory.ones.displayableName == "Ones")
    #expect(ScoreCategory.threeOfAKind.displayableName == "Three of a Kind")
    #expect(ScoreCategory.fullHouse.displayableName == "Full House")
    #expect(ScoreCategory.smallStraight.displayableName == "Small Straight")
    #expect(ScoreCategory.largeStraight.displayableName == "Large Straight")
    #expect(ScoreCategory.boat.displayableName == "Boat")
}

@Test func dieValueDisplayNames() throws {
    #expect(DieValue.one.displayableName == "One")
    #expect(DieValue.six.displayableName == "Six")
}

@Test func scoreCategorySections() throws {
    #expect(ScoreCategory.upperSection.count == 6)
    #expect(ScoreCategory.lowerSection.count == 7)
    #expect(ScoreCategory.ones.isUpperSection)
    #expect(!ScoreCategory.ones.isLowerSection)
    #expect(ScoreCategory.boat.isLowerSection)
    #expect(!ScoreCategory.boat.isUpperSection)
}

@Test func upperCategoryForDieValue() throws {
    #expect(ScoreCategory.upperCategory(for: .one) == .ones)
    #expect(ScoreCategory.upperCategory(for: .two) == .twos)
    #expect(ScoreCategory.upperCategory(for: .three) == .threes)
    #expect(ScoreCategory.upperCategory(for: .four) == .fours)
    #expect(ScoreCategory.upperCategory(for: .five) == .fives)
    #expect(ScoreCategory.upperCategory(for: .six) == .sixes)
}

@Test func ruleOptionsClassic() throws {
    let options: RuleOptions = .classic
    #expect(options.forcedJokerRules == true)
    #expect(options.boatBonus == true)
}

@Test func aiDifficultyDisplayNames() throws {
    #expect(AIEngine.Difficulty.easy.displayableName == "Easy")
    #expect(AIEngine.Difficulty.medium.displayableName == "Medium")
    #expect(AIEngine.Difficulty.hard.displayableName == "Hard")
}

@Test func rerollWithSomeKept() throws {
    let cookedRolls: [DieValue] = [
        .six, .five, .four, .three, .two,
        .one, .one,
        .six, .six,
    ]
    var round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")],
        cookedRolls: cookedRolls
    )
    try round.rollDice()
    #expect(round.dice.map(\.value) == [.six, .five, .four, .three, .two])

    try round.rollDice(keeping: [0, 1, 2])
    #expect(round.dice[0].value == .six)
    #expect(round.dice[1].value == .five)
    #expect(round.dice[2].value == .four)
    #expect(round.dice[3].value == .one)
    #expect(round.dice[4].value == .one)

    try round.rollDice(keeping: [0, 1, 2, 3, 4])
    #expect(round.dice.map(\.value) == [.six, .five, .four, .one, .one])
    #expect(round.turnPhase == .mustScore)
}
