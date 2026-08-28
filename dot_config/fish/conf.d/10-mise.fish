# mise provides the global Node.js, JDK, and Python runtimes. Without activation
# they are installed but never reach PATH. Guarded so that a fish session opened
# before Homebrew has installed mise does not error on every prompt.
if command -q mise
    mise activate fish | source
end
