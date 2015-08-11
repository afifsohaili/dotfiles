#!/bin/sh

tmux new -d -s Fashionate -n editor
tmux send-keys -t Fashionate:1 "cd ~/Projects/rails/fashionvendr" C-m
tmux new-window -n fashionate-server
tmux send-keys -t Fashionate:2 "cd ~/Projects/rails/fashionvendr && spring rails s -p 8000 Puma" C-m
tmux new-window -n cmd-windows
tmux send-keys -t Fashionate:3 "cd ~/Projects/rails/fashionvendr" C-m
tmux attach -t Fashionate
