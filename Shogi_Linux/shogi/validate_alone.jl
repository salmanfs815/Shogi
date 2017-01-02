####################
## START VALIDATE ##
####################

include("types.jl")
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
