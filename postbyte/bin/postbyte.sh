#!/bin/sh

tmux new -d -s postbyte -n postbyte
tmux send-keys -t postbyte:1.1 "cd ~/Projects/postbyte" C-m
tmux split-window -h
tmux send-keys -t postbyte:1.2 "cd ~/Projects/postbyte && mts" C-m
tmux split-window -h
tmux send-keys -t postbyte:1.3 "cd ~/Projects/postbyte" C-m
tmux split-window -h
tmux send-keys -t postbyte:1.4 "cd ~/Projects/postbyte" C-m
tmux select-layout main-horizontal

tmux new-window
tmux select-window -t 2
tmux send-keys -t postbyte:2.1 "cd ~/Projects/postbyte-backend" C-m
tmux split-window -h
tmux send-keys -t postbyte:2.2 "cd ~/Projects/postbyte-backend && mts" C-m
tmux split-window -h
tmux send-keys -t postbyte:2.3 "cd ~/Projects/postbyte-backend" C-m
tmux split-window -h
tmux send-keys -t postbyte:2.4 "cd ~/Projects/postbyte-backend" C-m
tmux select-layout main-horizontal

tmux at -t postbyte
