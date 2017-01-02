using Gtk.ShortNames, Graphics
using DataFrames
using SQLite

include("game_init.jl")
include("move.jl")
include("game_init.jl")
include("validate_alone.jl")
include("types.jl")
include("win.jl")
include("move_helpers.jl")

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
            try
                signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],(id2Arr[a][1]))
            catch e
                signal_handler_block(grid[id2Arr[a][2],id2Arr[a][3]],Int64(id2Arr[a][1]))
            end
        end
    end
    for b in 1:length(idArr)
        if idArr[b][1]!=0
            try
                signal_handler_block(grid[idArr[b][2],idArr[b][3]],(idArr[b][1]))
            catch e
                signal_handler_block(grid[idArr[b][2],idArr[b][3]],Int64(idArr[b][1]))
            end
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