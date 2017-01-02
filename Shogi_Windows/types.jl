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

