function fish_greeting
    set -l trainer (string upper $USER)
    set -l messages \
        "A wild TERMINAL appeared!" \
        "$trainer wants to ship something!" \
        "Your POKéMON are fully healed. Good luck!" \
        "PROF. BIRCH: A fine day for a commit!" \
        "A wild BUG is hiding in the tall grass..." \
        "Welcome back to HOENN, $trainer!" \
        "The tests look super effective today." \
        "$trainer used GIT PULL! It's up to date."
    set -l message $messages[(random 1 (count $messages))]

    set -l width (math (string length --visible -- $message) + 4)
    set -l blank (string repeat --count (math $width - 3) ' ')

    set_color brwhite
    string repeat --count $width ▄
    set_color black --background=brwhite
    printf '  %s  ' $message
    set_color normal
    printf '\n'
    set_color black --background=brwhite
    printf '%s' $blank
    set_color red --background=brwhite
    printf '▼  '
    set_color normal
    printf '\n'
    set_color brwhite
    string repeat --count $width ▀
    set_color normal
end
