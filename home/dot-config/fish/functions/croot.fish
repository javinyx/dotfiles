function croot --description 'Enter the root of the current Git repository'
    set -l root (command git rev-parse --show-toplevel 2>/dev/null)
    or begin
        echo 'croot: not inside a Git repository' >&2
        return 1
    end

    cd -- $root
end
