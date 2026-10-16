# OrbStack appends this to config.fish on first run. Managed here instead, so
# config.fish stays limited to environment variables: config.fish is a link into
# the dotfiles repository, so the line OrbStack appends shows up there to be
# discarded. Guarded for machines without OrbStack installed.
if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish
end
