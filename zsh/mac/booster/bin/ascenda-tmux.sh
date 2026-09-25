#!/bin/sh

open /Applications/Slack.app

tmux new -d -s work -n all
tmux send-keys -t work:1 "cd ~/work/loyalty_engine" C-m
tmux split-window -v
tmux send-keys -t work:1 "cd ~/work/points_bank" C-m
tmux select-window -t 2
tmux split-window -h
tmux send-keys -t work:1 "cd ~/work/guardhouse" C-m
tmux select-window -t 3
tmux split-window -h
tmux send-keys -t work:1 "cd ~/work/e2e-reporting" C-m
tmux new-window
tmux send-keys -t work:2 "cd ~/work/loyalty_engine" C-m
tmux new-window
tmux send-keys -t work:3 "cd ~/work/points_bank" C-m
tmux new-window
tmux send-keys -t work:4 "cd ~/work/e2e-reporting" C-m
tmux new-window
tmux send-keys -t work:5 "cd ~/work/e2e-dev/apps_run" C-m
tmux send-keys -t work:5 "killovermind" C-m
tmux split-window -v
tmux send-keys -t work:5.2 "cd ~/work/e2e-dev/apps_run" C-m
tmux at -t work
