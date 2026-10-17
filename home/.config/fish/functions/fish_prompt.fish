function fish_prompt
    set -l last_status $status
    set -l display_path
    set -l projects_dir "$HOME/Projects"

    if string match --quiet "$projects_dir/*" "$PWD"
        set display_path (string replace "$projects_dir/" "" "$PWD")
    else if test "$PWD" = "$projects_dir"
        set display_path .
    else
        set display_path (prompt_pwd)
    end

    set_color red
    printf '󰐝  '
    set_color --bold green
    printf '%s' "$display_path"
    set_color normal

    set -l branch (command git branch --show-current 2>/dev/null)
    if test -n "$branch"
        set_color blue
        printf '   %s' "$branch"

        if test -n "$(command git status --porcelain 2>/dev/null)"
            set_color yellow
            printf ' •'
        end
    end

    printf '\n'

    if test $last_status -eq 0
        set_color --bold normal
    else
        set_color --bold red
    end
    printf '► '

    set_color normal
end
