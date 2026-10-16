# The mise.run installer puts mise in ~/.local/bin, which nothing else adds to
# PATH. Interactive shells get full activation; scripts and editor-spawned
# shells get shims, which pick the version per invocation instead of freezing
# the environment of the directory the shell started in.
fish_add_path -g ~/.local/bin
if status is-interactive
    mise activate fish | source
else
    mise activate fish --shims | source
end
