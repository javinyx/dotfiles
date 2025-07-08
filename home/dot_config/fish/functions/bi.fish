function bi
  brew install $argv[1]

  if [ $status -eq 0 ]
    echo "✔️  Successfully installed $argv[1]"
    brew bundle dump --force --no-vscode
  end
end