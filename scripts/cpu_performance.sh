#!/bin/bash
available_policies=(/sys/devices/system/cpu/cpufreq/policy*/scaling_governor)

for policy in "${available_policies[@]}"; do
    current_governor=$(cat "$policy")
    if [[ $policy == */policy0/scaling_governor ]]; then
        new_governor="performance"
    elif [[ $current_governor == "performance" ]]; then
        new_governor="schedutil"
    else
        new_governor="performance"
    fi
    echo "$new_governor" | sudo tee "$policy" > /dev/null
    if [[ $? -eq 0 ]]; then
        echo "Changed governor to '$new_governor' for $policy"
    else
        echo "Failed to change governor for $policy"
    fi
done
