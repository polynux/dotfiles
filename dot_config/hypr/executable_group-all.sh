#!/bin/bash
ws=$(hyprctl activeworkspace -j | jq .id)
clients=$(hyprctl clients -j | jq --argjson ws "$ws" '[.[] | select(.workspace.id == $ws and .floating == false and .mapped == true)]')

total=$(echo "$clients" | jq length)
if [ "$total" -le 1 ]; then exit; fi

current_addr=$(hyprctl activewindow -j | jq -r .address)
SLEEP=0.02

if [ "$total" -eq 1 ]; then
  # Ungroup
  addr=$(echo "$clients" | jq -r .[0].address)
  hyprctl dispatch focuswindow address:$addr
  hyprctl dispatch moveoutofgroup
  # Cycle and ungroup others
  while hyprctl dispatch changegroupactive f; do
    hyprctl dispatch moveoutofgroup
  done
else
  master_addr=$(hyprctl clients -j | jq -r "[.[] | select (.workspace.id == $(hyprctl activewindow -j | jq .workspace.id))] | min_by(.at[0]) | .address")
  hyprctl dispatch focuswindow address:$master_addr
  sleep $SLEEP
  hyprctl dispatch togglegroup
  sleep $SLEEP
  for addr in $(echo "$clients" | jq -r '[.[] | select(.master != true)] | .[].address'); do
    hyprctl dispatch focuswindow address:$addr
    sleep $SLEEP
    hyprctl dispatch moveintogroup l
    sleep $SLEEP
  done
  hyprctl dispatch focuswindow address:$current_addr
fi
