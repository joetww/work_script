#!/bin/sh
WNAME="work"
if ! tmux attach-session -t ${WNAME}; then
    tmux new-session -d -s ${WNAME} -n 'irssi' 'irssi'
    tmux split-window -t ${WNAME} -h -l 20 'cat ~/.irssi/nicklistfifo'
    tmux select-pane -t irssi.0 
    tmux send-keys -t irssi "/nicklist fifo" C-m
    tmux new-window
    tmux select-window -t irssi
    ${0}
fi
