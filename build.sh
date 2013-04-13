#!/bin/bash


# Target directory for compiled files starting from build script's path without leading and 
# trailing slashes.
build_directory="build"

# Compiler executor for Coffeescript files. Check build task for execution details if you use 
# something different from Coffeescript.
compiler=coffee

# Executor for Node applications. Used to run tests and start servers. Check these tasks for
# execution details if you use something different from Node.
application_launcher=node

name=$(basename "$0")

if [[ "$#" == "0" ]]; then
    echo "$name: Missing task list"
    echo
    echo "Usage: $name [ task1 ] [ task2 ] [ task3 ] [ ... ]"
    echo
    echo "Tasks:"
    echo "  build:          Build project and tests."
    echo
    echo "  test:           Build project and run all tests."
    echo "                  Equivalent to \"$name build run-tests\"."
    echo "  run-tests:      Run all tests."
    echo
    echo "  server:         Stop running server (if existing), build project and start server."
    echo "                  Equivalent to \"$name stop-server build start-server\"."
    echo "  restart-server: Stop running server (if existing) and start server."
    echo "                  Equivalent to \"$name stop-server start-server\"."
    echo "  start-server:   Start server."
    echo "  stop-server:    Stop running server (if existing)."
    echo
    echo "  watch:          Start infinite loop triggering succeeding tasks whenever a file changes"
    echo "                  in project directory. Use only once."
    echo "  dev:            Build everything, restart server, run tests and repeat whenever a file"
    echo "                  changes. Equivalent to \"$name test watch test\"."
    exit 1
fi


# cd to script's directory for relative links
cd $(cd $(dirname $0); pwd -P)


# task list to be executed
tasks=("${@:1}")


# ensure that needed programs are installed
for program in $compiler $application_launcher; do
    hash $program 2>/dev/null || { 
        echo >&2 "Please install required $program. Aborting."; exit 1;
    }
done


notify() {

    # platform-dependent function to send simple desktop notifications

    local message=$1      # the message to be sent
    local message_type=$2 # "error" || "success" || undefined
    
    # linux: notify-send
    if hash "notify-send" 2> /dev/null; then
        local icon="face-plain"
        if [[ "$message_type" == "error" ]]; then
            icon="error"
        elif [[ "$message_type" == "success" ]]; then
            icon="face-smile-big"
        fi
        notify-send -u low -t 500 -i "$icon" "$message"
    fi
}

build() {
    echo "Build project..."
    changes=( "$(rsync -av "$source_directory/" "$build_directory")" )
    for filepath in $changes; do
      if [[ $filepath == *.coffee ]]; then
        $compiler -b --compile "$build_directory/$filepath"
      fi
    done
}


run_tests() {
    echo "Execute tests..."
    $application_launcher $build_directory/test/precompiler.spec.js
    if [[ $? > 0 ]]; then
        notify "<strong>One or more tests failed!</strong>" "error"
    else
        notify "<strong>All tests passed.</strong>" "success"
    fi
}


start_server() {
    echo "Start server..."
    $application_launcher "$build_directory/run-server.js" &
    echo $! > .serverpid
}

stop_server() {
    if [ -f ".serverpid" ]; then
        local server_pid=$(head -n 1 .serverpid)
        rm .serverpid
        if [[ $server_pid > 0 ]]; then
            echo "Stop server..."
            kill $server_pid
            server_pid=0
        fi
    fi
}


watch() {
    echo "Waiting for file changes..."
    tasks=("${tasks[@]}" "watch" "${tasks[@]}")
    inotifywait -rqe close_write,moved_to,create ./lib ./test
}


process_tasks() {
    while [[ ${#tasks[@]} > 0 ]]; do
        local task=${tasks[0]}
        unset tasks[0]
        tasks=("${tasks[@]}")
        case "$task" in
            'build')
                build
                ;;
            'test')
                build
                run_tests
                ;;
            'run-tests')
                run_tests
                ;;
            'server')
                stop_server
                build
                start_server
                ;;
            'restart-server')
                stop_server
                start_server
                ;;
            'start-server')
                start_server
                ;;
            'stop-server')
                stop_server
                ;;
            'watch')
                watch
                ;;
            'dev')
                ./$0 server run-tests watch server run-tests
                exit
                ;;
            *)
                echo "WARNING: Unknown task $task. Skip and continue..."
                ;;
        esac
    done
}


process_tasks
