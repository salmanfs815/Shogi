using Gtk.ShortNames, Graphics
import DataFrames
import SQLite


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


#################
### START WIN ###
#################

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


function createGame(payload::String)
    global gameType
    global legality
    global timelimit
    global limitadd
    global goFirst
    global goSecond
    global db
    payload=strip(payload)
    payload=chomp(payload)
    i=1
    wincode=""
    while payload[i]!=':'
        wincode=string(wincode,payload[i])
        i+=1
    end
    if wincode=='e'
        return false
    end
    wincode=parse(Int64,wincode)
    if wincode==0
        gameType=""
        i+=1
        for a in i:length(payload)
            goFirst=string(goFirst,payload[a])
            goSecond=string(goSecond,payload[a])
        end
        while payload[i]!=':'
            gameType=string(gameType,payload[i])
            i+=1
        end
        i+=1
        legality=""
        while payload[i]!=':'
            legality=string(legality,payload[i])
            i+=1
        end
        if legality=="1"
            legality="F"
        else
            legality="T"
        end
        i+=1
        timelimit=""
        while payload[i]!=':'
            timelimit=string(timelimit,payload[i])
            i+=1
        end
        timelimit=parse(Int64,timelimit)
        i+=1
        limitadd=""
        while i<length(payload)+1
            limitadd=string(limitadd,payload[i])
            i+=1
        end
        limitadd=parse(Int64,limitadd)
        if gameType=="S"
            gameType="standard"
        elseif gameType=="M"
            gameType="mini"
        elseif gameType=="C"
            gameType="chu"
        else
            gameType="tenjiku"
        end
        db=gameFileSetup(fileName,gameType,legality,timelimit,limitadd)
        return true
    end
    return false
end

function readInsertMove(payload::String)
    global board
    global allBoards
    payload=chomp(payload)
    global db
    global authString1
    global authString2
    global aMove
    i=1
    wincode=""
    while payload[i]!=':'
        wincode=string(wincode,payload[i])
        i+=1
    end
    wincode=parse(Int64,wincode)
    if wincode==1 #WINCODE FOR QUITTING
        return "quit"
    elseif wincode==2 #WINCODE FOR MAKING A MOVE
        i+=1
        tempauthString=""
        while payload[i]!=':'
            tempauthString=string(tempauthString,payload[i])
            i+=1
        end
        if tempauthString==authString1
            player=1
        else
            player=2
        end
        i+=1
        moveNum=""
        while payload[i]!=':'
            moveNum=string(moveNum,payload[i])
            i+=1
        end
        moveNum=parse(Int64,moveNum)
        i+=1
        moveType=""
        while payload[i]!=':'
            moveType=string(moveType,payload[i])
            i+=1
        end
        i+=1
        sourcex=""
        while payload[i]!=':'
            sourcex=string(sourcex,payload[i])
            i+=1
        end
        sourcex=parse(Int64,sourcex)
        i+=1
        sourcey=""
        while payload[i]!=':'
            sourcey=string(sourcey,payload[i])
            i+=1
        end
        sourcey=parse(Int64,sourcey)
        i+=1
        targetx=""
        while payload[i]!=':'
            targetx=string(targetx,payload[i])
            i+=1
        end
        targetx=parse(Int64,targetx)
        i+=1
        targety=""
        while payload[i]!=':'
            targety=string(targety,payload[i])
            i+=1
        end
        targety=parse(Int64,targety)
        i+=1
        option=""
        while payload[i]!=':'
            option=string(option,payload[i])
            i+=1
        end
        i+=1
        i_am_cheating=""
        while payload[i]!=':'
            i_am_cheating=string(i_am_cheating,payload[i])
            i+=1
        end
        i+=1
        targetx2=""
        while payload[i]!=':'
            targetx2=string(targetx2,payload[i])
            i+=1
        end
        targetx2=parse(Int64,targetx2)
        i+=1
        targety2=""
        while payload[i]!=':'
            targety2=string(targety2,payload[i])
            i+=1
        end
        targety2=parse(Int64,targety2)
        i+=1
        targetx3=""
        while payload[i]!=':'
            targetx3=string(targetx3,payload[i])
            i+=1
        end
        targetx3=parse(Int64,targetx3)
        i+=1
        targety3=""
        while i<length(payload)+1
            targety3=string(targety3,payload[i])
            i+=1
        end
        targety3=parse(Int64,targety3)
        i+=1

        if i_am_cheating==0
            i_am_cheating==false
        else
            i_am_cheating=true
        end
        if option=="0"
            option=""
        end
        if moveType=="1"
            moveType="move"
        elseif moveType=="2"
            moveType="drop"
        else
            moveType="resign"
        end
        aMove=move(moveNum,moveType,sourcex,sourcey,targetx,targety,option,i_am_cheating,targetx2,targety2,targetx3,targety3)
        makeMove(db,aMove)
        if moveType=="move"
            if targetx2 == 0
                board[targety][targetx]=board[sourcey][sourcex]
                board[sourcey][sourcex]=empty
            elseif targetx2 !=0 && targetx3 ==0
                board[targety2][targetx2]=board[sourcey][sourcex]
                board[sourcey][sourcex]=empty
            elseif targetx2 !=0 && targetx3 !=0
                board[targety3][targetx3]=board[sourcey][sourcex]
                board[sourcey][sourcex]=empty
            end
            push!(allBoards,duplicateBoard(board))
        end

        return aMove,player
    end
end

function getPrevMove(msg)
    i=0
    ret=""
    for a in 1:2
        i+=1
        while msg[i]!=':'
            i+=1
        end
    end
    i+=1
    while i<length(msg)+1
        ret=string(ret,msg[i])
        i+=1
    end
    return ret
end

function sendClient(receiver,msg)
    global currentMove
    global first
    global second
    if receiver=="first"
        println(clients[first],msg)
    else
        println(clients[second],msg)
    end
end

function getMove()
    global currentMove
    global first
    global second
    if (currentMove)%2==1
        msg=readline(clients[first])
        currentMove+=1
        msg=chomp(msg)
        println(msg)
        return msg
    else 
        msg=readline(clients[second])
        msg=chomp(msg)
        currentMove+=1
        println(msg)
        return msg
    end
end

function sendDelay()
    global currentMove
    global first
    global second
    if (currentMove)%2==1
        println(clients[second],wait_2)
    else 
        println(clients[first],wait_1)
    end
end

#=emptyP=piece("", "", 0, 0, -1, false)
board = [ [ emptyP for i = 1:N ] for j = 1:N ]=#

function server_init(portNum)
global port=portNum
global fileName="server.db"
filePath=joinpath(pwd(),fileName)
touch(filePath)
rm(filePath,recursive=false,force=true)
global db

global authString1="1a2b3c4d5e6f"
global authString2="7g8h9i10j11k12l"

global goFirst="0:$authString1:"
global goSecond="1:$authString2:"

global draw_1="3:$authString1:There is a draw"
global draw_2="3:$authString2:There is a draw"

global wait_1="8:$authString1:Not your turn, wait for player2"
global wait_2="8:$authString2:Not your turn, wait for player1"

global gameType=0
global legality=0
global timelimit=0
global limitadd=0
global server=listen(2000)
global player1=accept(server)
println("player accepted.")
global player2=accept(server)
println("player accepted.")
global first=rand(1:2)
global clients=[]
push!(clients,player1)
push!(clients,player2)
if first==1
    global second=2
else
    global second=1
end

settings=readline(clients[first])
ignore=readline(clients[second])
global currentMove=1

if createGame(settings)==true
    if timelimit==0
        isTimed=false
    else
        isTimed=true
    end
    if gameType=="standard"
        global N=9
    elseif gameType=="chu"
        global N =12
    elseif gameType=="mini"
        global N=5
    else
        global N=16
    end

    global empty=piece("", "", 0, 0, -1, false)

    global board = [ [ empty for i = 1:N ] for j = 1:N ]
    global allBoards=[]
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
    push!(allBoards,duplicateBoard(board))

    println(clients[first],goFirst)
    println(clients[second],goSecond)
    while (win("move",isTimed,timelimit,timelimit,allBoards)=="?")
        prevMove2="9:$authString2:"
        prevMove1="9:$authString1:"
        sendDelay()
        payload=getMove()
        readInsertMove(payload)
        if (currentMove-1)%2==1
            prevMove2=string(prevMove2,getPrevMove(payload))
            sendClient("second",prevMove2)
        else
            prevMove1=string(prevMove1,getPrevMove(payload))
            sendClient("first",prevMove1)
        end
    end
end
end


function readMove()
    global moveNum
    global currentMove
    global server
    move=chomp(readline(server))
    move=split(move,":")
    println(move)
    sx=parse(Int64,String(move[5]))
    sy=parse(Int64,String(move[6]))
    tx=parse(Int64,String(move[7]))
    ty=parse(Int64,String(move[8]))
    currentMove+=1
    println(move)
    push!(userMove,(sx,sy))
    push!(userMove,(tx,ty))
    moveCheck()
end

function sendMove(sx,sy,tx,ty)
    global server
    global authString
    global currentMove
    move="2:$authString:$currentMove:1:$sx:$sy:$tx:$ty:0:0:0:0:0:0"
    println(server,move)
    currentMove+=1
end


function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end


function checkWin(typeMove, istimed, sentetime, gotetime, boards)

    global window
    global grid
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end

function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end


function movePieceGUI(sx,sy,tx,ty)
    global board
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyPath)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyPath)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end



function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global board
    global userTurn
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            @async begin
            sendMove(sx,sy,tx,ty)
        end
            movePieceGUI(sx,sy,tx,ty)
            userMakingMove=readline(server)
            userMove=[]
        end
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove.option="!"
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove.option="!"
            end
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        push!(allBoards,duplicateBoard(board))
        if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            @async begin
            sendMove(sx,sy,tx,ty)
        end
            movePieceGUI(sx,sy,tx,ty)
            userMakingMove=readline(server)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            if moveNum%2==1
                if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                    thisMove.option="!"
                end
            else
                if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                    thisMove.option="!"
                end
            end
            @async begin
            sendMove(sx,sy,tx,ty)
        end
            movePieceGUI(sx,sy,tx,ty)
            userMakingMove=readline(server)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            push!(allBoards,duplicateBoard(board))
            if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    if moveNum%2==userTurn
        if userTurn==1
            init_buttons("sente")
        else
            init_buttons("gote")
        end
    else
        readMove()
    end
end



function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],UInt32(id2Arr[a][1]))
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            signal_handler_block(grid[idArr[b][2],idArr[b][3]],UInt32(idArr[b][1]))
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end



function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end


#$port $gameType $timeLimit $timeIncrement $japaneseRoulette $cheatingAllowed


function client_host(portNum,typeGame,limit,add,japRoulette,cheating,colorBoard)
global port=portNum
global gameType=typeGame
global timeLimit=limit
global timeAdd=add
global japaneseRoulette=japRoulette
global cheatingAllowed=cheating
global color=colorBoard

if cheatingAllowed=="T"
    global noCheating=0
else
    global noCheating=1
end


global currentMove=1
global gote_time=timeLimit
global sente_time=timeLimit

global requestGame=string("0:",uppercase(gameType[1]),":$noCheating:$timeLimit:$timeAdd")

global server=connect(port)
println(server, requestGame)

global settings=split(chomp(readline(server)),":")
println(settings)

global authString=settings[2]

if settings[1]=="0"
    global goFirst=true
else
    global goFirst=false
end

if settings[3]=="S"
    gameType="standard"
    global N=9
elseif settings[3]=="M"
    gameType="mini"
    global N=5
elseif  settings[3]=="C"
    gameType="chu"
    global N=12
else 
    gameType="tenjiku"
    global N=16
end

global empty=piece("", "", 0, 0, -1, false)

global board = [ [ empty for i = 1:N ] for j = 1:N ]
global allBoards=[]
global pieceArr=[]


global sente_promo_range
global gote_promo_range

if gameType == "tenjiku"
        sente_promo_range=1:5
        gote_promo_range=12:16
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
        sente_promo_range=1:4
        gote_promo_range=9:12
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
        sente_promo_range=1:3
        gote_promo_range=7:9
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
        sente_promo_range=1:1
        gote_promo_range=5:5
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



    push!(allBoards,duplicateBoard(board))
    global pieceArr=[]



    for y in 1:N
        for x in 1:N
            if board[y][x]!=empty
                push!(pieceArr,board[y][x])
            end
        end
    end

global grid = @Grid()
global window = @Window("Shogi by null_ptr")
#println(gameType)
global emptyPath=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
global moveNum=1
global double=["lion","falcon","soaring"]
global triple=["demon","vice","great","tetrarch"]
global sente=[]
global gote=[]
global idArr=[]
global id2Arr=[]
global prevsx=0
global prevsy=0
global prevtx=0
global prevty=0
global userMove=[]
global DF=0

for p in pieceArr
    if p.side==0
        push!(gote,p)
    else
        push!(sente,p)
    end
end


reset()
setBoardGUI()
if goFirst
    global userTurn=1
    init_buttons("sente")
else
    global userTurn=0
    global userMakingMove=readline(server)
    readMove()
end
push!(window,grid)
showall(window)

if !isinteractive()
    c = Condition()
    signal_connect(window, :destroy) do widget
        notify(c)
    end
    wait(c)
end
end


function readMove()
    global moveNum
    global currentMove
    global server
    move=chomp(readline(server))
    move=split(move,":")
    println(move)
    sx=parse(Int64,String(move[5]))
    sy=parse(Int64,String(move[6]))
    tx=parse(Int64,String(move[7]))
    ty=parse(Int64,String(move[8]))
    currentMove+=1
    println(move)
    push!(userMove,(sx,sy))
    push!(userMove,(tx,ty))
    moveCheck()
end

function sendMove(sx,sy,tx,ty)
    global server
    global authString
    global currentMove
    move="2:$authString:$currentMove:1:$sx:$sy:$tx:$ty:0:0:0:0:0:0"
    println(server,move)
    currentMove+=1
end


function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end


function checkWin(typeMove, istimed, sentetime, gotetime, boards)

    global window
    global grid
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end

function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end


function movePieceGUI(sx,sy,tx,ty)
    global board
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyPath)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyPath)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end



function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global board
    global userTurn
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            @async begin
            sendMove(sx,sy,tx,ty)
        end
            movePieceGUI(sx,sy,tx,ty)
            userMakingMove=readline(server)
            userMove=[]
        end
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove.option="!"
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove.option="!"
            end
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        push!(allBoards,duplicateBoard(board))
        if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            @async begin
            sendMove(sx,sy,tx,ty)
        end
            movePieceGUI(sx,sy,tx,ty)
            userMakingMove=readline(server)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            if moveNum%2==1
                if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                    thisMove.option="!"
                end
            else
                if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                    thisMove.option="!"
                end
            end
            @async begin
            sendMove(sx,sy,tx,ty)
        end
            movePieceGUI(sx,sy,tx,ty)
            userMakingMove=readline(server)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            push!(allBoards,duplicateBoard(board))
            if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    if moveNum%2==userTurn
        if userTurn==1
            init_buttons("sente")
        else
            init_buttons("gote")
        end
    else
        readMove()
    end
end



function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],UInt32(id2Arr[a][1]))
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            signal_handler_block(grid[idArr[b][2],idArr[b][3]],UInt32(idArr[b][1]))
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end



function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end


#$port $gameType $timeLimit $timeIncrement $japaneseRoulette $cheatingAllowed


function client_join(portNum,ipAddr,colorBoard)
global ip=ipAddr
global port=portNum
global gameType="standard"
global timeLimit=0
global timeAdd=0
global japaneseRoulette=false
global cheatingAllowed="F"
global color=colorBoard

if cheatingAllowed=="T"
    global noCheating=0
else
    global noCheating=1
end


global currentMove=1
global gote_time=timeLimit
global sente_time=timeLimit

global requestGame=string("0:",uppercase(gameType[1]),":$noCheating:$timeLimit:$timeAdd")

global server=connect(port)
println(server, requestGame)

global settings=split(chomp(readline(server)),":")
println(settings)

global authString=settings[2]

if settings[1]=="0"
    global goFirst=true
else
    global goFirst=false
end

if settings[3]=="S"
    gameType="standard"
    global N=9
elseif settings[3]=="M"
    gameType="mini"
    global N=5
elseif  settings[3]=="C"
    gameType="chu"
    global N=12
else 
    gameType="tenjiku"
    global N=16
end

global empty=piece("", "", 0, 0, -1, false)

global board = [ [ empty for i = 1:N ] for j = 1:N ]
global allBoards=[]
global pieceArr=[]


global sente_promo_range
global gote_promo_range

if gameType == "tenjiku"
        sente_promo_range=1:5
        gote_promo_range=12:16
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
        sente_promo_range=1:4
        gote_promo_range=9:12
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
        sente_promo_range=1:3
        gote_promo_range=7:9
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
        sente_promo_range=1:1
        gote_promo_range=5:5
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



    push!(allBoards,duplicateBoard(board))
    global pieceArr=[]



    for y in 1:N
        for x in 1:N
            if board[y][x]!=empty
                push!(pieceArr,board[y][x])
            end
        end
    end

global grid = @Grid()
global window = @Window("Shogi by null_ptr")
#println(gameType)
global emptyPath=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
global moveNum=1
global double=["lion","falcon","soaring"]
global triple=["demon","vice","great","tetrarch"]
global sente=[]
global gote=[]
global idArr=[]
global id2Arr=[]
global prevsx=0
global prevsy=0
global prevtx=0
global prevty=0
global userMove=[]
global DF=0

for p in pieceArr
    if p.side==0
        push!(gote,p)
    else
        push!(sente,p)
    end
end


reset()
setBoardGUI()
if goFirst
    global userTurn=1
    init_buttons("sente")
else
    global userTurn=0
    global userMakingMove=readline(server)
    readMove()
end
push!(window,grid)
showall(window)

if !isinteractive()
    c = Condition()
    signal_connect(window, :destroy) do widget
        notify(c)
    end
    wait(c)
end
end



function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end

function checkWin(typeMove, istimed, sentetime, gotetime, boards)
    global window
    global grid
    global frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end

function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end





function emailMsg()
    global window
    global frame
    destroy(frame)
    destroy(grid)
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Email game file at path: $fileName to your opponent.\n\n\t\t\t\tClick to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    push!(frame,button)
    push!(window,frame)
    showall(window)
end



function movePieceGUI(sx,sy,tx,ty)
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyImage)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyImage)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end



function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global board
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        board=demon_burning(board)
        push!(allBoards,duplicateBoard(board))
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
        makeMove(db,thisMove)
         if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            board=demon_burning(board)
            push!(allBoards,duplicateBoard(board))
            if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
            makeMove(db,thisMove)
             if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
    end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    clear_buttons()
end


function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],UInt32(id2Arr[a][1]))
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            signal_handler_block(grid[idArr[b][2],idArr[b][3]],UInt32(idArr[b][1]))
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end




function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end




function display_email(file,colorBoard)

global fileName=file
global color=colorBoard


global db=SQLite.DB(fileName)

global metaTable=SQLite.query(db,"select * from meta")
global movesTable=SQLite.query(db,"select * from moves")

global gameType=get(metaTable[2][1])

if gameType=="ten"
    gameType="tenjiku"
end

global isTimed=get(metaTable[2][3])
global timeAdd=parse(Int64,get(metaTable[2][4]))
if isTimed=="yes"
    global timeLimit=parse(Int64,get(metaTable[2][5]))
else 
    timeLimit=0
end

global sente_time=timeLimit
global gote_time=timeLimit
global allBoards=[]
if timeLimit > 0
    isTimed=true
else 
    isTimed=false
end


if gameType=="standard"
    gameTypeFile="S"
    global N=9
elseif gameType=="chu"
    gameTypeFile=="C"
    global N=12
elseif gameType=="mini"
    gameTypeFile="M"
    global N=5
else
    gameTypeFile="T"
    global N=16
end


global empty=piece("", "", 0, 0, -1, false)

global board = [ [ empty for i = 1:N ] for j = 1:N ]


global pieceArr=[]

global sente_promo_range
global gote_promo_range

