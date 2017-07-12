#!/bin/sh

tmux new -d -s ProjekIhsan -n development
tmux split-window -v
tmux select-pane -t 2
tmux send-keys "cd ~/Projects/tuisyen-sayang && meteor run -p 7000 --settings server/environments/local.json" C-m
tmux split-window -h
tmux select-pane -t 3
tmux send-keys "cd ~/Projects/tuisyen-sayang" C-m
tmux split-window -h
tmux select-pane -t 4
tmux send-keys "cd ~/Projects/tuisyen-sayang/.production" C-m
tmux select-window -t ProjekIhsan:1
tmux select-pane -t 1
tmux send-keys "cd ~/Projects/tuisyen-sayang" C-m
tmux send-keys "vim" C-m
tmux select-layout main-horizontal
tmux at -t ProjekIhsan
