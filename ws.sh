#!/bin/bash

function gen_workspaces() {
    i3-msg -t get_workspaces | jq -r '.[].name' | sort -n
}

function create_and_switch_to_new_workspace() {
    # Find the highest workspace number in use
    highest_used=$(i3-msg -t get_workspaces | jq '.[].num' | sort -nr | head -n1)
    # Calculate the next workspace number (add 1)
    next_workspace_num=$((highest_used + 1))
    # Switch to the new workspace, effectively creating it
    i3-msg workspace number "$next_workspace_num"
}

WORKSPACE=$( (echo empty; gen_workspaces) | rofi -dmenu -p "Select workspace:" -kb-accept-entry 'Alt_L')

if [ "empty" = "${WORKSPACE}" ]; then
    create_and_switch_to_new_workspace
elif [ -n "${WORKSPACE}" ]; then
    i3-msg workspace \""${WORKSPACE}"\"
fi