if gameType == "tenjiku"
        sente_promo_range=1:5
        gote_promo_range=12:16

        # sente/black/odd pieces
        push!(pieceArr,piece("lance", "lance", 16, 1, 1, false))
        push!(pieceArr,piece("lance", "lance", 16, 16, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 2, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 15, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 16, 3, 1, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 16, 14, 1, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 16, 4, 1, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 16, 13, 1, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 16, 5, 1, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 16, 12, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 16, 6, 1, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 16, 11, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 16, 7, 1, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 16, 10, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 16, 8, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 16, 9, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 15, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 15, 16, 1, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 15, 3, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 4, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 13, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 14, 1, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 15, 6, 1, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 15, 11, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 15, 7, 1, false))
        push!(pieceArr,piece("queen", "queen", 15, 8, 1, false))
        push!(pieceArr,piece("lion", "lion", 15, 9, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 15, 10, 1, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 1, 1, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 16, 1, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 2, 1, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 15, 1, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 14, 3, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 14, 14, 1, false))
        push!(pieceArr,piece("horse", "horse", 14, 4, 1, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 14, 13, 1, false)) # dragon horse 
        push!(pieceArr,piece("dragon", "dragon", 14, 5, 1, false)) # dragon king 
        push!(pieceArr,piece("dragon", "dragon", 14, 12, 1, false)) # dragon king 
        push!(pieceArr,piece("buffalo", "buffalo", 14, 6, 1, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 14, 11, 1, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 14, 7, 1, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 14, 10, 1, false)) # fire demon
        push!(pieceArr,piece("eagle", "eagle", 14, 8, 1, false)) # free eagle
        push!(pieceArr,piece("hawk", "hawk", 14, 9, 1, false)) # lion hawk
        push!(pieceArr,piece("smover", "smover", 13, 1, 1, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 13, 16, 1, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 13, 2, 1, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 13, 15, 1, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 13, 3, 1, false))
        push!(pieceArr,piece("rook", "rook", 13, 14, 1, false))
        push!(pieceArr,piece("falcon", "falcon", 13, 4, 1, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 13, 13, 1, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 13, 5, 1, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 13, 12, 1, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 6, 1, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 11, 1, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 7, 1, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 10, 1, false)) # rook general
        push!(pieceArr,piece("vice", "vice", 13, 8, 1, false)) # vice general
        push!(pieceArr,piece("great", "great", 13, 9, 1, false)) # great general
        push!(pieceArr,piece("pawn", "pawn", 12, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 12, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 13, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 14, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 15, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 16, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 5, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 16, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 15, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 3, 0, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 1, 14, 0, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 1, 4, 0, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 1, 13, 0, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 1, 5, 0, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 1, 12, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 6, 0, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 1, 11, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 7, 0, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 1, 10, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 8, 0, false)) # king
        push!(pieceArr,piece("elephant", "elephant", 1, 9, 0, false)) # drunk elephant
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 2, 16, 0, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 2, 3, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 4, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 13, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 14, 0, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 2, 6, 0, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 2, 11, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 7, 0, false))
        push!(pieceArr,piece("lion", "lion", 2, 8, 0, false))
        push!(pieceArr,piece("queen", "queen", 2, 9, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 10, 0, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 1, 0, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 16, 0, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 2, 0, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 15, 0, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 3, 3, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 3, 14, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 3, 13, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("dragon", "dragon", 3, 12, 0, false)) # dragon king
        push!(pieceArr,piece("buffalo", "buffalo", 3, 6, 0, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 3, 11, 0, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 3, 7, 0, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 3, 10, 0, false)) # fire demon
        push!(pieceArr,piece("hawk", "hawk", 3, 8, 0, false)) # lion hawk
        push!(pieceArr,piece("eagle", "eagle", 3, 9, 0, false)) # free eagle
        push!(pieceArr,piece("smover", "smover", 4, 1, 0, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 4, 16, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 4, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 4, 15, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 4, 3, 0, false))
        push!(pieceArr,piece("rook", "rook", 4, 14, 0, false))
        push!(pieceArr,piece("falcon", "falcon", 4, 4, 0, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 4, 13, 0, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 4, 5, 0, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 4, 12, 0, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 6, 0, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 11, 0, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 7, 0, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 10, 0, false)) # rook general
        push!(pieceArr,piece("great", "great", 4, 8, 0, false)) # great general
        push!(pieceArr,piece("vice", "vice", 4, 9, 0, false)) # vice general
        push!(pieceArr,piece("pawn", "pawn", 5, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 12, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 13, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 14, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 15, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 16, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 5, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 12, 0, false))

    elseif gameType == "chu" # game setup for chu shogi
        sente_promo_range=1:4
        gote_promo_range=9:12

        # sente/black/odd pieces
        push!(pieceArr,piece("cobra", "cobra", 8, 4, 1, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 8, 9, 1, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 9, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 12, 1, false))
        push!(pieceArr,piece("smover", "smover", 10, 1, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 2, 1, false))
        push!(pieceArr,piece("rook", "rook", 10, 3, 1, false))
        push!(pieceArr,piece("horse", "horse", 10, 4, 1, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 10, 5, 1, false)) # dragon king
        push!(pieceArr,piece("queen", "queen", 10, 6, 1, false))
        push!(pieceArr,piece("lion", "lion", 10, 7, 1, false))
        push!(pieceArr,piece("dragon", "dragon", 10, 8, 1, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 10, 9, 1, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 10, 10, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 11, 1, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 10, 12, 1, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 11, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 11, 3, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 5, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 11, 6, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 11, 7, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 8, 1, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 11, 10, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 11, 12, 1, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 12, 1, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 12, 2, 1, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 12, 3, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 12, 4, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 12, 5, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 12, 6, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 12, 7, 1, false))
        push!(pieceArr,piece("gold", "gold", 12, 8, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 12, 9, 1, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 12, 10, 1, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 12, 11, 1, false)) # ferocious leopard
        push!(pieceArr,piece("lance", "lance", 12, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("cobra", "cobra", 5, 4, 0, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 5, 9, 0, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 4, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 12, 0, false))
        push!(pieceArr,piece("smover", "smover", 3, 1, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 3, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 3, 3, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("lion", "lion", 3, 6, 0, false))
        push!(pieceArr,piece("queen", "queen", 3, 7, 0, false))
        push!(pieceArr,piece("dragon", "dragon", 3, 8, 0, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 3, 9, 0, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 3, 10, 0, false))
        push!(pieceArr,piece("vmover", "vmover", 3, 11, 0, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 3, 12, 0, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 2, 3, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 5, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 6, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 7, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 8, 0, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 2, 10, 0, false))
        push!(pieceArr,piece("chariot", "chariot", 2, 12, 0, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 2, 0, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 1, 3, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 4, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 5, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 6, 0, false))
        push!(pieceArr,piece("elephant", "elephant", 1, 7, 0, false)) # drunk elephant
        push!(pieceArr,piece("gold", "gold", 1, 8, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 9, 0, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 1, 10, 0, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 1, 11, 0, false)) #ferocious leopard
        push!(pieceArr,piece("lance", "lance", 1, 12, 0, false))

    elseif gameType == "standard" # game setup for standard shogi
        sente_promo_range=1:3
        gote_promo_range=7:9
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 7, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 9, 1, false))
        push!(pieceArr,piece("rook", "rook", 8, 2, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 8, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 1, 1, false))
        push!(pieceArr,piece("knight", "knight", 9, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 9, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 9, 4, 1, false)) # gold general 
        push!(pieceArr,piece("king", "king", 9, 5, 1, false))
        push!(pieceArr,piece("gold", "gold", 9, 6, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 9, 7, 1, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 9, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 9, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 3, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 9, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 2, 2, 0, false))
        push!(pieceArr,piece("rook", "rook", 2, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 4, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 5, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 6, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 7, 0, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 1, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 9, 0, false))

    else # game setup for minishogi
        sente_promo_range=1:1
        gote_promo_range=5:5
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 1, false))
        push!(pieceArr,piece("rook", "rook", 5, 1, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 5, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 5, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 5, 4, 1, false)) # gold general
        push!(pieceArr,piece("king", "king", 5, 5, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 2, 1, 0, false))
        push!(pieceArr,piece("king", "king", 1, 1, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 2, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("bishop", "bishop", 1, 4, 0, false))
        push!(pieceArr,piece("rook", "rook", 1, 5, 0, false))

    end
global grid = @Grid()
global window = @Window("Shogi by null_ptr")
#println(gameType)
global emptyImage=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
global moveNum=1
global double=["lion","falcon","soaring"]
global triple=["demon","vice","great","tetrarch"]
global sente=[]
global gote=[]
global idArr=[]
global id2Arr=[]
global prevsx=0
global prevsy=0
global prevtx=0
global prevty=0
global userMove=[]
global DF=0
global frame=@Frame()


for i in 1:length(movesTable[1])
    number=get(movesTable[1][i])
    moveType=get(movesTable[2][i])
    sx=(movesTable[3][i])
    sy=(movesTable[4][i])
    tx=get(movesTable[5][i])
    ty=get(movesTable[6][i])
    option=movesTable[7][i]
    tx2=movesTable[9][i]
    ty2=movesTable[10][i]
    tx3=movesTable[11][i]
    ty3=movesTable[12][i]
    if moveType=="move"
        sx=get(sx)
        sy=get(sy)
        if !isnull(tx3) && !isnull(tx2)
            tx3=get(tx3)
            ty3=get(ty3)
            tx2=get(tx2)
            ty2=get(ty2)
        elseif !isnull(tx2) && isnull(tx3)
            tx3=0
            ty3=0
            tx2=get(tx2)
            ty2=get(ty2)
        else
            tx3=0
            ty3=0
            tx2=0
            ty2=0
        end
        p=getPiece(sx,sy)
        if tx2==0
            tx=tx
            ty=ty
        elseif tx2>0 && tx3==0
            tx=tx2
            ty=ty2
        elseif tx2>0 && tx3>0
            tx=tx3
            ty=tx3
        end
        if getPiece(tx,ty)!=nothing
            getPiece(tx,ty).x=-1
            getPiece(-1,ty).y=-1
        end
        if !isnull(option) && get(option)=="!" && p!=nothing
            a=promote(p,gameType)
            p.name=a.name
            p.promoted=a.promoted
        end
        p.x=tx
        p.y=ty
    elseif moveType=="drop"
         option=get(option)
        for p in pieceArr
            if p.name==option && p.x==-1 && p.side==(number&2)$1
                dropped=p
            end
        end
        getPiece(tx,ty).x=-1
        getPiece(tx,ty).y=-1
        if number%2==0
            dropped.side=0
        else
            dropped.side=1
        end
        dropped.x=tx
        dropped.y=ty
    end
    moveNum=number+1
end


for p in pieceArr
    if p.x!=-1
        board[p.y][p.x]=p
    end
end

push!(allBoards,duplicateBoard(board))


for p in pieceArr
    if p.side==0
        push!(gote,p)
    else
        push!(sente,p)
    end
end

reset()
setBoardGUI()
if moveNum%2==1
    init_buttons("sente")
else
    init_buttons("gote")
end 

push!(window,grid)
showall(window)
sleep(20)
emailMsg()




if !isinteractive()
    c = Condition()
    signal_connect(window, :destroy) do widget
        notify(c)
    end
    wait(c)
end

end


function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end

function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end


function checkWin(typeMove, istimed, sentetime, gotetime, boards)
    global window
    global grid
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end





function movePieceGUI(sx,sy,tx,ty)
    global window
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyImage)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyImage)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end

