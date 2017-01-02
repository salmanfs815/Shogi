import DataFrames
import SQLite

include("types.jl")

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

################
### MAIN WIN ###
################
#=
i =1

for i in 1:movesPlayed

    #decisive=false
    counts=[]
    prevBoard=0
    allBoards=[]

    #CHECK FOR A RESIGN
    if moveType=="resign"
        #decisive=true
        if side==0
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


    
    #CHECK FOR A SAME BOARD POSITION
    if findBoard(board, allBoards)>0
        counts[findBoard(board)]+=1
    end

   
    #CHECK DRAW
    for count in counts
        if count == 4 && samePiecesCaptured() 
            #decisive = true
            #println("D")
            return "D"
        end
    end=#
    #=if decisive==true
        return
    end
    counter = 0

    #CHECK IF KING IS KILLED
    if board[targety][targetx].name=="king" || board[targety][targetx].name=="prince"
        counter+=1
    end    

    if targetx2 != -1 && targety2 != -1
        if board[targety2][targetx2].name=="king" || board[targety2][targetx2].name=="prince"
            counter+=1
        end
    end

    if targetx3 != -1 && targety3 != -1
        if board[targety3][targetx3].name=="king" || board[targety3][targetx3].name=="prince"
            counter+=1
        end
    end

    if counter == 2
        #decisive=true
        if side == 0 #White wins
            #println('W')
            return "W"
        else
            #println('B')
            return "B"
        end
        return
    end
    prevBoard=duplicateBoard(board)
    push!(allBoards,prevBoard)
    push!(counts,1)
    #if moveType=="move" 
        #sourcex= movesTable[3][i]
        #sourcey = movesTable[4][i]
        #if !isnull(targetx2) && !isnull(t)
        #movePiece(board, i, sourcex, sourcey, move_targetx, move_targety, option, targetx2, targety2)
    #end
    return "?"
end
#println(decisive)
#if !decisive
#    println("?")
#end
#displayBoard(board)
#displayBoard(prevBoard)
=#
