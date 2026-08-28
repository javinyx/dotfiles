function fish_right_prompt --description 'Show how long the last command took, once it is slow enough to care'
    if test $CMD_DURATION -lt 2000
        return
    end

    set -l seconds (math --scale=1 $CMD_DURATION / 1000)

    set_color brblack
    printf '%ss' $seconds
    set_color normal
end
