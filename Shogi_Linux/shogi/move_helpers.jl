include("types.jl")

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