#!/bin/sh

open /Applications/Slack.app
tmux new -d -s Booster -n fulcrum
tmux send-keys -t Booster:1 "cd ~/Booster/fulcrum" C-m
tmux split-window -v
tmux select-pane -t 2
tmux send-keys -t Booster:1 "cd ~/Booster/fulcrum" C-m
tmux split-window -h
tmux send-keys -t Booster:1 "cd ~/Booster/fulcrum" C-m
tmux split-window -h
tmux send-keys -t Booster:1 "cd ~/Booster/fulcrum" C-m
tmux select-layout main-horizontal
tmux new-window -n deployments
tmux send-keys -t Booster:2 "cd ~/Booster/autotomy" C-m
tmux select-window -t Booster:1
tmux at -t Booster
