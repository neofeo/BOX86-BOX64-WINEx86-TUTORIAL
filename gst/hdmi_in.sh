#!/bin/bash

#check current audio output
current_pulse_sink=$(pactl get-default-sink)

# cleaning gst instances
killall gst-launch-1.0

# Define the window title of your GStreamer window
WINDOW_TITLE="gst-launch-1.0"

# Check if wmctrl is installed
if ! command -v wmctrl &>/dev/null; then
    echo "Error: wmctrl is not installed. Please install it using your package manager."
    exit 1
fi

# Function to toggle fullscreen state
toggle_fullscreen() {
    # Sleep for a moment to ensure the window is created
    sleep 1

    # Find the window ID of the GStreamer window by title
    WINDOW_ID=$(wmctrl -l | grep "$WINDOW_TITLE" | awk '{print $1}')

    if [ -z "$WINDOW_ID" ]; then
        echo "Error: GStreamer window not found."
        exit 1
    fi

    # Toggle fullscreen state
    wmctrl -i -r "$WINDOW_ID" -b toggle,fullscreen
}

# Launch the GStreamer pipeline
gst-launch-1.0 -e alsasrc device=hw:CARD=rockchiphdmiin,DEV=0 ! audioconvert ! audioresample ! audio/x-raw,rate=48000 ! queue max-size-buffers=1000 max-size-bytes=0 max-size-time=1000000000 ! pulsesink device="$current_pulse_sink" sync=false async=false
audio_pid="$!"


GST_VIDEO_CONVERT_USE_RGA=1 gst-launch-1.0 -e v4l2src device=/dev/video0 ! video/x-raw,width=1920,height=1080 ! videoconvert ! ximagesink &
video_pid="$!"

# Toggle fullscreen
toggle_fullscreen


# Wait for the video pipeline to finish
wait "$video_pid"

# Clean up audio pipeline
if [[ -n "$audio_pid" ]]; then
    echo "Killing audio pipeline (PID: $audio_pid)"
    kill "$audio_pid"
fi