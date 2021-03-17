#!/usr/bin/env bash

EXECUTABLE_PATH = ""
YOUR_EXECUTABLE = a.out

valgrind --tool=memcheck --leak-check=full --track-origins=yes  --show-leak-kinds=all ./${EXECUTABLE_PATH}/${YOUR_EXECUTABLE}