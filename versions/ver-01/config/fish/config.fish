if status is-interactive
    # Commands to run in interactive sessions can go here
end
#oh-my-posh init fish --config /usr/share/oh-my-posh/themes/easy-term.omp.json | source
oh-my-posh init fish --config /usr/share/oh-my-posh/themes/jandedobbeleer.omp.json | source
#oh-my-posh init fish --config /usr/share/oh-my-posh/themes/remk.omp.json | source

set -U fish_greeting ""
alias ll "ls -lh"
alias l "ls -lha"
alias cp "cp -i"
alias mv "mv -i"
alias rm "rm -i"
alias vi "vim"
alias du "du -h"
alias df "df -h"

# opencode
fish_add_path /home/nkv/.opencode/bin


# Added by Antigravity CLI installer
set -gx PATH "/home/nkv/.local/bin" $PATH