function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global sente_time
    global gote_time
    global diff
    global user
    global board
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        board=demon_burning(board)
        push!(allBoards,duplicateBoard(board))
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
        makeMove(db,thisMove)
        if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            board=demon_burning(board)
            push!(allBoards,duplicateBoard(board))
            if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
            makeMove(db,thisMove)
            if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    if diff=="normal"
        tic()
        board1, timeTaken ,aiMove= AI_normal(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="hard"
        tic()
        board1, timeTaken ,aiMove= AI_hard(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="protracted"
        tic()
        board1, timeTaken ,aiMove= AI_protracted(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="suicidal"
        tic()
        board1, timeTaken ,aiMove= AI_suicidal(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    else 
        tic()
        board1, timeTaken ,aiMove= AI_random(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    end
    if moveNum%2==1
        if !(aiMove.sourcex in sente_promo_range) && ((aiMove.targetx in sente_promo_range) || (aiMove.targetx2 in sente_promo_range) || (aiMove.targetx3 in sente_promo_range))
            aiMove.option="!"
        end
    else
        if !(aiMove.sourcex in gote_promo_range) && ((aiMove.targetx in gote_promo_range) || (aiMove.targetx2 in gote_promo_range) || (aiMove.targetx3 in gote_promo_range))
            aiMove.option="!"
        end
    end
    makeMove(db,aiMove)
    if aiMove.move_type=="move"
        board[aiMove.targety][aiMove.targetx]=board[aiMove.sourcey][aiMove.sourcex]
        board[aiMove.targety][aiMove.targetx]=checkPromote(board[aiMove.targety][aiMove.targetx],moveNum,aiMove.targetx)
        board[aiMove.sourcey][aiMove.sourcex]=empty
        board=demon_burning(board)
        push!(allBoards,duplicateBoard(board))
        movePieceGUI(aiMove.sourcex,aiMove.sourcey,aiMove.targetx,aiMove.targety)
    end
    if checkWin(aiMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
    moveNum+=1
    init_buttons(user)
end

function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],UInt32(id2Arr[a][1]))
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            signal_handler_block(grid[idArr[b][2],idArr[b][3]],UInt32(idArr[b][1]))
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        #println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        #println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end



function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end


function display_load_ai(file,difficulty,colorBoard)

    global fileName=file

    global diff=difficulty

    global color=colorBoard

    global db=SQLite.DB(fileName)

    global metaTable=SQLite.query(db,"select * from meta")
    global movesTable=SQLite.query(db,"select * from moves")

    global gameType=get(metaTable[2][1])

    if gameType=="ten"
        gameType="tenjiku"
    end

    global isTimed=get(metaTable[2][3])
    global timeAdd=parse(Int64,get(metaTable[2][4]))
    if isTimed=="yes"
       global timeLimit=parse(Int64,get(metaTable[2][5]))
    else 
        timeLimit=0
    end

global sente_time=timeLimit
global gote_time=timeLimit
global allBoards=[]
if timeLimit > 0
    isTimed=true
else 
    isTimed=false
end



if diff=="normal"
    include("move_normal.jl")
elseif diff=="hard"
    include("move_hard.jl")
elseif diff=="protracted"
    include("move_protracted")
elseif diff=="suicidal"
    include("move_suicidal.jl")
else 
    include("move_random.jl")
end

if gameType=="standard"
    global N=9
elseif gameType=="chu"
    global N=12
elseif gameType=="mini"
    global N=5
else
    global N=16
end



global empty=piece("", "", 0, 0, -1, false)

global board = [ [ empty for i = 1:N ] for j = 1:N ]


global pieceArr=[]
global sente_promo_range
global gote_promo_range

if gameType == "tenjiku"
    sente_promo_range=1:5
    gote_promo_range=12:16

    # sente/black/odd pieces
    push!(pieceArr,piece("lance", "lance", 16, 1, 1, false))
    push!(pieceArr,piece("lance", "lance", 16, 16, 1, false))
    push!(pieceArr,piece("knight", "knight", 16, 2, 1, false))
    push!(pieceArr,piece("knight", "knight", 16, 15, 1, false))
    push!(pieceArr,piece("leopard", "leopard", 16, 3, 1, false)) # ferocious leopard
    push!(pieceArr,piece("leopard", "leopard", 16, 14, 1, false)) # ferocious leopard
    push!(pieceArr,piece("iron", "iron", 16, 4, 1, false)) # iron general
    push!(pieceArr,piece("iron", "iron", 16, 13, 1, false)) # iron general
    push!(pieceArr,piece("copper", "copper", 16, 5, 1, false)) # copper general
    push!(pieceArr,piece("copper", "copper", 16, 12, 1, false)) # copper general
    push!(pieceArr,piece("silver", "silver", 16, 6, 1, false)) # silver general
    push!(pieceArr,piece("silver", "silver", 16, 11, 1, false)) # silver general
    push!(pieceArr,piece("gold", "gold", 16, 7, 1, false)) # gold general
    push!(pieceArr,piece("gold", "gold", 16, 10, 1, false)) # gold general
    push!(pieceArr,piece("elephant", "elephant", 16, 8, 1, false)) # drunk elephant
    push!(pieceArr,piece("king", "king", 16, 9, 1, false))
    push!(pieceArr,piece("chariot", "chariot", 15, 1, 1, false)) # reverse chariot
    push!(pieceArr,piece("chariot", "chariot", 15, 16, 1, false)) # reverse chariot
    push!(pieceArr,piece("csoldier", "csoldier", 15, 3, 1, false)) # chariot soldier
    push!(pieceArr,piece("csoldier", "csoldier", 15, 4, 1, false)) # chariot soldier
    push!(pieceArr,piece("csoldier", "csoldier", 15, 13, 1, false)) # chariot soldier
    push!(pieceArr,piece("csoldier", "csoldier", 15, 14, 1, false)) # chariot soldier
    push!(pieceArr,piece("tiger", "tiger", 15, 6, 1, false)) # blind tiger
    push!(pieceArr,piece("tiger", "tiger", 15, 11, 1, false)) # blind tiger
    push!(pieceArr,piece("phoenix", "phoenix", 15, 7, 1, false))
    push!(pieceArr,piece("queen", "queen", 15, 8, 1, false))
    push!(pieceArr,piece("lion", "lion", 15, 9, 1, false))
    push!(pieceArr,piece("kirin", "kirin", 15, 10, 1, false))
    push!(pieceArr,piece("ssoldier", "ssoldier", 14, 1, 1, false)) # side soldier
    push!(pieceArr,piece("ssoldier", "ssoldier", 14, 16, 1, false)) # side soldier
    push!(pieceArr,piece("vsoldier", "vsoldier", 14, 2, 1, false)) # vertical soldier
    push!(pieceArr,piece("vsoldier", "vsoldier", 14, 15, 1, false)) # vertical soldier
    push!(pieceArr,piece("bishop", "bishop", 14, 3, 1, false))
    push!(pieceArr,piece("bishop", "bishop", 14, 14, 1, false))
    push!(pieceArr,piece("horse", "horse", 14, 4, 1, false)) # dragon horse 
    push!(pieceArr,piece("horse", "horse", 14, 13, 1, false)) # dragon horse 
    push!(pieceArr,piece("dragon", "dragon", 14, 5, 1, false)) # dragon king 
    push!(pieceArr,piece("dragon", "dragon", 14, 12, 1, false)) # dragon king 
    push!(pieceArr,piece("buffalo", "buffalo", 14, 6, 1, false)) # water buffalo
    push!(pieceArr,piece("buffalo", "buffalo", 14, 11, 1, false)) # water buffalo
    push!(pieceArr,piece("demon", "demon", 14, 7, 1, false)) # fire demon
    push!(pieceArr,piece("demon", "demon", 14, 10, 1, false)) # fire demon
    push!(pieceArr,piece("eagle", "eagle", 14, 8, 1, false)) # free eagle
    push!(pieceArr,piece("hawk", "hawk", 14, 9, 1, false)) # lion hawk
    push!(pieceArr,piece("smover", "smover", 13, 1, 1, false)) # side mover
    push!(pieceArr,piece("smover", "smover", 13, 16, 1, false)) # side mover
    push!(pieceArr,piece("vmover", "vmover", 13, 2, 1, false)) # vertical mover
    push!(pieceArr,piece("vmover", "vmover", 13, 15, 1, false)) # vertical mover
    push!(pieceArr,piece("rook", "rook", 13, 3, 1, false))
    push!(pieceArr,piece("rook", "rook", 13, 14, 1, false))
    push!(pieceArr,piece("falcon", "falcon", 13, 4, 1, false)) # horned falcon
    push!(pieceArr,piece("falcon", "falcon", 13, 13, 1, false)) # horned falcon
    push!(pieceArr,piece("soaring", "soaring", 13, 5, 1, false)) # soaring eagle
    push!(pieceArr,piece("soaring", "soaring", 13, 12, 1, false)) # soaring eagle
    push!(pieceArr,piece("bgeneral", "bgeneral", 13, 6, 1, false)) # bishop general
    push!(pieceArr,piece("bgeneral", "bgeneral", 13, 11, 1, false)) # bishop general
    push!(pieceArr,piece("rgeneral", "rgeneral", 13, 7, 1, false)) # rook general
    push!(pieceArr,piece("rgeneral", "rgeneral", 13, 10, 1, false)) # rook general
    push!(pieceArr,piece("vice", "vice", 13, 8, 1, false)) # vice general
    push!(pieceArr,piece("great", "great", 13, 9, 1, false)) # great general
    push!(pieceArr,piece("pawn", "pawn", 12, 1, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 2, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 3, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 4, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 5, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 6, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 7, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 8, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 9, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 10, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 11, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 12, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 13, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 14, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 15, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 12, 16, 1, false))
    push!(pieceArr,piece("dog", "dog", 11, 5, 1, false))
    push!(pieceArr,piece("dog", "dog", 11, 12, 1, false))

    # gote/white/even pieces
    push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
    push!(pieceArr,piece("lance", "lance", 1, 16, 0, false))
    push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
    push!(pieceArr,piece("knight", "knight", 1, 15, 0, false))
    push!(pieceArr,piece("leopard", "leopard", 1, 3, 0, false)) # ferocious leopard
    push!(pieceArr,piece("leopard", "leopard", 1, 14, 0, false)) # ferocious leopard
    push!(pieceArr,piece("iron", "iron", 1, 4, 0, false)) # iron general
    push!(pieceArr,piece("iron", "iron", 1, 13, 0, false)) # iron general
    push!(pieceArr,piece("copper", "copper", 1, 5, 0, false)) # copper general
    push!(pieceArr,piece("copper", "copper", 1, 12, 0, false)) # copper general
    push!(pieceArr,piece("silver", "silver", 1, 6, 0, false)) # silver general
    push!(pieceArr,piece("silver", "silver", 1, 11, 0, false)) # silver general
    push!(pieceArr,piece("gold", "gold", 1, 7, 0, false)) # gold general
    push!(pieceArr,piece("gold", "gold", 1, 10, 0, false)) # gold general
    push!(pieceArr,piece("king", "king", 1, 8, 0, false)) # king
    push!(pieceArr,piece("elephant", "elephant", 1, 9, 0, false)) # drunk elephant
    push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
    push!(pieceArr,piece("chariot", "chariot", 2, 16, 0, false)) # reverse chariot
    push!(pieceArr,piece("csoldier", "csoldier", 2, 3, 0, false)) # chariot soldier
    push!(pieceArr,piece("csoldier", "csoldier", 2, 4, 0, false)) # chariot soldier
    push!(pieceArr,piece("csoldier", "csoldier", 2, 13, 0, false)) # chariot soldier
    push!(pieceArr,piece("csoldier", "csoldier", 2, 14, 0, false)) # chariot soldier
    push!(pieceArr,piece("tiger", "tiger", 2, 6, 0, false)) # blind tiger
    push!(pieceArr,piece("tiger", "tiger", 2, 11, 0, false)) # blind tiger
    push!(pieceArr,piece("kirin", "kirin", 2, 7, 0, false))
    push!(pieceArr,piece("lion", "lion", 2, 8, 0, false))
    push!(pieceArr,piece("queen", "queen", 2, 9, 0, false))
    push!(pieceArr,piece("phoenix", "phoenix", 2, 10, 0, false))
    push!(pieceArr,piece("ssoldier", "ssoldier", 3, 1, 0, false)) # side soldier
    push!(pieceArr,piece("ssoldier", "ssoldier", 3, 16, 0, false)) # side soldier
    push!(pieceArr,piece("vsoldier", "vsoldier", 3, 2, 0, false)) # vertical soldier
    push!(pieceArr,piece("vsoldier", "vsoldier", 3, 15, 0, false)) # vertical soldier
    push!(pieceArr,piece("bishop", "bishop", 3, 3, 0, false))
    push!(pieceArr,piece("bishop", "bishop", 3, 14, 0, false))
    push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse 
    push!(pieceArr,piece("horse", "horse", 3, 13, 0, false)) # dragon horse
    push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
    push!(pieceArr,piece("dragon", "dragon", 3, 12, 0, false)) # dragon king
    push!(pieceArr,piece("buffalo", "buffalo", 3, 6, 0, false)) # water buffalo
    push!(pieceArr,piece("buffalo", "buffalo", 3, 11, 0, false)) # water buffalo
    push!(pieceArr,piece("demon", "demon", 3, 7, 0, false)) # fire demon
    push!(pieceArr,piece("demon", "demon", 3, 10, 0, false)) # fire demon
    push!(pieceArr,piece("hawk", "hawk", 3, 8, 0, false)) # lion hawk
    push!(pieceArr,piece("eagle", "eagle", 3, 9, 0, false)) # free eagle
    push!(pieceArr,piece("smover", "smover", 4, 1, 0, false)) # side mover
    push!(pieceArr,piece("smover", "smover", 4, 16, 0, false)) # side mover
    push!(pieceArr,piece("vmover", "vmover", 4, 2, 0, false)) # vertical mover
    push!(pieceArr,piece("vmover", "vmover", 4, 15, 0, false)) # vertical mover
    push!(pieceArr,piece("rook", "rook", 4, 3, 0, false))
    push!(pieceArr,piece("rook", "rook", 4, 14, 0, false))
    push!(pieceArr,piece("falcon", "falcon", 4, 4, 0, false)) # horned falcon
    push!(pieceArr,piece("falcon", "falcon", 4, 13, 0, false)) # horned falcon
    push!(pieceArr,piece("soaring", "soaring", 4, 5, 0, false)) # soaring eagle
    push!(pieceArr,piece("soaring", "soaring", 4, 12, 0, false)) # soaring eagle
    push!(pieceArr,piece("bgeneral", "bgeneral", 4, 6, 0, false)) # bishop general
    push!(pieceArr,piece("bgeneral", "bgeneral", 4, 11, 0, false)) # bishop general
    push!(pieceArr,piece("rgeneral", "rgeneral", 4, 7, 0, false)) # rook general
    push!(pieceArr,piece("rgeneral", "rgeneral", 4, 10, 0, false)) # rook general
    push!(pieceArr,piece("great", "great", 4, 8, 0, false)) # great general
    push!(pieceArr,piece("vice", "vice", 4, 9, 0, false)) # vice general
    push!(pieceArr,piece("pawn", "pawn", 5, 1, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 2, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 3, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 4, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 5, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 6, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 7, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 8, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 9, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 10, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 11, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 12, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 13, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 14, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 15, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 5, 16, 0, false))
    push!(pieceArr,piece("dog", "dog", 6, 5, 0, false))
    push!(pieceArr,piece("dog", "dog", 6, 12, 0, false))

elseif gameType == "chu" # game setup for chu shogi
    sente_promo_range=1:4
    gote_promo_range=9:12

    # sente/black/odd pieces
    push!(pieceArr,piece("cobra", "cobra", 8, 4, 1, false)) # AKA go-between
    push!(pieceArr,piece("cobra", "cobra", 8, 9, 1, false)) # AKA go-between
    push!(pieceArr,piece("pawn", "pawn", 9, 1, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 2, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 3, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 4, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 5, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 6, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 7, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 8, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 9, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 10, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 11, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 9, 12, 1, false))
    push!(pieceArr,piece("smover", "smover", 10, 1, 1, false))
    push!(pieceArr,piece("vmover", "vmover", 10, 2, 1, false))
    push!(pieceArr,piece("rook", "rook", 10, 3, 1, false))
    push!(pieceArr,piece("horse", "horse", 10, 4, 1, false)) # dragon horse
    push!(pieceArr,piece("dragon", "dragon", 10, 5, 1, false)) # dragon king
    push!(pieceArr,piece("queen", "queen", 10, 6, 1, false))
    push!(pieceArr,piece("lion", "lion", 10, 7, 1, false))
    push!(pieceArr,piece("dragon", "dragon", 10, 8, 1, false)) # dragon king
    push!(pieceArr,piece("horse", "horse", 10, 9, 1, false)) # dragon horse
    push!(pieceArr,piece("rook", "rook", 10, 10, 1, false))
    push!(pieceArr,piece("vmover", "vmover", 10, 11, 1, false)) # vertical mover
    push!(pieceArr,piece("smover", "smover", 10, 12, 1, false)) # side mover
    push!(pieceArr,piece("chariot", "chariot", 11, 1, 1, false)) # reverse chariot
    push!(pieceArr,piece("bishop", "bishop", 11, 3, 1, false))
    push!(pieceArr,piece("tiger", "tiger", 11, 5, 1, false)) # blind tiger
    push!(pieceArr,piece("phoenix", "phoenix", 11, 6, 1, false))
    push!(pieceArr,piece("kirin", "kirin", 11, 7, 1, false))
    push!(pieceArr,piece("tiger", "tiger", 11, 8, 1, false)) # blind tiger
    push!(pieceArr,piece("bishop", "bishop", 11, 10, 1, false))
    push!(pieceArr,piece("chariot", "chariot", 11, 12, 1, false)) # reverse chariot
    push!(pieceArr,piece("lance", "lance", 12, 1, 1, false))
    push!(pieceArr,piece("leopard", "leopard", 12, 2, 1, false)) # ferocious leopard
    push!(pieceArr,piece("copper", "copper", 12, 3, 1, false)) # copper general
    push!(pieceArr,piece("silver", "silver", 12, 4, 1, false)) # silver general
    push!(pieceArr,piece("gold", "gold", 12, 5, 1, false)) # gold general
    push!(pieceArr,piece("elephant", "elephant", 12, 6, 1, false)) # drunk elephant
    push!(pieceArr,piece("king", "king", 12, 7, 1, false))
    push!(pieceArr,piece("gold", "gold", 12, 8, 1, false)) # gold general
    push!(pieceArr,piece("silver", "silver", 12, 9, 1, false)) # silver general
    push!(pieceArr,piece("copper", "copper", 12, 10, 1, false)) # copper general
    push!(pieceArr,piece("leopard", "leopard", 12, 11, 1, false)) # ferocious leopard
    push!(pieceArr,piece("lance", "lance", 12, 12, 1, false))

    # gote/white/even pieces
    push!(pieceArr,piece("cobra", "cobra", 5, 4, 0, false)) # AKA go-between
    push!(pieceArr,piece("cobra", "cobra", 5, 9, 0, false)) # AKA go-between
    push!(pieceArr,piece("pawn", "pawn", 4, 1, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 2, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 3, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 4, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 5, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 6, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 7, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 8, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 9, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 10, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 11, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 4, 12, 0, false))
    push!(pieceArr,piece("smover", "smover", 3, 1, 0, false)) # side mover
    push!(pieceArr,piece("vmover", "vmover", 3, 2, 0, false)) # vertical mover
    push!(pieceArr,piece("rook", "rook", 3, 3, 0, false))
    push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse
    push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
    push!(pieceArr,piece("lion", "lion", 3, 6, 0, false))
    push!(pieceArr,piece("queen", "queen", 3, 7, 0, false))
    push!(pieceArr,piece("dragon", "dragon", 3, 8, 0, false)) # dragon king
    push!(pieceArr,piece("horse", "horse", 3, 9, 0, false)) # dragon horse
    push!(pieceArr,piece("rook", "rook", 3, 10, 0, false))
    push!(pieceArr,piece("vmover", "vmover", 3, 11, 0, false)) # vertical mover
    push!(pieceArr,piece("smover", "smover", 3, 12, 0, false)) # side mover
    push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
    push!(pieceArr,piece("bishop", "bishop", 2, 3, 0, false))
    push!(pieceArr,piece("tiger", "tiger", 2, 5, 0, false)) # blind tiger
    push!(pieceArr,piece("kirin", "kirin", 2, 6, 0, false))
    push!(pieceArr,piece("phoenix", "phoenix", 2, 7, 0, false))
    push!(pieceArr,piece("tiger", "tiger", 2, 8, 0, false)) # blind tiger
    push!(pieceArr,piece("bishop", "bishop", 2, 10, 0, false))
    push!(pieceArr,piece("chariot", "chariot", 2, 12, 0, false)) # reverse chariot
    push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
    push!(pieceArr,piece("leopard", "leopard", 1, 2, 0, false)) # ferocious leopard
    push!(pieceArr,piece("copper", "copper", 1, 3, 0, false)) # copper general
    push!(pieceArr,piece("silver", "silver", 1, 4, 0, false)) # silver general
    push!(pieceArr,piece("gold", "gold", 1, 5, 0, false)) # gold general
    push!(pieceArr,piece("king", "king", 1, 6, 0, false))
    push!(pieceArr,piece("elephant", "elephant", 1, 7, 0, false)) # drunk elephant
    push!(pieceArr,piece("gold", "gold", 1, 8, 0, false)) # gold general
    push!(pieceArr,piece("silver", "silver", 1, 9, 0, false)) # silver general
    push!(pieceArr,piece("copper", "copper", 1, 10, 0, false)) # copper general
    push!(pieceArr,piece("leopard", "leopard", 1, 11, 0, false)) #ferocious leopard
    push!(pieceArr,piece("lance", "lance", 1, 12, 0, false))

elseif gameType == "standard" # game setup for standard shogi
    sente_promo_range=1:3
    gote_promo_range=7:9
    # sente/black/odd player
    push!(pieceArr,piece("pawn", "pawn", 7, 1, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 2, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 3, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 4, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 5, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 6, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 7, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 8, 1, false))
    push!(pieceArr,piece("pawn", "pawn", 7, 9, 1, false))
    push!(pieceArr,piece("rook", "rook", 8, 2, 1, false))
    push!(pieceArr,piece("bishop", "bishop", 8, 8, 1, false))
    push!(pieceArr,piece("lance", "lance", 9, 1, 1, false))
    push!(pieceArr,piece("knight", "knight", 9, 2, 1, false))
    push!(pieceArr,piece("silver", "silver", 9, 3, 1, false)) # silver general
    push!(pieceArr,piece("gold", "gold", 9, 4, 1, false)) # gold general 
    push!(pieceArr,piece("king", "king", 9, 5, 1, false))
    push!(pieceArr,piece("gold", "gold", 9, 6, 1, false)) # gold general
    push!(pieceArr,piece("silver", "silver", 9, 7, 1, false)) # silver general
    push!(pieceArr,piece("knight", "knight", 9, 8, 1, false))
    push!(pieceArr,piece("lance", "lance", 9, 9, 1, false))

    # gote/white/even player
    push!(pieceArr,piece("pawn", "pawn", 3, 1, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 2, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 3, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 4, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 5, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 6, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 7, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 8, 0, false))
    push!(pieceArr,piece("pawn", "pawn", 3, 9, 0, false))
    push!(pieceArr,piece("bishop", "bishop", 2, 2, 0, false))
    push!(pieceArr,piece("rook", "rook", 2, 8, 0, false))
    push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
    push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
    push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
    push!(pieceArr,piece("gold", "gold", 1, 4, 0, false)) # gold general
    push!(pieceArr,piece("king", "king", 1, 5, 0, false))
    push!(pieceArr,piece("gold", "gold", 1, 6, 0, false)) # gold general
    push!(pieceArr,piece("silver", "silver", 1, 7, 0, false)) # silver general
    push!(pieceArr,piece("knight", "knight", 1, 8, 0, false))
    push!(pieceArr,piece("lance", "lance", 1, 9, 0, false))

else # game setup for minishogi
    sente_promo_range=1:1
    gote_promo_range=5:5
    # sente/black/odd player
    push!(pieceArr,piece("pawn", "pawn", 4, 5, 1, false))
    push!(pieceArr,piece("rook", "rook", 5, 1, 1, false))
    push!(pieceArr,piece("bishop", "bishop", 5, 2, 1, false))
    push!(pieceArr,piece("silver", "silver", 5, 3, 1, false)) # silver general
    push!(pieceArr,piece("gold", "gold", 5, 4, 1, false)) # gold general
    push!(pieceArr,piece("king", "king", 5, 5, 1, false))

    # gote/white/even player
    push!(pieceArr,piece("pawn", "pawn", 2, 1, 0, false))
    push!(pieceArr,piece("king", "king", 1, 1, 0, false))
    push!(pieceArr,piece("gold", "gold", 1, 2, 0, false)) # gold general
    push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
    push!(pieceArr,piece("bishop", "bishop", 1, 4, 0, false))
    push!(pieceArr,piece("rook", "rook", 1, 5, 0, false))

end

global grid = @Grid()
global window = @Window("Shogi by null_ptr")
global emptyImage=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
global moveNum=1
global double=["lion","falcon","soaring"]
global triple=["demon","vice","great","tetrarch"]
global sente=[]
global gote=[]
global idArr=[]
global id2Arr=[]
global prevsx=0
global prevsy=0
global prevtx=0
global prevty=0
global userMove=[]
global DF=0

for p in pieceArr
    if p.side==0
        push!(gote,p)
    else
        push!(sente,p)
    end
end

for i in 1:length(movesTable[1])
    number=get(movesTable[1][i])
    moveType=get(movesTable[2][i])
    sx=(movesTable[3][i])
    sy=(movesTable[4][i])
    tx=get(movesTable[5][i])
    ty=get(movesTable[6][i])
    option=movesTable[7][i]
    tx2=movesTable[9][i]
    ty2=movesTable[10][i]
    tx3=movesTable[11][i]
    ty3=movesTable[12][i]
    if moveType=="move"
        sx=get(sx)
        sy=get(sy)
        if !isnull(tx3) && !isnull(tx2)
            tx3=get(tx3)
            ty3=get(ty3)
            tx2=get(tx2)
            ty2=get(ty2)
        elseif !isnull(tx2) && isnull(tx3)
            tx3=0
            ty3=0
            tx2=get(tx2)
            ty2=get(ty2)
        else
            tx3=0
            ty3=0
            tx2=0
            ty2=0
        end
        p=getPiece(sx,sy)
        if tx2==0
            tx=tx
            ty=ty
        elseif tx2>0 && tx3==0
            tx=tx2
            ty=ty2
        elseif tx2>0 && tx3>0
            tx=tx3
            ty=tx3
        end
        if getPiece(tx,ty)!=nothing
            getPiece(tx,ty).x=-1
            getPiece(-1,ty).y=-1
        end
        if !isnull(option) && get(option)=="!" && p!=nothing
            a=promote(p,gameType)
            p.name=a.name
            p.promoted=a.promoted
        end
        p.x=tx
        p.y=ty
    elseif moveType=="drop"
       option=get(option)
       for p in pieceArr
        if p.name==option && p.x==-1 && p.side==(number&2)$1
            dropped=p
        end
    end
    getPiece(tx,ty).x=-1
    getPiece(tx,ty).y=-1
    if number%2==0
        dropped.side=0
    else
        dropped.side=1
    end
    dropped.x=tx
    dropped.y=ty
end
moveNum=number+1
end


for p in pieceArr
    if p.x!=-1
        board[p.y][p.x]=p
    end
end


global user="sente"


reset()
setBoardGUI()
if moveNum%2==0
    user="gote"
    init_buttons(user)
else
    user="sente"
    init_buttons(user)
end

push!(window,grid)
showall(window)




if !isinteractive()
    c = Condition()
    signal_connect(window, :destroy) do widget
    notify(c)
end
wait(c)
end

end


function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end


function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end


function checkWin(typeMove, istimed, sentetime, gotetime, boards)
    global window
    global grid
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end

function movePieceGUI(sx,sy,tx,ty)
    global board
    global window
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyImage)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyImage)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end



function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global sente_time
    global gote_time
    #global board
    global diff
    global user
    global board
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        board=demon_burning(board)
        push!(allBoards,duplicateBoard(board))
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
        makeMove(db,thisMove)
         if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            board=demon_burning(board)
            push!(allBoards,duplicateBoard(board))
            if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove=move(moveNum,"move",sx,sy,tx,ty,"!",false,tx2,ty2,tx3,ty3)
            end
        end
            makeMove(db,thisMove)
             if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    if diff=="normal"
        tic()
        board1, timeTaken ,aiMove= AI_normal(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="hard"
        tic()
        board1, timeTaken ,aiMove= AI_hard(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="protracted"
        tic()
        board1, timeTaken ,aiMove= AI_protracted(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    elseif diff=="suicidal"
        tic()
        board1, timeTaken ,aiMove= AI_suicidal(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    else 
        tic()
        board1, timeTaken ,aiMove= AI_random(board,moveNum)
        if moveNum%2==1
            sente_time-=timeTaken
            sente_time+=timeAdd
            #println(sente_time)
        else
            gote_time-=timeTaken
            gote_time+=timeAdd
            #println(gote_time)
        end
    end

    if moveNum%2==1
        if !(aiMove.sourcex in sente_promo_range) && ((aiMove.targetx in sente_promo_range) || (aiMove.targetx2 in sente_promo_range) || (aiMove.targetx3 in sente_promo_range))
            aiMove.option="!"
        end
    else
        if !(aiMove.sourcex in gote_promo_range) && ((aiMove.targetx in gote_promo_range) || (aiMove.targetx2 in gote_promo_range) || (aiMove.targetx3 in gote_promo_range))
            aiMove.option="!"
        end
    end
    makeMove(db,aiMove)
    if aiMove.move_type=="move"
        board[aiMove.targety][aiMove.targetx]=board[aiMove.sourcey][aiMove.sourcex]
        board[aiMove.targety][aiMove.targetx]=checkPromote(board[aiMove.targety][aiMove.targetx],moveNum,aiMove.targetx)
        board[aiMove.sourcey][aiMove.sourcex]=empty
        board=demon_burning(board)
        movePieceGUI(aiMove.sourcex,aiMove.sourcey,aiMove.targetx,aiMove.targety)
    end
     if checkWin(aiMove.move_type,isTimed,sente_time,gote_time,allBoards)
            #println("checking time")
            return
    end
    moveNum+=1
    init_buttons(user)
end


function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],UInt32(id2Arr[a][1]))
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            signal_handler_block(grid[idArr[b][2],idArr[b][3]],UInt32(idArr[b][1]))
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        #println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        #println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end

function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end






function display_ai(ofType,limit,add,japRoulette,ifFirst,cheatingAllowed,difficulty,colorBoard)

    global gameType=ofType
    global timeLimit=limit
    global timeAdd=add
    global jRoulette=japRoulette
    global goFirst=ifFirst
    global cheating=cheatingAllowed
    global diff=difficulty
    global color=colorBoard
    global sente_time=timeLimit
    global gote_time=timeLimit
    global allBoards=[]
    if timeLimit > 0
        global isTimed=true
    else 
        global isTimed=false
    end


    global grid = @Grid()
    global window = @Window("Shogi by null_ptr")
    global emptyImage=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
    global moveNum=1
    global double=["lion","falcon","soaring"]
    global triple=["demon","vice","great","tetrarch"]
    global sente=[]
    global gote=[]
    global idArr=[]
    global id2Arr=[]
    global prevsx=0
    global prevsy=0
    global prevtx=0
    global prevty=0
    global userMove=[]
    global DF=0

    global fileName="gameplay.db"
    filePath=joinpath(pwd(),fileName)
    touch(filePath)
    rm(filePath,recursive=false,force=true)


    if diff=="normal"
        include("move_normal.jl")
    elseif diff=="hard"
        include("move_hard.jl")
    elseif diff=="protracted"
        include("move_protracted")
    elseif diff=="suicidal"
        include("move_suicidal.jl")
    else 
        include("move_random.jl")
    end

    if gameType=="standard"
        gameTypeFile="S"
        global N=9
    elseif gameType=="chu"
        gameTypeFile="C"
        global N=12
    elseif gameType=="mini"
        gameTypeFile="M"
        global N=5
    else
        gameTypeFile="T"
        global N=16
    end


    global empty=piece("", "", 0, 0, -1, false)

    global board = [ [ empty for i = 1:N ] for j = 1:N ]


    global pieceArr=[]

    global db=gameFileSetup(fileName,gameTypeFile,cheating,timeLimit,timeAdd)

    global sente_promo_range
    global gote_promo_range

    if gameType == "tenjiku"
        sente_promo_range=1:5
        gote_promo_range=12:16

        # sente/black/odd pieces
        push!(pieceArr,piece("lance", "lance", 16, 1, 1, false))
        push!(pieceArr,piece("lance", "lance", 16, 16, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 2, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 15, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 16, 3, 1, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 16, 14, 1, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 16, 4, 1, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 16, 13, 1, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 16, 5, 1, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 16, 12, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 16, 6, 1, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 16, 11, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 16, 7, 1, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 16, 10, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 16, 8, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 16, 9, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 15, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 15, 16, 1, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 15, 3, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 4, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 13, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 14, 1, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 15, 6, 1, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 15, 11, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 15, 7, 1, false))
        push!(pieceArr,piece("queen", "queen", 15, 8, 1, false))
        push!(pieceArr,piece("lion", "lion", 15, 9, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 15, 10, 1, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 1, 1, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 16, 1, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 2, 1, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 15, 1, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 14, 3, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 14, 14, 1, false))
        push!(pieceArr,piece("horse", "horse", 14, 4, 1, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 14, 13, 1, false)) # dragon horse 
        push!(pieceArr,piece("dragon", "dragon", 14, 5, 1, false)) # dragon king 
        push!(pieceArr,piece("dragon", "dragon", 14, 12, 1, false)) # dragon king 
        push!(pieceArr,piece("buffalo", "buffalo", 14, 6, 1, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 14, 11, 1, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 14, 7, 1, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 14, 10, 1, false)) # fire demon
        push!(pieceArr,piece("eagle", "eagle", 14, 8, 1, false)) # free eagle
        push!(pieceArr,piece("hawk", "hawk", 14, 9, 1, false)) # lion hawk
        push!(pieceArr,piece("smover", "smover", 13, 1, 1, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 13, 16, 1, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 13, 2, 1, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 13, 15, 1, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 13, 3, 1, false))
        push!(pieceArr,piece("rook", "rook", 13, 14, 1, false))
        push!(pieceArr,piece("falcon", "falcon", 13, 4, 1, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 13, 13, 1, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 13, 5, 1, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 13, 12, 1, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 6, 1, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 11, 1, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 7, 1, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 10, 1, false)) # rook general
        push!(pieceArr,piece("vice", "vice", 13, 8, 1, false)) # vice general
        push!(pieceArr,piece("great", "great", 13, 9, 1, false)) # great general
        push!(pieceArr,piece("pawn", "pawn", 12, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 12, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 13, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 14, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 15, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 16, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 5, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 16, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 15, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 3, 0, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 1, 14, 0, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 1, 4, 0, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 1, 13, 0, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 1, 5, 0, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 1, 12, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 6, 0, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 1, 11, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 7, 0, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 1, 10, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 8, 0, false)) # king
        push!(pieceArr,piece("elephant", "elephant", 1, 9, 0, false)) # drunk elephant
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 2, 16, 0, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 2, 3, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 4, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 13, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 14, 0, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 2, 6, 0, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 2, 11, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 7, 0, false))
        push!(pieceArr,piece("lion", "lion", 2, 8, 0, false))
        push!(pieceArr,piece("queen", "queen", 2, 9, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 10, 0, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 1, 0, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 16, 0, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 2, 0, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 15, 0, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 3, 3, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 3, 14, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 3, 13, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("dragon", "dragon", 3, 12, 0, false)) # dragon king
        push!(pieceArr,piece("buffalo", "buffalo", 3, 6, 0, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 3, 11, 0, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 3, 7, 0, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 3, 10, 0, false)) # fire demon
        push!(pieceArr,piece("hawk", "hawk", 3, 8, 0, false)) # lion hawk
        push!(pieceArr,piece("eagle", "eagle", 3, 9, 0, false)) # free eagle
        push!(pieceArr,piece("smover", "smover", 4, 1, 0, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 4, 16, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 4, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 4, 15, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 4, 3, 0, false))
        push!(pieceArr,piece("rook", "rook", 4, 14, 0, false))
        push!(pieceArr,piece("falcon", "falcon", 4, 4, 0, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 4, 13, 0, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 4, 5, 0, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 4, 12, 0, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 6, 0, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 11, 0, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 7, 0, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 10, 0, false)) # rook general
        push!(pieceArr,piece("great", "great", 4, 8, 0, false)) # great general
        push!(pieceArr,piece("vice", "vice", 4, 9, 0, false)) # vice general
        push!(pieceArr,piece("pawn", "pawn", 5, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 12, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 13, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 14, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 15, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 16, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 5, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 12, 0, false))

    elseif gameType == "chu" # game setup for chu shogi
        sente_promo_range=1:4
        gote_promo_range=9:12

        # sente/black/odd pieces
        push!(pieceArr,piece("cobra", "cobra", 8, 4, 1, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 8, 9, 1, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 9, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 12, 1, false))
        push!(pieceArr,piece("smover", "smover", 10, 1, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 2, 1, false))
        push!(pieceArr,piece("rook", "rook", 10, 3, 1, false))
        push!(pieceArr,piece("horse", "horse", 10, 4, 1, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 10, 5, 1, false)) # dragon king
        push!(pieceArr,piece("queen", "queen", 10, 6, 1, false))
        push!(pieceArr,piece("lion", "lion", 10, 7, 1, false))
        push!(pieceArr,piece("dragon", "dragon", 10, 8, 1, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 10, 9, 1, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 10, 10, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 11, 1, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 10, 12, 1, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 11, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 11, 3, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 5, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 11, 6, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 11, 7, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 8, 1, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 11, 10, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 11, 12, 1, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 12, 1, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 12, 2, 1, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 12, 3, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 12, 4, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 12, 5, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 12, 6, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 12, 7, 1, false))
        push!(pieceArr,piece("gold", "gold", 12, 8, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 12, 9, 1, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 12, 10, 1, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 12, 11, 1, false)) # ferocious leopard
        push!(pieceArr,piece("lance", "lance", 12, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("cobra", "cobra", 5, 4, 0, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 5, 9, 0, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 4, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 12, 0, false))
        push!(pieceArr,piece("smover", "smover", 3, 1, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 3, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 3, 3, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("lion", "lion", 3, 6, 0, false))
        push!(pieceArr,piece("queen", "queen", 3, 7, 0, false))
        push!(pieceArr,piece("dragon", "dragon", 3, 8, 0, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 3, 9, 0, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 3, 10, 0, false))
        push!(pieceArr,piece("vmover", "vmover", 3, 11, 0, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 3, 12, 0, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 2, 3, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 5, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 6, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 7, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 8, 0, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 2, 10, 0, false))
        push!(pieceArr,piece("chariot", "chariot", 2, 12, 0, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 2, 0, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 1, 3, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 4, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 5, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 6, 0, false))
        push!(pieceArr,piece("elephant", "elephant", 1, 7, 0, false)) # drunk elephant
        push!(pieceArr,piece("gold", "gold", 1, 8, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 9, 0, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 1, 10, 0, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 1, 11, 0, false)) #ferocious leopard
        push!(pieceArr,piece("lance", "lance", 1, 12, 0, false))

    elseif gameType == "standard" # game setup for standard shogi
        sente_promo_range=1:3
        gote_promo_range=7:9
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 7, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 9, 1, false))
        push!(pieceArr,piece("rook", "rook", 8, 2, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 8, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 1, 1, false))
        push!(pieceArr,piece("knight", "knight", 9, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 9, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 9, 4, 1, false)) # gold general 
        push!(pieceArr,piece("king", "king", 9, 5, 1, false))
        push!(pieceArr,piece("gold", "gold", 9, 6, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 9, 7, 1, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 9, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 9, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 3, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 9, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 2, 2, 0, false))
        push!(pieceArr,piece("rook", "rook", 2, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 4, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 5, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 6, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 7, 0, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 1, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 9, 0, false))

    else # game setup for minishogi
        sente_promo_range=1:1
        gote_promo_range=5:5
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 1, false))
        push!(pieceArr,piece("rook", "rook", 5, 1, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 5, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 5, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 5, 4, 1, false)) # gold general
        push!(pieceArr,piece("king", "king", 5, 5, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 2, 1, 0, false))
        push!(pieceArr,piece("king", "king", 1, 1, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 2, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("bishop", "bishop", 1, 4, 0, false))
        push!(pieceArr,piece("rook", "rook", 1, 5, 0, false))

    end


    for p in pieceArr
        if p.x!=-1
            board[p.y][p.x]=p
        end
    end

    push!(allBoards,duplicateBoard(board))

    for p in pieceArr
        if p.side==0
            push!(gote,p)
        else
            push!(sente,p)
        end
    end

    global user="sente"


    reset()
    setBoardGUI()
    if goFirst
        println("user")
        init_buttons(user)
    else
        if diff=="normal"
            tic()
            board, timeTaken ,aiMove= AI_normal(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        elseif diff=="hard"
            tic()
            board, timeTaken ,aiMove= AI_hard(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        elseif diff=="protracted"
            tic()
            board, timeTaken ,aiMove= AI_protracted(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        elseif diff=="suicidal"
            tic()
            board, timeTaken ,aiMove= AI_suicidal(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        else 
            tic()
            board, timeTaken ,aiMove= AI_random(board,moveNum)
            if moveNum%2==1
                sente_time-=timeTaken
                sente_time+=timeAdd
                #println(sente_time)
            else
                gote_time-=timeTaken
                gote_time+=timeAdd
                #println(gote_time)
            end
        end
        makeMove(db,aiMove)
        if aiMove.move_type=="move"
            movePieceGUI(aiMove.sourcex,aiMove.sourcey,aiMove.targetx,aiMove.targety)
        end
        if  checkWin(aiMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return 
        end
        moveNum+=1
        user="gote"
        init_buttons(user)
    end

    push!(window,grid)
    showall(window)



    if !isinteractive()
        c = Condition()
        signal_connect(window, :destroy) do widget
        notify(c)
    end
    wait(c)
    end
end


function checkWin(typeMove, istimed, sentetime, gotetime, boards)
    global window
    global grid
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end


function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end

function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end

function movePieceGUI(sx,sy,tx,ty)
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyImage)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyImage)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end



function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global board
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        board=demon_burning(board)
        push!(allBoards,duplicateBoard(board))
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove.option="!"
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove.option="!"
            end
        end
        makeMove(db,thisMove)
        if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            board=demon_burning(board)
            push!(allBoards,duplicateBoard(board))
            if moveNum%2==1
                if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                println("promote")
                thisMove.option="!"
                end
            else
                if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                println("promote")
                thisMove.option="!"
                end
            end
            makeMove(db,thisMove)
            if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    if moveNum%2==1
        init_buttons("sente")
    else
        init_buttons("gote")
    end
end


function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],UInt32(id2Arr[a][1]))
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            signal_handler_block(grid[idArr[b][2],idArr[b][3]],UInt32(idArr[b][1]))
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        #println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        #println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end



function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end




function display_load_pvp(file,colorBoard)
    global fileName=file
    global color = colorBoard

    global db=SQLite.DB(fileName)

    global metaTable=SQLite.query(db,"select * from meta")
    global movesTable=SQLite.query(db,"select * from moves")

    global gameType=get(metaTable[2][1])
    global isTimed=get(metaTable[2][3])
    global timeAdd=parse(Int64,get(metaTable[2][4]))
    if isTimed=="yes"
        global timeLimit=parse(Int64,get(metaTable[2][5]))
    else 
        global timeLimit=0
    end

    global sente_time=timeLimit
    global gote_time=timeLimit
    global allBoards=[]
    if timeLimit > 0
        global isTimed=true
    else 
        global isTimed=false
    end

    if gameType=="ten"
        gameType="tenjiku"
    end


    if gameType=="standard"
        gameTypeFile="S"
        global N=9
    elseif gameType=="chu"
        gameTypeFile=="C"
        global N=12
    elseif gameType=="mini"
        gameTypeFile="M"
        global N=5
    else
        gameTypeFile="T"
        global N=16
    end



    global empty=piece("", "", 0, 0, -1, false)

    global board = [ [ empty for i = 1:N ] for j = 1:N ]


    global pieceArr=[]

    global sente_promo_range
    global gote_promo_range

    if gameType == "tenjiku"
        sente_promo_range=1:5
        gote_promo_range=12:16

        # sente/black/odd pieces
        push!(pieceArr,piece("lance", "lance", 16, 1, 1, false))
        push!(pieceArr,piece("lance", "lance", 16, 16, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 2, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 15, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 16, 3, 1, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 16, 14, 1, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 16, 4, 1, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 16, 13, 1, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 16, 5, 1, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 16, 12, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 16, 6, 1, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 16, 11, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 16, 7, 1, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 16, 10, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 16, 8, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 16, 9, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 15, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 15, 16, 1, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 15, 3, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 4, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 13, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 14, 1, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 15, 6, 1, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 15, 11, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 15, 7, 1, false))
        push!(pieceArr,piece("queen", "queen", 15, 8, 1, false))
        push!(pieceArr,piece("lion", "lion", 15, 9, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 15, 10, 1, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 1, 1, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 16, 1, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 2, 1, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 15, 1, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 14, 3, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 14, 14, 1, false))
        push!(pieceArr,piece("horse", "horse", 14, 4, 1, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 14, 13, 1, false)) # dragon horse 
        push!(pieceArr,piece("dragon", "dragon", 14, 5, 1, false)) # dragon king 
        push!(pieceArr,piece("dragon", "dragon", 14, 12, 1, false)) # dragon king 
        push!(pieceArr,piece("buffalo", "buffalo", 14, 6, 1, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 14, 11, 1, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 14, 7, 1, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 14, 10, 1, false)) # fire demon
        push!(pieceArr,piece("eagle", "eagle", 14, 8, 1, false)) # free eagle
        push!(pieceArr,piece("hawk", "hawk", 14, 9, 1, false)) # lion hawk
        push!(pieceArr,piece("smover", "smover", 13, 1, 1, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 13, 16, 1, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 13, 2, 1, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 13, 15, 1, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 13, 3, 1, false))
        push!(pieceArr,piece("rook", "rook", 13, 14, 1, false))
        push!(pieceArr,piece("falcon", "falcon", 13, 4, 1, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 13, 13, 1, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 13, 5, 1, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 13, 12, 1, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 6, 1, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 11, 1, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 7, 1, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 10, 1, false)) # rook general
        push!(pieceArr,piece("vice", "vice", 13, 8, 1, false)) # vice general
        push!(pieceArr,piece("great", "great", 13, 9, 1, false)) # great general
        push!(pieceArr,piece("pawn", "pawn", 12, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 12, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 13, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 14, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 15, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 16, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 5, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 16, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 15, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 3, 0, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 1, 14, 0, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 1, 4, 0, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 1, 13, 0, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 1, 5, 0, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 1, 12, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 6, 0, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 1, 11, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 7, 0, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 1, 10, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 8, 0, false)) # king
        push!(pieceArr,piece("elephant", "elephant", 1, 9, 0, false)) # drunk elephant
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 2, 16, 0, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 2, 3, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 4, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 13, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 14, 0, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 2, 6, 0, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 2, 11, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 7, 0, false))
        push!(pieceArr,piece("lion", "lion", 2, 8, 0, false))
        push!(pieceArr,piece("queen", "queen", 2, 9, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 10, 0, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 1, 0, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 16, 0, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 2, 0, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 15, 0, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 3, 3, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 3, 14, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 3, 13, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("dragon", "dragon", 3, 12, 0, false)) # dragon king
        push!(pieceArr,piece("buffalo", "buffalo", 3, 6, 0, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 3, 11, 0, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 3, 7, 0, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 3, 10, 0, false)) # fire demon
        push!(pieceArr,piece("hawk", "hawk", 3, 8, 0, false)) # lion hawk
        push!(pieceArr,piece("eagle", "eagle", 3, 9, 0, false)) # free eagle
        push!(pieceArr,piece("smover", "smover", 4, 1, 0, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 4, 16, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 4, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 4, 15, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 4, 3, 0, false))
        push!(pieceArr,piece("rook", "rook", 4, 14, 0, false))
        push!(pieceArr,piece("falcon", "falcon", 4, 4, 0, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 4, 13, 0, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 4, 5, 0, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 4, 12, 0, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 6, 0, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 11, 0, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 7, 0, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 10, 0, false)) # rook general
        push!(pieceArr,piece("great", "great", 4, 8, 0, false)) # great general
        push!(pieceArr,piece("vice", "vice", 4, 9, 0, false)) # vice general
        push!(pieceArr,piece("pawn", "pawn", 5, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 12, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 13, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 14, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 15, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 16, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 5, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 12, 0, false))

    elseif gameType == "chu" # game setup for chu shogi
        sente_promo_range=1:4
        gote_promo_range=9:12

        # sente/black/odd pieces
        push!(pieceArr,piece("cobra", "cobra", 8, 4, 1, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 8, 9, 1, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 9, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 12, 1, false))
        push!(pieceArr,piece("smover", "smover", 10, 1, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 2, 1, false))
        push!(pieceArr,piece("rook", "rook", 10, 3, 1, false))
        push!(pieceArr,piece("horse", "horse", 10, 4, 1, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 10, 5, 1, false)) # dragon king
        push!(pieceArr,piece("queen", "queen", 10, 6, 1, false))
        push!(pieceArr,piece("lion", "lion", 10, 7, 1, false))
        push!(pieceArr,piece("dragon", "dragon", 10, 8, 1, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 10, 9, 1, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 10, 10, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 11, 1, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 10, 12, 1, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 11, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 11, 3, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 5, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 11, 6, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 11, 7, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 8, 1, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 11, 10, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 11, 12, 1, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 12, 1, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 12, 2, 1, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 12, 3, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 12, 4, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 12, 5, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 12, 6, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 12, 7, 1, false))
        push!(pieceArr,piece("gold", "gold", 12, 8, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 12, 9, 1, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 12, 10, 1, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 12, 11, 1, false)) # ferocious leopard
        push!(pieceArr,piece("lance", "lance", 12, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("cobra", "cobra", 5, 4, 0, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 5, 9, 0, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 4, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 12, 0, false))
        push!(pieceArr,piece("smover", "smover", 3, 1, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 3, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 3, 3, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("lion", "lion", 3, 6, 0, false))
        push!(pieceArr,piece("queen", "queen", 3, 7, 0, false))
        push!(pieceArr,piece("dragon", "dragon", 3, 8, 0, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 3, 9, 0, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 3, 10, 0, false))
        push!(pieceArr,piece("vmover", "vmover", 3, 11, 0, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 3, 12, 0, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 2, 3, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 5, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 6, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 7, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 8, 0, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 2, 10, 0, false))
        push!(pieceArr,piece("chariot", "chariot", 2, 12, 0, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 2, 0, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 1, 3, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 4, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 5, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 6, 0, false))
        push!(pieceArr,piece("elephant", "elephant", 1, 7, 0, false)) # drunk elephant
        push!(pieceArr,piece("gold", "gold", 1, 8, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 9, 0, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 1, 10, 0, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 1, 11, 0, false)) #ferocious leopard
        push!(pieceArr,piece("lance", "lance", 1, 12, 0, false))

    elseif gameType == "standard" # game setup for standard shogi
        sente_promo_range=1:3
        gote_promo_range=7:9
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 7, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 9, 1, false))
        push!(pieceArr,piece("rook", "rook", 8, 2, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 8, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 1, 1, false))
        push!(pieceArr,piece("knight", "knight", 9, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 9, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 9, 4, 1, false)) # gold general 
        push!(pieceArr,piece("king", "king", 9, 5, 1, false))
        push!(pieceArr,piece("gold", "gold", 9, 6, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 9, 7, 1, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 9, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 9, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 3, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 9, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 2, 2, 0, false))
        push!(pieceArr,piece("rook", "rook", 2, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 4, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 5, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 6, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 7, 0, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 1, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 9, 0, false))

    else # game setup for minishogi
        sente_promo_range=1:1
        gote_promo_range=5:5
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 1, false))
        push!(pieceArr,piece("rook", "rook", 5, 1, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 5, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 5, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 5, 4, 1, false)) # gold general
        push!(pieceArr,piece("king", "king", 5, 5, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 2, 1, 0, false))
        push!(pieceArr,piece("king", "king", 1, 1, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 2, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("bishop", "bishop", 1, 4, 0, false))
        push!(pieceArr,piece("rook", "rook", 1, 5, 0, false))

    end

    global grid = @Grid()
    global window = @Window("Shogi by null_ptr")
    global emptyImage=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
    global moveNum=1
    global double=["lion","falcon","soaring"]
    global triple=["demon","vice","great","tetrarch"]
    global sente=[]
    global gote=[]
    global idArr=[]
    global id2Arr=[]
    global prevsx=0
    global prevsy=0
    global prevtx=0
    global prevty=0
    global userMove=[]
    global DF=0

    for p in pieceArr
        if p.side==0
            push!(gote,p)
        else
            push!(sente,p)
        end
    end
    
    for i in 1:length(movesTable[1])
        number=get(movesTable[1][i])
        moveType=get(movesTable[2][i])
        sx=(movesTable[3][i])
        sy=(movesTable[4][i])
        tx=get(movesTable[5][i])
        ty=get(movesTable[6][i])
        option=movesTable[7][i]
        tx2=movesTable[9][i]
        ty2=movesTable[10][i]
        tx3=movesTable[11][i]
        ty3=movesTable[12][i]
        if moveType=="move"
            sx=get(sx)
            sy=get(sy)
            if !isnull(tx3) && !isnull(tx2)
                tx3=get(tx3)
                ty3=get(ty3)
                tx2=get(tx2)
                ty2=get(ty2)
            elseif !isnull(tx2) && isnull(tx3)
                tx3=0
                ty3=0
                tx2=get(tx2)
                ty2=get(ty2)
            else
                tx3=0
                ty3=0
                tx2=0
                ty2=0
            end
            p=getPiece(sx,sy)
            if tx2==0
                tx=tx
                ty=ty
            elseif tx2>0 && tx3==0
                tx=tx2
                ty=ty2
            elseif tx2>0 && tx3>0
                tx=tx3
                ty=tx3
            end
            if getPiece(tx,ty)!=nothing
                getPiece(tx,ty).x=-1
                getPiece(-1,ty).y=-1
            end
            if !isnull(option) && get(option)=="!" && p!=nothing
                a=promote(p,gameType)
                p.name=a.name
                p.promoted=a.promoted
            end
            p.x=tx
            p.y=ty
        elseif moveType=="drop"
           option=get(option)
           for p in pieceArr
            if p.name==option && p.x==-1 && p.side==(number&2)$1
                dropped=p
            end
        end
        getPiece(tx,ty).x=-1
        getPiece(tx,ty).y=-1
        if number%2==0
            dropped.side=0
        else
            dropped.side=1
        end
        dropped.x=tx
        dropped.y=ty
    end
    moveNum=number+1
end


for p in pieceArr
    if p.x!=-1
        board[p.y][p.x]=p
    end
end

push!(allBoards,duplicateBoard(board))


reset()
setBoardGUI()
if moveNum%2==1
    init_buttons("sente")
else
    init_buttons("gote")
end 

push!(window,grid)
showall(window)




if !isinteractive()
    c = Condition()
    signal_connect(window, :destroy) do widget
    notify(c)
end
wait(c)
end

end


function getPiece(xCoord,yCoord)
    for piece in pieceArr
        if piece.x==xCoord && piece.y==yCoord
            return piece
        end
    end
end

function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end
    path=joinpath(path,color)
    side = p.side == 0? "left":"right"
    path=joinpath(path,side)
    if p.promoted
        path=joinpath(path,string(lowercase(p.original),"p"))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end



function checkWin(typeMove, istimed, sentetime, gotetime, boards)
    global window
    global grid
    frame=@Frame()
    button=@Button()
    setproperty!(button,:label,"Click to exit.")
    id=signal_connect(button,"clicked") do widget
        destroy(window)
    end
    if win(typeMove, istimed, sentetime, gotetime, boards)=="W"
        setproperty!(button,:label,"Gote wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    elseif win(typeMove, istimed, sentetime, gotetime, boards)=="B"
        setproperty!(button,:label,"Sente wins! Click to exit.")
        destroy(grid)
        push!(frame,button)
        push!(window,frame)
        showall(window)
        return true
    else
        return false
    end
end

function checkPromote(p,number,tx)
    global gameType
    global gote_promo_range
    global sente_promo_range
    if number%2==1
        if tx in sente_promo_range
            p=promote(p,gameType)
            return p
        end
    else
        if tx in gote_promo_range
            p=promote(p,gameType)
            return p
        end
    end
    return p
end


function movePieceGUI(sx,sy,tx,ty)
    global board
    global moveNum
    p=getPiece(sx,sy)
    if p!=nothing
        t=getPiece(tx,ty)
        if t!=nothing
            t.x=-1
            t.y=-1
        end
        a=checkPromote(p,moveNum,tx)
        p.name=a.name
        p.promoted=a.promoted
        p.x=tx
        p.y=ty
        eImage=@Image()
        setproperty!(eImage,:file,emptyPath)
        setproperty!(grid[sx,sy],:image,eImage)
        i=@Image()
        setproperty!(i,:file,getImage(p))
        setproperty!(grid[tx,ty],:image,i)
    end
end

function reset()
    global N
    for y in 1: N
        for x in 1:N
            image = @Image()
            setproperty!(image, :file, emptyPath)
            b=@Button()
            setproperty!(b,:image,image)
            grid[x,y]=b
        end
    end
end



function setBoardGUI()
    for p in pieceArr
        if p.x!=-1
            image = @Image()
            setproperty!(image, :file, getImage(p)) 
            destroy(grid[p.x,p.y])
            b=@Button()
            setproperty!(b,:image,image)
            grid[p.x,p.y]=b
        end
    end
end



function moveCheck()
    global sente_time
    global gote_time
    global board
    global prevtx
    global prevty
    global prevsx
    global prevsy
    global DF
    global userMove
    global moveNum
    sx=userMove[1][1]
    sy=userMove[1][2]
    tx=userMove[2][1]
    ty=userMove[2][2]
    tx2=-1
    ty2=-1
    tx3=-1
    ty3=-1
    if DF==1
        if tx==sx && ty==sy #Doesnt want second move
            thisMove=move(moveNum,"move",prevsx,prevsy,sx,sy,"",false,tx2,ty2,tx3,ty3)
            userMove=[]
        else #wants second move
            thisMove=move(moveNum,"move",prevsx,prevsy,prevtx,prevty,"",false,tx,ty,tx3,ty3)
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        end
        if moveNum%2==1
            if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                thisMove.option="!"
            end
        else
            if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                thisMove.option="!"
            end
        end
        board[ty][tx]=board[sy][sx]
        board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
        board[sy][sx]=empty
        board=demon_burning(board)
        push!(allBoards,duplicateBoard(board))
        makeMove(db,thisMove)
        if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
            return
        end
        DF=0
    else
        if getPiece(sx,sy)!= nothing && getPiece(sx,sy).name in double && DF==0
            DF=1
            moveNum-=1
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
        else
            thisMove=move(moveNum,"move",sx,sy,tx,ty,"",false,tx2,ty2,tx3,ty3)
            if moveNum%2==1
                if !(sx in sente_promo_range) && ((tx in sente_promo_range) || (tx2 in sente_promo_range) || (tx3 in sente_promo_range))
                    thisMove.option="!"
                end
            else
                if !(sx in gote_promo_range) && ((tx in gote_promo_range) || (tx2 in gote_promo_range) || (tx3 in gote_promo_range))
                    thisMove.option="!"
                end
            end
            movePieceGUI(sx,sy,tx,ty)
            userMove=[]
            board[ty][tx]=board[sy][sx]
            board[ty][tx]=checkPromote(board[ty][tx],moveNum,tx)
            board[sy][sx]=empty
            board=demon_burning(board)

            push!(allBoards,duplicateBoard(board))
            makeMove(db,thisMove)
            if checkWin(thisMove.move_type,isTimed,sente_time,gote_time,allBoards)
                return
            end
        end
    end
    prevsx=sx
    prevsy=sy
    prevtx=tx
    prevty=ty
    moveNum+=1
    if moveNum%2==1
        init_buttons("sente")
    else
        init_buttons("gote")
    end
end


function clear_buttons()
    for a in 1:length(id2Arr)
        if id2Arr[a][1]!=0
            signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],(id2Arr[a][1]))
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            signal_handler_block(grid[idArr[b][2],idArr[b][3]],(idArr[b][1]))
        end
    end
