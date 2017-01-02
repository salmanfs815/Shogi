import DataFrames
import SQLite

Base.eval(:(have_color=true))

type move 
    move_number::Int64 # -1 if irrelevant
    move_type::String # "move", "drop" or "resign"
    sourcex::Int8 # -1 if no source
    sourcey::Int8 # -1 if no source
    targetx::Int8 # -1 if no target
    targety::Int8 # -1 if no target
    option::String # "" (empty string) if no option
    i_am_cheating::Bool # false by default, true if cheating
    targetx2::Int8 # -1 if no target2
    targety2::Int8 # -1 if no target2
    targetx3::Int8 # -1 if no target3
    targety3::Int8 # -1 if no target3
end

noMove = move(-1, "move", -1, -1, -1, -1, "", false, -1, -1, -1, -1)

type piece
    original::String # original piece name ("" for empty space) - constant throughout life of program
    name::String  # piece name ("" for empty space) - changes upon promotion
    x::Int8    # x-coordinate (0 for empty space)
    y::Int8    # y-coordinate (0 for empty space)
    side::Int8 # 0 for white; 1 for black; -1 for empty space
    promoted::Bool # false by default, true if promoted
end

empty = piece("", "", 0, 0, -1, false)


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


#println(capturedByOdd)
#println(capturedByEven)
function samePiecesCaptured(capturedByEven, capturedByOdd)
    numOfCapturedByOdd = length(capturedByOdd)
    numOfCapturedByEven =length(capturedByEven)
    if !isdefined(capturedByEven) || !isdefined(capturedByOdd)
        return true
    end
    if numOfCapturedByOdd==numOfCapturedByEven

        return true
    end
    return false
end

function samePiece(p1,p2)
    if p1.name==p2.name && p1.x==p2.x && p1.y==p2.y && p1.side==p2.side
        return true
    else
        return false
    end
end

function sameBoard(b1,b2)
    for i in eachindex(b1)
        for j in eachindex(b1)
            if !samePiece(b1[i][j],b2[i][j])
                return false
            end
        end
    end
    return true
end


function check_draw(curr, allBoards)
    count = 0

    for b in eachindex(allBoards)
        if sameBoard(curr,allBoards[b])
            count+=1
        end
    end
    if count == 4
        return true
    end
    return false
end

function find_our_king(board, side)
    boardLength = length(board)
    for i in 1:boardLength
        for j in 1:boardLength
            if board[j][i].name == "king" && board[j][i].side == side
                return board[j][i]
            end
        end
    end
    return -1
end

function find_our_prince(board, side)
    boardLength = length(board)
    for i in 1:boardLength
        for j in 1:boardLength
            if board[j][i].name == "prince" && board[j][i].side == side
                return board[j][i]
            end
        end
    end
    return -1
end

function win(moveType, is_timed, sente_time, gote_time, allBoards) 
    numOfBoards = length(allBoards)
    board = allBoards[numOfBoards]
    boardLength=length(allBoards[1])
    if boardLength == 5
        gameType = "minishogi"
    elseif boardLength == 9 
        gameType = "standard"   
    elseif boardLength == 12
        gameType = "chu"
    else 
        gameType = "ten"
    end

    #CHECK FOR A RESIGN
    if moveType =="resign"
        #decisive=true
        if side == 0
            #println("r")
            return "r"
        else 
            #println("R")
            return "R"
        end
    end

    if is_timed
        if sente_time <= 0
            #println("W")
            #decisive=true
            return "W"
        elseif gote_time <= 0 
            #println("B")
            #decisive=true
            return "B"
        end
    end
    
    if check_draw(board, allBoards) && samePiecesCaptured() 
        return "D"
    end

    #=if decisive==true
        return
    end
    =#

    sentePieces = Array(piece, 0) #0 element piece array
    gotePieces = Array(piece, 0)
    senteKing = empty
    goteKing = empty
    sentePrince = empty
    gotePrince = empty

    # go through board
    for i in 1:length(board)
        for j in 1:length(board[1])

            #get all our pieces in board into ourPieces array
            if board[i][j].side == 1
                push!(sentePieces, board[i][j])
            elseif board[i][j].side == 0
                push!(gotePieces, board[i][j])
            end

            #get enemy king
            if board[i][j].name == "king" && board[i][j].side == 1
                senteKing = board[i][j]
            #get our king
            elseif board[i][j].name == "king" && board[i][j].side == 0
                goteKing = board[i][j]

            elseif board[i][j].name == "prince" && board[i][j].side == 1
                sentePrince = board[i][j]
            elseif board[i][j].name == "prince" && board[i][j].side == 0
                sentePrince = board[i][j]
            end

        end
    end

    #CHECK IF KING IS KILLED
    if gameType == "minishogi" || gameType == "standard"
        #println("check wins")
        if senteKing == empty
            return "W"
        elseif goteKing == empty
            return "B"
        end
        #println("not a win")
    end

    if gameType == "ten" || gameType == "chu"
        #println("check wins")
        if senteKing == empty && sentePrince == empty
            return "W"
        elseif goteKing == empty && gotePrince == empty
            return "B"
        end
        #println("not a win")
    end
#=    prevBoard=duplicateBoard(board)
    push!(allBoards,prevBoard)
    push!(counts,1)=#
    #if moveType=="move" 
        #sourcex= movesTable[3][i]
        #sourcey = movesTable[4][i]
        #if !isnull(targetx2) && !isnull(t)
        #movePiece(board, i, sourcex, sourcey, move_targetx, move_targety, option, targetx2, targety2)
    #end
    #println("?")
    return "?"
end

#checks if the target coordinates are not possible because they are not in the board
#done
function valid_boundaries(board, sourcex, sourcey, targetx, targety)
    boardLength = length(board)
    #for x greater than boardLength
    if sourcex == boardLength && targetx > sourcex
        return false
    #for x less than 1
    elseif sourcex == 1 && targetx < sourcex
        return false
    #for y greater than boardLength
    elseif sourcey == boardLength && targety > sourcey
        return false
    #for t less than 1
    elseif sourcey == 1 && targety < sourcey
        return false
    #if none of the four checks is true then there isn't a boundary error
    else 
    #println("true valid boundaries")
       return true
    end
end

#checks if oponent is not truly moving
#done
function same_coordinates(sourcex, sourcey, targetx, targety)
    if sourcex == targetx && sourcey == targety
        return true
    else 
        return false
    end
end

#checks if the target is valid (empty or oponent's piece)
#done
function target_valid(board, targetx, targety, side)
    if targetx <= 0 || targety <= 0 # - Salman
        return false
    end
    return board[targety][targetx].side != side # Salman

    #check for emptyness
    if board[targety][targetx].name != ""
    #if same color return false
        if side == board[targety][targetx].side
            return false
        else    
            #can move if is oponent's -> captures
            return true
        end
    else 
        #if empty return true
        return true
    end
end

function demon_move_burn(board, targetx, targety, side)
    #if oponent's then make empty
    if targetx <= 0 || targety <= 0 || targetx > 16 || targety > 16 # - Salman
        return board
    end

    if board[targety][targetx].name == "" || board[targety][targetx].name == "demon" || board[targety][targetx].side == side
        return board
    end
    if board[targety][targetx].side != side 
        board[targety][targetx] = empty
        return board
    end
end

#=function demon_valid(board, targetx, targety, side)
    if targetx < 0 || targety < 0 # - Salman
        return false
    end
    #if is empty or if is a demon or if it is one of our pieces return true
    if board[targety][targetx].name == "" || board[targety][targetx].side == side || board[targety][targetx].name == "demon"
        return true
    end
    return false
end=#

################################
### Standard and mini pieces ###
################################

