function mkcd --description 'Create a directory and enter it'
    if test (count $argv) -ne 1
        echo 'usage: mkcd DIRECTORY' >&2
        return 2
    end

    mkdir -p -- $argv[1]; and cd -- $argv[1]
end
