node-build-script
=================

A simple build script for Coffeescript-based Node applications. It supports file
change monitoring to trigger real-time deployment, test execution and web server (re-)starting.

Usage
-----

    build.sh [ task1 ] [ task2 ] [ task3 ] [ ... ]

Tasks
-----

      build:          Build project.

      test:           Build project and build and runs all tests.
                      Equivalent to "build.sh build build-tests run-tests".
      build-tests:    Build all tests.
      run-tests:      Run all tests.

      server:         Stop running server (if existing), build project and start server.
                      Equivalent to "build.sh stop-server build start-server".
      restart-server: Stop running server (if existing) and start server.
                      Equivalent to "build.sh stop-server start-server".
      start-server:   Start server.
      stop-server:    Stop running server (if existing).

      watch:          Start infinite loop triggering succeeding tasks whenever a file changes in
                      project directory. Use only once.
      dev:            Build everything, runs tests and repeats whenever a file changes.
                      Equivalent to "build.sh test watch test".

