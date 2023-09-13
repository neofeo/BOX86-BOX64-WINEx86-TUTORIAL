#!/bin/bash

# Kill the existing audio pipeline
pkill -f "gst-launch-1.0.*pulsesink"

#check current audio output
current_pulse_sink=$(pactl get-default-sink)

# Launch the GStreamer pipeline
gst-launch-1.0 -e alsasrc device=hw:CARD=rockchiphdmiin,DEV=0 ! audioconvert ! audioresample ! audio/x-raw,rate=48000 ! queue max-size-buffers=1000 max-size-bytes=0 max-size-time=1000000000 ! pulsesink device="$current_pulse_sink" &
audio_pid="$!"
