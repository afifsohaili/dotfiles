#!/bin/sh

tmux new -d -s ProjekIhsan -n development
tmux split-window -v
tmux select-pane -t 2
tmux send-keys "cd ~/Projects/meteor/projekihsan && meteor run -p 7000 --settings server/environments/local.json" C-m
tmux split-window -h
tmux select-pane -t 3
tmux send-keys "cd ~/Projects/meteor/projekihsan" C-m
tmux split-window -h
tmux select-pane -t 4
tmux send-keys "cd ~/Projects/meteor/projekihsan" C-m
tmux new-window -n deployment
tmux send-keys -t ProjekIhsan:2 "cd ~/Projects/meteor/projekihsan/.production" C-m
tmux select-window -t ProjekIhsan:1
tmux select-pane -t 1
tmux send-keys "cd ~/Projects/meteor/projekihsan" C-m
tmux send-keys "vim" C-m
tmux select-layout main-horizontal
tmux at -t ProjekIhsan
