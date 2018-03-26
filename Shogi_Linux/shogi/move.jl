
#=
include("move_suicidal.jl")     # difficulty level 1
include("move_random.jl")       # difficulty level 2
include("move_protracted.jl")   # difficulty level 3
include("move_normal.jl")       # difficulty level 4
include("move_hard.jl")         # difficulty level 5
=#
include("move_helpers.jl")

function updateBoard(oldBoard, movesTable)

    #duplicate the game board recursively using i-1 version and set the gametype depending on board size
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
    
    #keep track of the current move, the ith move, and if the game is still being played
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
       
        #conditionals for actions based on the variable moveType
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