end


function init_target_buttons(sx,sy)
    global sente_time
    global gote_time
    clear_buttons()
    global id
    for y in 1:N
        for x in 1:N
            tempMove=move(moveNum,"move",sx,sy,x,y,"",false,-1,-1,-1,-1)
            id2=0
            if inRange(board,tempMove)
                id2=signal_connect(grid[x,y],"clicked") do widget
                    push!(userMove,(x,y))
                    if moveNum%2==1
                        sente_time-=toc()
                        sente_time+=timeAdd
                        println(sente_time)
                    else
                        gote_time-=toc()
                        gote_time+=timeAdd
                        println(gote_time)
                    end
                    for a in 1:N
                        for b in 1:N
                            setproperty!(grid[b,a],:sensitive,true)
                        end
                    end
                    moveCheck()
                end
            else
                setproperty!(grid[x,y],:sensitive,false)
            end
            push!(id2Arr,(id2,x,y))
        end
    end
end



function init_buttons(side::String)
    global DF
    clear_buttons()
    if DF==1
        #println("make 2nd move")
        id=signal_connect(grid[prevtx,prevty],"clicked") do widget
                tic()
                push!(userMove,(prevtx,prevty))
                init_target_buttons(prevtx,prevty)
            end
        push!(idArr,(id,prevtx,prevty))
    elseif side=="sente"
        for p in sente
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                #println(userMove)
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
        end
    else
        for p in gote
            if p.x!=-1
            id=signal_connect(grid[p.x,p.y],"clicked") do widget
                tic()
                push!(userMove,(p.x,p.y))
                #println(userMove)
                init_target_buttons(p.x,p.y)
            end
            push!(idArr,(id,p.x,p.y))
        end
    end
    end
