#!/bin/bash
gpu_policy="/sys/class/devfreq/fb000000.gpu/governor"

current_governor=$(cat "$gpu_policy")
if [[ $current_governor == "performance" ]]; then
    new_governor="simple_ondemand"
else
    new_governor="performance"
fi
echo "$new_governor" | sudo tee "$gpu_policy" > /dev/null
if [[ $? -eq 0 ]]; then
    echo "Changed GPU governor to '$new_governor'"
else
    echo "Failed to change GPU governor"
fi
