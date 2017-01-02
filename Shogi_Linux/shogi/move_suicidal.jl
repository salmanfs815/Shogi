#include("move.jl")
#include("move_helpers.jl")
include("validate_alone.jl")

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