end



function display_pvp(typeGame,limit,add,jRoulette,ifFirst,cheatingAllowed,colorBoard)

    fileName="gameplay.db"
    filePath=joinpath(pwd(),fileName)
    chmod(filePath,0o777,recursive=true)
    touch(filePath)
    rm(filePath,recursive=false,force=true)

    global color=colorBoard

    global gameType=typeGame
    global timeLimit=limit
    global timeAdd=add
    global japRoulette=jRoulette
    global goFirst=ifFirst
    global cheating=cheatingAllowed

    global sente_promo_range
    global gote_promo_range

    global sente_time=timeLimit
    global gote_time=timeLimit
    global allBoards=[]
    if timeLimit > 0
        global isTimed=true
    else 
        global isTimed=false
    end

    if gameType=="standard"
        gameTypeFile="S"
        global N=9
    elseif gameType=="chu"
        gameTypeFile=="C"
        global N=12
    elseif gameType=="mini"
        gameTypeFile="M"
        global N=5
    else
        gameTypeFile="T"
        global N=16
    end



    global empty=piece("", "", 0, 0, -1, false)

    global board = [ [ empty for i = 1:N ] for j = 1:N ]


    global pieceArr=[]

    global db=gameFileSetup(fileName,gameTypeFile,cheating,timeLimit,timeAdd)

    if gameType == "tenjiku"
        sente_promo_range=1:5
        gote_promo_range=12:16

        # sente/black/odd pieces
        push!(pieceArr,piece("lance", "lance", 16, 1, 1, false))
        push!(pieceArr,piece("lance", "lance", 16, 16, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 2, 1, false))
        push!(pieceArr,piece("knight", "knight", 16, 15, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 16, 3, 1, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 16, 14, 1, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 16, 4, 1, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 16, 13, 1, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 16, 5, 1, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 16, 12, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 16, 6, 1, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 16, 11, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 16, 7, 1, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 16, 10, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 16, 8, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 16, 9, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 15, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 15, 16, 1, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 15, 3, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 4, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 13, 1, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 15, 14, 1, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 15, 6, 1, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 15, 11, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 15, 7, 1, false))
        push!(pieceArr,piece("queen", "queen", 15, 8, 1, false))
        push!(pieceArr,piece("lion", "lion", 15, 9, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 15, 10, 1, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 1, 1, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 14, 16, 1, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 2, 1, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 14, 15, 1, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 14, 3, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 14, 14, 1, false))
        push!(pieceArr,piece("horse", "horse", 14, 4, 1, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 14, 13, 1, false)) # dragon horse 
        push!(pieceArr,piece("dragon", "dragon", 14, 5, 1, false)) # dragon king 
        push!(pieceArr,piece("dragon", "dragon", 14, 12, 1, false)) # dragon king 
        push!(pieceArr,piece("buffalo", "buffalo", 14, 6, 1, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 14, 11, 1, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 14, 7, 1, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 14, 10, 1, false)) # fire demon
        push!(pieceArr,piece("eagle", "eagle", 14, 8, 1, false)) # free eagle
        push!(pieceArr,piece("hawk", "hawk", 14, 9, 1, false)) # lion hawk
        push!(pieceArr,piece("smover", "smover", 13, 1, 1, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 13, 16, 1, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 13, 2, 1, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 13, 15, 1, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 13, 3, 1, false))
        push!(pieceArr,piece("rook", "rook", 13, 14, 1, false))
        push!(pieceArr,piece("falcon", "falcon", 13, 4, 1, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 13, 13, 1, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 13, 5, 1, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 13, 12, 1, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 6, 1, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 13, 11, 1, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 7, 1, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 13, 10, 1, false)) # rook general
        push!(pieceArr,piece("vice", "vice", 13, 8, 1, false)) # vice general
        push!(pieceArr,piece("great", "great", 13, 9, 1, false)) # great general
        push!(pieceArr,piece("pawn", "pawn", 12, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 12, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 13, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 14, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 15, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 12, 16, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 5, 1, false))
        push!(pieceArr,piece("dog", "dog", 11, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 16, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 15, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 3, 0, false)) # ferocious leopard
        push!(pieceArr,piece("leopard", "leopard", 1, 14, 0, false)) # ferocious leopard
        push!(pieceArr,piece("iron", "iron", 1, 4, 0, false)) # iron general
        push!(pieceArr,piece("iron", "iron", 1, 13, 0, false)) # iron general
        push!(pieceArr,piece("copper", "copper", 1, 5, 0, false)) # copper general
        push!(pieceArr,piece("copper", "copper", 1, 12, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 6, 0, false)) # silver general
        push!(pieceArr,piece("silver", "silver", 1, 11, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 7, 0, false)) # gold general
        push!(pieceArr,piece("gold", "gold", 1, 10, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 8, 0, false)) # king
        push!(pieceArr,piece("elephant", "elephant", 1, 9, 0, false)) # drunk elephant
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("chariot", "chariot", 2, 16, 0, false)) # reverse chariot
        push!(pieceArr,piece("csoldier", "csoldier", 2, 3, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 4, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 13, 0, false)) # chariot soldier
        push!(pieceArr,piece("csoldier", "csoldier", 2, 14, 0, false)) # chariot soldier
        push!(pieceArr,piece("tiger", "tiger", 2, 6, 0, false)) # blind tiger
        push!(pieceArr,piece("tiger", "tiger", 2, 11, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 7, 0, false))
        push!(pieceArr,piece("lion", "lion", 2, 8, 0, false))
        push!(pieceArr,piece("queen", "queen", 2, 9, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 10, 0, false))
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 1, 0, false)) # side soldier
        push!(pieceArr,piece("ssoldier", "ssoldier", 3, 16, 0, false)) # side soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 2, 0, false)) # vertical soldier
        push!(pieceArr,piece("vsoldier", "vsoldier", 3, 15, 0, false)) # vertical soldier
        push!(pieceArr,piece("bishop", "bishop", 3, 3, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 3, 14, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse 
        push!(pieceArr,piece("horse", "horse", 3, 13, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("dragon", "dragon", 3, 12, 0, false)) # dragon king
        push!(pieceArr,piece("buffalo", "buffalo", 3, 6, 0, false)) # water buffalo
        push!(pieceArr,piece("buffalo", "buffalo", 3, 11, 0, false)) # water buffalo
        push!(pieceArr,piece("demon", "demon", 3, 7, 0, false)) # fire demon
        push!(pieceArr,piece("demon", "demon", 3, 10, 0, false)) # fire demon
        push!(pieceArr,piece("hawk", "hawk", 3, 8, 0, false)) # lion hawk
        push!(pieceArr,piece("eagle", "eagle", 3, 9, 0, false)) # free eagle
        push!(pieceArr,piece("smover", "smover", 4, 1, 0, false)) # side mover
        push!(pieceArr,piece("smover", "smover", 4, 16, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 4, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("vmover", "vmover", 4, 15, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 4, 3, 0, false))
        push!(pieceArr,piece("rook", "rook", 4, 14, 0, false))
        push!(pieceArr,piece("falcon", "falcon", 4, 4, 0, false)) # horned falcon
        push!(pieceArr,piece("falcon", "falcon", 4, 13, 0, false)) # horned falcon
        push!(pieceArr,piece("soaring", "soaring", 4, 5, 0, false)) # soaring eagle
        push!(pieceArr,piece("soaring", "soaring", 4, 12, 0, false)) # soaring eagle
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 6, 0, false)) # bishop general
        push!(pieceArr,piece("bgeneral", "bgeneral", 4, 11, 0, false)) # bishop general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 7, 0, false)) # rook general
        push!(pieceArr,piece("rgeneral", "rgeneral", 4, 10, 0, false)) # rook general
        push!(pieceArr,piece("great", "great", 4, 8, 0, false)) # great general
        push!(pieceArr,piece("vice", "vice", 4, 9, 0, false)) # vice general
        push!(pieceArr,piece("pawn", "pawn", 5, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 12, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 13, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 14, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 15, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 5, 16, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 5, 0, false))
        push!(pieceArr,piece("dog", "dog", 6, 12, 0, false))

    elseif gameType == "chu" # game setup for chu shogi
        sente_promo_range=1:4
        gote_promo_range=9:12

        # sente/black/odd pieces
        push!(pieceArr,piece("cobra", "cobra", 8, 4, 1, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 8, 9, 1, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 9, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 9, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 10, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 11, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 9, 12, 1, false))
        push!(pieceArr,piece("smover", "smover", 10, 1, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 2, 1, false))
        push!(pieceArr,piece("rook", "rook", 10, 3, 1, false))
        push!(pieceArr,piece("horse", "horse", 10, 4, 1, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 10, 5, 1, false)) # dragon king
        push!(pieceArr,piece("queen", "queen", 10, 6, 1, false))
        push!(pieceArr,piece("lion", "lion", 10, 7, 1, false))
        push!(pieceArr,piece("dragon", "dragon", 10, 8, 1, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 10, 9, 1, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 10, 10, 1, false))
        push!(pieceArr,piece("vmover", "vmover", 10, 11, 1, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 10, 12, 1, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 11, 1, 1, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 11, 3, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 5, 1, false)) # blind tiger
        push!(pieceArr,piece("phoenix", "phoenix", 11, 6, 1, false))
        push!(pieceArr,piece("kirin", "kirin", 11, 7, 1, false))
        push!(pieceArr,piece("tiger", "tiger", 11, 8, 1, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 11, 10, 1, false))
        push!(pieceArr,piece("chariot", "chariot", 11, 12, 1, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 12, 1, 1, false))
        push!(pieceArr,piece("leopard", "leopard", 12, 2, 1, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 12, 3, 1, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 12, 4, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 12, 5, 1, false)) # gold general
        push!(pieceArr,piece("elephant", "elephant", 12, 6, 1, false)) # drunk elephant
        push!(pieceArr,piece("king", "king", 12, 7, 1, false))
        push!(pieceArr,piece("gold", "gold", 12, 8, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 12, 9, 1, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 12, 10, 1, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 12, 11, 1, false)) # ferocious leopard
        push!(pieceArr,piece("lance", "lance", 12, 12, 1, false))

        # gote/white/even pieces
        push!(pieceArr,piece("cobra", "cobra", 5, 4, 0, false)) # AKA go-between
        push!(pieceArr,piece("cobra", "cobra", 5, 9, 0, false)) # AKA go-between
        push!(pieceArr,piece("pawn", "pawn", 4, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 9, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 10, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 11, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 4, 12, 0, false))
        push!(pieceArr,piece("smover", "smover", 3, 1, 0, false)) # side mover
        push!(pieceArr,piece("vmover", "vmover", 3, 2, 0, false)) # vertical mover
        push!(pieceArr,piece("rook", "rook", 3, 3, 0, false))
        push!(pieceArr,piece("horse", "horse", 3, 4, 0, false)) # dragon horse
        push!(pieceArr,piece("dragon", "dragon", 3, 5, 0, false)) # dragon king
        push!(pieceArr,piece("lion", "lion", 3, 6, 0, false))
        push!(pieceArr,piece("queen", "queen", 3, 7, 0, false))
        push!(pieceArr,piece("dragon", "dragon", 3, 8, 0, false)) # dragon king
        push!(pieceArr,piece("horse", "horse", 3, 9, 0, false)) # dragon horse
        push!(pieceArr,piece("rook", "rook", 3, 10, 0, false))
        push!(pieceArr,piece("vmover", "vmover", 3, 11, 0, false)) # vertical mover
        push!(pieceArr,piece("smover", "smover", 3, 12, 0, false)) # side mover
        push!(pieceArr,piece("chariot", "chariot", 2, 1, 0, false)) # reverse chariot
        push!(pieceArr,piece("bishop", "bishop", 2, 3, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 5, 0, false)) # blind tiger
        push!(pieceArr,piece("kirin", "kirin", 2, 6, 0, false))
        push!(pieceArr,piece("phoenix", "phoenix", 2, 7, 0, false))
        push!(pieceArr,piece("tiger", "tiger", 2, 8, 0, false)) # blind tiger
        push!(pieceArr,piece("bishop", "bishop", 2, 10, 0, false))
        push!(pieceArr,piece("chariot", "chariot", 2, 12, 0, false)) # reverse chariot
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("leopard", "leopard", 1, 2, 0, false)) # ferocious leopard
        push!(pieceArr,piece("copper", "copper", 1, 3, 0, false)) # copper general
        push!(pieceArr,piece("silver", "silver", 1, 4, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 5, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 6, 0, false))
        push!(pieceArr,piece("elephant", "elephant", 1, 7, 0, false)) # drunk elephant
        push!(pieceArr,piece("gold", "gold", 1, 8, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 9, 0, false)) # silver general
        push!(pieceArr,piece("copper", "copper", 1, 10, 0, false)) # copper general
        push!(pieceArr,piece("leopard", "leopard", 1, 11, 0, false)) #ferocious leopard
        push!(pieceArr,piece("lance", "lance", 1, 12, 0, false))

    elseif gameType == "standard" # game setup for standard shogi
        sente_promo_range=1:3
        gote_promo_range=7:9
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 7, 1, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 2, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 3, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 4, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 5, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 6, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 7, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 8, 1, false))
        push!(pieceArr,piece("pawn", "pawn", 7, 9, 1, false))
        push!(pieceArr,piece("rook", "rook", 8, 2, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 8, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 1, 1, false))
        push!(pieceArr,piece("knight", "knight", 9, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 9, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 9, 4, 1, false)) # gold general 
        push!(pieceArr,piece("king", "king", 9, 5, 1, false))
        push!(pieceArr,piece("gold", "gold", 9, 6, 1, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 9, 7, 1, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 9, 8, 1, false))
        push!(pieceArr,piece("lance", "lance", 9, 9, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 3, 1, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 2, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 3, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 4, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 5, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 6, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 7, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 8, 0, false))
        push!(pieceArr,piece("pawn", "pawn", 3, 9, 0, false))
        push!(pieceArr,piece("bishop", "bishop", 2, 2, 0, false))
        push!(pieceArr,piece("rook", "rook", 2, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 1, 0, false))
        push!(pieceArr,piece("knight", "knight", 1, 2, 0, false))
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 1, 4, 0, false)) # gold general
        push!(pieceArr,piece("king", "king", 1, 5, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 6, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 7, 0, false)) # silver general
        push!(pieceArr,piece("knight", "knight", 1, 8, 0, false))
        push!(pieceArr,piece("lance", "lance", 1, 9, 0, false))

    else # game setup for minishogi
        sente_promo_range=1:1
        gote_promo_range=5:5
        # sente/black/odd player
        push!(pieceArr,piece("pawn", "pawn", 4, 5, 1, false))
        push!(pieceArr,piece("rook", "rook", 5, 1, 1, false))
        push!(pieceArr,piece("bishop", "bishop", 5, 2, 1, false))
        push!(pieceArr,piece("silver", "silver", 5, 3, 1, false)) # silver general
        push!(pieceArr,piece("gold", "gold", 5, 4, 1, false)) # gold general
        push!(pieceArr,piece("king", "king", 5, 5, 1, false))

        # gote/white/even player
        push!(pieceArr,piece("pawn", "pawn", 2, 1, 0, false))
        push!(pieceArr,piece("king", "king", 1, 1, 0, false))
        push!(pieceArr,piece("gold", "gold", 1, 2, 0, false)) # gold general
        push!(pieceArr,piece("silver", "silver", 1, 3, 0, false)) # silver general
        push!(pieceArr,piece("bishop", "bishop", 1, 4, 0, false))
        push!(pieceArr,piece("rook", "rook", 1, 5, 0, false))

    end


    for p in pieceArr
        if p.x!=-1
            board[p.y][p.x]=p
        end
    end
    push!(allBoards,duplicateBoard(board))


    global grid = @Grid()
    global window = @Window("Shogi by null_ptr")
    global emptyPath=joinpath(pwd(),"images",gameType,color,"left","empty.jpg")
    global moveNum=1
    global double=["lion","falcon","soaring"]
    global triple=["demon","vice","great","tetrarch"]
    global sente=[]
    global gote=[]
    global idArr=[]
    global id2Arr=[]
    global prevsx=0
    global prevsy=0
    global prevtx=0
    global prevty=0
    global userMove=[]
    global DF=0


    for p in pieceArr
        if p.side==0
            push!(gote,p)
        else
            push!(sente,p)
        end
    end

    reset()
    setBoardGUI()
    init_buttons("sente")

    push!(window,grid)
    showall(window)




    if !isinteractive()
        c = Condition()
        signal_connect(window, :destroy) do widget
        notify(c)
    end
    wait(c)
    end
