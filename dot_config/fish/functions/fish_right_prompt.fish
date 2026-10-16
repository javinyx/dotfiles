function fish_right_prompt
    if test $CMD_DURATION -lt 2000
        return
    end

    set -l seconds (math --scale=1 $CMD_DURATION / 1000)

    set_color 606861
    printf ' %ss' $seconds
    set_color normal
end
