import DataFrames
import SQLite

Base.eval(:(have_color = true))

function gameFileSetup(gameFile, typeOfGame, cheating, time_limit, time_add)

    db= SQLite.DB(gameFile)

    SQLite.execute!(db,"create table meta(key,value);")

    if typeOfGame == "S"
        SQLite.execute!(db,"insert into meta values ('type','standard');")
    elseif typeOfGame == "M"
        SQLite.execute!(db,"insert into meta values ('type','mini');")
    elseif typeOfGame == "C"
        SQLite.execute!(db,"insert into meta values ('type','chu');")
    elseif typeOfGame == "T"
        SQLite.execute!(db,"insert into meta values ('type','ten');")
    end

    if cheating == "T"
        SQLite.execute!(db,"insert into meta values ('legality','cheating');")
    else
        SQLite.execute!(db,"insert into meta values ('legality','legal');")
    end
    
    if time_limit == 0
        SQLite.execute!(db,"insert into meta values ('timed','no');")
        SQLite.execute!(db,"insert into meta (key) values ('time_add');")
        SQLite.execute!(db,"insert into meta (key) values ('sente_time');")
        SQLite.execute!(db,"insert into meta (key) values ('gote_time');")
    else
        SQLite.execute!(db,"insert into meta values ('timed','yes');")
        SQLite.execute!(db,"insert into meta values ('time_add','$time_add');")
        SQLite.execute!(db,"insert into meta values ('sente_time','$time_limit');")
        SQLite.execute!(db,"insert into meta values ('gote_time','$time_limit');")
    end

    SQLite.execute!(db,"insert into meta values ('seed','$(round(Int64,time()*1000))');")
    
    SQLite.execute!(db,"create table moves (move_number integer primary key ,move_type ,sourcex,sourcey,targetx,targety,option,i_am_cheating,targetx2,targety2,targetx3,targety3);")

    return db

end

function gameSetup(gameFile)
    # metaTable is a DataFrame holding SQLite meta table data
    metaTable = SQLite.query(gameFile, "select * from meta")

    gameType = get(metaTable[2][1]) # standard, mini, chu, or ten shogi
    if gameType == "ten"
        gameType = "tenjiku"
    end
    is_legal = get(metaTable[2][2]) == "yes"? true:false
    is_timed = get(metaTable[2][3]) == "yes"? true:false

    seed = 0
    try
        seed = parse(Int64, get(metaTable[2][7]))
    catch e
        seed = parse(Float64, get(metaTable[2][7])) # seed - unix time since epoch
        seed_str = string(seed)
        seed = parse(Int64, string(seed_str[1]) * seed_str[3:length(seed_str)-2])
    end

    # movesTable is a DataFrame holding SQLite moves table data
    movesTable = SQLite.query(gameFile, "select * from moves")

    # the number of moves that have been played so far in the game
    movesPlayed = length(movesTable[1])
    return metaTable, movesTable, gameType, seed, is_legal, is_timed
end

function getTimeData(metaTable)
    time_add = parse(Float64, get(metaTable[2][4]))
    sente_time = parse(Float64, get(metaTable[2][5]))
    gote_time = parse(Float64, get(metaTable[2][6]))
    return time_add, sente_time, gote_time
end

