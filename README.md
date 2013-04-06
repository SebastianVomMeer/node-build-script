node-build-script
=================

A simple build script for Coffeescript-based Node applications. It supports file
change monitoring to trigger real-time deployment and test execution.

Usage
-----

    build.sh [ task1 ] [ task2 ] [ task3 ] [ ... ]

Tasks
-----

      build:       Build project.
      test:        Build project and build and runs all tests.
                   Equivalent to "build.sh build build-tests run-tests".
      watch:       Start infinite loop triggering succeeding tasks whenever a file changes in
                   project directory. Use only once.
      dev:         Build everything, runs tests and repeats whenever a file changes.
                   Equivalent to "build.sh test watch test".
      build-tests: Build all tests.
      run-tests:   Run all tests.
