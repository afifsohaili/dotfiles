#!/bin/sh

tmux new -d -s service-rocket -n safety
tmux send-keys -t service-rocket:1.1 "cd ~/ServiceRocket/safety" C-m
tmux split-window -h
tmux send-keys -t service-rocket:1.2 "cd ~/ServiceRocket/safety && sbt run" C-m
tmux split-window -h
tmux send-keys -t service-rocket:1.3 "cd ~/ServiceRocket/safety && ngrok http 8500" C-m
tmux split-window -h
tmux send-keys -t service-rocket:1.4 "cd ~/ServiceRocket/safety" C-m
tmux select-layout main-horizontal
tmux resize-pane -D 20

tmux new-window
tmux select-window -t 2
tmux send-keys -t service-rocket:2.1 "cd ~/ServiceRocket/toolbox" C-m
tmux split-window -h
tmux send-keys -t service-rocket:2.2 "cd ~/ServiceRocket/toolbox && sbt run" C-m
tmux split-window -h
tmux send-keys -t service-rocket:2.3 "cd ~/ServiceRocket/toolbox && ngrok http 9000" C-m
tmux split-window -h
tmux send-keys -t service-rocket:2.4 "cd ~/ServiceRocket/toolbox" C-m
tmux select-layout main-horizontal
tmux resize-pane -D 20

tmux new-window
tmux select-window -t 3
tmux send-keys -t service-rocket:3.1 "cd ~/ServiceRocket/runbook" C-m
tmux split-window -h
tmux send-keys -t service-rocket:3.2 "cd ~/ServiceRocket/runbook" C-m
tmux split-window -h
tmux send-keys -t service-rocket:3.3 "cd ~/ServiceRocket/runbook" C-m
tmux split-window -h
tmux send-keys -t service-rocket:3.4 "cd ~/ServiceRocket/runbook" C-m
tmux select-layout main-horizontal
tmux resize-pane -D 20

tmux new-window
tmux select-window -t 4
tmux send-keys -t service-rocket:4.1 "cd ~/ServiceRocket/chewbacca" C-m
tmux split-window -h
tmux send-keys -t service-rocket:4.2 "cd ~/ServiceRocket/chewbacca" C-m
tmux split-window -h
tmux send-keys -t service-rocket:4.3 "cd ~/ServiceRocket/chewbacca" C-m
tmux split-window -h
tmux send-keys -t service-rocket:4.4 "cd ~/ServiceRocket/chewbacca" C-m
tmux select-layout main-horizontal
tmux resize-pane -D 20

tmux new-window
tmux select-window -t 5
tmux send-keys -t service-rocket:5.1 "cd ~/ServiceRocket/hansolo" C-m
tmux split-window -h
tmux send-keys -t service-rocket:5.2 "cd ~/ServiceRocket/hansolo" C-m
tmux split-window -h
tmux send-keys -t service-rocket:5.3 "cd ~/ServiceRocket/hansolo" C-m
tmux split-window -h
tmux send-keys -t service-rocket:5.4 "cd ~/ServiceRocket/hansolo" C-m
tmux select-layout main-horizontal
tmux resize-pane -D 20

tmux at -t service-rocket
