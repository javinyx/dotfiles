# OrbStack appends this to config.fish on first run. Managed here instead, so
# that chezmoi apply does not revert it and config.fish stays limited to
# environment variables. Guarded for machines without OrbStack installed.
if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish
end
