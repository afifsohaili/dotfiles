#!/bin/sh

tmux new -d -s Pos -n fulcrum
tmux send-keys -t Pos:1 "cd ~/Projects/PosSystem" C-m
tmux split-window -v
tmux select-pane -t 2
tmux send-keys -t Pos:1 "cd ~/Projects/PosSystem" C-m
tmux split-window -h
tmux send-keys -t Pos:1 "cd ~/Projects/PosSystem" C-m
tmux split-window -h
tmux send-keys -t Pos:1 "cd ~/Projects/PosSystem" C-m
tmux new-window -n deployments
tmux send-keys -t Pos:2 "cd ~/Projects/PosSystem" C-m
tmux select-window -t 1
tmux at -t Pos
