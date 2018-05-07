#!/bin/sh

tmux new -d -s tapir -n tapir
tmux send-keys -t tapir:1.1 "cd ~/ServiceRocket/tapir" C-m
tmux split-window -h
tmux send-keys -t tapir:1.2 "cd ~/ServiceRocket/tapir" C-m
tmux split-window -h
tmux send-keys -t tapir:1.3 "cd ~/ServiceRocket/tapir" C-m
tmux split-window -h
tmux send-keys -t tapir:1.4 "cd ~/ServiceRocket/tapir" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux new-window
tmux select-window -t 2
tmux send-keys -t tapir:2.1 "cd ~/ServiceRocket/tapir-web" C-m
tmux split-window -h
tmux send-keys -t tapir:2.2 "cd ~/ServiceRocket/tapir-web" C-m
tmux split-window -h
tmux send-keys -t tapir:2.3 "cd ~/ServiceRocket/tapir-web" C-m
tmux split-window -h
tmux send-keys -t tapir:2.4 "cd ~/ServiceRocket/tapir-web" C-m
tmux select-layout main-horizontal
tmux resize-pane -D 100000
tmux resize-pane -U 80

tmux new-window
tmux select-window -t 3
tmux send-keys -t tapir:3.1 "cd ~/ServiceRocket/jira-automations" C-m
tmux split-window -h
tmux send-keys -t tapir:3.2 "cd ~/ServiceRocket/jira-automations" C-m
tmux split-window -h
tmux send-keys -t tapir:3.3 "cd ~/ServiceRocket/jira-automations" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux at -t tapir
