#!/bin/bash

# Helper function to gracefully shut down our child processes when we exit.
clean_exit() {
    for PID in $CERTBOT_LOOP_PID; do
        if kill -0 $PID 2>/dev/null; then
            kill -SIGTERM "$PID"
            wait "$PID"
        fi
    done
}

# Make bash listen to the SIGTERM and SIGINT kill signals, and make them trigger
# a normal "exit" command in this script. Then we tell bash to execute the
# "clean_exit" function, seen above, in the case an "exit" command is triggered.
# This is done to give the child processes a chance to exit gracefully.
trap "exit" TERM INT
trap "clean_exit" EXIT

# Start the certbot certificate management script.
$(cd $(dirname $0); pwd)/run_certbot.sh &
CERTBOT_LOOP_PID=$!

# Nginx and the certbot update-loop process are now our children. As a parent
# we will wait for both of their PIDs, and if one of them exits we will follow
# suit and use the same status code as the program which exited first.
wait -n $CERTBOT_LOOP_PID
exit $?
