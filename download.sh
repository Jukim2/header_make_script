git clone git@github.com:Jukim2/header_make_script.git

mv header_make_script/header_make.sh $HOME
rm -rf header_make_script

RC_FILE="$HOME/.zshrc"

if [ "$(uname)" != "Darwin" ]; then
	RC_FILE="$HOME/.bashrc"
	if [[ -f "$HOME/.zshrc" ]]; then
		RC_FILE="$HOME/.zshrc"
	fi
fi

if !cat $RC_FILE | grep 'header_make.sh'; then
	echo -e "\nalias ham=\"bash $HOME/header_make.sh\"" >> "$RC_FILE"
fi
