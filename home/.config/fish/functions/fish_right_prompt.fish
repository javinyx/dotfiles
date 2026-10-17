function fish_right_prompt
    set -l last_status $status
    set -l message

    switch $last_status
        case 0
            if test $CMD_DURATION -ge 2000
                set message "It's super effective!"
            end
        case 130
            set message 'Got away safely!'
        case 127
            set message 'A wild typo appeared!'
        case '*'
            set message "But it failed! ($last_status)"
    end

    if test -z "$message"
        return
    end

    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end
    printf '%s' $message

    if test $CMD_DURATION -ge 2000
        set_color brblack
        printf ' %ss' (math --scale=1 $CMD_DURATION / 1000)
    end
    set_color normal
end
