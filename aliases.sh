# Some useful aliases

## ls
alias l='ls -CF'
alias lh='ls -lhGgo'
alias ll='ls -lh'
alias la='ls -A'
alias lS='ls -lhS'
alias lt='lh -tr'
alias l1='ls -1'

## System utilities
alias les='less -S'
alias c='clear'
alias cf='grep -c ">"'
alias r="source ~/.bashrc; history -n"
alias eb="vim ~/.bashrc"
alias hn="history -n"
alias R="R -q --no-save"
alias p='pwd'
alias sp='clear;du -sch * 2>/dev/null | sort -h'

alias lo="logout"
alias qlo="logout"

alias mtop='top -u $USER -d 1 -o %MEM'
alias ctop='top -u $USER -d 1 -o %CPU'

alias u='cd ..; clear; pwd; ls -lhGgo'
alias d="clear; cd -; ls -lhGgo"
