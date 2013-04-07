#!/bin/bash

build_directory="build"
compiler=coffee
application_launcher=node

name=$(basename "$0")

if [[ "$#" == "0" ]]; then
    echo "$name: Missing task list"
    echo
    echo "Usage: $name [ task1 ] [ task2 ] [ task3 ] [ ... ]"
    echo
    echo "Tasks:"
    echo "  build:          Build project."
    echo
    echo "  test:           Build project and build and runs all tests."
    echo "                  Equivalent to \"$name build build-tests run-tests\"."
    echo "  build-tests:    Build all tests."
    echo "  run-tests:      Run all tests."
    echo
    echo "  server:         Stop running server (if existing), build project and start server."
    echo "                  Equivalent to \"$name stop-server build start-server\"."
    echo "  restart-server: Stop running server (if existing) and start server."
    echo "                  Equivalent to \"$name stop-server start-server\"."
    echo "  start-server:   Start server."
    echo "  stop-server:    Stop running server (if existing)."
    echo
    echo "  watch:          Start infinite loop triggering succeeding tasks whenever a file changes in"
    echo "                  project directory. Use only once."
    echo "  dev:            Build everything, runs tests and repeats whenever a file changes."
    echo "                  Equivalent to \"$name test watch test\"."
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


build_project() {
    echo "Build project..."
    mkdir -p $build_directory/{lib,test}
    $compiler --compile --output $build_directory/lib lib/precompiler.coffee
}


build_tests() {
    echo "Build tests..."
    $compiler --compile --output $build_directory/test test/precompiler.spec.coffee
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

server_pid=0

start_server() {
    echo "Start server..."
    $application_launcher "$build_directory/run-server.js" &
    server_pid=$!
}

stop_server() {
    if [[ $server_pid > 0 ]]; then
        echo "Stop server..."
        kill $server_pid
        server_pid=0
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
                build_project
                ;;
            'test')
                build_project
                build_tests
                run_tests
                ;;
            'build-tests')
                build_tests
                ;;
            'run-tests')
                run_tests
                ;;
            'server')
                stop_server
                build_project
                start_server
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
                ./$0 test watch test
                exit
                ;;
            *)
                echo "WARNING: Unknown task $task. Skip and continue..."
                ;;
        esac
    done
}


process_tasks
