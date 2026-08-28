# Homebrew is not on PATH in a fresh fish session, and the /etc/paths.d entry
# macOS reads appends it after /usr/bin, so brew formulae cannot shadow the
# system copies. brew shellenv moves its bin directories to the front and sets
# HOMEBREW_PREFIX, MANPATH, and INFOPATH.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -x /usr/local/bin/brew
    /usr/local/bin/brew shellenv fish | source
end
