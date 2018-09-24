#!/bin/sh

tmux new -d -s conf-cloud -n conf-cloud
tmux send-keys -t conf-cloud:1.1 "cd ~/ServiceRocket/comp-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:1.2 "cd ~/ServiceRocket/comp-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:1.3 "cd ~/ServiceRocket/comp-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:1.4 "cd ~/ServiceRocket/comp-cloud/" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux new-window
tmux select-window -t 2
tmux send-keys -t conf-cloud:2.1 "cd ~/ServiceRocket/redir-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:2.2 "cd ~/ServiceRocket/redir-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:2.3 "cd ~/ServiceRocket/redir-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:2.4 "cd ~/ServiceRocket/redir-cloud/" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux new-window
tmux select-window -t 3
tmux send-keys -t conf-cloud:3.1 "cd ~/ServiceRocket/vis-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:3.2 "cd ~/ServiceRocket/vis-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:3.3 "cd ~/ServiceRocket/vis-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:3.4 "cd ~/ServiceRocket/vis-cloud/" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux new-window
tmux select-window -t 4
tmux send-keys -t conf-cloud:4.1 "cd ~/ServiceRocket/link-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:4.2 "cd ~/ServiceRocket/link-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:4.3 "cd ~/ServiceRocket/link-cloud/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:4.4 "cd ~/ServiceRocket/link-cloud/" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux new-window
tmux select-window -t 5
tmux send-keys -t conf-cloud:5.1 "cd ~/ServiceRocket/conf-cloud-utils/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:5.2 "cd ~/ServiceRocket/conf-cloud-utils/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:5.3 "cd ~/ServiceRocket/conf-cloud-utils/" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:5.4 "cd ~/ServiceRocket/conf-cloud-utils/" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux new-window
tmux select-window -t 6
tmux send-keys -t conf-cloud:6.1 "cd ~/ServiceRocket/jira-automations" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:6.2 "cd ~/ServiceRocket/jira-automations" C-m
tmux split-window -h
tmux send-keys -t conf-cloud:6.3 "cd ~/ServiceRocket/jira-automations" C-m
tmux select-layout main-vertical
tmux resize-pane -R 100000
tmux resize-pane -L 100

tmux select-window -t 1

tmux at -t conf-cloud
