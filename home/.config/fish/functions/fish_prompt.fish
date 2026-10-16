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

    set_color --bold 87b98d
    printf '  %s' "$display_path"

    set -l branch (command git branch --show-current 2>/dev/null)
    if test -n "$branch"
        set_color 7ca6c9
        printf '   %s' "$branch"

        if test -n "$(command git status --porcelain 2>/dev/null)"
            set_color e06c75
            printf ' •'
        end
    end

    printf '\n'

    if test $last_status -eq 0
        set_color --bold 87b98d
        printf '❯ '
    else
        set_color --bold e06c75
        printf '× %d ❯ ' $last_status
    end

    set_color normal
end
