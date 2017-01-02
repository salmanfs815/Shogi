#include("move.jl")
#include("move_helpers.jl")
include("validate_alone.jl")

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

    ##println  ("ourPieces: ", ourPieces)
    ##println  ("enemyPieces: ", enemyPieces)
    ##println  ("ourKing: ", ourKing)
    ##println  ("enemyKing: ", enemyKing)


    #= omit from random AI (no check for king safety)

    killerPieces = [] # array of pieces that can kill our king

    # identify pieces that can kill our king
    for apiece in enemyPieces
        if inKillRange(board, apiece, ourKing)
            ##println  ("found a killer: $apiece")
            push!(killerPieces, apiece)
        end
    end

    sX, sY, tX, tY = checkForWin(ourPieces,enemyKing)

    if sX != 0 # we can win this game
        moveMade = move(currentMove, "move", sX, sY, tX, tY, "", false, -1, -1, -1, -1)
        gameActive = false
    end


    inCheck = checkForCheck(enemyPieces, ourKing)

    ##println  ("inCheck: $inCheck")

    if inCheck && gameActive

        if length(killerPieces) == 1
            
            for apiece in ourPieces
                if inKillRange(board, apiece, killerPieces[1])
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

    =#

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


    #println("piece selected: ",move_piece)
    #println("valid moves: \n",validMoves)
    #=
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
                res, gameLen = simulate(board, move_number, currentMove)
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
            #myRes, gameLength = simulate(board, move_number, currentMove)
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
            moveMade = true


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
            moveMade = true

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
            moveMade = true

        else # were screwed, so resign with dignity!

            moveMade = move(currentMove,  "resign", -1, -1, -1, -1, "", false, -1, -1, -1, -1)
            moveMade = true
            
        end

    end # if moveMade != true
    =#

    #= end timing =#
    time_taken = toq()

    if length(board) == 16
        board = demon_burning(board)
    end

    return simulateMove(board, currentMove, moveMade.sourcex, moveMade.sourcey, moveMade.targetx, moveMade.targety)[1], time_taken, moveMade
end