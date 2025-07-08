function bu
  brew uninstall $argv[1]

  if [ $status -eq 0 ]
    echo "✔️  Successfully uninstalled $argv[1]"
    brew bundle dump --file=$BREWFILE_PATH --force --no-vscode
  end
end