end


gameType = "standard"
useTimeLimit = false
timeLimit = 0
timeIncrement = 0
difficulty = "normal"
japaneseRoulette = false
goFirst = true
cheatingAllowed = false
color = "red"
db = 0
ip = ""
port = 0
flag = -1


# returns directory of image corresponding to the piece.
function getImage(p::piece)
    path=pwd()
    path=joinpath(path,"images")
    if gameType=="standard"
        path=joinpath(path,"standard")
    elseif gameType=="minishogi"
        path=joinpath(path,"mini")
    elseif  gameType=="chu"
        path=joinpath(path,"chu")
    else 
        path=joinpath(path,"tenjiku")
    end

    path = joinpath(path, color)

    side = p.side == 0? "left":"right"

    path=joinpath(path,side)

    if p.promoted
        path=joinpath(path,string(lowercase(p.name)))
    else
        path=joinpath(path,string(p.name))
    end
    path=path*".jpg"
end

#=
for p in pieceArr
    println(getImage(p))
end
=#

#
function game_settings_menu_AI()
    #need @Entry(), @radioButton
    global gameSettingsMenuAI = @Grid()

    global gameTypesLabel = @Label("gameTypes:")
    global useTimeLimitLabel = @Label("Use Time Limit:")
    global timeLimitLabel = @Label("Time limit:")
    global timeIncrementLabel = @Label("Time Increment:")
    global DifficultyLabel = @Label("Difficulty:")
    global japaneseRouletteLabel = @Label("Japanese Roulette mode:")
    global goFirstLabel = @Label("Player goes first:")
    global cheatingAllowedLabel =@Label("Allow AI to Cheat:")
    global colorLabel =@Label("Select Background Color:")

    global gameTypesCombo = @ComboBoxText()
    push!(gameTypesCombo, "Mini")
    push!(gameTypesCombo, "Standard")
    push!(gameTypesCombo, "Chu")
    push!(gameTypesCombo, "Tenjiku" )
    setproperty!(gameTypesCombo, :active, 1)
    global useTimeLimitButton = @CheckButton() 
    global timeLimitEntry = @Entry()
    setproperty!(timeLimitEntry, :text, "0")
    global timeIncrementEntry = @Entry()
    setproperty!(timeIncrementEntry, :text, "0")
    global difficultyCombo = @ComboBoxText()
    push!(difficultyCombo, "Normal")
    push!(difficultyCombo, "Hard")
    push!(difficultyCombo, "Suicidal")
    push!(difficultyCombo, "Protracted Death")
    push!(difficultyCombo, "Random")
    setproperty!(difficultyCombo, :active, 0)
    global japaneseRoutletteButton = @CheckButton()
    global goFirstButton = @CheckButton() 
    global cheatingAllowedButton = @CheckButton()
    global startGameButton = @Button("Start Game")
    global colorCombo = @ComboBoxText()
    push!(colorCombo, "red")
    push!(colorCombo, "green")
    push!(colorCombo, "blue")
    setproperty!(colorCombo, :active, 0)

    global backButton = @Button("back")

    gameSettingsMenuAI[1,1] = gameTypesLabel
    gameSettingsMenuAI[1,2] = useTimeLimitLabel
    gameSettingsMenuAI[1,3] = timeLimitLabel
    gameSettingsMenuAI[1,4] = timeIncrementLabel
    gameSettingsMenuAI[1,5] = DifficultyLabel
    gameSettingsMenuAI[1,6] = japaneseRouletteLabel
    gameSettingsMenuAI[1,7] = goFirstLabel
    gameSettingsMenuAI[1,8] = cheatingAllowedLabel
    gameSettingsMenuAI[1,9] = colorLabel

    gameSettingsMenuAI[2,1] = gameTypesCombo
    gameSettingsMenuAI[2,2] = useTimeLimitButton
    gameSettingsMenuAI[2,3] = timeLimitEntry
    gameSettingsMenuAI[2,4] = timeIncrementEntry
    gameSettingsMenuAI[2,5] = difficultyCombo
    gameSettingsMenuAI[2,6] = japaneseRoutletteButton
    gameSettingsMenuAI[2,7] = goFirstButton
    gameSettingsMenuAI[2,8] = cheatingAllowedButton
    gameSettingsMenuAI[2,9] = colorCombo

    gameSettingsMenuAI[1,10] = startGameButton
    gameSettingsMenuAI[2,10] = backButton

    push!(window, gameSettingsMenuAI)
end

function game_settings_menu_player()
    #need @Entry(), @radioButton
    global gameSettingsMenuPlayer = @Grid()

    global gameTypesLabel = @Label("Game Types:")
    global useTimeLimitLabel = @Label("Use Time Limit:")
    global timeLimitLabel = @Label("Time Limit (0 for none):")
    global timeIncrementLabel = @Label("Time Increment (0 for none):")
    global japaneseRouletteLabel = @Label("Japanese Roulette mode:")
    global goFirstLabel = @Label("Player goes first:")
    global cheatingAllowedLabel =@Label("Allow AI to Cheat:")
    global colorLabel = @Label("Select Background Color:")

    global gameTypesCombo = @ComboBoxText()
    push!(gameTypesCombo, "Mini")
    push!(gameTypesCombo, "Standard")
    push!(gameTypesCombo, "Chu")
    push!(gameTypesCombo, "Tenjiku" )
    setproperty!(gameTypesCombo, :active, 1)
    global useTimeLimitButton = @CheckButton() 
    global timeLimitEntry = @Entry()
    setproperty!(timeLimitEntry, :text, "0")
    global timeIncrementEntry = @Entry()
    setproperty!(timeIncrementEntry, :text, "0")
    global japaneseRoutletteButton = @CheckButton()
    global goFirstButton = @CheckButton() 
    global cheatingAllowedButton = @CheckButton()
    global startGameButton = @Button("Start Game")
    global colorCombo = @ComboBoxText()
    push!(colorCombo, "red")
    push!(colorCombo, "green")
    push!(colorCombo, "blue")
    setproperty!(colorCombo, :active, 0)

    global backButton = @Button("back")

    gameSettingsMenuPlayer[1,1] = gameTypesLabel
    gameSettingsMenuPlayer[1,2] = useTimeLimitLabel
    gameSettingsMenuPlayer[1,3] = timeLimitLabel
    gameSettingsMenuPlayer[1,4] = timeIncrementLabel
    gameSettingsMenuPlayer[1,5] = japaneseRouletteLabel
    gameSettingsMenuPlayer[1,6] = goFirstLabel
    gameSettingsMenuPlayer[1,7] = cheatingAllowedLabel
    gameSettingsMenuPlayer[1,8] = colorLabel

    gameSettingsMenuPlayer[2,1] = gameTypesCombo
    gameSettingsMenuPlayer[2,2] = useTimeLimitButton
    gameSettingsMenuPlayer[2,3] = timeLimitEntry
    gameSettingsMenuPlayer[2,4] = timeIncrementEntry
    gameSettingsMenuPlayer[2,5] = japaneseRoutletteButton
    gameSettingsMenuPlayer[2,6] = goFirstButton
    gameSettingsMenuPlayer[2,7] = cheatingAllowedButton
    gameSettingsMenuPlayer[2,8] = colorCombo

    gameSettingsMenuPlayer[1,9] = startGameButton
    gameSettingsMenuPlayer[2,9] = backButton

    push!(window, gameSettingsMenuPlayer)
end

function startGameAI_button_clicked_callback(widget)

    global gameType = lowercase(unsafe_string(convert(Ptr{UInt8}, G_.active_text(gameSettingsMenuAI[2,1]))))
    #println(gameType)
    global useTimeLimit = getproperty(gameSettingsMenuAI[2,2], :active, Bool)
    #println(useTimeLimit)
    if useTimeLimit
        global timeLimit = parse(Int64, getproperty(gameSettingsMenuAI[2,3], :text, String))
        global timeIncrement = parse(Int64, getproperty(gameSettingsMenuAI[2,4], :text, String))
    end
    global difficulty = unsafe_string(convert(Ptr{UInt8}, G_.active_text(gameSettingsMenuAI[2,5])))
    global japaneseRoulette = getproperty(gameSettingsMenuAI[2,6], :active, Bool)
    global goFirst = getproperty(gameSettingsMenuAI[2,7], :active, Bool)
    global cheatingAllowed = getproperty(gameSettingsMenuAI[2,8], :active, Bool)
    if cheatingAllowed
        cheatingAllowed = "T"
    else
        cheatingAllowed = "F"
    end
    global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(gameSettingsMenuAI[2,9])))

    #call game window here
    #println(typeof(string(gameType[1])))
    #println(typeof(timeLimit))
   # println(typeof(timeIncrement))
    #println(typeof(useTimeLimit))
    global flag = 1
    destroy(window)
    
end
function startGamePlayer_button_clicked_callback(widget)
    global gameType = lowercase(unsafe_string(convert(Ptr{UInt8}, G_.active_text(gameSettingsMenuPlayer[2,1]))))
    #println(gameType)
    global useTimeLimit = getproperty(gameSettingsMenuPlayer[2,2], :active, Bool)
    #println(useTimeLimit)
    if useTimeLimit
        global timeLimit = parse(Int64, getproperty(gameSettingsMenuPlayer[2,3], :text, String))
        global timeIncrement = parse(Int64, getproperty(gameSettingsMenuPlayer[2,4], :text, String))
    end
    global japaneseRoulette = getproperty(gameSettingsMenuPlayer[2,5], :active, Bool)
    global goFirst = getproperty(gameSettingsMenuPlayer[2,6], :active, Bool)
    global cheatingAllowed = getproperty(gameSettingsMenuPlayer[2,7], :active, Bool)  
    if cheatingAllowed
        cheatingAllowed = "T"
    else
        cheatingAllowed = "F"
    end
    global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(gameSettingsMenuPlayer[2,8])))

    #destroy(window)
    #call game window
        #run(`julia display_pvp.jl  $gameType $0 $0 $japaneseRoulette $goFirst $cheatingAllowed`)    
        global flag = 0
        destroy(window)
end


#if start button clicked, go to game modes
function start_button_clicked_callback(widget)
    delete!(window, startMenuFrame)


    global vsAIButton = @Button("VS AI")
    global vsPlayerButton = @Button("VS Player")
    global networkButton = @Button("Network")
    global backButton = @Button("Back")

    global gameModeMenu = @Box(:v)
    global gameModeMenuFrame = @Frame()

    push!(gameModeMenu, vsAIButton)
    push!(gameModeMenu, vsPlayerButton)
    push!(gameModeMenu, networkButton)
    push!(gameModeMenu, backButton)

    push!(gameModeMenuFrame, gameModeMenu)
    push!(window, gameModeMenuFrame)
    #setproperty!(gameModeMenu, :row_homogeneous, true)
    #setproperty!(gameModeMenu, :column_homogeneous, true)
    setproperty!(gameModeMenu,:spacing,30)
    showall(window)

    id = signal_connect(vsAI_button_clicked_callback, vsAIButton, "clicked")
    id = signal_connect(vsPlayer_button_clicked_callback, vsPlayerButton, "clicked")
    id = signal_connect(network_button_clicked_callback, networkButton, "clicked")
    id = signal_connect(backMain_button_clicked_callback, backButton, "clicked")
end

function backMain_button_clicked_callback(widget)
    delete!(window, gameModeMenuFrame)
    push!(window, startMenuFrame)
    showall(window)
end

