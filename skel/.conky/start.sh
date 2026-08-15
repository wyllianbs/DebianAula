#! /bin/bash

> "$HOME/.conky/conky.log"

sleep 5s &&
pkill -u "$(whoami)" conky
conky -c ~/.conky/settings.lua 2> "$HOME/.conky/conky.log" &
