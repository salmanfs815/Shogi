import DataFrames
import SQLite

Base.eval(:(have_color = true))
include("validate_alone.jl")
#include("move.jl")

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

##############
#### MAIN ####
##############

#=#sets initial board and boardLength

gameFile = SQLite.DB(ARGS[1])
metaTable, movesTable, gameType, seed, is_legal, is_timed = gameSetup(gameFile)
oldBoard, boardLength, numOfPromotionRanks = boardSetup(gameType)
board, capturedByEven, capturedByOdd, gameActive = updateBoard(oldBoard, movesTable)

amove = move(1,"move", 8, 1, 9, 1, "", false, -1, -1, -1, -1)

if validate(board, amove, capturedByOdd, capturedByEven)
    println("valid move") #debugging
else 
    println("cheater") #debugging
end
=#


#=
println(elephant_black(board, sourcex, sourcey, targetx, targety))
println(elephant_white(board, sourcex, sourcey, targetx, targety))
println(pawn_black(board, sourcex, sourcey, targetx, targety))
println(pawn_white(board, sourcex, sourcey, targetx, targety))
println(gold_black(board, sourcex, sourcey, targetx, targety))
println(gold_white(board, sourcex, sourcey, targetx, targety))
println(side_mover(board, sourcex, sourcey, targetx, targety))
println(p_side_mover(board, sourcex, sourcey, targetx, targety))
println(vertical_mover(board, sourcex, sourcey, targetx, targety))
println(p_vertical_mover(board, sourcex, sourcey, targetx, targety))
println(bishop(board, sourcex, sourcey, targetx, targety))
println(dragon_horse(board, sourcex, sourcey, targetx, targety))
println(rook(board, sourcex, sourcey, targetx, targety))
println(dragon_king(board, sourcex, sourcey, targetx, targety))
println(falcon_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2))
println(falcon_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2))
println(soaring_black(board, sourcex, sourcey, targetx, targety, targetx2, targety2))
println(soaring_white(board, sourcex, sourcey, targetx, targety, targetx2, targety2))
println(lance_black(board, sourcex, sourcey, targetx, targety))
println(lance_white(board, sourcex, sourcey, targetx, targety))
println(p_lance_black(board, sourcex, sourcey, targetx, targety))
println(p_lance_white(board, sourcex, sourcey, targetx, targety))
println(chariot(board, sourcex, sourcey, targetx, targety))
println(p_chariot_black(board, sourcex, sourcey, targetx, targety))
println(p_chariot_white(board, sourcex, sourcey, targetx, targety))
println(tiger_black(board, sourcex, sourcey, targetx, targety))
println(tiger_white(board, sourcex, sourcey, targetx, targety))
println(p_tiger(board, sourcex, sourcey, targetx, targety))
println(leopard(board, sourcex, sourcey, targetx, targety))
println(copper_black(board, sourcex, sourcey, targetx, targety))
println(copper_white(board, sourcex, sourcey, targetx, targety))
println(silver_black(board, sourcex, sourcey, targetx, targety))
println(silver_white(board, sourcex, sourcey, targetx, targety))
println(king(board, sourcex, sourcey, targetx, targety))
println(kirin(board, sourcex, sourcey, targetx, targety))
println(lion(board, sourcex, sourcey, targetx, targety, targetx2, targety2))
println(phoenix(board, sourcex, sourcey, targetx, targety))
println(queen(board, sourcex, sourcey, targetx, targety))
println(knight_black(board, sourcex, sourcey, targetx, targety))
println(knight_white(board, sourcex, sourcey, targetx, targety))
println(prince(board, sourcex, sourcey, targetx, targety))
println(vice(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3))
println(great(board, sourcex, sourcey, targetx, targety))
println(bgeneral(board, sourcex, sourcey, targetx, targety))
println(rgeneral(board, sourcex, sourcey, targetx, targety))
println(demon(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3))
println(tetrarch(board, sourcex, sourcey, targetx, targety, targetx2, targety2, targetx3, targety3))
println(buffalo(board, sourcex, sourcey, targetx, targety))
println(csoldier(board, sourcex, sourcey, targetx, targety))
println(ssoldier_black(board, sourcex, sourcey, targetx, targety))
println(ssoldier_white(board, sourcex, sourcey, targetx, targety))
println(vsoldier_black(board, sourcex, sourcey, targetx, targety))
println(vsoldier_white(board, sourcex, sourcey, targetx, targety))
println(iron_black(board, sourcex, sourcey, targetx, targety))
println(iron_white(board, sourcex, sourcey, targetx, targety))
println(eagle(board, sourcex, sourcey, targetx, targety, targetx2, targety2))
println(hawk(board, sourcex, sourcey, targetx, targety, targetx2, targety2))
println(multi_black(board, sourcex, sourcey, targetx, targety))
println(multi_white(board, sourcex, sourcey, targetx, targety))
println(dog_black(board, sourcex, sourcey, targetx, targety))
println(dog_white(board, sourcex, sourcey, targetx, targety))

    return false=#

