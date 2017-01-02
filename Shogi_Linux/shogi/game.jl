using Gtk.ShortNames, Graphics
import DataFrames
import SQLite
#include("display_pvp.jl")

include("game_init.jl")
include("types.jl")
include("move_helpers.jl")

Base.eval(:(have_color=true))


#N=boardLen

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

gameType = lowercase(gameType)
difficulty = lowercase(difficulty)

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