function vsAI_button_clicked_callback(widget)
    delete!(window, gameModeMenuFrame)

    game_settings_menu_AI()

    #setproperty!(startMenu, :row_homogeneous, true)
    #setproperty!(startMenu, :column_homogeneous, true)
    setproperty!(gameSettingsMenuAI,:column_spacing,70)
    setproperty!(gameSettingsMenuAI,:row_spacing,20)

    showall(window)

    id = signal_connect(startGameAI_button_clicked_callback, startGameButton, "clicked")
    id = signal_connect(backGameModeAI_button_clicked_callback, backButton, "clicked")
end

function vsPlayer_button_clicked_callback(widget)
    delete!(window, gameModeMenuFrame)

    game_settings_menu_player()
    setproperty!(gameSettingsMenuPlayer,:column_spacing,70)
    setproperty!(gameSettingsMenuPlayer,:row_spacing,20)
    showall(window)

    id = signal_connect(startGamePlayer_button_clicked_callback, startGameButton, "clicked")
    id = signal_connect(backGameModePlayer_button_clicked_callback, backButton, "clicked")

end

function network_button_clicked_callback(widget)
    delete!(window, gameModeMenuFrame)

    global networkMenu = @Box(:v)
    global networkMenuFrame = @Frame()

    global joinButton = @Button("Join")
    global hostPlayerButton = @Button("Host Player")
    global backButton = @Button("Back")

    push!(networkMenu, joinButton)
    push!(networkMenu, hostPlayerButton)
    push!(networkMenu, backButton)

    setproperty!(networkMenu,:spacing,30)

    push!(networkMenuFrame, networkMenu)
    push!(window, networkMenuFrame)

    showall(window)

    id = signal_connect(join_button_clicked_callback, joinButton, "clicked")
    id = signal_connect(hostPlayer_button_clicked_callback, hostPlayerButton, "clicked")
    id = signal_connect(backGameModeNetwork_button_clicked_callback, backButton, "clicked")


end

function backGameModeAI_button_clicked_callback(widget)
    delete!(window, gameSettingsMenuAI)
    push!(window, gameModeMenuFrame)
    showall(window)
end
function backGameModePlayer_button_clicked_callback(widget)
    delete!(window, gameSettingsMenuPlayer)
    push!(window, gameModeMenuFrame)
    showall(window)
end
function backGameModeNetwork_button_clicked_callback(widget)
    delete!(window, networkMenuFrame)
    push!(window, gameModeMenuFrame)
    showall(window)
end

function join_button_clicked_callback(widget)
    delete!(window, networkMenuFrame)
    global joinMenu = @Grid()
    global joinMenuFrame = @Frame()

    global IPLabel = @Label("IP")
    global portLabel = @Label("port")
    global colorLabel = @Label("Select Background Color:")

    global IPEntry = @Entry()
    global portEntry = @Entry()
    global colorCombo = @ComboBoxText()
    push!(colorCombo, "red")
    push!(colorCombo, "green")
    push!(colorCombo, "blue")
    setproperty!(colorCombo, :active, 0)

    global joinStartButton = @Button("Start")
    global backButton = @Button("Back")

    joinMenu[1,1] = IPLabel
    joinMenu[1,2] = portLabel
    joinMenu[1,3] = colorLabel

    joinMenu[2,1] = IPEntry
    joinMenu[2,2] = portEntry
    joinMenu[2,3] = colorCombo

    joinMenu[1,4] = joinStartButton
    joinMenu[2,4] = backButton

    setproperty!(joinMenu,:column_spacing,70)
    setproperty!(joinMenu,:row_spacing,20)

    push!(joinMenuFrame, joinMenu)
    push!(window, joinMenuFrame)
    showall(window)

    id = signal_connect(joinStart_button_clicked_callback, joinStartButton, "clicked")
    id = signal_connect(backJoin_button_clicked_callback, backButton, "clicked")

end

function joinStart_button_clicked_callback(widget)
    #delete!(window,joinMenu)
    global ip = getproperty(joinMenu[2,1], :text, String)
    global port = parse(Int64,getproperty(joinMenu[2,2], :text, String))
    global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(joinMenu[2,3])))
    #get database?
    #call game frame here
    global flag = 6
    destroy(window)
end

function hostPlayer_button_clicked_callback(widget)
    delete!(window, networkMenuFrame)
    global hostGameMenu = @Grid()
    global hostGameMenuFrame = @Frame()

    portLabel = @Label("Port")
    databaseLabel = @Label("Game File:")

    startHostPlayerButton = @Button("Start")

    portEntry = @Entry()   

    global gameTypesLabel = @Label("gameTypes:")
    global useTimeLimitLabel = @Label("Use Time Limit:")
    global timeLimitLabel = @Label("Time Limit (0 for none):")
    global timeIncrementLabel = @Label("Time Increment (0 for none):")
    global japaneseRouletteLabel = @Label("Japanese Roulette mode:")
    global goFirstLabel = @Label("Player goes first:")
    global cheatingAllowedLabel =@Label("Allow AI to Cheat:")
    global colorLabel = @Label("Select Background Color:")

    global gameTypesCombo = @ComboBoxText()
    push!(gameTypesCombo, "Mini")
    push!(gameTypesCombo, "Standard")
    push!(gameTypesCombo, "Chu")
    push!(gameTypesCombo, "Tenjiku" )
    setproperty!(gameTypesCombo, :active, 0)
    global useTimeLimitButton = @CheckButton() 
    global timeLimitEntry = @Entry()
    setproperty!(timeLimitEntry, :text, 0)
    global timeIncrementEntry = @Entry()
    setproperty!(timeIncrementEntry, :text, 0)
    global japaneseRoutletteButton = @CheckButton()
    global goFirstButton = @CheckButton() 
    global cheatingAllowedButton = @CheckButton()
    global startGameButton = @Button("Start Game")
    global colorCombo = @ComboBoxText()
    push!(colorCombo, "red")
    push!(colorCombo, "green")
    push!(colorCombo, "blue")
    setproperty!(colorCombo, :active, 0)
    global backButton = @Button("Back")


    hostGameMenu[1,1] = gameTypesLabel
    hostGameMenu[1,2] = useTimeLimitLabel
    hostGameMenu[1,3] = timeLimitLabel
    hostGameMenu[1,4] = timeIncrementLabel
    hostGameMenu[1,5] = japaneseRouletteLabel
    hostGameMenu[1,6] = goFirstLabel
    hostGameMenu[1,7] = cheatingAllowedLabel
    hostGameMenu[1,8] = portLabel
    hostGameMenu[1,9] = colorLabel

    hostGameMenu[2,1] = gameTypesCombo
    hostGameMenu[2,2] = useTimeLimitButton
    hostGameMenu[2,3] = timeLimitEntry
    hostGameMenu[2,4] = timeIncrementEntry
    hostGameMenu[2,5] = japaneseRoutletteButton
    hostGameMenu[2,6] = goFirstButton
    hostGameMenu[2,7] = cheatingAllowedButton
    hostGameMenu[2,8] = portEntry
    hostGameMenu[2,9] = colorCombo

    hostGameMenu[1,10] = startHostPlayerButton
    hostGameMenu[2,10] = backButton

    setproperty!(hostGameMenu,:column_spacing,70)
    setproperty!(hostGameMenu,:row_spacing,20)

    push!(window, hostGameMenuFrame)
    push!(hostGameMenuFrame, hostGameMenu)
    showall(window)
    id = signal_connect(startHostPlayer_button_clicked_callback, startHostPlayerButton,"clicked")
    id = signal_connect(backHost_button_clicked_callback, backButton, "clicked")
end

function backJoin_button_clicked_callback(widget)
    delete!(window, joinMenuFrame)
    push!(window, networkMenuFrame)
    showall(window)
end
function backHost_button_clicked_callback(widget)
    delete!(window, hostGameMenuFrame)
    push!(window, networkMenuFrame)
    showall(window)
end
function startHostPlayer_button_clicked_callback(widget)
    global gameType = lowercase(unsafe_string(convert(Ptr{UInt8}, G_.active_text(hostGameMenu[2,1]))))
    #println(gameType)
    global useTimeLimit = getproperty(hostGameMenu[2,2], :active, Bool)
    #println(useTimeLimit)
    if useTimeLimit
        global timeLimit = parse(Int64, getproperty(hostGameMenu[2,3], :text, String))
        global timeIncrement = parse(Int64, getproperty(hostGameMenu[2,4], :text, String))
    end
    global japaneseRoulette = getproperty(hostGameMenu[2,5], :active, Bool)
    global goFirst = getproperty(hostGameMenu[2,6], :active, Bool)
    global cheatingAllowed = getproperty(hostGameMenu[2,7], :active, Bool)  
    if cheatingAllowed
        cheatingAllowed = "T"
    else
        cheatingAllowed = "F"
    end
    global port = getproperty(hostGameMenu[2,8],:text,String)
    global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(hostGameMenu[2,8])))
    #destroy(window)
    #call game window
        #run(`julia display_pvp.jl  $gameType $0 $0 $japaneseRoulette $goFirst $cheatingAllowed`)    
        global flag = 5
        destroy(window)
end

function database_button_clicked_callback(widget)
    #select game file 
    path = open_dialog("Pick game file")
    if path[end-2: end] == ".db" && length(path) > 0 
       #delete!(window, continueMenuFrame)
        global db = path
        #call game with database
        #showall(window)
    end
end


function continue_button_clicked_callback(widget)
    delete!(window, startMenuFrame)

    global localButton = @Button("Local Player Game")
    global localAIButton = @Button("Local AI Game")
    global emailButton = @Button("Play by Email")

    global continueMenu = @Box(:v)
    global continueMenuFrame = @Frame()

    global backButton = @Button("Back")

    push!(continueMenu, localButton)
    push!(continueMenu, localAIButton)
    push!(continueMenu, emailButton)
    push!(continueMenu, backButton)

    setproperty!(continueMenu,:spacing,30)

    push!(continueMenuFrame, continueMenu)
    push!(window, continueMenuFrame)

    showall(window)

    id = signal_connect(localAI_button_clicked_callback, localAIButton, "clicked")
    id = signal_connect(local_button_clicked_callback, localButton, "clicked")
    id = signal_connect(email_button_clicked_callback, emailButton, "clicked")
    id = signal_connect(backContinue_button_clicked_callback, backButton, "clicked")
end

function backContinue_button_clicked_callback(widget)
    delete!(window, continueMenuFrame)
    push!(window,startMenuFrame)
    showall(window)
end

function localAI_button_clicked_callback(widget)
    delete!(window, continueMenuFrame)

    global difficultyLabel = "Difficulty:"
    global databaseLabel = "Select Game File:"
    global colorLabel = "Select Background Color:"

    global difficultyCombo = @ComboBoxText()
    push!(difficultyCombo, "Normal")
    push!(difficultyCombo, "Hard")
    push!(difficultyCombo, "Suicidal")
    push!(difficultyCombo, "Protracted Death")
    push!(difficultyCombo, "Random")
    setproperty!(difficultyCombo, :active, 0)

    global AIDatabaseButton = @Button("Select File")
    global startAILocalGame = @Button("Start")
    global colorCombo = @ComboBoxText()
    push!(colorCombo, "red")
    push!(colorCombo, "green")
    push!(colorCombo, "blue")
    setproperty!(colorCombo, :active, 0)

    global backButton = @Button("Back")

    global localAIFrame = @Frame()
    global localAIMenu = @Grid()

    localAIMenu[1,1] = difficultyLabel
    localAIMenu[1,2] = databaseLabel
    localAIMenu[1,3] = colorLabel
    localAIMenu[1,4] = startAILocalGame

    localAIMenu[2,1] = difficultyCombo
    localAIMenu[2,2] = AIDatabaseButton
    localAIMenu[2,3] = colorCombo
    localAIMenu[2,4] = backButton

    setproperty!(localAIMenu,:column_spacing,70)
    setproperty!(localAIMenu,:row_spacing,20)

    push!(localAIFrame, localAIMenu)
    push!(window, localAIFrame)



    showall(window)

    id = signal_connect(AIDatabase_button_clicked_callback, AIDatabaseButton, "clicked")
    id = signal_connect(StartAILocalGame_button_clicked_callback, startAILocalGame, "clicked")
    id = signal_connect(backButtonLocalAI_button_clicked_callback, backButton, "clicked")

end

function backButtonLocalAI_button_clicked_callback(widget)
    delete!(window,localAIFrame)
    push!(window,continueMenuFrame)
    showall(window)
end

function AIDatabase_button_clicked_callback(widget)
        path = open_dialog("Pick game file")
    if path[end-2: end] == ".db" && length(path) > 0 
       #delete!(window, continueMenuFrame)
        global db = path
        #call game with database
        #showall(window)
    end
end

function StartAILocalGame_button_clicked_callback(widget)
        global difficulty = lowercase(unsafe_string(convert(Ptr{UInt8}, G_.active_text(localAIMenu[2,1]))))
        global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(localAIMenu[2,3])))

        global flag = 3
        destroy(window)
    end

function local_button_clicked_callback(widget)
    #select game file 
    path = open_dialog("Pick game file")
    if path[end-2: end] == ".db" && length(path) > 0 
        delete!(window, continueMenuFrame)
        global db = path
        #call game with database
        #global flag = 2

        #destroy(window)
        delete!(window, continueMenuFrame)
        global localGameMenuFrame = @Frame()
        global localGameMenu = @Grid()
        global colorLabel = @Label("Select Background Color:")
        global colorCombo = @ComboBoxText()
        push!(colorCombo, "red")
        push!(colorCombo, "green")
        push!(colorCombo, "blue")
        setproperty!(colorCombo, :active, 0)
        global startGameButton = @Button("Start")
        global backButton = @Button("Back")

        localGameMenu[1,1] = colorLabel
        localGameMenu[2,1] = colorCombo
        localGameMenu[1,2] = startGameButton
        localGameMenu[2,2] = backButton

        setproperty!(localGameMenu,:column_spacing,70)
        setproperty!(localGameMenu,:row_spacing,20)

        push!(localGameMenuFrame, localGameMenu)
        push!(window,localGameMenuFrame)
        showall(window)

        id = signal_connect(startLocalGame_button_clicked_callback, startGameButton, "clicked")
        id = signal_connect(backLocalGame_button_clicked_callback, backButton, "clicked")

    end
end

function startLocalGame_button_clicked_callback(widget)
    global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(localGameMenu[2,1])))

    global flag = 2

    destroy(window)
end

function backLocalGame_button_clicked_callback(widget)
    path = ""
    delete!(window,localGameMenuFrame)
    push!(window, continueMenuFrame)
    showall(window)
end

function email_button_clicked_callback(widget)
    #delete!(window, continueMenuFrame)
    #select game
    path = open_dialog("Pick game file")
    if path[end-2: end] == ".db"
        delete!(window, continueMenuFrame)
        global db = path

        #global flag = 4
        #destroy(window)
        delete!(window, continueMenuFrame)
        global db = path

        delete!(window, continueMenuFrame)
        global emailGameMenuFrame = @Frame()
        global emailGameMenu = @Grid()
        global colorLabel = @Label("Select Background Color:")
        global colorCombo = @ComboBoxText()
        push!(colorCombo, "red")
        push!(colorCombo, "green")
        push!(colorCombo, "blue")
        setproperty!(colorCombo, :active, 0)
        global startGameButton = @Button("Start")
        global backButton = @Button("Back")

        emailGameMenu[1,1] = colorLabel
        emailGameMenu[2,1] = colorCombo
        emailGameMenu[1,2] = startGameButton
        emailGameMenu[2,2] = backButton

        setproperty!(emailGameMenu,:column_spacing,70)
        setproperty!(emailGameMenu,:row_spacing,20) 

        push!(emailGameMenuFrame, emailGameMenu)
        push!(window,emailGameMenuFrame)
        showall(window)

        id = signal_connect(startEmailGame_button_clicked_callback, startGameButton, "clicked")
        id = signal_connect(backEmailGame_button_clicked_callback, backButton, "clicked")


    end
end

function startEmailGame_button_clicked_callback(widget)
    global flag = 4
    global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(emailGameMenu[2,1])))
    destroy(window)
end

function backEmailGame_button_clicked_callback(widget)
    path = ""
    delete!(window,emailGameMenuFrame)
    push!(window, continueMenuFrame)
    showall(window)
end

function replay_button_clicked_callback(widget)
    #delete!(window, startMenuFrame)
    #replay game here
     path = open_dialog("Pick game file")
    if path[end-2: end] == ".db"
        delete!(window, startMenuFrame)
        global db = SQLite.DB(path)   

        global replayGameMenuFrame = @Frame()
        global replayGameMenu = @Grid()
        global colorLabel = @Label("Select Background Color:")
        global colorCombo = @ComboBoxText()
        push!(colorCombo, "red")
        push!(colorCombo, "green")
        push!(colorCombo, "blue")
        setproperty!(colorCombo, :active, 0)
        global startGameButton = @Button("Start")
        global backButton = @Button("Back")

        replayGameMenu[1,1] = colorLabel
        replayGameMenu[2,1] = colorCombo
        replayGameMenu[1,2] = startGameButton
        replayGameMenu[2,2] = backButton

        setproperty!(replayGameMenu,:column_spacing,70)
        setproperty!(replayGameMenu,:row_spacing,20) 

        push!(replayGameMenuFrame, replayGameMenu)
        push!(window,replayGameMenuFrame)
        showall(window)

        id = signal_connect(replayGame_button_clicked_callback, startGameButton, "clicked")
        id = signal_connect(replayMenuBack_button_clicked_callback, backButton, "clicked")

        #replay_game(db)
    end
end

function replayGame_button_clicked_callback(widget)
    global color = unsafe_string(convert(Ptr{UInt8}, G_.active_text(replayGameMenu[2,1])))
    delete!(window, replayGameMenuFrame)
    replay_game(db)
end

function replayMenuBack_button_clicked_callback(widget)
    delete!(window, replayGameMenuFrame)
    push!(window, startMenuFrame)
    showall(window)
end

function displayGuiBoard(board, grid)
    global window
    emptyImage=joinpath(pwd(),"images",gameType, color,"left","empty.jpg")
    #println(board)
    for y in 1:length(board)
        for x in 1:length(board[1])
            destroy(grid[x,y])
            image = @Image()
            #println(isalpha(board[y][x].name))
            if isempty(board[y][x].name)
                setproperty!(image, :file, emptyImage)
            else
                setproperty!(image, :file, getImage(board[y][x]))            
            end
            grid[x,y]=image
        end
    end

    showall(window)

end

function movePieceGui(gameType::String, board::Array{Array{piece,1},1}, move_number, sourceX, sourceY, targetX, targetY, option, targetX2, targetY2, targetX3, targetY3)
    
    sourceX = Int64(get(sourceX))
    sourceY = Int64(get(sourceY))
    targetX = Int64(get(targetX))
    targetY = Int64(get(targetY)) 

    board[targetY][targetX] = board[sourceY][sourceX] # move piece at source to target, removing piece in process
    board[targetY][targetX].x = targetX # setting piece x
    board[targetY][targetX].y = targetY # setting piece y
    board[sourceY][sourceX] = empty #set source space to empty

    if !isnull(targetX2) && !isnull(targetY2)
        targetX2 = Int64(get(targetX2))
        targetY2 = Int64(get(targetY2))

        if targetX2 >= 1 && targetX2 <= length(board[1]) && targetY2 >= 1 && targetY2 <= length(board)

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

            board[targetY3][targetX3] = board[targetY2][targetX2] # move piece at source to target, removing piece in process
            board[targetY3][targetX3].x = targetX3 # setting piece x
            board[targetY3][targetX3].y = targetY3 # setting piece y
            board[targetY2][targetX2] = empty #set source space to empty
        end
    end

    if !isnull(option)  # promote piece
        if get(option) == "!"
            board[targetY][targetX] = promote(board[targetY][targetX], gameType)
            ##println  (board[targetY][targetX])
        end
    end
end

