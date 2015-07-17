#!bin/bash

tmux new -s Meteor
tmux send-keys -t Meteor:1 "tolong && vim" C-m