#checks if the moves are allowed, piece: king
#done
function king(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    #the king can only move to any combination: (x/x+1/x-1, y/y+1/y-1)
    if targetx > sourcex+1 || targetx < sourcex-1 || targety > sourcey+1 || targety < sourcey-1
        return false
    end
    return true
end

#checks if the moves are allowed, white pieces: gold general, promoted silver general, promoted lance, promoted pawn, promoted knight
#done
function gold_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex-1 && targety == sourcey 
        return true
    elseif targetx == sourcex || targetx == sourcex+1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else
            return true
        end
    else
        return false
    end
end

#checks if the moves are allowed, black pieces: gold general, promoted silver general, promoted lance, promoted pawn, promoted knight
#done
function gold_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex+1 && targety == sourcey 
        return true
    elseif targetx == sourcex || targetx == sourcex-1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else
            return true
        end
    else
        return false
    end
end

#checks if the moves are allowed, black piece: pawn
#done
function pawn_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex-1 && targety == sourcey
        return true
    end
    return false
end

#checks if the moves are allowed, white piece: pawn
#done
function pawn_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex+1 && targety == sourcey
        return true
    end
    return false
end

#checks if the moves are allowed, black piece: silver general
#done
function silver_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex-1 
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else 
            return true
        end
    elseif targetx == sourcex+1
        if targety == sourcey+1 || targety == sourcey-1
            return true
        end
    else 
        return false
    end
    return false
end

#checks if the moves are allowed, white piece: silver general
#done
function silver_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex-1 
        if targety == sourcey+1 || targety == sourcey-1
            return true
        end
    elseif targetx == sourcex+1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else 
            return true
        end
    else 
        return false
    end
    return false
end

#checks if the moves are allowed, black piece: knight
#done
function knight_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex-2 
        if targety == sourcey+1 || targety == sourcey-1 
            return true
        end
    end
    return false
end

#checks if the moves are allowed, white piece: knight
#done
function knight_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex+2 
        if targety == sourcey+1 || targety == sourcey-1 
            return true
        end
    end
    return false
end


function ne_bishop(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    deltaX = abs(sourcex-targetx)
    deltaY = abs(sourcey-targety)

    if deltaX != deltaY
        return false
    end

    if targetx > sourcex && targety < sourcey # target is NE of bishop

        i = targetx
        j = targety
        while i > sourcex+1 && j < sourcey-1
            i -= 1
            j += 1
            if board[j][i].side != -1
                return false
            end
        end
    else 
        return false
    end
    return true
end

function nw_bishop(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    deltaX = abs(sourcex-targetx)
    deltaY = abs(sourcey-targety)

    if deltaX != deltaY
        return false
    end

    if targetx < sourcex && targety < sourcey # target is NW of bishop

        i = targetx
        j = targety
        while i < sourcex-1 && j < sourcey-1
            i += 1
            j += 1
            if board[j][i].side != -1
                return false
            end
        end
    else 
        return false
    end
    return true
end

function se_bishop(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    deltaX = abs(sourcex-targetx)
    deltaY = abs(sourcey-targety)

    if deltaX != deltaY
        return false
    end

    if targetx > sourcex && targety > sourcey # target is SE of bishop

        i = targetx
        j = targety
        while i > sourcex+1 && j > sourcey+1
            i -= 1
            j -= 1
            if board[j][i].side != -1
                return false
            end
        end

    else 
        return false
    end
    return true
end

function sw_bishop(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    deltaX = abs(sourcex-targetx)
    deltaY = abs(sourcey-targety)

    if deltaX != deltaY
        return false
    end

    if targetx < sourcex && targety > sourcey # target is SW of bishop

        i = targetx
        j = targety
        while i < sourcex-1 && j > sourcey+1
            i += 1
            j -= 1
            if board[j][i].side != -1
                return false
            end
        end
    else 
        return false
    end
    return true
end

#checks if the moves are allowed, piece: bishop
#not done
function bishop(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    deltaX = abs(sourcex-targetx)
    deltaY = abs(sourcey-targety)

    if deltaX != deltaY
        return false
    end

    if targetx < sourcex && targety < sourcey # target is NW of bishop

        i = targetx
        j = targety
        while i < sourcex-1 && j < sourcey-1
            i += 1
            j += 1
            if board[j][i].side != -1
                return false
            end
        end

    elseif targetx < sourcex && targety > sourcey # target is SW of bishop

        i = targetx
        j = targety
        while i < sourcex-1 && j > sourcey+1
            i += 1
            j -= 1
            if board[j][i].side != -1
                return false
            end
        end

    elseif targetx > sourcex && targety < sourcey # target is NE of bishop

        i = targetx
        j = targety
        while i > sourcex+1 && j < sourcey-1
            i -= 1
            j += 1
            if board[j][i].side != -1
                return false
            end
        end

    elseif targetx > sourcex && targety > sourcey # target is SE of bishop

        i = targetx
        j = targety
        while i > sourcex+1 && j > sourcey+1
            i -= 1
            j -= 1
            if board[j][i].side != -1
                return false
            end
        end

    else 
        return false
    end
    return true

    #=
    #this piece can only move (x-i/x+i,y+i/y-i)
    #delta x and delta y should be equal :: Diagonal
    if abs(sourcex-targetx) == abs(sourcey-targety)
        #(+,+)
        if targetx>sourcex && targety>sourcey
            for x in sourcex+1:targetx
                for y in sourcey+1:targety
                    if x == targetx && y == targety
                        #println("enters")
                        if board[y][x].name  != ""
                            if board[y][x].side != board[sourcey][sourcex].side
                                return true
                            else 
                                return false
                            end
                        else
                            return true
                        end
                    else
                        if abs(sourcex-x) == abs(sourcey-y)
                            if board[y][x].name != ""
                                return false
                            end
                        end
                    end
                end
            end
        #(+,-)
        elseif targetx>sourcex && targety<sourcey
            for x in sourcex+1:targetx
                for y in sourcey-1:-1:targety
                    if x == targetx && y == targety
                        if board[y][x].name  != ""
                            if board[y][x].side != board[sourcey][sourcex].side
                                return true
                            else 
                                return false
                            end
                        else
                            return true
                        end
                    else
                        if abs(sourcex-x) == abs(sourcey-y)
                            if board[y][x].name != ""
                                return false
                            end
                        end
                    end
                end
            end
        #(-,+)
        elseif targetx<sourcex && targety>sourcey
            for x in sourcex-1:-1:targetx
                for y in sourcey+1:targety
                    if x == targetx && y == targety
                        if board[y][x].name  != ""
                            if board[y][x].side != board[sourcey][sourcex].side
                                return true
                            else 
                                return false
                            end
                        else
                            return true
                        end
                    else
                        if abs(sourcex-x) == abs(sourcey-y)
                            if board[y][x].name != ""
                                return false
                            end
                        end
                    end
                end
            end
        #(-,-)
        elseif targetx<sourcex && targety<sourcey
            #println("enters")
            for x in sourcex-1:-1:targetx
                for y in sourcey-1:-1:targety
                    #println(x)
                    #println(y)
                    if x == targetx && y == targety
                        if board[y][x].name  != ""
                            if board[y][x].side != board[sourcey][sourcex].side
                                return true
                            else 
                                return false
                            end
                        else
                            return true
                        end
                    else
                        if abs(sourcex-x) == abs(sourcey-y)
                            if board[y][x].name != ""
                                return false
                            end
                        end
                    end
                end
            end
        else
            return false
        end
    else 
        return false
    end
    =#
end

#checks if the moves are allowed, piece: promoted bishop
#done
function dragon_horse(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety)
        return true
    end
    if targety == sourcey && (targetx == sourcex-1 || targetx == sourcex+1)
        return true
    end
    if targetx == sourcex && (targety == sourcey-1 || targety == sourcey+1)
        return true
    end
    return false
end


#checks if the moves are allowed, piece: rook
# give it a last check
function rook(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    if sourcex == targetx
        if targety > sourcey
            for i = sourcey+1:targety-1
                if board[i][sourcex].side != -1
                    return false
                end
            end
        else 
            for i = targety+1:sourcey-1
                if board[i][sourcex].side != -1
                    return false
                end
            end
        end
    elseif sourcey == targety
        if targetx > sourcex
            for i = sourcex+1:targetx-1
                if board[sourcey][i].side != -1
                    return false
                end
            end
        else 
            for i = targetx+1:sourcex-1
                if board[sourcey][i].side != -1
                    return false
                end
            end
        end
    else 
        return false
    end

    return true

    #=
    #this piece can move horizontally
    if targety == sourcey
        #moving left
        if targetx>sourcex
            for i in sourcex+1:targetx
                #println("entered")
                #println(board[targety][i])
                if i == targetx

                    if board[targety][targetx].side != board[targety][targetx].side
                        return true
                    end
                    return false
                end
                if board[targety][i].name != ""
                    return false
                end
            end
            return true
        #moving right
        else
            for i in sourcex-1:-1:targetx
                if i == targetx
                    if board[targety][targetx].side != board[targety][targetx].side
                        return true
                    end
                    return false
                end
                if board[targety][i].name != ""
                    return false
                end
            end
            return true
        end
    #this piece can move vertically
    elseif targetx == sourcex
        #moving downwards
        if targety>sourcey
            for i in sourcey+1:targety
                if i == targety
                    if board[targety][targetx].side != board[targety][targetx].side
                        return true
                    end
                    return false
                end
                if board[i][targetx].name != ""
                    return false
                end
            end
            return true
        else
            #move upwards
            for i in sourcey-1:-1:targety
                if i == targety
                    if board[targety][targetx].side != board[targety][targetx].side
                        return true
                    end
                    return false
                end
                if board[i][targetx].name != ""
                    return false
                end
            end
            return true
        end
    else 
        return false
    end
    =#
end

#checks if the moves are allowed, piece: promoted rook
#done
function dragon_king(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !rook(board, sourcex, sourcey, targetx, targety)
        #only combinations: (x+1/x-1, y+1/y-1)
        if targety == sourcey+1 || targety == sourcey-1
            if targetx == sourcex+1 || targetx == sourcex-1
                return true
            end
        end
        return false
    else
        return true
    end
end


#checks if the moves are allowed, black piece: lance
#done
function lance_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    #this piece can only move upwards
    if targety == sourcey && targetx>sourcex
        for i in sourcex+1:targetx
            if i == targetx
                if target_valid(board, i, targety, 0)
                    return true
                end
            end
            if board[targety][i].name != ""
                return false
            end
        end
        return false
    else
        return false
    end
end


#checks if the moves are allowed, white piece: lance
#done
function lance_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    #this piece can only move vertically and downwards
    if targety == sourcey && targetx<sourcex
        for i in sourcex-1:-1:targetx
            if i == targetx
                if target_valid(board, i, targety, 1)
                    return true
                end
            end
            if board[targety][i].name != ""
                return false
            end
        end
        return false
    else
        return false
    end
end

##################
### Chu pieces ###
##################

#checks if the moves are allowed, black piece: copper general
#done
function copper_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex+1 && targety == sourcey
        return true
    elseif targetx == sourcex-1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else
            return true
        end
    else
        return false
    end
end

#checks if the moves are allowed, white piece: copper general
#done
function copper_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex-1 && targety == sourcey
        return true
    elseif targetx == sourcex+1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else
            return true
        end
    else
        return false

    end
end

#checks if the moves are allowed, piece: go between
#done
function go_between(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targety == sourcey
        if targetx == sourcex-1 || targetx == sourcex+1
            return true
        end
    end
    return false
end

#checks if the moves are allowed, piece: queen
#done
function queen(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety) || rook(board, sourcex, sourcey, targetx, targety)
        return true
    end
    return false
end

#checks if the moves are allowed, piece: ferocious leopard
#done
function leopard(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex+1 || targetx == sourcex-1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else 
            return true
        end
    else 
        return false
    end
end

#checks if moves are allowed - for blind tiger(black) and drunken elephant(white)
#done
function tiger_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    if targetx == sourcex-1 && targety == sourcey
        return false
    elseif targetx == sourcex-1 ||  targetx == sourcex || targetx == sourcex+1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else
            return true
        end
    else
        return false
    end
    return false
end

#checks if moves are allowed - for blind tiger(white) and drunken elephant(black)
#done
function tiger_white(board, sourcex, sourcey, targetx, targety)
     if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex+1 && targety == sourcey
        return false
    elseif targetx == sourcex-1 ||  targetx == sourcex || targetx == sourcex+1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        else
            return true
        end
    else
        return false
    end
    return false
end

#done
function elephant_black(board, sourcex, sourcey, targetx, targety)
    if tiger_white(board, sourcex, sourcey, targetx, targety)
        return true
    end
    return false
end

#done
function elephant_white(board, sourcex, sourcey, targetx, targety)
    if tiger_black(board, sourcex, sourcey, targetx, targety)
        return true
    end
    return false
end

 
#checks if moves are allowed for reverse chariot (promotes to whale)
#done
function chariot(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if sourcey == targety
        if targetx > sourcex
            for i = sourcex+1:targetx-1
                if board[sourcey][i].side != -1
                    return false
                end
            end
            return true
        else 
            for i = targetx+1:sourcex-1
                if board[sourcey][i].side != -1
                    return false
                end
            end
            return true
        end
    else 
        return false
    end
end

#checks valid moves for flying ox(promoted vertical mover)
#done
function p_vertical_mover(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety) || chariot(board, sourcex, sourcey, targetx, targety)
        return true
    end
    return false
end

#checks the valid horizontal moves
#done
function check_side(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if sourcex == targetx
        if targety > sourcey
            for i = sourcey+1:targety-1
                if board[i][sourcex].side != -1
                    return false
                end
            end
        else 
            for i = targety+1:sourcey-1
                if board[i][sourcex].side != -1
                    return false
                end
            end
        end
    else 
        return false
    end
    return true
end

#checks the valid moves for side_mover
#done
function side_mover(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !check_side(board, sourcex, sourcey, targetx, targety)
        #only combinations: (x, y+1/y-1)
        if targety == sourcey
            if targetx == sourcex+1 || targetx == sourcex-1
                return true
            end
        end
        return false
    else
        return true
    end
end

#checks valid moves for free boar(promoted side mover)
#done
function p_side_mover(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety) || check_side(board, sourcex, sourcey, targetx, targety)
        return true
    end
    return false
end

#checks if the moves are allowed, piece: vertical mover
#done
function vertical_mover(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !chariot(board, sourcex, sourcey, targetx, targety)
        #only combinations: (x, y+1/y-1)
        if targetx == sourcex
            if targety == targety+1 || targety == targety-1
                return true
            end
        end
        return false
    else
        return true
    end
end

#checks if the moves are allowed, piece: flying stag (promoted tiger)
#done
function p_tiger(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !vertical_mover(board, sourcex, sourcey, targetx, targety)
        #only combinations: (x+1/x-1, y+1/y-1)
        if targety == targety+1 || targety == targety-1
            if targetx == sourcex+1 || targetx == sourcex-1
                return true
            end
        end
        return false
    else
        return true
    end
end

#checks if the moves are allowed, black piece: whale (promoted reverse chariot)
#done
function p_chariot_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !chariot(board, sourcex, sourcey, targetx, targety)
        deltaX = abs(sourcex-targetx)
        deltaY = abs(sourcey-targety)

        if deltaX != deltaY
            return false
        end

        if targetx > sourcex && targety < sourcey # target is NE of bishop

            i = targetx
            j = targety
            while i > sourcex+1 && j < sourcey-1
                i -= 1
                j += 1
                if board[j][i].side != -1
                    return false
                end
            end

        elseif targetx > sourcex && targety > sourcey # target is SE of bishop

            i = targetx
            j = targety
            while i > sourcex+1 && j > sourcey+1
                i -= 1
                j -= 1
                if board[j][i].side != -1
                    return false
                end
            end
        else 
            return false
        end
        return true
    else
        return true
    end
end

#checks if the moves are allowed, white piece: whale (promoted reverse chariot)
#done
function p_chariot_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !chariot(board, sourcex, sourcey, targetx, targety)
        deltaX = abs(sourcex-targetx)
        deltaY = abs(sourcey-targety)

        if deltaX != deltaY
            return false
        end

        if targetx < sourcex && targety < sourcey # target is NW of bishop

            i = targetx
            j = targety
            while i < sourcex-1 && j < sourcey-1
                i += 1
                j += 1
                if board[j][i].side != -1
                    return false
                end
            end

        elseif targetx < sourcex && targety > sourcey # target is SW of bishop

            i = targetx
            j = targety
            while i < sourcex-1 && j > sourcey+1
                i += 1
                j -= 1
                if board[j][i].side != -1
                    return false
                end
            end
        else 
            return false
        end
        return true
    else 
        return true
    end
end

#checks if the moves are allowed, black piece: white horse (promoted lance)
#done
function p_lance_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !p_chariot_white(board, sourcex, sourcey, targetx, targety)
        return false
    end
    return true
end

#checks if the moves are allowed, white piece: white horse (promoted lance)
#done
function p_lance_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if !p_chariot_black(board, sourcex, sourcey, targetx, targety)
        return false
    end
    return true
end

#checks if the moves are allowed, piece: kirin
#done
function kirin(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targety == targety+1 || targety == targety-1
        if targetx == sourcex+1 || targetx == sourcex-1
            return true
        end
        #check this
    elseif targety == sourcey && (targetx == sourcex-2 || targetx == sourcex+2)
        return true
    elseif targetx == sourcex && (targety == sourcey-2 || targety == sourcey+2)
        return true
    else 
        return false
    end
end

#checks if the moves are allowed, white piece: black piece: falcon
#done
function falcon_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
    side = board[sourcey][sourcex].side
    #check the skipping move thing.
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if check_side(board, sourcex, sourcey, targetx, targety) || bishop(board, sourcex, sourcey, targetx, targety) || lance_white(board, sourcex, sourcey, targetx, targety)
        return true
    else
        if targetx == sourcex-2 && targety == sourcey
            return true
        elseif targetx == sourcex-1 && targety == sourcey
            if targetx2== -1 && targetx2 == -1
                return false
            end
            if targetx2 == sourcex && targety2 == sourcey
                return true
            elseif targetx2 == sourcex-2 && targety2 == sourcey
                if !target_valid(board, targetx2, targety2, side) || !valid_boundaries(targetx, targety, targetx2, targety2)
                    return false
                end
                return true
            else
                return false 
            end
        else
            return false
        end
    end
end

#checks if the moves are allowed, white piece: falcon
#done
function falcon_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
    side = board[sourcey][sourcex].side
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if check_side(board, sourcex, sourcey, targetx, targety) || bishop(board, sourcex, sourcey, targetx, targety) || lance_black(board, sourcex, sourcey, targetx, targety)
        return true
    else
        if targetx == sourcex+2 && targety == sourcey
            return true
        elseif targetx == sourcex+1 && targety == sourcey
            if targetx2== -1 && targetx2 == -1
                return false
            end
            if targetx2 == sourcex && targety2 == sourcey
                return true
            elseif targetx2 == sourcex+2 && targety2 == sourcey
                if !target_valid(board, targetx2, targety2, side) || !valid_boundaries(targetx, targety, targetx2, targety2)
                    return false
                end
                return true
            else
                return false
            end
        else
            return false
        end
    end
end

#checks valid moves for soaring eagle_black
#done
function soaring_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
    side = board[sourcey][sourcex].side
     if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if p_chariot_black(board, sourcex, sourcey, targetx, targety) || check_side(board, sourcex, sourcey, targetx, targety)
        return true
    else
        if targetx == sourcex-2 && (targety == sourcey+2 || targety == sourcey-2)
            return true
        elseif targetx == sourcex-1 &&(targety == sourcey+1 || targety == sourcey-1)
            if targetx2== -1 && targetx2 == -1
                return false
            end
            if targetx2 == sourcex && targety2 == sourcey
                return true
            elseif targetx2 == sourcex-2 && (targety2 == sourcey+2 || targety == sourcey-2)
                if !target_valid(board, targetx2, targety2, side) || !valid_boundaries(targetx, targety, targetx2, targety2)
                    return false
                end
                return true
            else
                return false
            end
        else
            return false
        end
    end
end

#checks valid moves for soaring eagle_white
#done
function soaring_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
    side = board[sourcey][sourcex].side
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if p_chariot_white(board, sourcex, sourcey, targetx, targety) || check_side(board, sourcex, sourcey, targetx, targety)
        return true
    else
        if targetx == sourcex+2 && (targety == sourcey+2 || targety == sourcey-2)
            return true
        elseif targetx == sourcex+1 &&(targety == sourcey+1 || targety == sourcey-1)
            if targetx2== -1 && targetx2 == -1
                return false
            end
            if targetx2 == sourcex && targety2 == sourcey
                return true
            elseif targetx2 == sourcex+2 && (targety2 == sourcey+2 || targety2 == sourcey-2)
                if !target_valid(board, targetx2, targety2, side) || !valid_boundaries(targetx, targety, targetx2, targety2)
                    return false
                end
                return true
            else
                return false
            end
        else
            return false
        end
    end
end

#checks valid moves for phoenix(promotes to queen)
#done
function phoenix(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    if (targetx == sourcex+1 || targetx == sourcex-1) && targety == sourcey 
        return true
    elseif (targety == sourcey+1 || targety == sourcey-1) && targetx == sourcex 
        return true
    elseif targetx == sourcex+2 || targetx == sourcex-2
        if targety == sourcey+2 || targety == sourcey-2
            return true
        end
        return false
    else
        return false
    end
end

#checks if the moves are allowed, piece: lion
#done
function lion(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
    side = board[sourcey][sourcex].side
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    #checks for (x/x-1/x+1/x-2/x+2, y/y-1/y+1/y-2/y+2)
    if targetx > sourcex+2 || targetx < sourcex-2
        return false
    end
    if targety > sourcey+2 || targety < sourcey-2
        return false
    end 
    if king(board, sourcex, sourcey, targetx, targety)
        #make sure this check isn't problematic
        if targetx2== -1 && targetx2 == -1
            return false
        end
        #it can move back
        if targetx2 == sourcex && targety2 == sourcey
            return true
        else
            if !target_valid(board, targetx2, targety2, side) || !valid_boundaries(targetx, targety, targetx2, targety2)
                return false
            end
            if king(board, targetx, targety, targetx2, targety2)
                return true
            end
            return false
        end
    else 
        #means jump
        return true
    end
end

########################
#### Tenjiku pieces ####
########################

#Laura's Tenjiku fncs

#done
function prince(board, sourcex, sourcey, targetx, targety)
    if king(board, sourcex, sourcey, targetx, targety)
        return true
    end
    return false
end

#done
function is_capturing(board, sourcex, sourcey, targetx, targety)
    if board[targety][targetx].side != -1 || board[targety][targetx].side != board[sourcey][sourcex].side 
        return true
    end
    return false
end

#done
function vice(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
    side = board[sourcey][sourcex].side
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    if bgeneral(board, sourcex, sourcey, targetx, targety)
        return true
    end
    #first target
    if !king(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if king(board, sourcex, sourcey, targetx, targety) && is_capturing(board, sourcex, sourcey, targetx, targety)
        return true
    end
    #second target
    if !target_valid(board, targetx2, targety2, side) || same_coordinates(targetx, targety, targetx2, targety2) || !valid_boundaries(board, targetx, targety, targetx2, targety2) || !king(board, targetx, targety, targetx2, targety2)
        return false
    end
    if king(board, targetx, targety, targetx2, targety2) && is_capturing(board, targetx, targety, targetx2, targety2)
        return true
    end
    #third target
    if !target_valid(board, targetx3, targety3, side) || same_coordinates(targetx2, targety2, targetx3, targety3) || !valid_boundaries(board, targetx2, targety2, targetx3, targety3) || !king(board, targetx2, targety2, targetx3, targety3)
        return false
    end
    if king(board, targetx2, targety2, targetx3, targety3)
        return true
    end
    return false
end

#done
function bgeneral(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if is_capturing(board, sourcex, sourcey, targetx, targety) 
        if bishop(board, sourcex, sourcey, targetx, targety) 
            if board[targety][targetx].name == "king" || board[targety][targetx].name == "prince"
                return true
            end
        end
        deltaX = abs(sourcex-targetx)
        deltaY = abs(sourcey-targety)

        if deltaX != deltaY
            return false
        end

        if board[targety][targetx].name == "rgeneral" || board[targety][targetx].name == "bgeneral" || board[targety][targetx].name == "great" || board[targety][targetx].name == "vice"
            return true
        end

        if targetx < sourcex && targety < sourcey # target is NW of bishop

            i = targetx
            j = targety
            while i < sourcex-1 && j < sourcey-1
                i += 1
                j += 1
                if board[j][i].name == "king" || board[j][i].name == "prince" || board[j][i].name == "rgeneral" || board[j][i].name == "bgeneral" || board[j][i].name == "great" || board[j][i].name == "vice"
                    return false
                end
            end

        elseif targetx < sourcex && targety > sourcey # target is SW of bishop

            i = targetx
            j = targety
            while i < sourcex-1 && j > sourcey+1
                i += 1
                j -= 1
                if board[j][i].name == "king" || board[j][i].name == "prince" || board[j][i].name == "rgeneral" || board[j][i].name == "bgeneral" || board[j][i].name == "great" || board[j][i].name == "vice"
                    return false
                end
            end

        elseif targetx > sourcex && targety < sourcey # target is NE of bishop

            i = targetx
            j = targety
            while i > sourcex+1 && j < sourcey-1
                i -= 1
                j += 1
                if board[j][i].name == "king" || board[j][i].name == "prince" || board[j][i].name == "rgeneral" || board[j][i].name == "bgeneral" || board[j][i].name == "great" || board[j][i].name == "vice"
                    return false
                end
            end

        elseif targetx > sourcex && targety > sourcey # target is SE of bishop

            i = targetx
            j = targety
            while i > sourcex+1 && j > sourcey+1
                i -= 1
                j -= 1
                if board[j][i].name == "king" || board[j][i].name == "prince" || board[j][i].name == "rgeneral" || board[j][i].name == "bgeneral" || board[j][i].name == "great" || board[j][i].name == "vice"
                    return false
                end
            end

        else 
            return false
        end
        return true
    else 
        if bishop(board, sourcex, sourcey, targetx, targety)
            return true
        end
        return false
    end

    return true
end

function find_demons(board)
    arr = []
    boardLength = length(board)

    for i in 1:boardLength
        for j in 1:boardLength
            if board[j][i].name == "demon"
                push!(arr, board[j][i])
            end
        end
    end
    #println("array of demons ", arr)
    return arr
end

function demon_burning(board)
    arr = find_demons(board)
    if length(arr) == 0
        return board 
    end
    #println("array of demons in demon burning ", arr)
    for piece in arr
        endx = piece.x
        endy = piece.y

        side = piece.side
        board = demon_move_burn(board, endx+1, endy-1, side)
        board = demon_move_burn(board, endx+1, endy, side)
        board = demon_move_burn(board, endx+1, endy+1, side)
        board = demon_move_burn(board, endx, endy+1, side)
        board = demon_move_burn(board, endx, endy-1, side)
        board = demon_move_burn(board, endx-1, endy+1, side)
        board = demon_move_burn(board, endx-1, endy, side)
        board = demon_move_burn(board, endx-1, endy-1, side)
    end
    return board
end

#done
#find the demon and return true for everywhere it is valid to burn
#function check_burning(board, side)
    #=arr = find_demons(board)
    if length(arr) == 0
        return board 
    end
    for demon in eachindex(arr)
        piece = arr[demon]
        endx = piece.x
        endy = piece.y

        side = piece.side
        board = demon_move_burn(board, endx+1, endy-1, side)
        board = demon_move_burn(board, endx+1, endy, side)
        board = demon_move_burn(board, endx+1, endy+1, side)
        board = demon_move_burn(board, endx, endy+1, side)
        board = demon_move_burn(board, endx, endy-1, side)
        board = demon_move_burn(board, endx-1, endy+1, side)
        board = demon_move_burn(board, endx-1, endy, side)
        board = demon_move_burn(board, endx-1, endy-1, side)
        return board
    end
end


    #call this function after moving demon
    if find_demons(board, side) == piece("", "", 0, 0, -1, false)
        #demon was killed
        return false
    end
    #check all 8 adjacent spaces have been burnt except if demon
    piece = find_demons(board, side)
    endx = piece.x
    endy = piece.y
    side = piece.side

    if demon_valid(board, endx+1, endy-1, side) || demon_valid(board, endx+1, endy, side) || demon_valid(board, endx+1, endy+1, side) || demon_valid(board, endx, endy+1, side) || demon_valid(board, endx, endy-1, side) || demon_valid(board, endx-1, endy+1, side) || demon_valid(board, endx-1, endy, side) || demon_valid(board, endx-1, endy-1, side)
        return true
    end
    return false=#
#end

function demon(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
    side = board[sourcey][sourcex].side
    #valid = false
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety) || side_mover(board, sourcex, sourcey, targetx, targety)
        return true
    end

    #first target
    if !king(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if king(board, sourcex, sourcey, targetx, targety) && is_capturing(board, sourcex, sourcey, targetx, targety)
        return true
    end
    #second target
    if !target_valid(board, targetx2, targety2, side) || same_coordinates(targetx, targety, targetx2, targety2) || !valid_boundaries(board, targetx, targety, targetx2, targety2) || !king(board, targetx, targety, targetx2, targety2)
        return false
    end
    if king(board, targetx, targety, targetx2, targety2) && is_capturing(board, targetx, targety, targetx2, targety2)
        return true
    end
    #third target
    if !target_valid(board, targetx3, targety3, side) || same_coordinates(targetx2, targety2, targetx3, targety3) || !valid_boundaries(board, targetx2, targety2, targetx3, targety3) || !king(board, targetx2, targety2, targetx3, targety3)
        return false
    end
    if king(board, targetx2, targety2, targetx3, targety3)
        return true
    end
    return false
end

#done
function buffalo(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety) || side_mover(board, sourcex, sourcey, targetx, targety)
        return true
    end
    if targety == sourcey
        if targetx == sourcex-2 || targetx == sourcex+2 
            return true
        end
    end
    return false
end

#done
function vsoldier_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if lance_black(board, sourcex, sourcey, targetx, targety)
        return true
    end
    if targetx == sourcex
        if targety > sourcey+2 || targety < sourcey-2
            return false
        end
        return true
    end
    if targetx == sourcex+1 && targety == sourcey
        return true
    end
    return false
end

#done
function vsoldier_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if lance_white(board, sourcex, sourcey, targetx, targety)
        return true
    end
    if targetx == sourcex
        if targety > sourcey+2 || targety < sourcey-2
            return false
        end
        return true
    end
    if targetx == sourcex-1 && targety == sourcey
        return true
    end
    return false
end

#done
function iron_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex-1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        end
        return true
    end
    return false
end

#done
function iron_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if targetx == sourcex+1
        if targety > sourcey+1 || targety < sourcey-1
            return false
        end
        return true
    end
    return false
end

#done
function hawk(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety)
        return true
    end
    if lion(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
        return true
    end
    return false
end

#done
function multi_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if lance_black(board, sourcex, sourcey, targetx, targety)
        return true
    end

    deltaX = abs(sourcex-targetx)
    deltaY = abs(sourcey-targety)

    if deltaX != deltaY
        return false
    end

    if targetx > sourcex && targety < sourcey # target is NE of bishop

        i = targetx
        j = targety
        while i > sourcex+1 && j < sourcey-1
            i -= 1
            j += 1
            if board[j][i].side != -1
                return false
            end
        end

    elseif targetx > sourcex && targety > sourcey # target is SE of bishop

        i = targetx
        j = targety
        while i > sourcex+1 && j > sourcey+1
            i -= 1
            j -= 1
            if board[j][i].side != -1
                return false
            end
        end
    else 
        return false
    end
    return true
end

#done
function multi_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if lance_white(board, sourcex, sourcey, targetx, targety)
        return true
    end
    deltaX = abs(sourcex-targetx)
    deltaY = abs(sourcey-targety)

    if deltaX != deltaY
        return false
    end

    if targetx < sourcex && targety < sourcey # target is NW of bishop

        i = targetx
        j = targety
        while i < sourcex-1 && j < sourcey-1
            i += 1
            j += 1
            if board[j][i].side != -1
                return false
            end
        end

    elseif targetx < sourcex && targety > sourcey # target is SW of bishop

        i = targetx
        j = targety
        while i < sourcex-1 && j > sourcey+1
            i += 1
            j -= 1
            if board[j][i].side != -1
                return false
            end
        end
    else 
        return false
    end
    return true
end

#done
function dog_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if pawn_black(board, sourcex, sourcey, targetx, targety)
        return true
    end
    if targetx == sourcex+1
        if targety == sourcey-1 || targety == sourcey+1
            return true
        end
    end
    return false
end

#done
function dog_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if pawn_white(board, sourcex, sourcey, targetx, targety)
        return true
    end
    if targetx == sourcex-1
        if targety == sourcey-1 || targety == sourcey+1
            return true
        end
    end
    return false
end

###################
#Daniel's Tenjiku fncs


#done
function great(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if rgeneral(board, sourcex, sourcey, targetx, targety) || bgeneral(board, sourcex, sourcey, targetx, targety)
        return true
    end
    return false
end

function rgeneral(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    if is_capturing(board, sourcex, sourcey, targetx, targety) 
        if rook(board, sourcex, sourcey, targetx, targety) 
            if board[targety][targetx].name == "king" || board[targety][targetx].name == "prince"
                return true
            end
        end
        
        if sourcex == targetx
            if targety > sourcey
                if board[targety][targetx].name == "rgeneral" || board[targety][targetx].name == "bgeneral" || board[targety][targetx].name == "great" || board[targety][targetx].name == "vice"
                    return true
                end
                for i = sourcey+1:targety-1
                    if board[i][targetx].name == "king" || board[i][targetx].name == "prince" || board[i][targetx].name == "rgeneral" || board[i][targetx].name == "bgeneral" || board[i][targetx].name == "great" || board[i][targetx].name == "vice"
                        return false
                    end
                end
            else 
                if board[targety][targetx].name == "rgeneral" || board[targety][targetx].name == "bgeneral" || board[targety][targetx].name == "great" || board[targety][targetx].name == "vice"
                    return true
                end
                for i = targety+1:sourcey-1
                    if board[i][targetx].name == "king" || board[i][targetx].name == "prince" || board[i][targetx].name == "rgeneral" || board[i][targetx].name == "bgeneral" || board[i][targetx].name == "great" || board[i][targetx].name == "vice"
                        return false
                    end
                end
            end
        
        elseif sourcey == targety
            if targetx > sourcex
                if board[targety][targetx].name == "rgeneral" || board[targety][targetx].name == "bgeneral" || board[targety][targetx].name == "great" || board[targety][targetx].name == "vice"
                    return true
                end
                for i = sourcex+1:targetx-1
                    if board[i][targetx].name == "king" || board[i][targetx].name == "prince" || board[i][targetx].name == "rgeneral" || board[i][targetx].name == "bgeneral" || board[i][targetx].name == "great" || board[i][targetx].name == "vice"
                        return false
                    end
                end
            else 
                if board[targety][targetx].name == "rgeneral" || board[targety][targetx].name == "bgeneral" || board[targety][targetx].name == "great" || board[targety][targetx].name == "vice"
                    return true
                end
                for i = targetx+1:sourcex-1
                    if board[i][targetx].name == "king" || board[i][targetx].name == "prince" || board[i][targetx].name == "rgeneral" || board[i][targetx].name == "bgeneral" || board[i][targetx].name == "great" || board[i][targetx].name == "vice"
                        return false
                    end
                end
            end
        else 
            return false
        end

    else 
        if rook(board, sourcex, sourcey, targetx, targety)
            return true
        end
        return false
    end
    
    return true
end

#done
function csoldier(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if bishop(board, sourcex, sourcey, targetx, targety) || chariot(board, sourcex, sourcey, targetx, targety)
        return true
    elseif (targetx == sourcex) && ((targety == sourcey-1) ||(targety == sourcey-2) ||(targety == sourcey+1) ||(targety == sourcey+2))
        return true
    else
        return false
    end 
end

#done
function ssoldier_black(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if check_side(board, sourcex, sourcey, targetx, targety)
        return true
    elseif ((targetx == sourcex-1) || (targetx == sourcex-2)|| (targetx == sourcex+1)) && targety== sourcey
        return true
    else
        return false
    end
end

#done
function ssoldier_white(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    if check_side(board, sourcex, sourcey, targetx, targety)
        return true
    elseif ((targetx == sourcex+1) || (targetx == sourcex+2)|| (targetx == sourcex-1)) && targety== sourcey
        return true
    else
        return false
    end
end

function eagle(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
    side = board[sourcey][sourcex].side
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    #queen
    if queen(board, sourcex, sourcey, targetx, targety)
        return true
    end
    #jumps
    if (targetx == sourcex-2 || targetx == sourcex+2) && (targety == sourcey-2 || targety == sourcey+2)
        return true
    end
    if (targetx == sourcex-2 || targetx == sourcex+2) && targety == sourcey
        return true
    end
    if (targety == sourcey-2 || targety == sourcey+2) && targetx == sourcex
        return true
    end
    #lion move
    if (targetx == sourcex-1 || targetx == sourcex+1) && (targety == sourcey-1 || targety == sourcey+1)
        if !target_valid(board, targetx2, targety2, side) || same_coordinates(targetx, targety, targetx2, targety2) || !valid_boundaries(targetx, targety, targetx2, targety2)
            return false
        end
        if (targetx2 == targetx-1 || targetx2 == targetx+1) && (targety2 == targety-1 || targety2 == targety+1)
            return true
        end
    end
    return false
end

function tetrarch(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
    side = board[sourcey][sourcex].side
    if !target_valid(board, targetx, targety, side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end

    #igui -done
    if king(board, sourcex, sourcey, targetx, targety) && sourcex == targetx2 && sourcey == targety2
        return true
    end
    
    #jumps and vertical
    if targety == sourcey-2 && targety2 == sourcey-3 && targetx == sourcex
        return true
    end

    if targety == sourcey+2 && targety2 == sourcey+3 && targetx == sourcex
        return true
    end

    #jumps and horizontal 
    if (targetx == sourcex-2 || targetx == sourcex+2) && targety ===  sourcey
        if check_side(board, targetx, targety, targetx2, targety2)
            return true
        end
    end

    #jumps and bishop move
    #first target jumps to star
    if targety == sourcey-2
        if targetx == sourcex+2
            if ne_bishop(board,targetx, targety, targetx2, targety2)
                return true
            end
        elseif targetx == sourcex-2
            if nw_bishop(board,targetx, targety, targetx2, targety2)
                return true
            end
        else 
            return false
        end
    end
    if targety == sourcey+2
        if targetx == sourcex+2
            if se_bishop(board,targetx, targety, targetx2, targety2)
                return true
            end
        elseif targetx == sourcex-2
            if sw_bishop(board,targetx, targety, targetx2, targety2)
                return true
            end
        else 
            return false
        end
    end

    if king(board, sourcex, sourcey, targetx, targety)
        if !target_valid(board, targetx2, targety2, side) || same_coordinates(targetx, targety, targetx2, targety2) || !valid_boundaries(board, targetx, targety, targetx2, targety2)
            return false
        end
        #sliding sides
        if targety == targety2
            if targetx2 == sourcex-2 
                if lance_white(board, targetx2, targety2, targetx3, targety3)
                    return true
                end
            end
            if targetx2 == sourcex+2
                if lance_black(board, targetx2, targety2, targetx3, targety3)
                    return true
                end
            end
        #unique square at top
        elseif targetx == targetx2
            if !target_valid(board, targetx3, targety3, side) || same_coordinates(targetx2, targety2, targetx3, targety3) || !valid_boundaries(board, targetx2, targety2, targetx3, targety3)
               return false
            end
            if targety2 == sourcey-2
                if targety3 == sourcey-3
                    return true
                end
            end
            if targetx2 == sourcex+2
                if targety3 == sourcey+3
                    return true
                end
            end
        #sliding four corners
        elseif targety2 == sourcey-2
            #=if !target_valid(board, targetx3, targety3, side) || same_coordinates(targetx2, targety2, targetx3, targety3) || !valid_boundaries(board, targetx2, targety2, targetx3, targety3)
                return false
            end=#
            if targetx2 == sourcex+2
                if ne_bishop(board,targetx2, targety2, targetx3, targety3)
                    return true
                end
            elseif targetx2 == sourcex-2
                if nw_bishop(board,targetx2, targety2, targetx3, targety3)
                    return true
                end
            else 
                return false
            end
        elseif targety2 == sourcey+2
            #=if !target_valid(board, targetx3, targety3, side) || same_coordinates(targetx2, targety2, targetx3, targety3) || !valid_boundaries(board, targetx2, targety2, targetx3, targety3)
                return false
            end=#
            if targetx2 == sourcex+2
                if se_bishop(board,targetx2, targety2, targetx3, targety3)
                    return true
                end
            elseif targetx2 == sourcex-2
                if sw_bishop(board,targetx2, targety2, targetx3, targety3)
                    return true
                end
            else 
                return false
            end
        else
            return false
        end
    end
    return false
end

#done
function empty_square_drop(board, targetx, targety)
    #no matter what, the piece cannot be dropped in a non-empty square for drop
    if board[targety][targetx].name != ""
        return false
    else 
        return true
    end
end

#updte this
#done
function promotion_check(board, sourcex, sourcey, targetx, targety)
    boardLength = length(board)
    #println(boardLength)
    if boardLength == 5
        gameType = "minishogi"
    elseif boardLength == 9 
        gameType = "standard"   
    elseif boardLength == 12
        gameType = "chu"
    else 
        gameType = "ten"
    end

    if gameType == "standard"
        #if black then only lines form 1-3
        if board[sourcey][sourcex].side == 1 && (1<=targetx<=3)
            return true
        #if white then only lines form 7-9
        elseif board[sourcey][sourcex].side == 0 && (7<=targetx<=9)
            return true
        else
            return false
        end
    elseif gameType == "chu"
        #if black then only lines form 1-4
        if board[sourcey][sourcex].side == 1 && (1<=targetx<=4)
            return true
        #if white then only lines form 9-12
        elseif board[sourcey][sourcex].side == 0 && (9<=targetx<=12)
            return true
        else
            return false
        end
    elseif gameType == "ten"
        #if black then only lines form 1-4
        if board[sourcey][sourcex].side == 1 && (1<=targetx<=4)
            return true
        #if white then only lines form 12-16
        elseif board[sourcey][sourcex].side == 0 && (12<=targetx<=16)
            return true
        else
            return false
        end
    else #gameType == "mini"
        #if black then only top line
        if board[sourcey][sourcex].side == 1 && targetx == 1
            return true
        #if white then only last line
        elseif board[sourcey][sourcex].side == 0 && targetx == 5
            return true
        else
            return false
        end
    end
end

#DROP STUFF STARTS HERE

#done -> returns ::piece
function find_opposite_king(board, side)
    boardLength = length(board)
    for i in 1:boardLength
        for j in 1:boardLength
            if board[j][i].name == "king" && board[j][i].side != side
                return board[j][i]
            end
        end
    end
    return false
end

#=
#changes all possible promoted pieces back to normal
#done
function promotion_change_drop(board, targetx, targety)
    if board[targety][targetx].name == 'P' 
        board[targety][targetx].name == 'p'
    
    elseif board[targety][targetx].name == 'L'
        board[targety][targetx].name == 'l'
 
    elseif board[targety][targetx].name == 'N' 
        board[targety][targetx].name == 'n'

    elseif board[targety][targetx].name == 'S'
        board[targety][targetx].name == 's'

    elseif board[targety][targetx].name == 'B'
        board[targety][targetx].name == 'b'

    elseif board[targety][targetx].name == 'R'
        board[targety][targetx].name == 'r'
    end
end
=#

#checks if the dropped piece has at least one allowed move
#done
function allowed_moves_drop(board, piece, targetx, targety, side)
    #piece all of them
    if piece == "rook"
        if rook(board, targetx,targety,targetx+1,targety) || rook(board, targetx,targety,targetx-1,targety) || rook(board, targetx,targety,targetx,targety+1) || rook(targetx,targety,targetx,targety-1)
            return true
        end
    elseif (piece == "pawn" && side == 1) || (piece == "lance" && side == 1)
        if pawn_black(board, targetx,targety,targetx-1,targety)
            return true
        end
    elseif (piece== "pawn" && side == 0) || (piece == "lance" && side == 0)
        if pawn_white(board, targetx,targety,targetx+1,targety)
            return true
        end
    elseif piece== "gold" && side == 1
        if  gold_black(board, targetx,targety,targetx+1,targety) ||  gold_black(board, targetx,targety,targetx-1,targety) || gold_black(board, targetx,targety,targetx,targety+1) ||  gold_black(board, targetx,targety,targetx,targety-1) || gold_black(board, targetx,targety,targetx-1,targety-1) ||  gold_black(board, targetx,targety,targetx-1,targety+1) 
            return true
        end
    elseif piece== "gold" && side == 0
        if  gold_white(board, targetx,targety,targetx+1,targety) ||  gold_white(board, targetx,targety,targetx-1,targety) || gold_white(board, targetx,targety,targetx,targety+1) ||  gold_white(board, targetx,targety,targetx,targety-1) || gold_white(board, targetx,targety,targetx+1,targety+1) ||  gold_white(board, targetx,targety,targetx+1,targety-1) 
            return true
        end
    elseif piece== "silver" && side == 1
        if  silver_black(board, targetx,targety,targetx-1,targety-1) ||  silver_black(board, targetx,targety,targetx-1,targety+1) || silver_black(board, targetx,targety,targetx-1,targety) || silver_black(board, targetx,targety,targetx+1,targety+1) ||  silver_black(board, targetx,targety,targetx+1,targety-1) 
            return true
        end
    elseif piece== "silver" && side == 0
        if  silver_white(board, targetx,targety,targetx+1,targety+1) ||  silver_white(board, targetx,targety,targetx-1,targety+1) || silver_white(board, targetx,targety,targetx+1,targety) || silver_white(board, targetx,targety,targetx+1,targety-1) ||  silver_white(board, targetx,targety,targetx-1,targety-1)
            return true
        end
    elseif piece== "bishop"
        if bishop(board, targetx,targety,targetx+1,targety+1) || bishop(board, targetx,targety,targetx-1,targety-1) || bishop(board, targetx,targety,targetx+1,targety-1) || bishop(board, targetx,targety,targetx-1,targety+1)
            return true
        end
    elseif piece== "knight" && side == 1
        if knight_black(board, targetx,targety,targetx-2,targety-1) || knight_black(board, targetx,targety,targetx-2,targety+1)
            return true
        end
    elseif piece== "knight" && side == 0
        if knight_white(board, targetx,targety,targetx+2,targety-1) || knight_white(board, targetx,targety,targetx+2,targety+1)
            return true
        end
    else
        return false
    end
end

#checks if the drop is valid
#done
function drop_check(board, piece, targetx, targety, side, capturedByOdd, capturedByEven)
    boardLength = length(board)
    piece_name = piece

    if piece_name == "king"  #cannot drop a king
       return false
    end
    #promotion_change_drop(board, targetx, targety) #cannot drop promoted piece, so change to unpromoted

    king = find_opposite_king(board, side)

    if allowed_moves_drop(piece_name, targetx, targety, side)
        if !inRange(board, move(-1, "move", targetx, targety, king.x, king.y, "", false, -1, -1, -1, -1)) ############ using inKillingRange function from move.jl
            if piece_name == "pawn" #if its a pawn cannot be on the same column as a pawn of that player
                for i=1:boardLength
                    if board[i][targetx].name == "pawn"
                        return false
                    end
                end
            end

            if side == 1 && length(capturedByOdd)>0
                for i in eachindex(capturedByOdd)
                    if isdefined(capturedByOdd, i)
                        if piece_name == lowercase(capturedByOdd[i].name)
                            return false
                        end
                    end
                end
                return true
            elseif side == 0 && length(capturedByEven)>0
                for i in eachindex(capturedByEven)
                    if isdefined(capturedByEven, i)
                        if piece_name == lowercase(capturedByEven[i].name)
                            return false
                        end
                    end
                end
                return true
            else 
                return false   
            end
        end
    end
    return false #if is in range to kill or if it has no allowed moves
end

#checks if they have the piece in their captured bank (this fnc needs to be called before dropping)
#done
function before_drop_check(piece, side, capturedByOdd, capturedByEven)
    #black dropping
    if side == 1
            if length(capturedByOdd)>0
                for i in eachindex(capturedByOdd)
                     if isdefined(capturedByOdd, i)
                        if piece == lowercase(capturedByOdd[i].name)
                            return true
                        end
                    end
                end
                return false
            else 
                return false
            end   
    #white dropping
    elseif side == 0
        if length(capturedByEven)>0
            for i in eachindex(capturedByEven)
                if isdefined(capturedByEven, i)
                    if piece == lowercase(capturedByEven[i].name)
                        return true
                    end
                end
            end
            return false
        else
            return false
        end
    else
        return false
    end
end

#DROP STUFF END HERE

## for inkillrange - will check for the maximum range of lion.
function lionRange(board, sourcex, sourcey, targetx, targety)
    if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
        return false
    end
    #the lion can only move to any combination: (x-2/x-1/x/x+1/x-1, /y-2/y-1/y/y+1/y+2)
    if targetx > sourcex+2 || targetx < sourcex-2
        return false
    elseif targety > sourcey+2 || targety < sourcey-2
        return false
    else 
        return true
    end
end


#main for standard and mini
function standard_mini(board, sourcex, sourcey, targetx, targety, option)
    #checks if is in valid line for promotion
    #println(option)
    if option == "!" || option == '!'
       # println("entered option")
        if !promotion_check(board, sourcex, sourcey, targetx, targety)
            return false
        end
    end

    #println("starts looking for name 2 : ", board[sourcey][sourcex].name)
    if board[sourcey][sourcex].name == "king"
           #println("enters 0")
        if king(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "rook"
        if rook(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "bishop"
        if bishop(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "dragon"
        if dragon_king(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "horse"
        if dragon_horse(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "gold"
        #if move number (aka i) is odd then black 
        if board[sourcey][sourcex].side == 1
            if gold_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if gold_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "silver"
        if board[sourcey][sourcex].side == 1
            if silver_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if silver_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "knight"
        if board[sourcey][sourcex].side == 1
            if knight_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if knight_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "lance"
        if board[sourcey][sourcex].side == 1
            if lance_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if lance_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "pawn"
        #println("enters 1")
        if board[sourcey][sourcex].side == 1
                    #println("enters 2")
            if pawn_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if pawn_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    else 
        return false
    end
    return false
end

function dropping(board, targetx, targety, option, side)
    boardLength = length(board)

    if targetx > boardLength || targety > boardLength || targetx < 1|| targety < 1 
        return false
    end

    #check that they have the piece that is being droppped (call before actually dropping)
    if !before_drop_check(option, side, capturedByOdd, capturedByEven) 
        return false
    end

    if option != "" && option != "!"
        if drop_check(board, option, targetx, targety, side, capturedByOdd, capturedByEven)
            return true
        else 
            return false
        end
    else
        return false
    end
end

#main for chu
function chu(board, sourcex, sourcey, targetx, targety, targetx2, targety2, option)
    #checks if is in valid line for promotion
    if option == "!" || option == '!'
        if targetx2 != -1 && targety2 != -1 
            if !(promotion_check(board, sourcex, sourcey, targetx, targety) || promotion_check(board, targetx, targety, targetx2, targety2))
                return false
            end
        else
            if !promotion_check(board, sourcex, sourcey, targetx, targety)
                return false
            end
        end
    end

    if board[sourcey][sourcex].name == "cobra"
        if go_between(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "elephant"
        if board[sourcey][sourcex].side == 1
            if elephant_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if elephant_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "pawn"
        if board[sourcey][sourcex].side == 1
            if pawn_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if pawn_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name == "gold" 
        if board[sourcey][sourcex].side == 1
            if gold_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if gold_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name == "smover"
        if side_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "boar"
        #promoted side mover is free boar
        if p_side_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "vmover"
        if vertical_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "ox"
        #promoted vertical mover is flying ox
        if p_vertical_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "bishop"
        if bishop(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "horse"
        if dragon_horse(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "rook" 
        if rook(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "dragon"
        if dragon_king(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "falcon"
        if board[sourcey][sourcex].side == 1
            if falcon_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        else 
            if falcon_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        end
    elseif board[sourcey][sourcex].name == "soaring"
        if board[sourcey][sourcex].side  == 1
            if soaring_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        else 
            if soaring_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "lance"
        if board[sourcey][sourcex].side  == 1
            if lance_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if lance_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "white"
        #white horse == promoted lance
        if board[sourcey][sourcex].side == 1
            if p_lance_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if p_lance_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "chariot"
        if chariot(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "whale"
        #promoted reverse chariot == whale
        if board[sourcey][sourcex].side == 1
            if p_chariot_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if p_chariot_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "tiger"
        if board[sourcey][sourcex].side == 1
            if tiger_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if tiger_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "stag"
        #flying stag == promoted blind tiger
        if p_tiger(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "leopard"
        if leopard(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "copper"
        if board[sourcey][sourcex].side == 1
            if copper_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if copper_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "silver"
        if board[sourcey][sourcex].side == 1
            if silver_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if silver_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "king"
        #promoted drunk elephant == king == prince
        if king(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "kirin"
        #n in chu shogi is kirin
        if kirin(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "lion"
        #promoted kirin == lion
        if lion(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "phoenix"
        if phoenix(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "queen"
        if queen(board, sourcex, sourcey, targetx, targety)
            return true
        end
    else 
        return false
    end
    return false
end

function ten(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3, option)
       #checks if is in valid line for promotion
    if option == "!" || option == '!'
        if targetx2 != -1 && targety2 != -1  && targetx3 != -1 && targety3 != -1 
            if !(promotion_check(board, sourcex, sourcey, targetx, targety) || promotion_check(board, targetx, targety, targetx2, targety2) || promotion_check(board, targetx2, targety2, targetx3, targety3))
                return false
            end
        elseif targetx2 != -1 && targety2 != -1 
            if !(promotion_check(board, sourcex, sourcey, targetx, targety) || promotion_check(board, targetx, targety, targetx2, targety2))
                return false
            end
        else
            if !promotion_check(board, sourcex, sourcey, targetx, targety)
                return false
            end
        end
    end

    if board[sourcey][sourcex].name == "elephant"
        if board[sourcey][sourcex].side == 1
            if elephant_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if elephant_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "pawn"
        if board[sourcey][sourcex].side == 1
            if pawn_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if pawn_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name == "gold" 
        if board[sourcey][sourcex].side == 1
            if gold_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if gold_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name == "smover"
        if side_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "boar"
        #promoted side mover is free boar
        if p_side_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "vmover"
        if vertical_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "ox"
        #promoted vertical mover is flying ox
        if p_vertical_mover(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "bishop"
        if bishop(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "horse"
        if dragon_horse(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "rook" 
        if rook(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "dragon"
        if dragon_king(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name == "falcon"
        if board[sourcey][sourcex].side == 1
            if falcon_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        else 
            if falcon_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        end
    elseif board[sourcey][sourcex].name == "soaring"
        if board[sourcey][sourcex].side  == 1
            if soaring_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        else 
            if soaring_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "lance"
        if board[sourcey][sourcex].side  == 1
            if lance_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if lance_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "white"
        #white horse == promoted lance
        if board[sourcey][sourcex].side == 1
            if p_lance_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if p_lance_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "chariot"
        if chariot(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "whale"
        #promoted reverse chariot == whale
        if board[sourcey][sourcex].side == 1
            if p_chariot_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if p_chariot_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "tiger"
        if board[sourcey][sourcex].side == 1
            if tiger_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if tiger_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "stag"
        #flying stag == promoted blind tiger
        if p_tiger(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "leopard"
        if leopard(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "copper"
        if board[sourcey][sourcex].side == 1
            if copper_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if copper_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "silver"
        if board[sourcey][sourcex].side == 1
            if silver_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if silver_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "king"
        #promoted drunk elephant == king == prince
        if king(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "kirin"
        #n in chu shogi is kirin
        if kirin(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "lion"
        #promoted kirin == lion
        if lion(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "phoenix"
        if phoenix(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "queen"
        if queen(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "knight"
        if board[sourcey][sourcex].side == 1
            if knight_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if knight_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "prince"
        if prince(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "vice"
        if vice(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "great"
        if great(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "bgeneral"
        if bgeneral(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "rgeneral"
        if rgeneral(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "demon"
        if demon(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "tetrarch"
        if tetrarch(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "buffalo"
        if buffalo(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "csoldier"
        if csoldier(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "ssoldier"
        if board[sourcey][sourcex].side == 1
            if ssoldier_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if ssoldier_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "vsoldier"
        if board[sourcey][sourcex].side == 1
            if vsoldier_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if vsoldier_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "iron"
        if board[sourcey][sourcex].side == 1
            if iron_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if iron_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "eagle"
        if eagle(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
           return true
        end
    elseif board[sourcey][sourcex].name ==  "hawk"
        if hawk(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
            return true
        end
    elseif board[sourcey][sourcex].name ==  "multi"
        if board[sourcey][sourcex].side == 1
            if multi_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if multi_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    elseif board[sourcey][sourcex].name ==  "dog"
        if board[sourcey][sourcex].side == 1
            if dog_black(board, sourcex, sourcey, targetx, targety)
                return true
            end
        else 
            if dog_white(board, sourcex, sourcey, targetx, targety)
                return true
            end
        end
    else 
        return false
    end
    #burning(board, board[sourcey][sourcex].side)
    return false
end

function validate(board, amove, capturedByOdd, capturedByEven)
    println("move number: $(amove.move_number)") # for debugging
    
    boardLength = length(board)

    if boardLength == 5
        gameType = "minishogi"
    elseif boardLength == 9 
        gameType = "standard"   
    elseif boardLength == 12
        gameType = "chu"
    else 
        gameType = "ten"
    end

    i = amove.move_number
    moveType = amove.move_type
    sourcex = amove.sourcex 
    sourcey = amove.sourcey 
    targetx = amove.targetx 
    targety = amove.targety 
    option = amove.option 
    targetx2 = amove.targetx2 
    targety2 = amove.targety2 
    targetx3 = amove.targetx3 
    targety3 = amove.targety3

    side = i % 2


    if moveType == "resign"
        return true
    end

    if moveType == "move"
        #println("it is a move")
        if board[sourcey][sourcex].side == 1 && !isodd(i)
            return false
        end
        if board[sourcey][sourcex].side == 0 && !iseven(i)
            return false
        end
        #check if the target is valid or if it is actually moving
        if !target_valid(board, targetx, targety, board[sourcey][sourcex].side) || same_coordinates(sourcex, sourcey, targetx, targety) || !valid_boundaries(board, sourcex, sourcey, targetx, targety)
                            #println("generals") 
            return false
        end

        if gameType == "chu"
            if chu(board, sourcex, sourcey, targetx, targety, targetx2, targety2, option)
                return true
            end    
        elseif gameType == "ten"
            if ten(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3, option)
                return true
            end
        else
                #println("stand mini 1") 
                #println("starts looking for name: ", board[sourcey][sourcex].name)
            if standard_mini(board, sourcex, sourcey, targetx, targety, option)
               # println("stand mini 2") 
                return true
            end
        end

    elseif moveType == "drop"
        if gameType == "chu" || gameType == "ten"
            return false
        end
        #arrays?
        if dropping(board, targetx, targety, option, board[sourcey][sourcex].side, capturedByOdd, capturedByEven)
            return true
        end
    else 
        return false
    end
    return false
end


function movePiece(gameType::String, board::Array{Array{piece,1},1}, move_number::Int64, sourceX, sourceY, targetX, targetY, option, targetX2, targetY2, targetX3, targetY3)
    global capturedByOdd
    global capturedByEven
    
    sourceX = Int64(get(sourceX))
    sourceY = Int64(get(sourceY))
    targetX = Int64(get(targetX))
    targetY = Int64(get(targetY))

    if board[targetY][targetX] != empty # there is currently a piece in the target location
        board[targetY][targetX].side = move_number%2
        if move_number%2 == 0 # even side
            push!(capturedByEven, board[targetY][targetX])
        else # odd side
            push!(capturedByOdd, board[targetY][targetX])
        end
    end
    board[targetY][targetX] = board[sourceY][sourceX] # move piece at source to target, removing piece in process
    board[targetY][targetX].x = targetX # setting piece x
    board[targetY][targetX].y = targetY # setting piece y
    board[sourceY][sourceX] = empty #set source space to empty

    if !isnull(targetX2) && !isnull(targetY2)
        targetX2 = Int64(get(targetX2))
        targetY2 = Int64(get(targetY2))

        if targetX2 >= 1 && targetX2 <= length(board[1]) && targetY2 >= 1 && targetY2 <= length(board)
            if board[targetY2][targetX2] != empty # there is currently a piece in the target location
                board[targetY2][targetX2].side = move_number%2
                if move_number%2 == 0 # even side
                    push!(capturedByEven, board[targetY2][targetX2])
                else # odd side
                    push!(capturedByOdd, board[targetY2][targetX2])
                end
            end
            board[targetY2][targetX2] = board[targetY][targetX] # move piece at source to target, removing piece in process
            board[targetY2][targetX2].x = targetX2 # setting piece x
            board[targetY2][targetX2].y = targetY2 # setting piece y
            board[targetY][targetX] = empty #set source space to empty
        end
    end

    if !isnull(targetX3) && !isnull(targetY3)
        targetX3 = Int64(get(targetX3))
        targetY3 = Int64(get(targetY3))

        if targetX3 >= 1 && targetX3 <= length(board[1]) && targetY3 >= 1 && targetY3 <= length(board)
            if board[targetY3][targetX3] != empty # there is currently a piece in the target location
                board[targetY3][targetX3].side = move_number%2
                if move_number%2 == 0 # even side
                    push!(capturedByEven, board[targetY3][targetX3])
                else # odd side
                    push!(capturedByOdd, board[targetY3][targetX3])
                end
            end
            board[targetY3][targetX3] = board[targetY2][targetX2] # move piece at source to target, removing piece in process
            board[targetY3][targetX3].x = targetX3 # setting piece x
            board[targetY3][targetX3].y = targetY3 # setting piece y
            board[targetY2][targetX2] = empty #set source space to empty
        end
    end

    if length(board) == 16
        board = demon_burning(board)
    end

    if !isnull(option)  # promote piece
        if get(option) == "!"
            board[targetY][targetX] = promote(board[targetY][targetX], gameType)
            ##println  (board[targetY][targetX])
        end
    end
end

function dropPiece(board::Array{Array{piece,1},1}, move_number::Int64, option, targetX, targetY)
    option = lowercase(get(option))
    targetX = Int64(get(targetX))
    targetY = Int64(get(targetY))
    
    # this is unnecessary because a piece can't be dropped where there is already an existing piece,
    # but I'm doing it anyway so in case of an illegal move, the piece isn't lost (it's captured)
    
    if board[targetY][targetX] != empty # there is currently a piece in the target location
        board[targetY][targetX].side = move_number%2
        if move_number%2 == 0 # even side
            push!(capturedByEven, board[targetY][targetX])
        else # odd side
            push!(capturedByOdd, board[targetY][targetX])
        end
    end
    
    droppedPiece = piece(option, option, targetX, targetY, move_number%2, false)
    board[targetY][targetX] = droppedPiece
    removeFromDropPool(board, droppedPiece)
end

function removeFromDropPool(board::Array{Array{piece,1},1}, droppedPiece::piece)
    global capturedByEven
    global capturedByOdd

    if droppedPiece.side == 0 # even side
        i = findfirst(capturedByEven, board[droppedPiece.y][droppedPiece.x])
        if i > 0
            deleteat!(capturedByEven, i)
        end
    else # odd side
        i = findfirst(capturedByOdd, board[droppedPiece.y][droppedPiece.x])
        if i > 0
            deleteat!(capturedByOdd, i)
        end
    end
end

# for debugging purposes
function displayBoard(board::Array{Array{piece,1},1})
    boardLength = length(board)
    println("\n")
    print("   ")
    for i = 1:boardLength
        if i < 10
            print("     $i      ")
        else 
            print("     $i     ")
        end
    end
    print("\n   ")
    for i = 1:(boardLength*12)
        print("-")
    end
    println("")
    for y = 1:boardLength
        print("  |")
        for x = 1:boardLength
            pieceName = board[y][x].name
            for i=length(pieceName)+1:9 # 9 chars in the longest name
                if i%2 == 0
                    pieceName = pieceName*" "
                else 
                    pieceName = " "*pieceName
                end
            end
            if board[y][x].name == "king" && board[y][x].side == 0
                print_with_color(:green, " $pieceName ")
            elseif board[y][x].name == "king" && board[y][x].side == 1
                print_with_color(:yellow, " $pieceName ")
            elseif board[y][x].side == 1
                print_with_color(:blue, " $pieceName ")
            elseif board[y][x].side == 0
                print_with_color(:red, " $pieceName ")
            else 
                print(" $pieceName ")
            end
            print("|")      
        end
        print(" $y\n   ")
        for i = 1:(boardLength*12)
            print("-")
        end
        println("")
    end
end

# this function returns the best piece to be dropped and where to drop it
function pickPieceDrop(board::Array{Array{piece,1},1}, move_number::Int64, capturedByOdd, capturedByEven)
    
    ourPieces = []
    enemyPieces = []

    for y = 1:length(board)
        for x = 1:length(board)
            if board[y][x].side == move_number%2
                push!(ourPieces, board[y][x])
            else 
                push!(enemyPieces, board[y][x])
            end
        end
    end

    if currentMove %2 == 0 # even player's turn
        dropBank = capturedByEven
    else 
        dropBank = capturedByOdd
    end

    rankedPieces = ["demon","great","vice","hawk","rgeneral","eagle","queen","bgeneral","falcon","lion","soaring","csoldier","buffalo","dragon","horse","rook","bishop","vsoldier","ssoldier","vmover","smover","lance","chariot","king","phoenix","kirin","elephant","gold","leopard","tiger","silver","copper","iron","knigh","dog","pawn"]
    best = piece("", "", 0, 0, -1, false)
    for bestPiece in rankedPieces
        for apiece in dropBank
            if apiece.name == bestPiece
                best = apiece
                break
            end
        end
    end

    if best.side == -1
        return best, 0, 0
    end

    safeMoves = []
    for y in length(board)
        for x in length(board[1])
            if board[y][x].side != move_number%2 && board[y][x].side != -1
                for apiece in enemyPieces
                    if !inRange(board, move(move_number, "move", apiece.x, apiece.y, x, y, "", false, -1, -1, -1, -1))
                        push!(safeMoves, (x,y))
                    end
                end
            end
        end
    end
    srand()
    targetX, targetY = safeMoves[rand(1:length(safeMoves))]

    return best, targetX, targetY
end

#checks if sourcePiece can kill targetPiece
function inRange(board::Array{Array{piece,1},1}, amove::move)

    name = board[amove.sourcey][amove.sourcex].name
    side = board[amove.sourcey][amove.sourcex].side
    sourcex = amove.sourcex
    sourcey = amove.sourcey
    targetx = amove.targetx
    targety = amove.targety
    targetx2 = amove.targetx2
    targety2 = amove.targety2
    targetx3 = amove.targetx3
    targety3 = amove.targety3

    #println(name)
    #=println(board[sourcey][sourcex])
    if board[sourcey][sourcex].side == -1
        return false
    end=#
    if name == "cobra" && go_between(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "elephant"
        if side == 1 && elephant_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && elephant_white(board, sourcex, sourcey, targetx, targety)
            return true 
        end 
    elseif name == "pawn"
        #println("something 1")
        if side == 1 && pawn_black(board, sourcex, sourcey, targetx, targety)
            #println("something 2")
            return true
        elseif side == 0 && pawn_white(board, sourcex, sourcey, targetx, targety)
            #println("something 3")
            return true
        end
    elseif name == "gold"
        if side == 1 && gold_black(board, sourcex, sourcey, targetx, targety)
            return true 
        elseif side == 0 && gold_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "smover" && side_mover(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "boar" && p_side_mover(board, sourcex, sourcey, targetx, targety)
        return true 
    elseif name == "vmover" && vertical_mover(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "ox" && p_vertical_mover(board, sourcex, sourcey, targetx, targety)
        return true 
    elseif name == "bishop" && bishop(board, sourcex, sourcey, targetx, targety)
        #println("something 4")
        return true 
    elseif name == "horse" && dragon_horse(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "rook" && rook(board, sourcex, sourcey, targetx, targety)
        return true 
    elseif name == "dragon" && dragon_king(board, sourcex, sourcey, targetx, targety)
        return true 
    elseif name == "falcon"
        if side == 1 && falcon_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
            return true 
        elseif side == 0 && falcon_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
            return true 
        end
    elseif name == "soaring"
        if side == 1 && soaring_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
            return true 
        elseif side == 0 && soaring_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
            return true 
        end
    elseif name == "lance"
        if side == 1 && lance_black(board, sourcex, sourcey, targetx, targety)
            return true 
        elseif side == 0 && lance_white(board, sourcex, sourcey, targetx, targety)
            return true 
        end
    elseif name == "white"
        if side == 1 && p_lance_black(board, sourcex, sourcey, targetx, targety)
                return true
        elseif side == 0 && p_lance_white(board, sourcex, sourcey, targetx, targety)
            return true 
        end
    elseif name == "chariot" && chariot(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "whale"
        if side == 1 && p_chariot_black(board, sourcex, sourcey, targetx, targety)
            return true 
        elseif side == 0 && p_chariot_white(board, sourcex, sourcey, targetx, targety)
            return true 
        end
    elseif name == "tiger"
        if side == 1 && tiger_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && tiger_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "stag" && p_tiger(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "leopard" && leopard(board, sourcex, sourcey, targetx, targety)
        return true 
    elseif name == "copper"
        if side == 1 && copper_black(board, sourcex, sourcey, targetx, targety)
            return true 
        elseif side == 0 && copper_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "silver"
        if side == 1 && silver_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && silver_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "king" && king(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "kirin" && kirin(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "lion" && lion(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
        return true
    elseif name == "phoenix" && phoenix(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "queen" && queen(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "knight"
        if side == 1 && knight_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && knight_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "prince" && prince(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "vice" && vice(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
        return true
    elseif name == "great" && great(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "bgeneral" && bgeneral(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "rgeneral" && rgeneral(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "demon" && demon(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
        return true
    elseif name == "tetrarch" && tetrarch(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3)
        return true
    elseif name == "buffalo" && buffalo(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "csoldier" && csoldier(board, sourcex, sourcey, targetx, targety)
        return true
    elseif name == "ssoldier"
        if side == 1 && ssoldier_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && ssoldier_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "vsoldier"
        if side == 1 && vsoldier_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && vsoldier_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "iron"
        if side == 1 && iron_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && iron_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "eagle" && eagle(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
        return true
    elseif name == "hawk" && hawk(board, sourcex, sourcey, targetx, targety, targetx2, targety2)
        return true
    elseif name == "multi"
        if side == 1 && multi_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && multi_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    elseif name == "dog"
        if side == 1 && dog_black(board, sourcex, sourcey, targetx, targety)
            return true
        elseif side == 0 && dog_white(board, sourcex, sourcey, targetx, targety)
            return true
        end
    end
    return false
end

# return sourceX, sourceY, targetX, targetY of winning move
function checkForWin(board::Array{Array{piece,1},1}, ourPieces, enemyKing::piece)
    #check if ourPieces are within king kill range
    for apiece in ourPieces
        if inRange(board, move(-1, "move", apiece.x, apiece.y, enemyKing.x, enemyKing.y, "", false, -1, -1, -1, -1))
            #do this move to win
            return apiece.x, apiece.y, enemyKing.x, enemyKing.y
        end
    end
    return 0,0,0,0
end

# returns true if our king is in check; o/w false
function checkForCheck(board::Array{Array{piece,1},1}, enemyPieces, ourKing::piece)

    for aEnemyPiece in enemyPieces
        if inRange(board, move(-1, "move", aEnemyPiece.x, aEnemyPiece.y, ourKing.x, ourKing.y, "", false, -1, -1, -1, -1))
            return true
        end
    end
    return false
end

# check if a piece can block the check that king is in
# precondition: only 1 piece can currently assassinate our king
# return sourceX, sourceY, targetX, targetY of move that can block check; o/w returns 0,0,0,0
function checkForBlock(board::Array{Array{piece,1},1}, move_number::Int64)

    ourPieces = []
    killerPiece = piece("", "", 0, 0, -1, false) # opponent piece that threatens the life of our majesty
    ourKing = piece("", "", 0, 0, -1, false)

    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side == move_number%2
                if board[y][x].name == "king"
                    ourKing = duplicatePiece(board[y][x])
                end
                push!(ourPieces, board[y][x])
            end
        end
    end

    for y = 1:length(board)
        for x = 1:length(board[1])
            if (board[y][x].side != move_number%2) && (board[y][x].side != -1) && inRange(board, move(move_number, "move", board[y][x].x, board[y][x].x, ourKing.x, ourKing.y, "", false, -1, -1, -1, -1))
                killerPiece = board[y][x]
            end
        end
    end



    # loop thru board and make array of moves on killer piece's path
    # identify moves that are on path of king killing

    killerPath = [] # an array of coordinate tuples

    if killerPiece.name == "lance"
        # assert: y coordinates of king and lance must be same since lance can only move vertically
        if ourKing.x > killerPiece.x # king is to the right of the lance
            for i = killPiece.x+1:ourKing.x-1
                push!(killerPath, (i, killerPiece.y))
            end
        else # king is on top, lance can move up 
            for i = ourKing.x+1:killerPiece.x-1
                push!(killerPath, (i, killerPiece.y))
            end
        end
    elseif killerPiece.name in ["rook", "dragon"]
        if ourKing.x == killerPiece.x 
            if ourKing.y > killerPiece.y # king is on bottom, rook can move down
                for i = killPiece.y+1:ourKing.y-1
                    push!(killerPath, (killerPiece.x, i))
                end
            else # king is on top, rook can move up 
                for i = ourKing.y+1:killerPiece.y-1
                    push!(killerPath, (killerPiece.x, i))
                end
            end
        elseif ourKing.y == killerPiece.y 
            if ourKing.x > killerPiece.x # king is on left, rook can move left 
                for i = killerPiece.x+1:ourKing.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            else # king is on right, rook can move right
                for i = ourKing.x+1:killerPiece.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            end
        end
    elseif killerPiece.name in ["bishop", "horse"]
        sourcex = killerPiece.x
        sourcey = killerPiece.y
        targetx = ourKing.x 
        targety = ourKing.y
        if targetx < sourcex && targety < sourcey # target is NE of bishop
            i = targetx
            j = targety
            while i < sourcex-1 && j < sourcey-1
                i += 1
                j += 1
                push!(killerPath, (i, j))
            end
        elseif targetx < sourcex && targety > sourcey # target is SE of bishop
            i = targetx
            j = targety
            while i < sourcex-1 && j > sourcey+1
                i += 1
                j -= 1
                push!(killerPath, (i, j))
            end
        elseif targetx > sourcex && targety < sourcey # target is NW of bishop
            i = targetx
            j = targety
            while i > sourcex+1 && j < sourcey-1
                i -= 1
                j += 1
                push!(killerPath, (i, j))
            end
        elseif targetx > sourcex && targety > sourcey # target is SW of bishop
            i = targetx
            j = targety
            while i > sourcex+1 && j > sourcey+1
                i -= 1
                j -= 1
                push!(killerPath, (i, j))
            end
        end
    elseif killerPiece.name in ["chariot", "vmover", "stag"]
        if ourKing.x > killerPiece.x 
            for i = killerPiece.x+1:ourKing.x-1
                push!(killerPath, (i, killerPiece.y))
            end
        else 
            for i = ourKing.x+1:killerPiece.x-1
                push!(killerPath, (i, killerPiece.y))
            end
        end
    elseif killerPiece.name == "smover"
        if ourKing.y > killerPiece.y 
            for i = killPiece.y+1:ourKing.y-1
                push!(killerPath, (killerPiece.x, i))
            end
        else 
            for i = ourKing.y+1:killerPiece.y-1
                push!(killerPath, (killerPiece.x, i))
            end
        end
    elseif killerPiece.name == "whale"
        if ourKing.y == killerPiece.y
            if ourKing.x > killerPiece.x 
                for i = killerPiece.x+1:ourKing.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            else 
                for i = ourKing.x+1:killerPiece.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            end
        else 
            sourcex = killerPiece.x
            sourcey = killerPiece.y
            targetx = ourKing.x 
            targety = ourKing.y
            if killerPiece.side == 0
                if targetx < sourcex && targety > sourcey
                    i = targetx
                    j = targety
                    while i < sourcex-1 && j > sourcey+1
                        i += 1
                        j -= 1
                        push!(killerPath, (i, j))
                    end
                elseif targetx < sourcex && targety < sourcey # target is NE of bishop
                    i = targetx
                    j = targety
                    while i < sourcex-1 && j < sourcey-1
                        i += 1
                        j += 1
                        push!(killerPath, (i, j))
                    end
                end
            elseif killerPiece.side == 1
                if targetx > sourcex && targety < sourcey # target is NW of bishop
                    i = targetx
                    j = targety
                    while i > sourcex+1 && j < sourcey-1
                        i -= 1
                        j += 1
                        push!(killerPath, (i, j))
                    end
                elseif targetx > sourcex && targety > sourcey # target is SW of bishop
                    i = targetx
                    j = targety
                    while i > sourcex+1 && j > sourcey+1
                        i -= 1
                        j -= 1
                        push!(killerPath, (i, j))
                    end
                end
            end
        end
    elseif killerPiece.name == "falcon"
        if (killerPiece.x == ourKing.x) || (killerPiece.y == ourKing.y)
            if ourKing.x == killerPiece.x 
                if ourKing.y > killerPiece.y # king is on bottom, rook can move down
                    for i = killPiece.y+1:ourKing.y-1
                        push!(killerPath, (killerPiece.x, i))
                    end
                else # king is on top, rook can move up 
                    for i = ourKing.y+1:killerPiece.y-1
                        push!(killerPath, (killerPiece.x, i))
                    end
                end
            elseif ourKing.y == killerPiece.y 
                if killerPiece.side == 0 && (ourKing.x < killerPiece.x)
                    for i = ourKing.x+1:killerPiece.x-1
                        push!(killerPath, (i, ourKing.y))
                    end
                elseif killerPiece.side == 1 (ourKing.x > killerPiece.x)
                    for i = killerPiece.x+1:ourKing.x-1
                        push!(killerPath, (i, ourKing.y))
                    end
                end
            end
        else
            sourcex = killerPiece.x
            sourcey = killerPiece.y
            targetx = ourKing.x 
            targety = ourKing.y
            if targetx < sourcex && targety < sourcey # target is NE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j < sourcey-1
                    i += 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx < sourcex && targety > sourcey # target is SE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j > sourcey+1
                    i += 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety < sourcey # target is NW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j < sourcey-1
                    i -= 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety > sourcey # target is SW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j > sourcey+1
                    i -= 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            end
        end
    elseif killerPiece.name == "soaring"
        if killerPiece.x == ourKing.x || killerPiece.y == ourKing.y
            if ourKing.x == killerPiece.x 
                if ourKing.y > killerPiece.y # king is on bottom, rook can move down
                    for i = killPiece.y+1:ourKing.y-1
                        push!(killerPath, (killerPiece.x, i))
                    end
                else # king is on top, rook can move up 
                    for i = ourKing.y+1:killerPiece.y-1
                        push!(killerPath, (killerPiece.x, i))
                    end
                end
            elseif ourKing.y == killerPiece.y 
                if ourKing.x > killerPiece.x # king is on left, rook can move left 
                    for i = killerPiece.x+1:ourKing.x-1
                        push!(killerPath, (i, killerPiece.y))
                    end
                else # king is on right, rook can move right
                    for i = ourKing.x+1:killerPiece.x-1
                        push!(killerPath, (i, killerPiece.y))
                    end
                end
            end
        else 
            sourcex = killerPiece.x
            sourcey = killerPiece.y
            targetx = ourKing.x 
            targety = ourKing.y
            if killerPiece.side == 0
                if targetx < sourcex && targety > sourcey
                    i = targetx
                    j = targety
                    while i < sourcex-1 && j > sourcey+1
                        i += 1
                        j -= 1
                        push!(killerPath, (i, j))
                    end
                elseif targetx < sourcex && targety < sourcey # target is NE of bishop
                    i = targetx
                    j = targety
                    while i < sourcex-1 && j < sourcey-1
                        i += 1
                        j += 1
                        push!(killerPath, (i, j))
                    end
                end
            elseif killerPiece.side == 1
                if targetx > sourcex && targety < sourcey # target is NW of bishop
                    i = targetx
                    j = targety
                    while i > sourcex+1 && j < sourcey-1
                        i -= 1
                        j += 1
                        push!(killerPath, (i, j))
                    end
                elseif targetx > sourcex && targety > sourcey # target is SW of bishop
                    i = targetx
                    j = targety
                    while i > sourcex+1 && j > sourcey+1
                        i -= 1
                        j -= 1
                        push!(killerPath, (i, j))
                    end
                end
            end
        end
    elseif killerPiece.name == "ox"
        if killerPiece.y == ourKing.y
            if ourKing.x > killerPiece.x 
                for i = killerPiece.x+1:ourKing.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            else 
                for i = ourKing.x+1:killerPiece.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            end
        else
            sourcex = killerPiece.x
            sourcey = killerPiece.y
            targetx = ourKing.x 
            targety = ourKing.y
            if targetx < sourcex && targety < sourcey # target is NE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j < sourcey-1
                    i += 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx < sourcex && targety > sourcey # target is SE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j > sourcey+1
                    i += 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety < sourcey # target is NW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j < sourcey-1
                    i -= 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety > sourcey # target is SW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j > sourcey+1
                    i -= 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            end 
        end
    elseif killerPiece.name == "boar"
        if killerPiece.x == ourKing.x
            if ourKing.y > killerPiece.y 
                for i = killPiece.y+1:ourKing.y-1
                    push!(killerPath, (killerPiece.x, i))
                end
            else 
                for i = ourKing.y+1:killerPiece.y-1
                    push!(killerPath, (killerPiece.x, i))
                end
            end
        else
            sourcex = killerPiece.x
            sourcey = killerPiece.y
            targetx = ourKing.x 
            targety = ourKing.y
            if targetx < sourcex && targety < sourcey # target is NE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j < sourcey-1
                    i += 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx < sourcex && targety > sourcey # target is SE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j > sourcey+1
                    i += 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety < sourcey # target is NW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j < sourcey-1
                    i -= 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety > sourcey # target is SW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j > sourcey+1
                    i -= 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            end 
        end
    elseif killerPiece.name == "queen"
        if killerPiece.x == ourKing.x || killerPiece.y == ourKing.y 
            if ourKing.x == killerPiece.x 
                if ourKing.y > killerPiece.y # king is on bottom, rook can move down
                    for i = killPiece.y+1:ourKing.y-1
                        push!(killerPath, (killerPiece.x, i))
                    end
                else # king is on top, rook can move up 
                    for i = ourKing.y+1:killerPiece.y-1
                        push!(killerPath, (killerPiece.x, i))
                    end
                end
            elseif ourKing.y == killerPiece.y 
                if ourKing.x > killerPiece.x # king is on left, rook can move left 
                    for i = killerPiece.x+1:ourKing.x-1
                        push!(killerPath, (i, killerPiece.y))
                    end
                else # king is on right, rook can move right
                    for i = ourKing.x+1:killerPiece.x-1
                        push!(killerPath, (i, killerPiece.y))
                    end
                end
            end
        else 
            sourcex = killerPiece.x
            sourcey = killerPiece.y
            targetx = ourKing.x 
            targety = ourKing.y
            if targetx < sourcex && targety < sourcey # target is NE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j < sourcey-1
                    i += 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx < sourcex && targety > sourcey # target is SE of bishop
                i = targetx
                j = targety
                while i < sourcex-1 && j > sourcey+1
                    i += 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety < sourcey # target is NW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j < sourcey-1
                    i -= 1
                    j += 1
                    push!(killerPath, (i, j))
                end
            elseif targetx > sourcex && targety > sourcey # target is SW of bishop
                i = targetx
                j = targety
                while i > sourcex+1 && j > sourcey+1
                    i -= 1
                    j -= 1
                    push!(killerPath, (i, j))
                end
            end
        end
    elseif killerPiece.name == "white"
        if ourKing.y == killerPiece.y
            if ourKing.x > killerPiece.x 
                for i = killerPiece.x+1:ourKing.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            else 
                for i = ourKing.x+1:killerPiece.x-1
                    push!(killerPath, (i, killerPiece.y))
                end
            end
        else 
            sourcex = killerPiece.x
            sourcey = killerPiece.y
            targetx = ourKing.x 
            targety = ourKing.y
            if killerPiece.side == 0
                if targetx < sourcex && targety > sourcey
                    i = targetx
                    j = targety
                    while i < sourcex-1 && j > sourcey+1
                        i += 1
                        j -= 1
                        push!(killerPath, (i, j))
                    end
                elseif targetx < sourcex && targety < sourcey # target is NE of bishop
                    i = targetx
                    j = targety
                    while i < sourcex-1 && j < sourcey-1
                        i += 1
                        j += 1
                        push!(killerPath, (i, j))
                    end
                end
            elseif killerPiece.side == 1
                if targetx > sourcex && targety < sourcey # target is NW of bishop
                    i = targetx
                    j = targety
                    while i > sourcex+1 && j < sourcey-1
                        i -= 1
                        j += 1
                        push!(killerPath, (i, j))
                    end
                elseif targetx > sourcex && targety > sourcey # target is SW of bishop
                    i = targetx
                    j = targety
                    while i > sourcex+1 && j > sourcey+1
                        i -= 1
                        j -= 1
                        push!(killerPath, (i, j))
                    end
                end
            end
        end
    end
    

    saviourMoves = []
    # loop thru our pieces
        # check if any piece can move to killer pieces path - can use allowed_moves_drop()
            # add to array of saviour_moves
    for (x, y) in killerPath
        for apiece in ourPieces
            if inRange(board, move(move_number+1, "move", apiece.x, apiece.y, x, y, "", false, -1, -1, -1, -1))
                push!(saviourMoves, (apiece, (x,y)))
            end
        end
    end

    # pick lowest ranking piece's saviour move
    pieceRanks = reverse(["demon","great","vice","hawk","rgeneral","eagle","queen","bgeneral","falcon","lion","soaring","csoldier","buffalo","dragon","horse","rook","bishop","vsoldier","ssoldier","vmover","smover","lance","chariot","king","phoenix","kirin","elephant","gold","leopard","tiger","silver","copper","iron","knigh","dog","pawn"])

    for rank in pieceRanks
        for move in saviourMoves
            if rank == move[1].name
                # return sX, sY, tX, tY of saviour move; o/w 0,0,0,0
                return move[1].x, move[1].y, move[2][1], move[2][2]
            end
        end
    end

    return 0,0,0,0

end

#check whether king can run. Returns coordinates where king can run to if possible,
#else returns (0,0) if king cannot run
function checkForRun(board::Array{Array{piece,1},1}, move_number::Int64)

    boardLength = length(board)

    #king is in check, iterate through possible moves
    enemyPieces = []
    ourPieces = []
    ourKing = piece("", "", 0, 0, -1, false)

    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side == move_number%2
                if board[y][x].name == "king"
                    ourKing = board[y][x]
                end
                push!(ourPieces, board[y][x])
            elseif board[y][x].side != move_number%2 && board[y][x].side != -1
                push!(enemyPieces, board[y][x])
            end
        end
    end
    ##println  (enemyPieces)
    nonDeathMoves = []
    for y in -1:1 # y
        for x in -1:1 # x
            #create simulation king with available offsets
            simulateCheck = false # check if simulateKing is in check
            simulateKing = duplicatePiece(ourKing)
            simulateKing.x += x
            simulateKing.y += y
            if simulateKing.x > 0 && simulateKing.y > 0 && simulateKing.x <= boardLength && simulateKing.y <= boardLength # if location is not out of bounds
                if board[simulateKing.y][simulateKing.x].side != move_number%2  #if allied piece is not at location
                    for aEnemyPiece in enemyPieces
                        if inRange(board, move(move_number, "move", aEnemyPiece.x, aEnemyPiece.y, simulateKing.x, simulateKing.y, "", false, -1, -1, -1, -1))
                            simulateCheck = true
                        end
                    end
                    #if move results in a surviving king, push that move onto array
                    if simulateCheck == false
                        push!(nonDeathMoves,(simulateKing.x, simulateKing.y)) #pushing x,y coordinates as tuple
                    end
                end
            else
                simulateCheck = true
            end
        end     
    end
    #if there are no moves that will let king survive, resign
    if length(nonDeathMoves) == 0
        #resign 
        return 0, 0
    else
        # else make a random nondeath move from nonDeathMoves array
        srand()
        return targetX, targetY = nonDeathMoves[rand(1:length(nonDeathMoves))]        
    end

    
end

function duplicateBoard(board::Array{Array{piece,1},1})
    boardLength = length(board)
    copy = [ [ empty for i = 1:boardLength ] for j = 1:boardLength ]
    for i in eachindex(board)
        for j in eachindex(board[i])
            copy[i][j]=duplicatePiece(board[i][j])
        end
    end
    return copy
end

function duplicatePiece(original::piece)
    return piece(original.original, original.name, original.x, original.y, original.side, original.promoted)
end

# returns promoted piece
function promote(oldPiece::piece, gameType::String)
    name = oldPiece.original
    x = oldPiece.x
    y = oldPiece.y 
    side = oldPiece.side
    promoted = oldPiece.promoted

    newPiece = duplicatePiece(oldPiece)
    newPiece.promoted = true
    
    if promoted    
        return newPiece
    end

    if gameType == "tenjiku"

        if name == "chariot"
            newPiece.name = "whale"
        elseif name == "tiger"
            newPiece.name = "stag" # flying stag
        elseif name == "silver"
            newPiece.name = "vmover"
        elseif name == "vmover"
            newPiece.name = "ox" # flying ox
        elseif name == "kirin"
            newPiece.name = "lion"
        elseif name == "lion"
            newPiece.name = "hawk"
        elseif name == "iron"
            newPiece.name = "vsoldier"
        elseif name == "vsoldier"
            newPiece.name = "csoldier"
        elseif name == "csoldier"
            newPiece.name = "tetrarch"
        elseif name == "pawn"
            newPiece.name = "gold"
        elseif name == "gold"
            newPiece.name = "rook"
        elseif name == "rook"
            newPiece.name = "dragon"
        elseif name == "dragon"
            newPiece.name = "soaring"
        elseif name == "soaring"
            newPiece.name = "rgeneral"
        elseif name == "rgeneral"
            newPiece.name = "great"
        elseif name == "elephant"
            newPiece.name = "prince"
        elseif name == "lance"
            newPiece.name = "white" # white horse
        elseif name == "dog"
            newPiece.name = "multi"
        elseif name == "copper"
            newPiece.name = "smover"
        elseif name == "smover"
            newPiece.name = "boar"
        elseif name == "phoenix"
            newPiece.name = "queen"
        elseif name == "queen"
            newPiece.name = "eagle"
        elseif name == "knight"
            newPiece.name = "ssoldier"
        elseif name == "ssoldier"
            newPiece.name = "buffalo"
        elseif name == "buffalo"
            newPiece.name = "demon"
        elseif name == "leopard"
            newPiece.name = "bishop"
        elseif name == "bishop"
            newPiece.name = "horse"
        elseif name == "horse"
            newPiece.name = "falcon"
        elseif name == "falcon"
            newPiece.name = "bgeneral"
        elseif name == "bgeneral"
            newPiece.name = "vice"
        else
            newPiece.promoted = false
        end

    elseif gameType == "chu"

        if name == "bishop"
            newPiece.name = "horse"
        elseif name == "tiger"
            newPiece.name = "stag"
        elseif name == "copper"
            newPiece.name = "smover"
        elseif name == "horse"
            newPiece.name = "falcon"
        elseif name == "dragon"
            newPiece.name = "soaring"
        elseif name == "elephant"
            newPiece.name = "prince"
        elseif name == "leopard"
            newPiece.name = "bishop"
        elseif name == "cobra" # go-between
            newPiece.name = "elephant"
        elseif name == "gold"
            newPiece.name = "rook"
        elseif name == "kirin"
            newPiece.name = "lion"
        elseif name == "lance"
            newPiece.name = "white"
        elseif name == "pawn"
            newPiece.name = "gold"
        elseif name == "phoenix"
            newPiece.name = "queen"
        elseif name == "chariot"
            newPiece.name = "whale"
        elseif name == "rook"
            newPiece.name = "dragon"
        elseif name == "smover"
            newPiece.name = "boar"
        elseif name == "silver"
            newPiece.name = "vmover"
        elseif name == "vmover"
            newPiece.name = "ox"
        else
            newPiece.promoted = false
        end

    elseif gameType == "standard" || gameType == "mini"

        if name == "rook"
            newPiece.name = "dragon"
        elseif name == "bishop"
            newPiece.name = "horse"
        elseif name == "silver"
            newPiece.name = "gold"
        elseif name == "knight"
            newPiece.name = "gold"
        elseif name == "lance"
            newPiece.name = "gold"
        elseif name == "pawn"
            newPiece.name = "gold"
        else 
            newPiece.promoted = false 
        end

    else
        newPiece.promoted = false
    end

    return newPiece
end

# simulates a game starting at current board state and runs until any king is killed or until max_moves reached
# returns king_killed, move_number of kill (1 for enemy king killed; -1 for our king killed)
# returns 0, move_number if simuation exceeds 100 simulated moves
# WARNING: this function is recursive
function simulate_normal(board, move_number, currentMove)

    #println("entering simulate_normal()") # for debugging

    const max_moves = 20

    if move_number - currentMove > max_moves
        return 0, move_number
    end

    ourPieces = []
    enemyPieces = []
    ourKing = piece("", "", 0, 0, -1, false)
    enemyKing = piece("", "", 0, 0, -1, false)

    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side == move_number % 2
                if board[y][x].name == "king"
                    ourKing = board[y][x]
                end
                push!(ourPieces, board[y][x])
            elseif board[y][x].side != -1
                if board[y][x].name == "king"
                    enemyKing = board[y][x]
                end
                push!(enemyPieces, board[y][x])
            end
        end
    end

    if ourKing == piece("", "", 0, 0, -1, false)
        if move_number%2 == currentMove%2
            return -1, move_number-1
        else
            return 1, move_number-1 
        end
    end

    # check if enemy king wants to be killed
    for apiece in ourPieces
        if inRange(board, move(move_number, "move", apiece.x, apiece.y, enemyKing.x, enemyKing.y, "", false, -1, -1, -1, -1))
            if move_number%2 == currentMove%2
                return 1, move_number
            else
                return -1, move_number 
            end
        end 
    end

    safeMoves = [] # where any pieces cannot move to; i.e. safe moves for our pieces
    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side != currentMove%2
                for apiece in enemyPieces
                    if !inRange(board, move(currentMove, "move", apiece.x, apiece.y, x, y, "", false, -1, -1, -1, -1))
                        push!(safeMoves, (x,y))
                    end
                end
            end
        end
    end

    possibleMoves = []

    for apiece in ourPieces
        for amove in safeMoves
            # moving apiece to move is valid
            if inRange(board, move(move_number+1, "move", apiece.x, apiece.y, amove[1], amove[2], "", false, -1, -1, -1, -1))
                push!(possibleMoves, (apiece, amove))
            end
        end
    end

    srand()
    sourcePiece, target = possibleMoves[rand(1:length(possibleMoves))]
    sourceX = sourcePiece.x
    sourceY = sourcePiece.y 
    targetX = target[1]
    targetY = target[2]

    board, move_number = simulateMove(board, move_number, sourceX, sourceY, targetX, targetY)

    return simulate_normal(board, move_number + 1, currentMove)

end

function AI_normal(board, currentMove)

    #println("entering AI_normal()") # for debugging

    gameActive = true

    #= start timing =#
    tic()

    currentSide = currentMove % 2 #getting current side for convenience

    #AI check 0: check if won

    ourPieces = Array(piece, 0) #0 element piece array
    enemyPieces = Array(piece, 0)
    enemyKing = empty
    ourKing = empty

    # go through board
    for i in 1:length(board)
        for j in 1:length(board[1])

            #get all our pieces in board into ourPieces array
            if currentSide == board[i][j].side
                push!(ourPieces, board[i][j])
            elseif board[i][j].side != -1
                push!(enemyPieces, board[i][j])
            end

            #get enemy king
            if board[i][j].name == "king" && board[i][j].side != currentSide
                enemyKing = board[i][j]
            #get our king
            elseif board[i][j].name == "king" && board[i][j].side == currentSide
                ourKing = board[i][j]
            end 

        end
    end

    #= for debugging =#
    println("ourPieces: ", ourPieces)
    println("enemyPieces: ", enemyPieces)
    println("ourKing: ", ourKing)
    println("enemyKing: ", enemyKing)

    killerPieces = [] # array of pieces that can kill our king

    # identify pieces that can kill our king
    for apiece in enemyPieces
        if inRange(board, move(currentMove, "move", apiece.x, apiece.y, ourKing.x, ourKing.y, "", false, -1, -1, -1, -1))
            ##println  ("found a killer: $apiece")
            push!(killerPieces, apiece)
        end
    end

    println("killerPieces: ", killerPieces) # for debugging


    sX, sY, tX, tY = checkForWin(board, ourPieces,enemyKing)

    if sX != 0 # we can win this game
        moveMade = move(currentMove, "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
        gameActive = false
    end

    println("result of checkForWin: sX $sX, sY $sY, tX $tX, tY $tY") # for debugging

    inCheck = checkForCheck(board, enemyPieces, ourKing)

    println("inCheck: $inCheck") # for debugging

    if inCheck && gameActive

        if length(killerPieces) == 1
            
            println("1 killer piece") # for debugging

            for apiece in ourPieces
                if inRange(board, move(currentMove, "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1))
                    moveMade = move(currentMove,  "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y)
                    ##println  ("move made on line 916")
                    gameActive = false
                    break
                end
            end

            println("gameActive: $gameActive") # for debugging

            if gameActive

                
                # check if we can block the move
                sX, sY, tX, tY = checkForBlock(board, currentMove)
                
                println("result of checkForBlock: sX $sX, sY $sY, tX $tX, tY $tY") # for debugging
                
                if sX != 0 # block the move
                    moveMade = move(currentMove,  "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, sX, sY, tX, tY)
                    ##println  ("move made on line 923")
                    gameActive = false
                else
                    tX, tY = checkForRun(board, currentMove)
                    ##println  ("checkForRun: $tX, $tY")
                    if tX != 0         # make king run
                        moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                        board, currentMove = simulateMove(board, currentMove, ourKing.x, ourKing.y, tX, tY)
                        ##println  ("move made on line 930")
                        gameActive = false
                    else #king cannot run
                        ##println  ("move made on line 934")
                        moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                        gameActive = false
                    end
                end
                
            end
        else

            println("more than 1 killerPiece") # for debugging

            # check if king can run

            tX, tY = checkForRun(board, currentMove)
            ##println  ("checkForRun: $tX, $tY")
            if tX != 0         # make king run
                moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                board, currentMove = simulateMove(board, currentMove, 0,0, tX, tY)
                #println  ("move made on line 947")
                gameActive = false
            else #king cannot run
                #println  ("move made on line 951")
                moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                gameActive = false
            end
        end

    end


    if gameActive

        println("!inCheck && gameActive")

        loopCount = 1
        validMoves = [] # valid moves for move_piece
        move_piece = piece("", "", 0, 0, -1, false)
        while gameActive
            srand()
            move_piece = ourPieces[rand(1:length(ourPieces))]
            for y = 1:length(board)
                for x = 1:length(board[1])
                    if board[y][x].side != move_piece.side # can't move onto friendly piece
                        if inRange(board, move(currentMove+1, "move", move_piece.x, move_piece.y, x, y, "", false, -1, -1, -1, -1))
                            push!(validMoves, (x,y))
                        end
                    end
                end
            end
            loopCount += 1
            if length(validMoves) >= 1
                break
            end
            if loopCount > 100
                println("resigning because loopCount exceeded 100")
                moveMade = move(currentMove,  "resign", -1, -1, -1, -1,"", false, -1, -1, -1, -1)
                gameActive = false
            end
        end

    end
    #println("piece selected: ",move_piece)
    #println("valid moves: \n",validMoves)

    if gameActive

        simulateResults = []

        myRes = 0
        gameLength = 0

        for move in validMoves
            #global myRes
            #global gameLength
           # println("piece selected 2: ",move_piece)  
            newBoard, move_number = simulateMove(board, currentMove, move_piece.x, move_piece.y, move[1], move[2])
           # println("piece selected 3: ",move_piece)      
            const numOfTrials = 10

            wins = 0
            losses = 0
            draws = 0
            winGameLenTotal = 0
            lossGameLenTotal = 0
            drawGameLenTotal = 0
            trialResults = []
            for i = 1:numOfTrials
                res, gameLen = simulate_normal(board, move_number, currentMove)
                if res == 1
                    wins += 1
                    winGameLenTotal += gameLen
                elseif res == -1
                    losses += 1
                    lossGameLenTotal += gameLen
                else 
                    draws += 1
                    drawGameLenTotal += gameLen
                end
            end
            if wins >= losses && wins >= draws
                myRes = 1
                gameLength = winGameLenTotal / wins
            elseif losses >= draws
                myRes = -1
                gameLength = lossGameLenTotal / losses
            else 
                myRes = 0
                gameLength = drawGameLenTotal / draws
            end
            #myRes, gameLength = simulate_normal(board, move_number, currentMove)
            push!(simulateResults, (myRes, gameLength))
        end


        #=
        insert 50 trials of simulate for each valid move
        find best move to make
        place final results into simulateResults
        =#

        winningMoves = []
        losingMoves = []
        miscMoves = []
        for i = 1:length(simulateResults)
            if simulateResults[i][1] == 1
                #pushing gameLength, sourcex, sourcey, targetx,targety
                push!(winningMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            elseif simulateResults[i][1] == -1
                push!(losingMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            else 
                push!(miscMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            end
        end


        if length(winningMoves) > 0
            # make the possibly winning move
            bestMove = winningMoves[1]
            for i = 2:length(winningMoves)
                if winningMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = winningMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)
            board, currentMove = simulateMove(board, currentMove, sourceX, sourceY, targetX, targetY)
            #moveMade = true


        elseif length(losingMoves) > 0

            bestMove = losingMoves[1]
            for i = 2:length(losingMoves)
                if losingMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = losingMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)
            board, currentMove = simulateMove(board, currentMove, sourceX, sourceY, targetX, targetY)
            #moveMade = true

        elseif length(miscMoves) > 0

            bestMove = miscMoves[1]
            for i = 2:length(miscMoves)
                if miscMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = miscMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)
            board, currentMove = simulateMove(board, currentMove, sourceX, sourceY, targetX, targetY)
            #moveMade = true

        else # were screwed, so resign with dignity!

            moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
            #moveMade = true
            
        end

    end # if moveMade != true

    #= end timing =#
    time_taken = toq()

    if length(board) == 16
        board = demon_burning(board)
    end

    return board, time_taken, moveMade
end

# simulates a game starting at current board state and runs until any king is killed or until max_moves reached
# returns king_killed, move_number of kill (1 for enemy king killed; -1 for our king killed)
# returns 0, move_number if simuation exceeds 100 simulated moves
# WARNING: this function is recursive
function simulate_hard(board, move_number, currentMove)

    #println("entering simulate_hard()") # for debugging

    const max_moves = 20

    if move_number - currentMove > max_moves
        return 0, move_number
    end

    ourPieces = []
    enemyPieces = []
    ourKing = piece("", "", 0, 0, -1, false)
    enemyKing = piece("", "", 0, 0, -1, false)

    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side == move_number % 2
                if board[y][x].name == "king"
                    ourKing = board[y][x]
                end
                push!(ourPieces, board[y][x])
            elseif board[y][x].side != -1
                if board[y][x].name == "king"
                    enemyKing = board[y][x]
                end
                push!(enemyPieces, board[y][x])
            end
        end
    end

    if ourKing == piece("", "", 0, 0, -1, false)
        if move_number%2 == currentMove%2
            return -1, move_number-1
        else
            return 1, move_number-1 
        end
    end

    # check if enemy king wants to be killed
    for apiece in ourPieces
        if inRange(board, move(move_number, "move", apiece.x, apiece.y, enemyKing.x, enemyKing.y, "", false, -1, -1, -1, -1))
            if move_number%2 == currentMove%2
                return 1, move_number
            else
                return -1, move_number 
            end
        end 
    end

    safeMoves = [] # where any pieces cannot move to; i.e. safe moves for our pieces
    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side != currentMove%2
                for apiece in enemyPieces
                    if !inRange(board, move(currentMove, "move", apiece.x, apiece.y, x, y, "", false, -1, -1, -1, -1))
                        push!(safeMoves, (x,y))
                    end
                end
            end
        end
    end

    possibleMoves = []

    for apiece in ourPieces
        for amove in safeMoves
            # moving apiece to move is valid
            if inRange(board, move(move_number+1, "move", apiece.x, apiece.y, amove[1], amove[2], "", false, -1, -1, -1, -1))
                push!(possibleMoves, (apiece, amove))
            end
        end
    end

    srand()
    sourcePiece, target = possibleMoves[rand(1:length(possibleMoves))]
    sourceX = sourcePiece.x
    sourceY = sourcePiece.y 
    targetX = target[1]
    targetY = target[2]

    board, move_number = simulateMove(board, move_number, sourceX, sourceY, targetX, targetY)

    return simulate_hard(board, move_number + 1, currentMove)

end

function AI_hard(board, currentMove)

    if length(board) == 5
        gameType = "mini"
    elseif length(board) == 9
        gameType = "standard"
    elseif length(board) == 12
        gameType = "chu"
    elseif length(board) == 16
        gameType = "tenjiku"
    end

    #println("entering AI_hard()") # for debugging

    gameActive = true

    #= start timing =#
    tic()

    currentSide = currentMove % 2 #getting current side for convenience

    #AI check 0: check if won

    ourPieces = Array(piece, 0) #0 element piece array
    enemyPieces = Array(piece, 0)
    enemyKing = empty
    ourKing = empty

    # go through board
    for i in 1:length(board)
        for j in 1:length(board[1])

            #get all our pieces in board into ourPieces array
            if currentSide == board[i][j].side
                push!(ourPieces, board[i][j])
            elseif board[i][j].side != -1
                push!(enemyPieces, board[i][j])
            end

            #get enemy king
            if board[i][j].name == "king" && board[i][j].side != currentSide
                enemyKing = board[i][j]
            #get our king
            elseif board[i][j].name == "king" && board[i][j].side == currentSide
                ourKing = board[i][j]
            end 

        end
    end

    #= for debugging =#
    println("ourPieces: ", ourPieces)
    println("enemyPieces: ", enemyPieces)
    println("ourKing: ", ourKing)
    println("enemyKing: ", enemyKing)

    killerPieces = [] # array of pieces that can kill our king

    # identify pieces that can kill our king
    for apiece in enemyPieces
        if inRange(board, move(currentMove, "move", apiece.x, apiece.y, ourKing.x, ourKing.y, "", false, -1, -1, -1, -1))
            ##println  ("found a killer: $apiece")
            push!(killerPieces, apiece)
        end
    end

    println("killerPieces: ", killerPieces) # for debugging


    sX, sY, tX, tY = checkForWin(board, ourPieces,enemyKing)

    if sX != 0 # we can win this game
        moveMade = move(currentMove, "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
        gameActive = false
    end

    println("result of checkForWin: sX $sX, sY $sY, tX $tX, tY $tY") # for debugging

    inCheck = checkForCheck(board, enemyPieces, ourKing)

    println("inCheck: $inCheck") # for debugging

    if inCheck && gameActive

        if length(killerPieces) == 1
            
            println("1 killer piece") # for debugging

            for apiece in ourPieces
                if inRange(board, move(currentMove, "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1))
                    moveMade = move(currentMove,  "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y)
                    ##println  ("move made on line 916")
                    gameActive = false
                    break
                end
            end

            println("gameActive: $gameActive") # for debugging

            if gameActive

                
                # check if we can block the move
                sX, sY, tX, tY = checkForBlock(board, currentMove)
                
                println("result of checkForBlock: sX $sX, sY $sY, tX $tX, tY $tY") # for debugging
                
                if sX != 0 # block the move
                    moveMade = move(currentMove,  "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, sX, sY, tX, tY)
                    ##println  ("move made on line 923")
                    gameActive = false
                else
                    tX, tY = checkForRun(board, currentMove)
                    ##println  ("checkForRun: $tX, $tY")
                    if tX != 0         # make king run
                        moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                        board, currentMove = simulateMove(board, currentMove, ourKing.x, ourKing.y, tX, tY)
                        ##println  ("move made on line 930")
                        gameActive = false
                    else #king cannot run
                        ##println  ("move made on line 934")
                        moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                        gameActive = false
                    end
                end
                
            end
        else

            println("more than 1 killerPiece") # for debugging

            # check if king can run

            tX, tY = checkForRun(board, currentMove)
            ##println  ("checkForRun: $tX, $tY")
            if tX != 0         # make king run
                moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                board, currentMove = simulateMove(board, currentMove, 0,0, tX, tY)
                #println  ("move made on line 947")
                gameActive = false
            else #king cannot run
                #println  ("move made on line 951")
                moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                gameActive = false
            end
        end

    end


    if gameActive

        println("!inCheck && gameActive")

        loopCount = 1
        validMoves = [] # valid moves for move_piece
        move_piece = piece("", "", 0, 0, -1, false)
        while gameActive
            srand()
            move_piece = ourPieces[rand(1:length(ourPieces))]
            for y = 1:length(board)
                for x = 1:length(board[1])
                    if board[y][x].side != move_piece.side # can't move onto friendly piece
                        if inRange(board, move(currentMove+1, "move", move_piece.x, move_piece.y, x, y, "", false, -1, -1, -1, -1))
                            push!(validMoves, (x,y))
                        end
                    end
                end
            end
            loopCount += 1
            if length(validMoves) >= 1
                break
            end
            if loopCount > 100
                println("resigning because loopCount exceeded 100")
                moveMade = move(currentMove,  "resign", -1, -1, -1, -1,"", false, -1, -1, -1, -1)
                gameActive = false
            end
        end

    end
    #println("piece selected: ",move_piece)
    #println("valid moves: \n",validMoves)

    if gameActive

        simulateResults = []

        myRes = 0
        gameLength = 0

        for move in validMoves
            #global myRes
            #global gameLength
           # println("piece selected 2: ",move_piece)  
            newBoard, move_number = simulateMove(board, currentMove, move_piece.x, move_piece.y, move[1], move[2])
           # println("piece selected 3: ",move_piece)      
            const numOfTrials = 10

            wins = 0
            losses = 0
            draws = 0
            winGameLenTotal = 0
            lossGameLenTotal = 0
            drawGameLenTotal = 0
            trialResults = []
            for i = 1:numOfTrials
                res, gameLen = simulate_hard(board, move_number, currentMove)
                if res == 1
                    wins += 1
                    winGameLenTotal += gameLen
                elseif res == -1
                    losses += 1
                    lossGameLenTotal += gameLen
                else 
                    draws += 1
                    drawGameLenTotal += gameLen
                end
            end
            if wins >= losses && wins >= draws
                myRes = 1
                gameLength = winGameLenTotal / wins
            elseif losses >= draws
                myRes = -1
                gameLength = lossGameLenTotal / losses
            else 
                myRes = 0
                gameLength = drawGameLenTotal / draws
            end
            #myRes, gameLength = simulate_hard(board, move_number, currentMove)
            push!(simulateResults, (myRes, gameLength))
        end


        #=
        insert 50 trials of simulate for each valid move
        find best move to make
        place final results into simulateResults
        =#

        winningMoves = []
        losingMoves = []
        miscMoves = []
        for i = 1:length(simulateResults)
            if simulateResults[i][1] == 1
                #pushing gameLength, sourcex, sourcey, targetx,targety
                push!(winningMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            elseif simulateResults[i][1] == -1
                push!(losingMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            else 
                push!(miscMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            end
        end


        if length(winningMoves) > 0
            # make the possibly winning move
            bestMove = winningMoves[1]
            for i = 2:length(winningMoves)
                if winningMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = winningMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)


        elseif length(losingMoves) > 0

            bestMove = losingMoves[1]
            for i = 2:length(losingMoves)
                if losingMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = losingMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)

        elseif length(miscMoves) > 0

            bestMove = miscMoves[1]
            for i = 2:length(miscMoves)
                if miscMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = miscMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)
            
        else # were screwed, so resign with dignity!

            moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
            
        end

        board, currentMove = simulateMove(board, currentMove, moveMade.sourcex, moveMade.sourcey, moveMade.targetx, moveMade.targety)
        
    end

    #= end timing =#
    time_taken = toq()

    if length(board) == 16
        board = demon_burning(board)
    end

    return board, time_taken, moveMade
end

# simulates a game starting at current board state and runs until any king is killed or until max_moves reached
# returns king_killed, move_number of kill (1 for enemy king killed; -1 for our king killed)
# returns 0, move_number if simuation exceeds 100 simulated moves
# WARNING: this function is recursive
function simulate_suicidal(board, move_number, currentMove)

    #println("entering simulate_suicidal()") # for debugging

    const max_moves = 20

    if move_number - currentMove > max_moves
        return 0, move_number
    end

    ourPieces = []
    enemyPieces = []
    ourKing = piece("", "", 0, 0, -1, false)
    enemyKing = piece("", "", 0, 0, -1, false)

    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side == move_number % 2
                if board[y][x].name == "king"
                    ourKing = board[y][x]
                end
                push!(ourPieces, board[y][x])
            elseif board[y][x].side != -1
                if board[y][x].name == "king"
                    enemyKing = board[y][x]
                end
                push!(enemyPieces, board[y][x])
            end
        end
    end

    if ourKing == piece("", "", 0, 0, -1, false)
        if move_number%2 == currentMove%2
            return 1, move_number-1
        else
            return -1, move_number-1 
        end
    end

    # check if enemy king wants to be killed
    for apiece in ourPieces
        if inRange(board, move(move_number, "move", apiece.x, apiece.y, enemyKing.x, enemyKing.y, "", false, -1, -1, -1, -1))
            if move_number%2 == currentMove%2
                return -1, move_number
            else
                return 1, move_number 
            end
        end 
    end

    safeMoves = [] # where any pieces cannot move to; i.e. safe moves for our pieces
    for y = 1:length(board)
        for x = 1:length(board[1])
            if board[y][x].side != currentMove%2
                for apiece in enemyPieces
                    if !inRange(board, move(currentMove, "move", apiece.x, apiece.y, x, y, "", false, -1, -1, -1, -1))
                        push!(safeMoves, (x,y))
                    end
                end
            end
        end
    end

    possibleMoves = []

    for apiece in ourPieces
        for amove in safeMoves
            # moving apiece to move is valid
            if inRange(board, move(move_number+1, "move", apiece.x, apiece.y, amove[1], amove[2], "", false, -1, -1, -1, -1))
                push!(possibleMoves, (apiece, amove))
            end
        end
    end

    srand()
    sourcePiece, target = possibleMoves[rand(1:length(possibleMoves))]
    sourceX = sourcePiece.x
    sourceY = sourcePiece.y 
    targetX = target[1]
    targetY = target[2]

    board, move_number = simulateMove(board, move_number, sourceX, sourceY, targetX, targetY)

    return simulate_suicidal(board, move_number + 1, currentMove)

end

function AI_suicidal(board, currentMove)

    #println("entering AI_suicidal()") # for debugging

    gameActive = true

    #= start timing =#
    tic()

    currentSide = currentMove % 2 #getting current side for convenience

    #AI check 0: check if won

    ourPieces = Array(piece, 0) #0 element piece array
    enemyPieces = Array(piece, 0)
    enemyKing = empty
    ourKing = empty

    # go through board
    for i in 1:length(board)
        for j in 1:length(board[1])

            #get all our pieces in board into ourPieces array
            if currentSide == board[i][j].side
                push!(ourPieces, board[i][j])
            elseif board[i][j].side != -1
                push!(enemyPieces, board[i][j])
            end

            #get enemy king
            if board[i][j].name == "king" && board[i][j].side != currentSide
                enemyKing = board[i][j]
            #get our king
            elseif board[i][j].name == "king" && board[i][j].side == currentSide
                ourKing = board[i][j]
            end 

        end
    end

    #= for debugging =#
    println("ourPieces: ", ourPieces)
    println("enemyPieces: ", enemyPieces)
    println("ourKing: ", ourKing)
    println("enemyKing: ", enemyKing)

    killerPieces = [] # array of pieces that can kill our king

    # identify pieces that can kill our king
    for apiece in enemyPieces
        if inRange(board, move(currentMove, "move", apiece.x, apiece.y, ourKing.x, ourKing.y, "", false, -1, -1, -1, -1))
            ##println  ("found a killer: $apiece")
            push!(killerPieces, apiece)
        end
    end

    println("killerPieces: ", killerPieces) # for debugging


    sX, sY, tX, tY = checkForWin(board, ourPieces,enemyKing)

    if sX != 0 # we can win this game
        moveMade = move(currentMove, "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
        gameActive = false
    end

    println("result of checkForWin: sX $sX, sY $sY, tX $tX, tY $tY") # for debugging

    inCheck = checkForCheck(board, enemyPieces, ourKing)

    println("inCheck: $inCheck") # for debugging

    if inCheck && gameActive

        if length(killerPieces) == 1
            
            println("1 killer piece") # for debugging

            for apiece in ourPieces
                if inRange(board, move(currentMove, "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1))
                    moveMade = move(currentMove,  "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y)
                    ##println  ("move made on line 916")
                    gameActive = false
                    break
                end
            end

            println("gameActive: $gameActive") # for debugging

            if gameActive

                
                # check if we can block the move
                sX, sY, tX, tY = checkForBlock(board, currentMove)
                
                println("result of checkForBlock: sX $sX, sY $sY, tX $tX, tY $tY") # for debugging
                
                if sX != 0 # block the move
                    moveMade = move(currentMove,  "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, sX, sY, tX, tY)
                    ##println  ("move made on line 923")
                    gameActive = false
                else
                    tX, tY = checkForRun(board, currentMove)
                    ##println  ("checkForRun: $tX, $tY")
                    if tX != 0         # make king run
                        moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                        board, currentMove = simulateMove(board, currentMove, ourKing.x, ourKing.y, tX, tY)
                        ##println  ("move made on line 930")
                        gameActive = false
                    else #king cannot run
                        ##println  ("move made on line 934")
                        moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                        gameActive = false
                    end
                end
                
            end
        else

            println("more than 1 killerPiece") # for debugging

            # check if king can run

            tX, tY = checkForRun(board, currentMove)
            ##println  ("checkForRun: $tX, $tY")
            if tX != 0         # make king run
                moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                board, currentMove = simulateMove(board, currentMove, 0,0, tX, tY)
                #println  ("move made on line 947")
                gameActive = false
            else #king cannot run
                #println  ("move made on line 951")
                moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                gameActive = false
            end
        end

    end


    if gameActive

        println("!inCheck && gameActive")

        loopCount = 1
        validMoves = [] # valid moves for move_piece
        move_piece = piece("", "", 0, 0, -1, false)
        while gameActive
            srand()
            move_piece = ourPieces[rand(1:length(ourPieces))]
            for y = 1:length(board)
                for x = 1:length(board[1])
                    if board[y][x].side != move_piece.side # can't move onto friendly piece
                        if inRange(board, move(currentMove+1, "move", move_piece.x, move_piece.y, x, y, "", false, -1, -1, -1, -1))
                            push!(validMoves, (x,y))
                        end
                    end
                end
            end
            loopCount += 1
            if length(validMoves) >= 1
                break
            end
            if loopCount > 100
                println("resigning because loopCount exceeded 100")
                moveMade = move(currentMove,  "resign", -1, -1, -1, -1,"", false, -1, -1, -1, -1)
                gameActive = false
            end
        end

    end
    #println("piece selected: ",move_piece)
    #println("valid moves: \n",validMoves)

    if gameActive

        simulateResults = []

        myRes = 0
        gameLength = 0

        for move in validMoves
            #global myRes
            #global gameLength
           # println("piece selected 2: ",move_piece)  
            newBoard, move_number = simulateMove(board, currentMove, move_piece.x, move_piece.y, move[1], move[2])
           # println("piece selected 3: ",move_piece)      
            const numOfTrials = 10

            wins = 0
            losses = 0
            draws = 0
            winGameLenTotal = 0
            lossGameLenTotal = 0
            drawGameLenTotal = 0
            trialResults = []
            for i = 1:numOfTrials
                res, gameLen = simulate_suicidal(board, move_number, currentMove)
                if res == 1
                    wins += 1
                    winGameLenTotal += gameLen
                elseif res == -1
                    losses += 1
                    lossGameLenTotal += gameLen
                else 
                    draws += 1
                    drawGameLenTotal += gameLen
                end
            end
            if wins >= losses && wins >= draws
                myRes = 1
                gameLength = winGameLenTotal / wins
            elseif losses >= draws
                myRes = -1
                gameLength = lossGameLenTotal / losses
            else 
                myRes = 0
                gameLength = drawGameLenTotal / draws
            end
            #myRes, gameLength = simulate_suicidal(board, move_number, currentMove)
            push!(simulateResults, (myRes, gameLength))
        end


        #=
        insert 50 trials of simulate for each valid move
        find best move to make
        place final results into simulateResults
        =#

        winningMoves = []
        losingMoves = []
        miscMoves = []
        for i = 1:length(simulateResults)
            if simulateResults[i][1] == 1
                #pushing gameLength, sourcex, sourcey, targetx,targety
                push!(winningMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            elseif simulateResults[i][1] == -1
                push!(losingMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            else 
                push!(miscMoves, (simulateResults[i][2], move_piece.x, move_piece.y, validMoves[i][1], validMoves[i][2]))
            end
        end


        if length(winningMoves) > 0
            # make the possibly winning move
            bestMove = winningMoves[1]
            for i = 2:length(winningMoves)
                if winningMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = winningMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)
            board, currentMove = simulateMove(board, currentMove, sourceX, sourceY, targetX, targetY)
            #moveMade = true


        elseif length(losingMoves) > 0

            bestMove = losingMoves[1]
            for i = 2:length(losingMoves)
                if losingMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = losingMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)
            board, currentMove = simulateMove(board, currentMove, sourceX, sourceY, targetX, targetY)
            #moveMade = true

        elseif length(miscMoves) > 0

            bestMove = miscMoves[1]
            for i = 2:length(miscMoves)
                if miscMoves[i][1] < bestMove[1] # smaller game length for winning 
                    bestMove = miscMoves[i]
                end
            end
            sourceX = bestMove[2]
            sourceY = bestMove[3]
            targetX = bestMove[4]
            targetY = bestMove[5]
            #println("bestMove is: ", bestMove)
            deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
            option = deservesPromotion == true? "!":""
            
            moveMade = move(currentMove,  "move", sourceX, sourceY, targetX, targetY, option, false, -1, -1, -1, -1)
            board, currentMove = simulateMove(board, currentMove, sourceX, sourceY, targetX, targetY)
            #moveMade = true

        else # were screwed, so resign with dignity!

            moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
            #moveMade = true
            
        end

    end # if moveMade != true

    #= end timing =#
    time_taken = toq()

    if length(board) == 16
        board = demon_burning(board)
    end

    return board, time_taken, moveMade
end

function AI_protracted(board, currentMove)

    gameActive = true

    #= start timing =#
    tic()

    currentSide = currentMove % 2 #getting current side for convenience

    #AI check 0: check if won

    ourPieces = Array(piece, 0) #0 element piece array
    enemyPieces = Array(piece, 0)
    #enemyKing = empty
    ourKing = empty

    # go through board
    for i in 1:length(board)
        for j in 1:length(board[1])

            #get all our pieces in board into ourPieces array
            if currentSide == board[i][j].side
                push!(ourPieces, board[i][j])
            elseif board[i][j].side != -1
                push!(enemyPieces, board[i][j])
            end

            #=
            #get enemy king
            if board[i][j].name == "king" && board[i][j].side != currentSide
                enemyKing = board[i][j]
            #get our king
            else=#if board[i][j].name == "king" && board[i][j].side == currentSide
                ourKing = board[i][j]
            end 

        end
    end

    ##println  ("ourPieces: ", ourPieces)
    ##println  ("enemyPieces: ", enemyPieces)
    ##println  ("ourKing: ", ourKing)
    ##println  ("enemyKing: ", enemyKing)

    killerPieces = [] # array of pieces that can kill our king

    # identify pieces that can kill our king
    for apiece in enemyPieces
        if inRange(board, move(currentMove, "move", apiece.x, apiece.y, ourKing.x, ourKing.y, "", false, -1, -1, -1, -1))
            ##println  ("found a killer: $apiece")
            push!(killerPieces, apiece)
        end
    end

    #=
    sX, sY, tX, tY = checkForWin(ourPieces,enemyKing)

    if sX != 0 # we can win this game
        moveMade = move(currentMove, "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
        gameActive = false
    end
    =#


    inCheck = checkForCheck(board, enemyPieces, ourKing)

    ##println  ("inCheck: $inCheck")

    if inCheck && gameActive

        if length(killerPieces) == 1
            
            for apiece in ourPieces
                if inRange(board, move(currentMove, "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1))
                    moveMade = move(currentMove,  "move", apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, apiece.x, apiece.y, killerPieces[1].x, killerPieces[1].y)
                    ##println  ("move made on line 916")
                    gameActive = false
                    break
                end
            end
            if gameActive

                
                # check if we can block the move
                sX, sY, tX, tY = checkForBlock(board, currentMove)
                ##println  ("checkForBlock: $sX, $sY, $tX, $tY")
                if sX != 0 # block the move
                    moveMade = move(currentMove,  "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
                    board, currentMove = simulateMove(board, currentMove, sX, sY, tX, tY)
                    ##println  ("move made on line 923")
                    gameActive = false
                else
                    tX, tY = checkForRun(board, currentMove)
                    ##println  ("checkForRun: $tX, $tY")
                    if tX != 0         # make king run
                        moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                        board, currentMove = simulateMove(board, currentMove, ourKing.x, ourKing.y, tX, tY)
                        ##println  ("move made on line 930")
                        gameActive = false
                    else #king cannot run
                        ##println  ("move made on line 934")
                        moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                        gameActive = false
                    end
                end
                
            end
        else
            # check if king can run

            tX, tY = checkForRun(board, currentMove)
            ##println  ("checkForRun: $tX, $tY")
            if tX != 0         # make king run
                moveMade = move(currentMove,  "move", ourKing.x, ourKing.y, tX, tY, "", false, -1, -1, -1, -1)
                board, currentMove = simulateMove(board, currentMove, 0,0, tX, tY)
                #println  ("move made on line 947")
                gameActive = false
            else #king cannot run
                #println  ("move made on line 951")
                moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
                gameActive = false
            end
        end

    end

    if gameActive
        move_piece = piece("", "", 0, 0, -1, false)
        validMoves = [] # valid moves for move_piece
        while true
            srand()
            move_piece = ourPieces[rand(1:length(ourPieces))]
            for y = 1:length(board)
                for x = 1:length(board[1])
                    if board[y][x].side != move_piece.side # can't move onto friendly piece
                        if inRange(board, move(currentMove, "move", move_piece.x, move_piece.y, x, y, "", false, -1, -1, -1, -1))
                            push!(validMoves, (x,y))
                        end
                    end
                end
            end
            if length(validMoves) > 0
                break 
            end
        end

        ourMove = validMoves[rand(1:length(validMoves))]
        moveMade = move(currentMove, "move", move_piece.x, move_piece.y, ourMove[1], ourMove[2], "", false, -1, -1, -1, -1)
    end

    #= end timing =#
    time_taken = toq()

    if length(board) == 16
        board = demon_burning(board)
    end

    return simulateMove(board, currentMove, moveMade.sourcex, moveMade.sourcey, moveMade.targetx, moveMade.targety)[1], time_taken, moveMade
end

function AI_random(board, currentMove)

    #= start timing =#
    tic()

    currentSide = currentMove % 2 #getting current side for convenience

    #AI check 0: check if won

    ourPieces = Array(piece, 0) #0 element piece array
    enemyPieces = Array(piece, 0)
    #enemyKing = empty
    #ourKing = empty

    # go through board
    for i in 1:length(board)
        for j in 1:length(board[1])

            #get all our pieces in board into ourPieces array
            if currentSide == board[i][j].side
                push!(ourPieces, board[i][j])
            elseif board[i][j].side != -1
                push!(enemyPieces, board[i][j])
            end
            #=
            #get enemy king
            if board[i][j].name == 'k' && board[i][j].side != currentSide
                enemyKing = board[i][j]
            #get our king
            elseif board[i][j].name == 'k' && board[i][j].side == currentSide
                ourKing = board[i][j]
            end 
            =#
        end
    end


    move_piece = piece("", "", 0, 0, -1, false)
    validMoves = [] # valid moves for move_piece
    while true
        srand()
        move_piece = ourPieces[rand(1:length(ourPieces))]
        for y = 1:length(board)
            for x = 1:length(board[1])
                if board[y][x].side != move_piece.side # can't move onto friendly piece
                    if inRange(board, move(currentMove, "move", move_piece.x, move_piece.y, x, y, "", false, -1, -1, -1, -1))
                        push!(validMoves, (x,y))
                    end
                end
            end
        end
        if length(validMoves) > 0
            break 
        end
    end

    ourMove = validMoves[rand(1:length(validMoves))]
    moveMade = move(currentMove, "move", move_piece.x, move_piece.y, ourMove[1], ourMove[2], "", false, -1, -1, -1, -1)


    #= end timing =#
    time_taken = toq()

    if length(board) == 16
        board = demon_burning(board)
    end

    return simulateMove(board, currentMove, moveMade.sourcex, moveMade.sourcey, moveMade.targetx, moveMade.targety)[1], time_taken, moveMade
end


function updateBoard(oldBoard, movesTable)

    board = duplicateBoard(oldBoard)

    if length(board) == 5
        gameType = "mini"
    elseif length(board) == 9
        gameType = "standard"
    elseif length(board) == 12
        gameType = "chu"
    elseif length(board) == 16
        gameType = "ten"
    end

    # holds all the pieces that the even player (player 1) has captured
    capturedByEven = Array{piece,1}
    # holds all the pieces that the odd player (player 2) has captured
    capturedByOdd = Array{piece,1}

    currentMove = 1
    movesPlayed = length(movesTable[1])
    gameActive = true # flag for whether game has been resigned
    while gameActive && (currentMove <= movesPlayed)
        #displayBoard(board) # for debugging
        #=
        get(movesTable[col][row]) to retrieve move data
         - row number is identical to move number
         - col 1: move_number
         - col 2: move_type (move, resign or drop)
         - col 3: sourcex
         - col 4: sourcey
         - col 5: targetx
         - col 6: targety
         - col 7: option (! for move ending in promotion, piece name for drop move)
         - col 8: i_am_cheating (non-NULL if cheating)
         - col 9: targetx2
         - col 10: targety2
        =#

        side = currentMove % 2
        moveType = get(movesTable[2][currentMove])
        sourceX = movesTable[3][currentMove]
        sourceY = movesTable[4][currentMove]
        targetX = movesTable[5][currentMove]
        targetY = movesTable[6][currentMove]
        option = movesTable[7][currentMove]
        targetX2 = movesTable[9][currentMove]
        targetY2 = movesTable[10][currentMove]
        targetX3 = movesTable[11][currentMove]
        targetY3 = movesTable[12][currentMove]
       
        
        if moveType == "move"
            movePiece(gameType, board, currentMove, sourceX, sourceY, targetX, targetY, option, targetX2, targetY2, targetX3, targetY3)
        elseif moveType == "drop"
            dropPiece(board, currentMove, option, targetX, targetY)
        elseif moveType == "resign"
            gameActive = false
        end
        
        currentMove += 1
    end
    return board, capturedByEven, capturedByOdd, gameActive
end

function simulateMove(board1, move_number, sourceX, sourceY, targetX, targetY)
    board = duplicateBoard(board1)
    board[targetY][targetX] = board[sourceY][sourceX] # move piece at source to target, removing piece in process
    board[targetY][targetX].x = targetX # setting piece x
    board[targetY][targetX].y = targetY # setting piece y
    board[sourceY][sourceX] = piece("", "", 0, 0, -1, false) #set source space to empty

    deservesPromotion = promotion_check(board, sourceX, sourceY, targetX, targetY)
    if deservesPromotion
        board[targetY][targetX].name = uppercase(board[targetY][targetX].name)
    end
    return board, move_number
end

# player is either "sente" or "gote"; playerTime is the time to be enterd into the meta table
function updateMetaTime(gameFile, player, playerTime)
    SQLite.query(gameFile, "update meta set value='$playerTime' where key='$(player*"_time")';")
end

# inputs: SQLite database file and move object
# doesn't return anything
function makeMove(db, amove::move)
    move_number = amove.move_number
    move_type = amove.move_type
    sourceX = amove.sourcex 
    sourceY = amove.sourcey 
    targetX = amove.targetx 
    targetY = amove.targety 
    option = amove.option 
    targetX2 = amove.targetx2 
    targetY2 = amove.targety2 
    targetX3 = amove.targetx3 
    targetY3 = amove.targety3

    #db=SQLite.DB(gameFile)

    if move_type == "resign"
        SQLite.query(db, "insert into moves(move_number, move_type) values ($move_number, '$move_type')")
    elseif move_type == "drop"
        SQLite.query(db, "insert into moves(move_number, move_type, targetx, targety, option) values ($move_number, '$move_type',$targetX, $targetY, '$option')")
    elseif move_type == "move"
        # if single move
        if (targetX2 <= 0 || targetY2 <= 0) && (targetX3 <= 0 || targetY3 <= 0)
            SQLite.query(db, "insert into moves(move_number, move_type, sourcex, sourcey, targetx, targety, option) values ($move_number, '$move_type', $sourceX, $sourceY, $targetX, $targetY, '$option')")
        # if double move
        elseif targetX3 <= 0 || targetY3 <= 0
            SQLite.query(db, "insert into moves(move_number, move_type, sourcex, sourcey, targetx, targety, option, targetx2, targety2) values ($move_number, '$move_type', $sourceX, $sourceY, $targetX, $targetY, '$option', $targetX2, $targetY2)")
        # if triple move
        else
            SQLite.query(db, "insert into moves(move_number, move_type, sourcex, sourcey, targetx, targety, option, targetx2, targety2, targetx3, targety3) values ($move_number, '$move_type', $sourceX, $sourceY, $targetX, $targetY, '$option', $targetX2, $targetY2, $targetX3, $targetY3)")
        end
    end
end

function getUserMove(move_number)
    tic()
    # get players move
    moveMade = noMove
    moveMade.move_number = move_number
    while true
        println("\nPlease enter your move in the following format (omit any irrelevant elements)")
        println("\tmove_type sourceX sourceY targetX targetY targetX2 targetY2 targetX3 targetY3 option")
        print("Enter your move now: ")
        moveSelection = split(lowercase(chomp(readline(STDIN))))

        #println(moveSelection) # for debugging

        if length(moveSelection) == 1 && moveSelection[1] == "resign"
            moveMade.move_type = moveSelection[1]
            break
        elseif length(moveSelection) == 4 && moveSelection[1] == "drop"
            moveMade.move_type = moveSelection[1]
            moveMade.targetx = parse(Int8, moveSelection[2])
            moveMade.targety = parse(Int8, moveSelection[3])
            moveMade.option = moveSelection[4]
            break
        elseif length(moveSelection) > 4 && moveSelection[1] == "move"
            if length(moveSelection) == 5 # single move
                moveMade.move_type = moveSelection[1]
                moveMade.sourcex = parse(Int8, moveSelection[2])
                moveMade.sourcey = parse(Int8, moveSelection[3])
                moveMade.targetx = parse(Int8, moveSelection[4])
                moveMade.targety = parse(Int8, moveSelection[5])
                break
            elseif length(moveSelection) == 6 && moveSelection[6] == "!" # single move with promotion
                moveMade.move_type = moveSelection[1]
                moveMade.sourcex = parse(Int8, moveSelection[2])
                moveMade.sourcey = parse(Int8, moveSelection[3])
                moveMade.targetx = parse(Int8, moveSelection[4])
                moveMade.targety = parse(Int8, moveSelection[5])
                moveMade.option = moveSelection[6]
                break
            elseif length(moveSelection) == 7 # double move
                moveMade.move_type = moveSelection[1]
                moveMade.sourcex = parse(Int8, moveSelection[2])
                moveMade.sourcey = parse(Int8, moveSelection[3])
                moveMade.targetx = parse(Int8, moveSelection[4])
                moveMade.targety = parse(Int8, moveSelection[5])
                moveMade.targetx2 = parse(Int8, moveSelection[6])
                moveMade.targety2 = parse(Int8, moveSelection[7])
                break
            elseif length(moveSelection) == 8 && moveSelection[8] == "!"  # double move with promotion
                moveMade.move_type = moveSelection[1]
                moveMade.sourcex = parse(Int8, moveSelection[2])
                moveMade.sourcey = parse(Int8, moveSelection[3])
                moveMade.targetx = parse(Int8, moveSelection[4])
                moveMade.targety = parse(Int8, moveSelection[5])
                moveMade.targetx2 = parse(Int8, moveSelection[6])
                moveMade.targety2 = parse(Int8, moveSelection[7])
                moveMade.option = moveSelection[8]
                break
            elseif length(moveSelection) == 9 # triple move 
                moveMade.move_type = moveSelection[1]
                moveMade.sourcex = parse(Int8, moveSelection[2])
                moveMade.sourcey = parse(Int8, moveSelection[3])
                moveMade.targetx = parse(Int8, moveSelection[4])
                moveMade.targety = parse(Int8, moveSelection[5])
                moveMade.targetx2 = parse(Int8, moveSelection[6])
                moveMade.targety2 = parse(Int8, moveSelection[7])
                moveMade.targetx3 = parse(Int8, moveSelection[8])
                moveMade.targety3 = parse(Int8, moveSelection[9])
                break
            elseif length(moveSelection) == 10 && moveSelection[10] == "!"  # triple move with promotion
                moveMade.move_type = moveSelection[1]
                moveMade.sourcex = parse(Int8, moveSelection[2])
                moveMade.sourcey = parse(Int8, moveSelection[3])
                moveMade.targetx = parse(Int8, moveSelection[4])
                moveMade.targety = parse(Int8, moveSelection[5])
                moveMade.targetx2 = parse(Int8, moveSelection[6])
                moveMade.targety2 = parse(Int8, moveSelection[7])
                moveMade.targetx3 = parse(Int8, moveSelection[8])
                moveMade.targety3 = parse(Int8, moveSelection[9])
                moveMade.option = moveSelection[10]
                break
            end
        end
        println("That is not a valid move selection. Please try again")
    end
    return moveMade, toq()
end


function main()
    gameSelection = ""
    while true 
        println("\nTo start a new game                                                enter 'N'")
        println("To continue an old game                                            enter 'O'")
        println("To replay a finished game                                          enter 'R'")
        println("To quit                                                            enter 'Q'")
        print("Please enter your selection now: ")
        gameSelection = uppercase(chomp(readline(STDIN)))
        if gameSelection in ["N", "O", "R", "Q"]
            break
        end
        println("$gameSelection is not a valid selection. Please try again.\n")
    end

    typeSelection = ""
    fileSelection = ""
    if gameSelection == "N"
        while true
            println("\nTo spectate an AI vs AI match                                      enter 'A'")
            println("To start a game against the AI                                     enter 'B'")
            println("To start a local match against another player on this computer     enter 'C'")
            println("To join a game against a remote program                            enter 'D'")
            println("To host a game and use AI as player                                enter 'E'")
            println("To host a game and play as a player                                enter 'F'")
            println("To start a new email game                                          enter 'G'")
            print("Please enter your selection now: ")
            typeSelection = uppercase(chomp(readline(STDIN)))
            if typeSelection in ["A", "B", "C", "D", "E", "F", "G"]
                break
            end
            println("$typeSelection is not a valid selection. Please try again.\n")
        end
    elseif gameSelection == "O"
        while true
            println("\nTo continue a local player vs player game                          enter 'H'")
            println("To take a turn in an email game                                    enter 'I'")
            print("Please enter your selection now: ")
            typeSelection = uppercase(chomp(readline(STDIN)))
            if typeSelection in ["H", "I"]
                while true
                    println("\nPlease make sure that the game file you would like to continue is in the working directory.")
                    println("The working directory is $(pwd())")
                    print("Please enter the complete filename of the game file that you would like to continue: ")
                    fileSelection = chomp(readline(STDIN))
                    files = readdir()
                    if fileSelection in files
                        break
                    end
                    println("$fileSelection does not exist. Please try again.\n")
                end
                break
            end
            println("$typeSelection is not a valid selection. Please try again.\n")
        end
    elseif gameSelection == "R"
        while true
            println("\nPlease make sure that the game file you would like to replay is in the working directory.")
            println("The working directory is $(pwd())")
            print("Please enter the complete filename of the game file that you would like to replay: ")
            fileSelection = chomp(readline(STDIN))
            files = readdir()
            if fileSelection in files
                run(`julia display_step.jl $fileSelection`)
                quit()
            end
            println("$fileSelection does not exist. Please try again.\n")
        end
    elseif gameSelection == "Q"
        println("It's so sad to see you go, maybe we'll play again next time!")
        quit()
    end


    if fileSelection != ""
        gameFile = SQLite.DB(fileSelection)
    else # if starting new game
        fileSelection = ""
        gameTypeSelection = ""
        legalitySelection = ""
        timeLimitSelection = 0
        timeAddSelection = 0
        while true
            print("\nPlease enter the complete filename for a new game file: ")
            fileSelection = chomp(readline(STDIN))
            files = readdir()
            if !(fileSelection in files)
                break
            end
            println("$fileSelection already exists. Please try something else.\n")
        end
        while true
            println("\nTo play a game of standard shogi                                   enter 'S'")
            println("To play a game of minishogi                                        enter 'M'")
            println("To play a game of chu shogi                                        enter 'C'")
            println("To play a game of tenjiku shogi                                    enter 'T'")
            print("Please enter your selection now: ")
            gameTypeSelection = uppercase(chomp(readline(STDIN)))
            if gameTypeSelection in ["S", "M", "C", "T"]
                break
            end
            println("$gameTypeSelection is not a valid selection. Please try again.\n")
        end
        while true
            println("\nTo allow cheating                                                  enter 'T'")
            println("To disallow cheating                                               enter 'F'")
            print("Please enter your selection now: ")
            legalitySelection = uppercase(chomp(readline(STDIN)))
            if legalitySelection in ["T", "F"]
                break
            end
            println("$legalitySelection is not a valid selection. Please try again.\n")
        end
        while true
            print("\nIf you would like to have a timed game, enter the total number of seconds for each player (0 for no timing): ")
            timeLimitSelection = tryparse(Float64, chomp(readline(STDIN)))
            if !isnull(timeLimitSelection) && get(timeLimitSelection) >= 0
                timeLimitSelection = get(timeLimitSelection)
                break
            end
            println("$timeLimitSelection is not a valid selection. Please try again.")
        end
        while timeLimitSelection > 0
            print("\nIf you would like time to be added on each turn, enter the number of seconds to be added (0 for no time add): ")
            timeAddSelection = tryparse(Float64, chomp(readline(STDIN)))
            if !isnull(timeAddSelection) && get(timeAddSelection) >= 0
                timeAddSelection = get(timeAddSelection)
                break
            end
            println("$timeAddSelection is not a valid selection. Please try again.")
        end
        gameFile = gameFileSetup(fileSelection, gameTypeSelection, legalitySelection, timeLimitSelection, timeAddSelection)
    end

    if typeSelection in ["A", "B", "E"] # any game mode involving AI
        difficultySelection = "N" # normal is default selection
        while true
            println("\nAI difficulty mode selection:")
            println("For suicidal                                                       enter 'S'")
            println("For random                                                         enter 'R'")
            println("For protracted death                                               enter 'P'")
            println("For normal                                                         enter 'N'")
            println("For hard                                                           enter 'H'")
            print("Please enter your selection now: ")
            difficultySelection = uppercase(chomp(readline(STDIN)))
            if difficultySelection in ["S", "R", "P", "N", "H"]
                break
            end
            println("$difficultySelection is not a valid option. Please try again.")
        end
        if difficultySelection == "S"
            AI = AI_suicidal
        elseif difficultySelection == "R"
            AI = AI_random
        elseif difficultySelection == "P"
            AI = AI_protracted
        elseif difficultySelection == "N"
            AI = AI_normal
        elseif difficultySelection == "H"
            AI = AI_hard
        end
    end

    metaTable, movesTable, gameType, seed, is_legal, is_timed = gameSetup(gameFile)
    movesPlayed = length(movesTable[1])

    if is_timed
        time_add, sente_time, gote_time = getTimeData(metaTable)
    else
        time_add, sente_time, gote_time = 0, 0, 0
    end

    board, boardLength, numOfPromotionRanks = boardSetup(gameType)

    displayBoard(board)

    board, capturedByEven, capturedByOdd, gameActive = updateBoard(board, movesTable)

    if typeSelection == "A" # local match: AI vs AI
        currentMove = movesPlayed + 1
        allBoards = []
        while gameActive
            #println("moves played: $movesPlayed")
            #currentMove = movesPlayed + 1
            player = currentMove%2 == 1?"sente":"gote"

            push!(allBoards, board)
            board = duplicateBoard(board)
            # moveMade is the move that has already been made on the board
            board, time_taken, moveMade = AI(board, currentMove)
            displayBoard(board)
            println(moveMade)
            if moveMade.move_type == "resign"
                gameActive = false
            end
            
            if !validate(allBoards[end], moveMade, capturedByOdd, capturedByEven)
                println("moveMade: ", moveMade)
                println("$player cheated! Game over!")
                gameActive = false
            end

            if is_timed
                if player == "sente"
                    sente_time = sente_time + time_add - time_taken
                    playerTime = sente_time
                else 
                    gote_time = gote_time + time_add - time_taken
                    playerTime = gote_time
                end

                if playerTime <= 0
                    println("$player ran out of time. Game over!")
                    gameActive = false
                end
            end

            winRes = win(moveMade.move_type, is_timed, sente_time, gote_time, allBoards)
            if winRes == "W"
                println("Gote won the game!")
                gameActive = false
            elseif winRes == "B"
                println("Sente won the game!")
                gameActive = false
            elseif winRes == "D"
                println("The game ended in a draw.")
                gameActive = false
            elseif winRes == "r"
                println("Gote resigned the game.")
                gameActive = false
            elseif winRes == "R"
                println("Sente resigned the game.")
                gameActive = false
            end

            makeMove(gameFile, moveMade)
            if is_timed
                updateMetaTime(gameFile, player, playerTime)
            end
            currentMove += 1

            push!(allBoards, board)
            board = duplicateBoard(board)
        end

    elseif typeSelection == "B" # local match: player vs AI
        currentMove = movesPlayed + 1
        allBoards = []
        while gameActive
            #println("moves played: $movesPlayed")
            #currentMove = movesPlayed + 1
            player = currentMove%2 == 1?"sente":"gote"

            if player == "gote" # AI's turn

                println("\n***********\n GOTE TURN \n***********\n")

                # moveMade is the move that has already been made on the board
                board, time_taken, moveMade = AI(board, currentMove)
                displayBoard(board)
                println(moveMade)
                if moveMade.move_type == "resign"
                    gameActive = false
                end
                
                if !validate(allBoards[length(allBoards)], moveMade, capturedByOdd, capturedByEven)
                    println("moveMade: ", moveMade)
                    println("$player cheated! Game over!")
                    gameActive = false
                end

                if is_timed
                    gote_time = gote_time + time_add - time_taken
                    
                    if gote_time <= 0
                        println("$player ran out of time. Game over!")
                        gameActive = false
                    end
                end

                winRes = win(moveMade.move_type, is_timed, sente_time, gote_time, allBoards)
                if winRes == "W"
                    println("Gote won the game!")
                    gameActive = false
                elseif winRes == "B"
                    println("Sente won the game!")
                    gameActive = false
                elseif winRes == "D"
                    println("The game ended in a draw.")
                    gameActive = false
                elseif winRes == "r"
                    println("Gote resigned the game.")
                    gameActive = false
                elseif winRes == "R"
                    println("Sente resigned the game.")
                    gameActive = false
                end

                makeMove(gameFile, moveMade)
                if is_timed
                    updateMetaTime(gameFile, player, gote_time)
                end

            else # human player's turn

                println("\n************\n SENTE TURN \n************\n")

                moveMade, time_taken = getUserMove(currentMove)

                displayBoard(board)
                println(moveMade)
                if !validate(board, moveMade, capturedByOdd, capturedByEven)
                    println("moveMade: ", moveMade)
                    println("$player cheated! Game over!")
                    gameActive = false
                end

                if is_timed
                    sente_time = sente_time + time_add - time_taken
                    
                    if sente_time <= 0
                        println("$player ran out of time. Game over!")
                        gameActive = false
                    end
                end

                winRes = win(moveMade.move_type, is_timed, sente_time, gote_time, allBoards)
                if winRes == "W"
                    println("Gote won the game!")
                    gameActive = false
                elseif winRes == "B"
                    println("Sente won the game!")
                    gameActive = false
                elseif winRes == "D"
                    println("The game ended in a draw.")
                    gameActive = false
                elseif winRes == "r"
                    println("Gote resigned the game.")
                    gameActive = false
                elseif winRes == "R"
                    println("Sente resigned the game.")
                    gameActive = false
                end

                board = simulateMove(board, currentMove, moveMade.sourcex, moveMade.sourcey, moveMade.targetx, moveMade.targety)[1]
                makeMove(gameFile, moveMade)
                if is_timed
                    updateMetaTime(gameFile, player, sente_time)
                end

            end

            currentMove += 1

            push!(allBoards, board)
            board = duplicateBoard(board)
        end

    elseif typeSelection in ["C","H"] # local match: player vs player
        currentMove = movesPlayed + 1
        allBoards = []
        while gameActive
            #println("moves played: $movesPlayed")
            #currentMove = movesPlayed + 1
            player = currentMove%2 == 1?"sente":"gote"

            if player == "sente"

                println("\n************\n SENTE TURN \n************\n")

                moveMade, time_taken = getUserMove(currentMove)

                displayBoard(board)
                println(moveMade)
                if !validate(board, moveMade, capturedByOdd, capturedByEven)
                    println("moveMade: ", moveMade)
                    println("$player cheated! Game over!")
                    gameActive = false
                end

                if is_timed
                    sente_time = sente_time + time_add - time_taken
                    
                    if sente_time <= 0
                        println("$player ran out of time. Game over!")
                        gameActive = false
                    end
                end

                winRes = win(moveMade.move_type, is_timed, sente_time, gote_time, allBoards)
                if winRes == "W"
                    println("Gote won the game!")
                    gameActive = false
                elseif winRes == "B"
                    println("Sente won the game!")
                    gameActive = false
                elseif winRes == "D"
                    println("The game ended in a draw.")
                    gameActive = false
                elseif winRes == "r"
                    println("Gote resigned the game.")
                    gameActive = false
                elseif winRes == "R"
                    println("Sente resigned the game.")
                    gameActive = false
                end

                board = simulateMove(board, currentMove, moveMade.sourcex, moveMade.sourcey, moveMade.targetx, moveMade.targety)[1]
                makeMove(gameFile, moveMade)
                if is_timed
                    updateMetaTime(gameFile, player, sente_time)
                end

            else 

                println("\n***********\n GOTE TURN \n***********\n")

                moveMade, time_taken = getUserMove(currentMove)

                displayBoard(board)
                println(moveMade)
                if !validate(board, moveMade, capturedByOdd, capturedByEven)
                    println("moveMade: ", moveMade)
                    println("$player cheated! Game over!")
                    gameActive = false
                end

                if is_timed
                    gote_time = gote_time + time_add - time_taken
                    
                    if gote_time <= 0
                        println("$player ran out of time. Game over!")
                        gameActive = false
                    end
                end

                winRes = win(moveMade.move_type, is_timed, sente_time, gote_time, allBoards)
                if winRes == "W"
                    println("Gote won the game!")
                    gameActive = false
                elseif winRes == "B"
                    println("Sente won the game!")
                    gameActive = false
                elseif winRes == "D"
                    println("The game ended in a draw.")
                    gameActive = false
                elseif winRes == "r"
                    println("Gote resigned the game.")
                    gameActive = false
                elseif winRes == "R"
                    println("Sente resigned the game.")
                    gameActive = false
                end

                board = simulateMove(board, currentMove, moveMade.sourcex, moveMade.sourcey, moveMade.targetx, moveMade.targety)[1]
                makeMove(gameFile, moveMade)
                if is_timed
                    updateMetaTime(gameFile, player, gote_time)
                end

            end
            currentMove += 1

            push!(allBoards, board)
            board = duplicateBoard(board)
        end

    elseif typeSelection in ["D", "E", "F"]
        println("This feature has not yet been implemented yet.")
    elseif typeSelection in ["G","I"]

        currentMove = movesPlayed + 1
        player = currentMove%2==1?"sente":"gote"

        println("\n************\n $(uppercase(player)) TURN \n************\n")

        moveMade, time_taken = getUserMove(currentMove)

        #displayBoard(board)
        #println(moveMade)
        if !validate(board, moveMade, capturedByOdd, capturedByEven)
            println("moveMade: ", moveMade)
            println("$player cheated! Game over!")
            gameActive = false
        end

        playerTime = player == "sente"?sente_time:gote_time
        if is_timed
            playerTime = playerTime + time_add - time_taken        
            if playerTime <= 0
                println("$player ran out of time. Game over!")
                gameActive = false
            end
        end

        winRes = ""#win(moveMade.move_type, is_timed, sente_time, gote_time, allBoards) # dont have allBoards for email games
        if winRes == "W"
            println("Gote won the game!")
            gameActive = false
        elseif winRes == "B"
            println("Sente won the game!")
            gameActive = false
        elseif winRes == "D"
            println("The game ended in a draw.")
            gameActive = false
        elseif winRes == "r"
            println("Gote resigned the game.")
            gameActive = false
        elseif winRes == "R"
            println("Sente resigned the game.")
            gameActive = false
        end

        makeMove(gameFile, moveMade)

        if is_timed
            updateMetaTime(gameFile, player, playerTime)
        end

    end
end

#precompile(main, ())
