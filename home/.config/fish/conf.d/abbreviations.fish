abbr --add --global ls 'eza --icons=auto --group-directories-first'
abbr --add --global ll 'eza --long --all --header --git --icons=auto --group-directories-first'
abbr --add --global lt 'eza --tree --level=2 --icons=auto --group-directories-first'

abbr --add --global g git
abbr --add --global gs 'git status --short --branch'
abbr --add --global ga 'git add'
abbr --add --global gc 'git commit'
abbr --add --global gca 'git commit --amend'
abbr --add --global gp 'git push'
abbr --add --global gpf 'git push --force-with-lease'
abbr --add --global gcapf 'git commit --amend --no-edit && git push --force-with-lease'
abbr --add --global gl 'git pull'
abbr --add --global gd 'git diff'
abbr --add --global grsu 'git remote set-url origin'

abbr --add --global c code
abbr --add --global lg lazygit
abbr --add --global bu 'mise bootstrap packages upgrade && mise upgrade'