function boardSetup(gameType)
    # board size: 16x16 for tenjiku, 12x12 for chu, 9x9 for standard, 5x5 for mini
    if gameType == "tenjiku"
        boardLength = 16
    elseif gameType == "chu"
        boardLength = 12
    elseif gameType == "standard"
        boardLength = 9
    else 
        boardLength = 5
    end

    # promotion ranks: 5 for tenjiku, 4 for chu, 3 for standard, 1 for mini
    if gameType == "tenjiku"
        numOfPromotionRanks = 5
    elseif gameType == "chu"
        numOfPromotionRanks = 4
    elseif gameType == "standard"
        numOfPromotionRanks = 3
    else 
        numOfPromotionRanks = 1
    end

    # populate a board of empty pieces
    # syntax is board[y][x] : 1st index is y coordinate, 2nd index is x coordinate
    # board[1][1] is the top left corner
    board = [ [ empty for i = 1:boardLength ] for j = 1:boardLength ]

    if gameType == "tenjiku"

        # sente/black/odd pieces
        board[1][16] = piece("lance", "lance", 16, 1, 1, false)
        board[16][16] = piece("lance", "lance", 16, 16, 1, false)
        board[2][16] = piece("knight", "knight", 16, 2, 1, false)
        board[15][16] = piece("knight", "knight", 16, 15, 1, false)
        board[3][16] = piece("leopard", "leopard", 16, 3, 1, false) # ferocious leopard
        board[14][16] = piece("leopard", "leopard", 16, 14, 1, false) # ferocious leopard
        board[4][16] = piece("iron", "iron", 16, 4, 1, false) # iron general
        board[13][16] = piece("iron", "iron", 16, 13, 1, false) # iron general
        board[5][16] = piece("copper", "copper", 16, 5, 1, false) # copper general
        board[12][16] = piece("copper", "copper", 16, 12, 1, false) # copper general
        board[6][16] = piece("silver", "silver", 16, 6, 1, false) # silver general
        board[11][16] = piece("silver", "silver", 16, 11, 1, false) # silver general
        board[7][16] = piece("gold", "gold", 16, 7, 1, false) # gold general
        board[10][16] = piece("gold", "gold", 16, 10, 1, false) # gold general
        board[8][16] = piece("elephant", "elephant", 16, 8, 1, false) # drunk elephant
        board[9][16] = piece("king", "king", 16, 9, 1, false)
        board[1][15] = piece("chariot", "chariot", 15, 1, 1, false) # reverse chariot
        board[16][15] = piece("chariot", "chariot", 15, 16, 1, false) # reverse chariot
        board[3][15] = piece("csoldier", "csoldier", 15, 3, 1, false) # chariot soldier
        board[4][15] = piece("csoldier", "csoldier", 15, 4, 1, false) # chariot soldier
        board[13][15] = piece("csoldier", "csoldier", 15, 13, 1, false) # chariot soldier
        board[14][15] = piece("csoldier", "csoldier", 15, 14, 1, false) # chariot soldier
        board[6][15] = piece("tiger", "tiger", 15, 6, 1, false) # blind tiger
        board[11][15] = piece("tiger", "tiger", 15, 11, 1, false) # blind tiger
        board[7][15] = piece("phoenix", "phoenix", 15, 7, 1, false)
        board[8][15] = piece("queen", "queen", 15, 8, 1, false)
        board[9][15] = piece("lion", "lion", 15, 9, 1, false)
        board[10][15] = piece("kirin", "kirin", 15, 10, 1, false)
        board[1][14] = piece("ssoldier", "ssoldier", 14, 1, 1, false) # side soldier
        board[16][14] = piece("ssoldier", "ssoldier", 14, 16, 1, false) # side soldier
        board[2][14] = piece("vsoldier", "vsoldier", 14, 2, 1, false) # vertical soldier
        board[15][14] = piece("vsoldier", "vsoldier", 14, 15, 1, false) # vertical soldier
        board[3][14] = piece("bishop", "bishop", 14, 3, 1, false)
        board[14][14] = piece("bishop", "bishop", 14, 14, 1, false)
        board[4][14] = piece("horse", "horse", 14, 4, 1, false) # dragon horse 
        board[13][14] = piece("horse", "horse", 14, 13, 1, false) # dragon horse 
        board[5][14] = piece("dragon", "dragon", 14, 5, 1, false) # dragon king 
        board[12][14] = piece("dragon", "dragon", 14, 12, 1, false) # dragon king 
        board[6][14] = piece("buffalo", "buffalo", 14, 6, 1, false) # water buffalo
        board[11][14] = piece("buffalo", "buffalo", 14, 11, 1, false) # water buffalo
        board[7][14] = piece("demon", "demon", 14, 7, 1, false) # fire demon
        board[10][14] = piece("demon", "demon", 14, 10, 1, false) # fire demon
        board[8][14] = piece("eagle", "eagle", 14, 8, 1, false) # free eagle
        board[9][14] = piece("hawk", "hawk", 14, 9, 1, false) # lion hawk
        board[1][13] = piece("smover", "smover", 13, 1, 1, false) # side mover
        board[16][13] = piece("smover", "smover", 13, 16, 1, false) # side mover
        board[2][13] = piece("vmover", "vmover", 13, 2, 1, false) # vertical mover
        board[15][13] = piece("vmover", "vmover", 13, 15, 1, false) # vertical mover
        board[3][13] = piece("rook", "rook", 13, 3, 1, false)
        board[14][13] = piece("rook", "rook", 13, 14, 1, false)
        board[4][13] = piece("falcon", "falcon", 13, 4, 1, false) # horned falcon
        board[13][13] = piece("falcon", "falcon", 13, 13, 1, false) # horned falcon
        board[5][13] = piece("soaring", "soaring", 13, 5, 1, false) # soaring eagle
        board[12][13] = piece("soaring", "soaring", 13, 12, 1, false) # soaring eagle
        board[6][13] = piece("bgeneral", "bgeneral", 13, 6, 1, false) # bishop general
        board[11][13] = piece("bgeneral", "bgeneral", 13, 11, 1, false) # bishop general
        board[7][13] = piece("rgeneral", "rgeneral", 13, 7, 1, false) # rook general
        board[10][13] = piece("rgeneral", "rgeneral", 13, 10, 1, false) # rook general
        board[8][13] = piece("vice", "vice", 13, 8, 1, false) # vice general
        board[9][13] = piece("great", "great", 13, 9, 1, false) # great general
        board[1][12] = piece("pawn", "pawn", 12, 1, 1, false)
        board[2][12] = piece("pawn", "pawn", 12, 2, 1, false)
        board[3][12] = piece("pawn", "pawn", 12, 3, 1, false)
        board[4][12] = piece("pawn", "pawn", 12, 4, 1, false)
        board[5][12] = piece("pawn", "pawn", 12, 5, 1, false)
        board[6][12] = piece("pawn", "pawn", 12, 6, 1, false)
        board[7][12] = piece("pawn", "pawn", 12, 7, 1, false)
        board[8][12] = piece("pawn", "pawn", 12, 8, 1, false)
        board[9][12] = piece("pawn", "pawn", 12, 9, 1, false)
        board[10][12] = piece("pawn", "pawn", 12, 10, 1, false)
        board[11][12] = piece("pawn", "pawn", 12, 11, 1, false)
        board[12][12] = piece("pawn", "pawn", 12, 12, 1, false)
        board[13][12] = piece("pawn", "pawn", 12, 13, 1, false)
        board[14][12] = piece("pawn", "pawn", 12, 14, 1, false)
        board[15][12] = piece("pawn", "pawn", 12, 15, 1, false)
        board[16][12] = piece("pawn", "pawn", 12, 16, 1, false)
        board[5][11] = piece("dog", "dog", 11, 5, 1, false)
        board[12][11] = piece("dog", "dog", 11, 12, 1, false)

        # gote/white/even pieces
        board[1][1] = piece("lance", "lance", 1, 1, 0, false)
        board[16][1] = piece("lance", "lance", 1, 16, 0, false)
        board[2][1] = piece("knight", "knight", 1, 2, 0, false)
        board[15][1] = piece("knight", "knight", 1, 15, 0, false)
        board[3][1] = piece("leopard", "leopard", 1, 3, 0, false) # ferocious leopard
        board[14][1] = piece("leopard", "leopard", 1, 14, 0, false) # ferocious leopard
        board[4][1] = piece("iron", "iron", 1, 4, 0, false) # iron general
        board[13][1] = piece("iron", "iron", 1, 13, 0, false) # iron general
        board[5][1] = piece("copper", "copper", 1, 5, 0, false) # copper general
        board[12][1] = piece("copper", "copper", 1, 12, 0, false) # copper general
        board[6][1] = piece("silver", "silver", 1, 6, 0, false) # silver general
        board[11][1] = piece("silver", "silver", 1, 11, 0, false) # silver general
        board[7][1] = piece("gold", "gold", 1, 7, 0, false) # gold general
        board[10][1] = piece("gold", "gold", 1, 10, 0, false) # gold general
        board[8][1] = piece("king", "king", 1, 8, 0, false) # king
        board[9][1] = piece("elephant", "elephant", 1, 9, 0, false) # drunk elephant
        board[1][2] = piece("chariot", "chariot", 2, 1, 0, false) # reverse chariot
        board[16][2] = piece("chariot", "chariot", 2, 16, 0, false) # reverse chariot
        board[3][2] = piece("csoldier", "csoldier", 2, 3, 0, false) # chariot soldier
        board[4][2] = piece("csoldier", "csoldier", 2, 4, 0, false) # chariot soldier
        board[13][2] = piece("csoldier", "csoldier", 2, 13, 0, false) # chariot soldier
        board[14][2] = piece("csoldier", "csoldier", 2, 14, 0, false) # chariot soldier
        board[6][2] = piece("tiger", "tiger", 2, 6, 0, false) # blind tiger
        board[11][2] = piece("tiger", "tiger", 2, 11, 0, false) # blind tiger
        board[7][2] = piece("kirin", "kirin", 2, 7, 0, false)
        board[8][2] = piece("lion", "lion", 2, 8, 0, false)
        board[9][2] = piece("queen", "queen", 2, 9, 0, false)
        board[10][2] = piece("phoenix", "phoenix", 2, 10, 0, false)
        board[1][3] = piece("ssoldier", "ssoldier", 3, 1, 0, false) # side soldier
        board[16][3] = piece("ssoldier", "ssoldier", 3, 16, 0, false) # side soldier
        board[2][3] = piece("vsoldier", "vsoldier", 3, 2, 0, false) # vertical soldier
        board[15][3] = piece("vsoldier", "vsoldier", 3, 15, 0, false) # vertical soldier
        board[3][3] = piece("bishop", "bishop", 3, 3, 0, false)
        board[14][3] = piece("bishop", "bishop", 3, 14, 0, false)
        board[4][3] = piece("horse", "horse", 3, 4, 0, false) # dragon horse 
        board[13][3] = piece("horse", "horse", 3, 13, 0, false) # dragon horse
        board[5][3] = piece("dragon", "dragon", 3, 5, 0, false) # dragon king
        board[12][3] = piece("dragon", "dragon", 3, 12, 0, false) # dragon king
        board[6][3] = piece("buffalo", "buffalo", 3, 6, 0, false) # water buffalo
        board[11][3] = piece("buffalo", "buffalo", 3, 11, 0, false) # water buffalo
        board[7][3] = piece("demon", "demon", 3, 7, 0, false) # fire demon
        board[10][3] = piece("demon", "demon", 3, 10, 0, false) # fire demon
        board[8][3] = piece("hawk", "hawk", 3, 8, 0, false) # lion hawk
        board[9][3] = piece("eagle", "eagle", 3, 9, 0, false) # free eagle
        board[1][4] = piece("smover", "smover", 4, 1, 0, false) # side mover
        board[16][4] = piece("smover", "smover", 4, 16, 0, false) # side mover
        board[2][4] = piece("vmover", "vmover", 4, 2, 0, false) # vertical mover
        board[15][4] = piece("vmover", "vmover", 4, 15, 0, false) # vertical mover
        board[3][4] = piece("rook", "rook", 4, 3, 0, false)
        board[14][4] = piece("rook", "rook", 4, 14, 0, false)
        board[4][4] = piece("falcon", "falcon", 4, 4, 0, false) # horned falcon
        board[13][4] = piece("falcon", "falcon", 4, 13, 0, false) # horned falcon
        board[5][4] = piece("soaring", "soaring", 4, 5, 0, false) # soaring eagle
        board[12][4] = piece("soaring", "soaring", 4, 12, 0, false) # soaring eagle
        board[6][4] = piece("bgeneral", "bgeneral", 4, 6, 0, false) # bishop general
        board[11][4] = piece("bgeneral", "bgeneral", 4, 11, 0, false) # bishop general
        board[7][4] = piece("rgeneral", "rgeneral", 4, 7, 0, false) # rook general
        board[10][4] = piece("rgeneral", "rgeneral", 4, 10, 0, false) # rook general
        board[8][4] = piece("great", "great", 4, 8, 0, false) # great general
        board[9][4] = piece("vice", "vice", 4, 9, 0, false) # vice general
        board[1][5] = piece("pawn", "pawn", 5, 1, 0, false)
        board[2][5] = piece("pawn", "pawn", 5, 2, 0, false)
        board[3][5] = piece("pawn", "pawn", 5, 3, 0, false)
        board[4][5] = piece("pawn", "pawn", 5, 4, 0, false)
        board[5][5] = piece("pawn", "pawn", 5, 5, 0, false)
        board[6][5] = piece("pawn", "pawn", 5, 6, 0, false)
        board[7][5] = piece("pawn", "pawn", 5, 7, 0, false)
        board[8][5] = piece("pawn", "pawn", 5, 8, 0, false)
        board[9][5] = piece("pawn", "pawn", 5, 9, 0, false)
        board[10][5] = piece("pawn", "pawn", 5, 10, 0, false)
        board[11][5] = piece("pawn", "pawn", 5, 11, 0, false)
        board[12][5] = piece("pawn", "pawn", 5, 12, 0, false)
        board[13][5] = piece("pawn", "pawn", 5, 13, 0, false)
        board[14][5] = piece("pawn", "pawn", 5, 14, 0, false)
        board[15][5] = piece("pawn", "pawn", 5, 15, 0, false)
        board[16][5] = piece("pawn", "pawn", 5, 16, 0, false)
        board[5][6] = piece("dog", "dog", 6, 5, 0, false)
        board[12][6] = piece("dog", "dog", 6, 12, 0, false)

    elseif gameType == "chu" # game setup for chu shogi

        # sente/black/odd pieces
        board[4][8] = piece("cobra", "cobra", 8, 4, 1, false) # AKA go-between
        board[9][8] = piece("cobra", "cobra", 8, 9, 1, false) # AKA go-between
        board[1][9] = piece("pawn", "pawn", 9, 1, 1, false)
        board[2][9] = piece("pawn", "pawn", 9, 2, 1, false)
        board[3][9] = piece("pawn", "pawn", 9, 3, 1, false)
        board[4][9] = piece("pawn", "pawn", 9, 4, 1, false)
        board[5][9] = piece("pawn", "pawn", 9, 5, 1, false)
        board[6][9] = piece("pawn", "pawn", 9, 6, 1, false)
        board[7][9] = piece("pawn", "pawn", 9, 7, 1, false)
        board[8][9] = piece("pawn", "pawn", 9, 8, 1, false)
        board[9][9] = piece("pawn", "pawn", 9, 9, 1, false)
        board[10][9] = piece("pawn", "pawn", 9, 10, 1, false)
        board[11][9] = piece("pawn", "pawn", 9, 11, 1, false)
        board[12][9] = piece("pawn", "pawn", 9, 12, 1, false)
        board[1][10] = piece("smover", "smover", 10, 1, 1, false)
        board[2][10] = piece("vmover", "vmover", 10, 2, 1, false)
        board[3][10] = piece("rook", "rook", 10, 3, 1, false)
        board[4][10] = piece("horse", "horse", 10, 4, 1, false) # dragon horse
        board[5][10] = piece("dragon", "dragon", 10, 5, 1, false) # dragon king
        board[6][10] = piece("queen", "queen", 10, 6, 1, false)
        board[7][10] = piece("lion", "lion", 10, 7, 1, false)
        board[8][10] = piece("dragon", "dragon", 10, 8, 1, false) # dragon king
        board[9][10] = piece("horse", "horse", 10, 9, 1, false) # dragon horse
        board[10][10] = piece("rook", "rook", 10, 10, 1, false)
        board[11][10] = piece("vmover", "vmover", 10, 11, 1, false) # vertical mover
        board[12][10] = piece("smover", "smover", 10, 12, 1, false) # side mover
        board[1][11] = piece("chariot", "chariot", 11, 1, 1, false) # reverse chariot
        board[3][11] = piece("bishop", "bishop", 11, 3, 1, false)
        board[5][11] = piece("tiger", "tiger", 11, 5, 1, false) # blind tiger
        board[6][11] = piece("phoenix", "phoenix", 11, 6, 1, false)
        board[7][11] = piece("kirin", "kirin", 11, 7, 1, false)
        board[8][11] = piece("tiger", "tiger", 11, 8, 1, false) # blind tiger
        board[10][11] = piece("bishop", "bishop", 11, 10, 1, false)
        board[12][11] = piece("chariot", "chariot", 11, 12, 1, false) # reverse chariot
        board[1][12] = piece("lance", "lance", 12, 1, 1, false)
        board[2][12] = piece("leopard", "leopard", 12, 2, 1, false) # ferocious leopard
        board[3][12] = piece("copper", "copper", 12, 3, 1, false) # copper general
        board[4][12] = piece("silver", "silver", 12, 4, 1, false) # silver general
        board[5][12] = piece("gold", "gold", 12, 5, 1, false) # gold general
        board[6][12] = piece("elephant", "elephant", 12, 6, 1, false) # drunk elephant
        board[7][12] = piece("king", "king", 12, 7, 1, false)
        board[8][12] = piece("gold", "gold", 12, 8, 1, false) # gold general
        board[9][12] = piece("silver", "silver", 12, 9, 1, false) # silver general
        board[10][12] = piece("copper", "copper", 12, 10, 1, false) # copper general
        board[11][12] = piece("leopard", "leopard", 12, 11, 1, false) # ferocious leopard
        board[12][12] = piece("lance", "lance", 12, 12, 1, false)

        # gote/white/even pieces
        board[4][5] = piece("cobra", "cobra", 5, 4, 0, false) # AKA go-between
        board[9][5] = piece("cobra", "cobra", 5, 9, 0, false) # AKA go-between
        board[1][4] = piece("pawn", "pawn", 4, 1, 0, false)
        board[2][4] = piece("pawn", "pawn", 4, 2, 0, false)
        board[3][4] = piece("pawn", "pawn", 4, 3, 0, false)
        board[4][4] = piece("pawn", "pawn", 4, 4, 0, false)
        board[5][4] = piece("pawn", "pawn", 4, 5, 0, false)
        board[6][4] = piece("pawn", "pawn", 4, 6, 0, false)
        board[7][4] = piece("pawn", "pawn", 4, 7, 0, false)
        board[8][4] = piece("pawn", "pawn", 4, 8, 0, false)
        board[9][4] = piece("pawn", "pawn", 4, 9, 0, false)
        board[10][4] = piece("pawn", "pawn", 4, 10, 0, false)
        board[11][4] = piece("pawn", "pawn", 4, 11, 0, false)
        board[12][4] = piece("pawn", "pawn", 4, 12, 0, false)
        board[1][3] = piece("smover", "smover", 3, 1, 0, false) # side mover
        board[2][3] = piece("vmover", "vmover", 3, 2, 0, false) # vertical mover
        board[3][3] = piece("rook", "rook", 3, 3, 0, false)
        board[4][3] = piece("horse", "horse", 3, 4, 0, false) # dragon horse
        board[5][3] = piece("dragon", "dragon", 3, 5, 0, false) # dragon king
        board[6][3] = piece("lion", "lion", 3, 6, 0, false)
        board[7][3] = piece("queen", "queen", 3, 7, 0, false)
        board[8][3] = piece("dragon", "dragon", 3, 8, 0, false) # dragon king
        board[9][3] = piece("horse", "horse", 3, 9, 0, false) # dragon horse
        board[10][3] = piece("rook", "rook", 3, 10, 0, false)
        board[11][3] = piece("vmover", "vmover", 3, 11, 0, false) # vertical mover
        board[12][3] = piece("smover", "smover", 3, 12, 0, false) # side mover
        board[1][2] = piece("chariot", "chariot", 2, 1, 0, false) # reverse chariot
        board[3][2] = piece("bishop", "bishop", 2, 3, 0, false)
        board[5][2] = piece("tiger", "tiger", 2, 5, 0, false) # blind tiger
        board[6][2] = piece("kirin", "kirin", 2, 6, 0, false)
        board[7][2] = piece("phoenix", "phoenix", 2, 7, 0, false)
        board[8][2] = piece("tiger", "tiger", 2, 8, 0, false) # blind tiger
        board[10][2] = piece("bishop", "bishop", 2, 10, 0, false)
        board[12][2] = piece("chariot", "chariot", 2, 12, 0, false) # reverse chariot
        board[1][1] = piece("lance", "lance", 1, 1, 0, false)
        board[2][1] = piece("leopard", "leopard", 1, 2, 0, false) # ferocious leopard
        board[3][1] = piece("copper", "copper", 1, 3, 0, false) # copper general
        board[4][1] = piece("silver", "silver", 1, 4, 0, false) # silver general
        board[5][1] = piece("gold", "gold", 1, 5, 0, false) # gold general
        board[6][1] = piece("king", "king", 1, 6, 0, false)
        board[7][1] = piece("elephant", "elephant", 1, 7, 0, false) # drunk elephant
        board[8][1] = piece("gold", "gold", 1, 8, 0, false) # gold general
        board[9][1] = piece("silver", "silver", 1, 9, 0, false) # silver general
        board[10][1] = piece("copper", "copper", 1, 10, 0, false) # copper general
        board[11][1] = piece("leopard", "leopard", 1, 11, 0, false) #ferocious leopard
        board[12][1] = piece("lance", "lance", 1, 12, 0, false)

    elseif gameType == "standard" # game setup for standard shogi

        # sente/black/odd player
        board[1][7] = piece("pawn", "pawn", 7, 1, 1, false)
        board[2][7] = piece("pawn", "pawn", 7, 2, 1, false)
        board[3][7] = piece("pawn", "pawn", 7, 3, 1, false)
        board[4][7] = piece("pawn", "pawn", 7, 4, 1, false)
        board[5][7] = piece("pawn", "pawn", 7, 5, 1, false)
        board[6][7] = piece("pawn", "pawn", 7, 6, 1, false)
        board[7][7] = piece("pawn", "pawn", 7, 7, 1, false)
        board[8][7] = piece("pawn", "pawn", 7, 8, 1, false)
        board[9][7] = piece("pawn", "pawn", 7, 9, 1, false)
        board[2][8] = piece("rook", "rook", 8, 2, 1, false)
        board[8][8] = piece("bishop", "bishop", 8, 8, 1, false)
        board[1][9] = piece("lance", "lance", 9, 1, 1, false)
        board[2][9] = piece("knight", "knight", 9, 2, 1, false)
        board[3][9] = piece("silver", "silver", 9, 3, 1, false) # silver general
        board[4][9] = piece("gold", "gold", 9, 4, 1, false) # gold general 
        board[5][9] = piece("king", "king", 9, 5, 1, false)
        board[6][9] = piece("gold", "gold", 9, 6, 1, false) # gold general
        board[7][9] = piece("silver", "silver", 9, 7, 1, false) # silver general
        board[8][9] = piece("knight", "knight", 9, 8, 1, false)
        board[9][9] = piece("lance", "lance", 9, 9, 1, false)

        # gote/white/even player
        board[1][3] = piece("pawn", "pawn", 3, 1, 0, false)
        board[2][3] = piece("pawn", "pawn", 3, 2, 0, false)
        board[3][3] = piece("pawn", "pawn", 3, 3, 0, false)
        board[4][3] = piece("pawn", "pawn", 3, 4, 0, false)
        board[5][3] = piece("pawn", "pawn", 3, 5, 0, false)
        board[6][3] = piece("pawn", "pawn", 3, 6, 0, false)
        board[7][3] = piece("pawn", "pawn", 3, 7, 0, false)
        board[8][3] = piece("pawn", "pawn", 3, 8, 0, false)
        board[9][3] = piece("pawn", "pawn", 3, 9, 0, false)
        board[2][2] = piece("bishop", "bishop", 2, 2, 0, false)
        board[8][2] = piece("rook", "rook", 2, 8, 0, false)
        board[1][1] = piece("lance", "lance", 1, 1, 0, false)
        board[2][1] = piece("knight", "knight", 1, 2, 0, false)
        board[3][1] = piece("silver", "silver", 1, 3, 0, false) # silver general
        board[4][1] = piece("gold", "gold", 1, 4, 0, false) # gold general
        board[5][1] = piece("king", "king", 1, 5, 0, false)
        board[6][1] = piece("gold", "gold", 1, 6, 0, false) # gold general
        board[7][1] = piece("silver", "silver", 1, 7, 0, false) # silver general
        board[8][1] = piece("knight", "knight", 1, 8, 0, false)
        board[9][1] = piece("lance", "lance", 1, 9, 0, false)

    else # game setup for minishogi

        # sente/black/odd player
        board[5][4] = piece("pawn", "pawn", 4, 5, 1, false)
        board[1][5] = piece("rook", "rook", 5, 1, 1, false)
        board[2][5] = piece("bishop", "bishop", 5, 2, 1, false)
        board[3][5] = piece("silver", "silver", 5, 3, 1, false) # silver general
        board[4][5] = piece("gold", "gold", 5, 4, 1, false) # gold general
        board[5][5] = piece("king", "king", 5, 5, 1, false)

        # gote/white/even player
        board[1][2] = piece("pawn", "pawn", 2, 1, 0, false)
        board[1][1] = piece("king", "king", 1, 1, 0, false)
        board[2][1] = piece("gold", "gold", 1, 2, 0, false) # gold general
        board[3][1] = piece("silver", "silver", 1, 3, 0, false) # silver general
        board[4][1] = piece("bishop", "bishop", 1, 4, 0, false)
        board[5][1] = piece("rook", "rook", 1, 5, 0, false)

    end
    return board, boardLength, numOfPromotionRanks
end