function replay_game(db) 
    global gameType
    metaTable, movesTable, gameType, seed, is_legal, is_timed = gameSetup(db)
    board,boardLength, numOfPromotionRanks = boardSetup(gameType)
    global boardArray = []

    initialBoard = duplicateBoard(board)
    push!(boardArray, initialBoard)
    global gameFrame = @Frame()
    global gameGrid = @Grid()

    push!(gameFrame, gameGrid)
    push!(window, gameFrame)

    emptyImage=joinpath(pwd(),"images","mini","left","empty.jpg")
    #set all pieces to empty
    for y in 1:boardLength
        for x in 1:boardLength
            image = @Image()
            setproperty!(image, :file, emptyImage)
            gameGrid[x,y]=image
        end
    end
    nextButton = @Button("Next")
    prevButton = @Button("Prev")
    gameGrid[boardLength+1,boardLength+1] = nextButton
    gameGrid[boardLength+1,boardLength+2] = prevButton

    #gameGrid[boardLength+1, boardLength] = quitButton

    #get all boards
    global currentMove = 1
    movesPlayed = length(movesTable[1])
    gameActive = true # flag for whether game has been resigned
    while currentMove < movesPlayed
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
            movePieceGui(gameType, board, currentMove, sourceX, sourceY, targetX, targetY, option, targetX2, targetY2, targetX3, targetY3)
            newBoard = duplicateBoard(board)
            push!(boardArray, newBoard)
        elseif moveType == "drop"
            dropPiece(board, currentMove, option, targetX, targetY)
            newBoard = duplicateBoard(board)
            push!(boardArray, newBoard)
        elseif moveType == "resign"
            break
        end
        
        currentMove += 1
    end
    
    displayGuiBoard(boardArray[currentMove], gameGrid)
    showall(window)
    #display most current board
    #have 2 buttons, forward and back
    #when click back, reload board with prev board, safe for forward

    id = signal_connect(next_button_clicked_callback, nextButton, "clicked")
    id = signal_connect(prev_button_clicked_callback, prevButton, "clicked")

end

function next_button_clicked_callback(widget)
    global currentMove
    #println("in next button. current move is: " ,currentMove)
    if currentMove < length(boardArray)
        currentMove = currentMove + 1
        displayGuiBoard(boardArray[currentMove], gameGrid)
    end
end   

function prev_button_clicked_callback(widget)
    global currentMove
    #println("in prev button. current move is: " ,currentMove)
    if currentMove > 1
        currentMove = currentMove - 1
        displayGuiBoard(boardArray[currentMove], gameGrid)
    end
end

function quit_button_clicked_callback(widget)
    destroy(window)
end

function help_button_clicked_callback(widget)
    delete!(window, startMenuFrame)
    resize!(window, 600,600)
    global helpMenu = @Grid()
    global helpMenuScroll = @ScrolledWindow()
    global helpMenuFrame = @Frame()

    global backButton = @Button("Back")
   #= global stepButton = @Button("Step Movement")
    global lineButton = @Button("Line Movement")
    global jumpButton = @Button("Jump Movement")
    global multipleButton = @Button("Multiple Movement")=#

    helpMenu[1,1] = backButton

    path=pwd()
    path=joinpath(path,"images")
    path=joinpath(path,"help")
    path = joinpath(path, "red")
    path=joinpath(path,"left")

    pawnImage = @Image()
    setproperty!(pawnImage, :file, joinpath(path,"pawn.jpg"))
    pawnLabel = @Label("steps forward")
    pawnName = @Label("Pawn:")

    dogImage = @Image()
    setproperty!(dogImage, :file, joinpath(path,"dog.jpg"))
    dogLabel = @Label("steps forward or diagonally backward")
    dogName = @Label("Dog:")

    cobraImage = @Image()
    setproperty!(cobraImage, :file, joinpath(path,"cobra.jpg"))
    cobraLabel = @Label("steps forward or backward")
    cobraName = @Label("Cobra:")

    knightImage = @Image()
    setproperty!(knightImage, :file, joinpath(path,"knight.jpg"))
    knightLabel = @Label("Has the two forward-most\nmoves of the Chess Knight")
    knightName = @Label("Knight:")

    ironImage = @Image()
    setproperty!(ironImage, :file, joinpath(path,"iron.jpg"))
    ironLabel = @Label("steps straight or disagonally forward")   
    ironName = @Label("Iron General:")

    copperImage = @Image()
    setproperty!(copperImage, :file, joinpath(path,"copper.jpg"))
    copperLabel = @Label("steps forward, backward or diagonally forward")   
    copperName = @Label("Copper General:")

    silverImage = @Image()
    setproperty!(silverImage, :file, joinpath(path,"silver.jpg"))
    silverLabel = @Label("steps in all 4 diagonal directions, or forward") 
    silverName = @Label("Silver General:")

    goldImage = @Image()
    setproperty!(goldImage, :file, joinpath(path,"gold.jpg"))
    goldLabel = @Label("steps in all 4 orthogonal directions, and diagonally forward")
    goldName = @Label("Gold General:")

    leopardImage = @Image()
    setproperty!(leopardImage, :file, joinpath(path,"leopard.jpg"))
    leopardLabel = @Label("steps forward, backward and in all 4 diagonal diretions") 
    leopardName = @Label("Ferocious Leopard:")

    tigerImage = @Image()
    setproperty!(tigerImage, :file, joinpath(path,"tiger.jpg"))
    tigerLabel = @Label("steps in all directions except forward") 
    tigerName = @Label("Blind Tiger:")

    elephantImage = @Image()
    setproperty!(elephantImage, :file, joinpath(path,"elephant.jpg"))
    elephantLabel = @Label("steps in all 8 directions except backward")
    elephantName = @Label("Drunken Elephant:")

    princeImage = @Image()
    setproperty!(princeImage, :file, joinpath(path,"elephantp.jpg"))
    princeLabel = @Label("steps in all 8 directions")
    princeName = @Label("Drunken Elephant:")

    kingImage = @Image()
    setproperty!(kingImage, :file, joinpath(path,"king.jpg"))
    kingLabel = @Label("steps in all 8 directions")
    kingName = @Label("King:")

    lanceImage = @Image()
    setproperty!(lanceImage, :file, joinpath(path,"lance.jpg"))
    lanceLabel = @Label("slides forward")
    lanceName = @Label("Lance:") 

    chariotImage = @Image()
    setproperty!(chariotImage, :file, joinpath(path,"chariot.jpg"))
    chariotLabel = @Label("slides forward or backward")
    chariotName = @Label("Reverse Chariot:") 

    smoverImage = @Image()
    setproperty!(smoverImage, :file, joinpath(path,"smover.jpg"))
    smoverLabel = @Label("steps forward or backward,\nslides orthogonally sideways") 
    smoverName = @Label("Side Mover:")

    vmoverImage = @Image()
    setproperty!(vmoverImage, :file, joinpath(path,"vmover.jpg"))
    vmoverLabel = @Label("steps orthogonally sideways,\nslides forward or backward") 
    vmoverName = @Label("Vertical Mover:")

    ssoldierImage = @Image()
    setproperty!(ssoldierImage, :file, joinpath(path,"ssoldier.jpg"))
    ssoldierLabel = @Label("steps one backward or two forward; slides sideways") 
    ssoldierName = @Label("Side Soldier:")

    vsoldierImage = @Image()
    setproperty!(vsoldierImage, :file, joinpath(path,"vsoldier.jpg"))
    vsoldierLabel = @Label("steps one backward or two sideways, slides forward") 
    vsoldierName = @Label("Vertical Soldier:")

    multiImage = @Image
    setproperty!(multiImage, :file, joinpath(path,"dogp.jpg"))
    multiLabel = @Label("Slides forward or diagonally backward") 
    multiName = @Label("Multi-General:")

    bishopImage = @Image()
    setproperty!(bishopImage, :file, joinpath(path,"bishop.jpg"))
    bishopLabel = @Label("slides in all 4 diagonal directions") 
    bishopName = @Label("Bishop:")
    
    rookImage = @Image()
    setproperty!(rookImage, :file, joinpath(path,"rook.jpg"))
    rookLabel = @Label("slides in all 4 orthogonal directions") 
    rookName = @Label("Rook:")   

    horseImage = @Image()
    setproperty!(horseImage, :file, joinpath(path,"horse.jpg"))
    horseLabel = @Label("slides diagonally, steps orthogonally") 
    horseName = @Label("Dragon Horse:")

    dragonImage = @Image()
    setproperty!(dragonImage, :file, joinpath(path,"dragon.jpg"))
    dragonLabel = @Label("slides orthogonally, steps diagonally") 
    dragonName = @Label("Dragon King:")

    buffaloImage = @Image()
    setproperty!(buffaloImage, :file, joinpath(path,"buffalo.jpg"))
    buffaloLabel = @Label("steps two forward or backward, slides sideways or diagonally") 
    buffaloName = @Label("Water Buffalo:")

    csoldierImage = @Image()
    setproperty!(csoldierImage, :file, joinpath(path,"csoldier.jpg"))
    csoldierLabel = @Label("Steps two sideways, slides forward, backward or diagonally") 
    csoldierName = @Label("Chariot Soldier:")

    stagImage = @Image()
    setproperty!(stagImage, :file, joinpath(path,"tigerp.jpg"))
    stagLabel = @Label("slides forward or backward,\nsteps sideway or along any diagonal") 
    stagName = @Label("Flying Stag:")

    whiteImage = @Image()
    setproperty!(whiteImage, :file, joinpath(path,"lancep.jpg"))
    whiteLabel = @Label("slides forward, backward,\nor diagonally forward") 
    whiteName = @Label("White Horse:")

    whaleImage = @Image()
    setproperty!(whaleImage, :file, joinpath(path,"chariotp.jpg"))
    whaleLabel = @Label("slides forward or backward,\nor diagonally backwards") 
    whaleName = @Label("Whale:")

    boarImage = @Image()
    setproperty!(boarImage, :file, joinpath(path,"smoverp.jpg"))
    boarLabel = @Label("slides along all 4 diagonals, and sideways") 
    boarName = @Label("Free Boar:")

    oxImage = @Image()
    setproperty!(oxImage, :file, joinpath(path,"vmoverp.jpg"))
    oxLabel = @Label("slides forward, backward and along all 4 diagonals") 
    oxName = @Label("Flying Ox:")

    queenImage = @Image()
    setproperty!(queenImage, :file, joinpath(path,"queen.jpg"))
    queenLabel = @Label("Slides in all 8 directions") 
    queenName = @Label("Queen:")

    phoenixImage = @Image()
    setproperty!(phoenixImage, :file, joinpath(path,"phoenix.jpg"))
    phoenixLabel = @Label("steps orthogonally, jumps 2 squares diagonally") 
    phoenixName = @Label("Phoenix:")

    kirinImage = @Image()
    setproperty!(kirinImage, :file, joinpath(path,"kirin.jpg"))
    kirinLabel = @Label("steps diagonally, jumps 2 squares orthogonally")
    kirinName = @Label("Kirin:")

    falconImage = @Image()
    setproperty!(falconImage, :file, joinpath(path,"falcon.jpg"))
    falconLabel = @Label("Double (step-)moves along forward ray,\nslides in 7 other directions")
    falconName = @Label("Horned Falcon:")

    soaringImage = @Image()
    setproperty!(soaringImage, :file, joinpath(path,"soaring.jpg"))
    soaringLabel = @Label("Double (step-)moves along forward diagonals,\n slides in 6 other directions")
    soaringName = @Label("Soaring Eagle:")

    eagleImage = @Image()
    setproperty!(eagleImage, :file, joinpath(path,"eagle.jpg"))
    eagleLabel = @Label("slides in all 8 directions,\nor can make a double-move of two diagonal steps")
    eagleName = @Label("Free Eagle:")   

    lionImage = @Image()
    setproperty!(lionImage, :file, joinpath(path,"lion.jpg"))
    lionLabel = @Label("Makes 2 King moves per turn,\nor steps/jumps to any square in that reach.")
    lionName = @Label("Lion:")    

    hawkImage = @Image()
    setproperty!(hawkImage, :file, joinpath(path,"hawk.jpg"))
    hawkLabel = @Label("Moves as Lion or Bishop")
    hawkName = @Label("Lion Hawk:")  

    bgeneralImage = @Image()
    setproperty!(bgeneralImage, :file, joinpath(path,"bgeneral.jpg"))
    bgeneralLabel = @Label("Slides diagonally, and can jump any number of pieces when capturing")
    bgeneralName = @Label("Bishop General:")  

    rgeneralImage = @Image()
    setproperty!(rgeneralImage, :file, joinpath(path,"rgeneral.jpg"))
    rgeneralLabel = @Label("Slides orthogonally, and can jump any number of pieces when capturing")
    rgeneralName = @Label("Rook General:")    

    viceImage = @Image()
    setproperty!(viceImage, :file, joinpath(path,"vice.jpg"))
    viceLabel = @Label("Moves as Bishop General, or can do a 3-step area move")
    viceName = @Label("Vice General:")    

    greatImage = @Image()
    setproperty!(greatImage, :file, joinpath(path,"great.jpg"))
    greatLabel = @Label("Slides in all 8 directions, can jump any number of pieces when capturing.")
    greatName = @Label("Great General:")   

    demonImage = @Image()
    setproperty!(demonImage, :file, joinpath(path,"demon.jpg"))
    demonLabel = @Label("Slides forward, backward and diagonally;\n3-step area move; Burns around Demon")
    demonName = @Label("Fire Demon") 

    #helpMenuStep[4,2] = backButton
    labelArray = [pawnLabel
                ,dogLabel
                ,cobraLabel
                ,knightLabel
                ,ironLabel
                ,copperLabel
                ,silverLabel
                ,goldLabel
                ,leopardLabel
                ,tigerLabel
                ,elephantLabel
                ,princeLabel
                ,kingLabel
                ,lanceLabel
                ,chariotLabel
                ,smoverLabel
                ,vmoverLabel
                ,ssoldierLabel
                ,vsoldierLabel
                ,multiLabel
                ,bishopLabel
                ,rookLabel
                ,horseLabel
                ,dragonLabel
                ,buffaloLabel
                ,csoldierLabel
                ,stagLabel
                ,whiteLabel
                ,whaleLabel
                ,boarLabel
                ,oxLabel
                ,queenLabel
                ,phoenixLabel
                ,kirinLabel
                ,falconLabel
                ,soaringLabel
                ,eagleLabel
                ,lionLabel
                ,hawkLabel
                ,bgeneralLabel
                ,rgeneralLabel
                ,viceLabel
                ,greatLabel
                ,demonLabel
]
    imageArray = [pawnImage
                ,dogImage
                ,cobraImage
                ,knightImage
                ,ironImage
                ,copperImage
                ,silverImage
                ,goldImage
                ,leopardImage
                ,tigerImage
                ,elephantImage
                ,princeImage
                ,kingImage
                ,lanceImage
                ,chariotImage
                ,smoverImage
                ,vmoverImage
                ,ssoldierImage
                ,vsoldierImage
                ,multiImage
                ,bishopImage
                ,rookImage
                ,horseImage
                ,dragonImage
                ,buffaloImage
                ,csoldierImage
                ,stagImage
                ,whiteImage
                ,whaleImage
                ,boarImage
                ,oxImage
                ,queenImage
                ,phoenixImage
                ,kirinImage
                ,falconImage
                ,soaringImage
                ,eagleImage
                ,lionImage
                ,hawkImage
                ,bgeneralImage
                ,rgeneralImage
                ,viceImage
                ,greatImage
                ,demonImage
    ]
    nameArray = [pawnName
                ,dogName
                ,cobraName
                ,knightName
                ,ironName
                ,copperName
                ,silverName
                ,goldName
                ,leopardName
                ,tigerName
                ,elephantName
                ,princeName
                ,kingName
                ,lanceName
                ,chariotName
                ,smoverName
                ,vmoverName
                ,ssoldierName
                ,vsoldierName
                ,multiName
                ,bishopName
                ,rookName
                ,horseName
                ,dragonName
                ,buffaloName
                ,csoldierName
                ,stagName
                ,whiteName
                ,whaleName
                ,boarName
                ,oxName
                ,queenName
                ,phoenixName
                ,kirinName
                ,falconName
                ,soaringName
                ,eagleName
                ,lionName
                ,hawkName
                ,bgeneralName
                ,rgeneralName
                ,viceName
                ,greatName
                ,demonName
    ]
    i = 2
    for name in nameArray
        helpMenu[1,i] = name
        i = i+1
    end
    i=2
    for image in imageArray
        helpMenu[2,i] = image
        i = i+1
    end
    i=2
    for label in labelArray
        helpMenu[3,i] = label
        i = i+1
    end
    setproperty!(helpMenu,:column_spacing,10)
    setproperty!(helpMenu,:row_spacing,20) 

    push!(helpMenuScroll, helpMenu)
    push!(helpMenuFrame, helpMenuScroll)
    push!(window, helpMenuFrame)
    showall(window)

    id = signal_connect(backHelp_button_clicked_callback, backButton, "clicked")

end

function backHelp_button_clicked_callback(widget)
    delete!(window, helpMenuFrame)
    push!(window, startMenuFrame)
    resize!(window, 400,300)
    showall(window)
end

function quickStart_button_clicked_callback(widget)
    destroy(window)
    global flag = 1
end

global startMenu = @Grid()

global window = @Window("Shogi by null_ptr",400,300)
global startMenuFrame = @Frame()
global titleLabel = @Label("Shogi")
global spacingLabel = @Label("_____________________________________________________________")
global titleImage = @Image()
path=pwd()
path=joinpath(path,"images")
path=joinpath(path,"title.png")
setproperty!(titleImage,:file,path )

global startButton = @Button("Start")
global quitButton = @Button("Quit")
global continueButton = @Button("Continue")
global replayButton = @Button("Replay")
global helpButton = @Button("Help")
global quickStartButton = @Button("Quick Start")

#=push!(startMenu, titleLabel)
push!(startMenu, startButton)
push!(startMenu, continueButton)
push!(startMenu, replayButton)
push!(startMenu, quitButton)=#

#startMenu[1,1] = titleLabel
startMenu[1,1] = titleImage
#startMenu[1,2] = spacingLabel


#startMenu[1,1] = titleLabel
startMenu[1,2] = startButton
startMenu[1,3] = continueButton
startMenu[1,4] = replayButton
startMenu[1,5] = helpButton
startMenu[1,6] = quickStartButton
startMenu[1,7] = quitButton
#setproperty!(startMenu, :row_homogeneous, true)
#setproperty!(startMenu, :column_homogeneous, true)
setproperty!(startMenu,:row_spacing,20)


push!(startMenuFrame, startMenu)
push!(window, startMenuFrame)



showall(window)

#if start button was clicked
id = signal_connect(start_button_clicked_callback, startButton, "clicked")
id = signal_connect(continue_button_clicked_callback, continueButton, "clicked")
id = signal_connect(replay_button_clicked_callback, replayButton, "clicked")
id = signal_connect(quit_button_clicked_callback, quitButton, "clicked")
id = signal_connect(help_button_clicked_callback, helpButton, "clicked")
id = signal_connect(quickStart_button_clicked_callback, quickStartButton, "clicked")
# Put your GUI code here
#run(`julia display_pvp.jl  $gameType $0 $0 $japaneseRoulette $goFirst $cheatingAllowed`)    

if flag == 0
    destroy(window)
    run(`julia display_pvp.jl  $gameType $0 $0 $japaneseRoulette $goFirst $cheatingAllowed`)    
end

if !isinteractive()
    c = Condition()
    signal_connect(window, :destroy) do widget

        notify(c)
    end
    wait(c)

end

println(gameType)
println(useTimeLimit)
println(timeLimit)
println(timeIncrement)
println(difficulty)
println(japaneseRoulette)
println(goFirst)
println(cheatingAllowed)
println(db)
println(ip)
println(port)



if difficulty=="normal"
        include("move_normal.jl")
    elseif difficulty=="hard"
        include("move_hard.jl")
    elseif difficulty=="protracted"
        include("move_protracted")
    elseif difficulty=="suicidal"
        include("move_suicidal.jl")
    else 
        include("move_random.jl")
end

if flag ==  0   
    #run(`julia display_pvp.jl  $gameType $timeLimit $timeIncrement $japaneseRoulette $goFirst $cheatingAllowed`)
    include("display_pvp.jl")  
    display_pvp(gameType,timeLimit,timeIncrement,japaneseRoulette,goFirst,cheatingAllowed,color)
elseif flag == 1
    include("display_ai.jl")
    display_ai(gameType,timeLimit,timeIncrement,japaneseRoulette,goFirst,cheatingAllowed,difficulty,color)
elseif flag == 2
    include("display_load_pvp.jl")
    display_load_pvp(db,color)
elseif flag == 3
    include("display_load_ai.jl")
    display_load_ai(db,difficulty,color)
elseif flag == 4
    include("display_email")
    display_email(db,color)
elseif flag == 5
    println("FLAG IS: ", flag)
    include("sever.jl")
    include("client.jl")
    @async begin
        client_host(port,gameType ,timeLimit,timeIncrement,japaneseRoulette,cheatingAllowed,color)
    end
    server(port)
elseif flag == 6
    include("client_join.jl")
    client_join(port,ip,color)
end


