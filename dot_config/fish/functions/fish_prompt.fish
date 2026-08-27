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

    set_color cyan
    printf '%s' "$display_path"

    set -l branch (command git branch --show-current 2>/dev/null)
    if test -n "$branch"
        set_color brblack
        printf ' %s' "$branch"
    end

    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end

    printf ' ❯ '
    set_color normal
end
