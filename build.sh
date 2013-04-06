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
    echo "  build:       Build project."
    echo "  test:        Build project and build and runs all tests."
    echo "               Equivalent to \"$name build build-tests run-tests\"."
    echo "  watch:       Start infinite loop triggering succeeding tasks whenever a file changes in"
    echo "               project directory. Use only once."
    echo "  dev:         Build everything, runs tests and repeats whenever a file changes."
    echo "               Equivalent to \"$name test watch test\"."
    echo "  build-tests: Build all tests."
    echo "  run-tests:   Run all tests."
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
            'watch')
                watch
                ;;
            'dev')
                ./$0 test watch test
                exit
        esac
    done
}


process_tasks
