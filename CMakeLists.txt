cmake_minimum_required(VERSION 3.8)
# Указываем свое название проекта
project("")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Пишем необходимые ключи
set(CMAKE_CXX_FLAGS "-std=c++0x -Wall -ggdb3")

# Указываем директорию с проектом
set(PROJECT_DIR "project")
# Указываем директории с хедерами
set(INCLUDE_DIR "include")

# Путь к include_dirs может меняться по умолчанию может меняться
include_directories(${PROJECT_DIR}/${INCLUDE_DIR})
include_directories(SYSTEM ${CMAKE_BINARY_DIR}/include)

# Подключает ExternalProject_Add
include(ExternalProject)
find_package(Git REQUIRED)

# Здесь задаем переменные для бибиотек и  создаем их
set(LIB_NAME "curr_lib_name")
set(LIB_NAME_SRC "")

# По умолчанию статические либы
add_library(${LIB_NAME} STATIC ${LIB_NAME_SRC})

# Устанавливаем таргет основной цели, подключаем к нему нужные либы
set(TARGET target_name)
add_executable(${TARGET} ${PROJECT_DIR}/main.c)
target_link_libraries(${TARGET} ${LIB_NAME})

# Опция, включает в компиляцию для подсчета покрытия тестами
option(ENABLE_COVERAGE "Build tests coverage statistic" OFF)
if (ENABLE_COVERAGE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g ")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftest-coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif ()

# Подтягивает cppcheck, прогоняет статический анализ
option(ENABLE_CPPCHECK "Configure and run cppcheck." OFF) # Makes boolean 'test' available.
if (ENABLE_CPPCHECK)

    list(APPEND CPPCHECK_CMAKE_ARGS
            "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}"
            )

    ExternalProject_Add(
            cppcheck
            GIT_REPOSITORY https://github.com/danmar/cppcheck.git
            GIT_TAG 1.79
            GIT_SHALLOW 1
            CMAKE_ARGS ${CPPCHECK_CMAKE_ARGS}
            PREFIX ${CMAKE_BINARY_DIR}/external/cppcheck/prefix
            TMP_DIR ${CMAKE_BINARY_DIR}/external/cppcheck/tmp
            STAMP_DIR ${CMAKE_BINARY_DIR}/external/cppcheck/stamp
            DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/external/cppcheck/download
            SOURCE_DIR ${CMAKE_BINARY_DIR}/external/cppcheck/src
            BINARY_DIR ${CMAKE_BINARY_DIR}/external/cppcheck/build
    )

    # Добавляем аргументы для анализа
    # По умолчинию пишем их в CPPCHECK_ARGS
    list(APPEND CPPCHECK_ARGS
            --enable=all
            --std=c11
            --verbose
            --error-exitcode=1
            --language=c
            --suppress=missingIncludeSystem
            ${CMAKE_SOURCE_DIR}/${PROJECT_DIR}/"current_folder"/*.c
            )

    # Создаем соответствующую цели для анализа
    add_custom_target(
            check1
            COMMAND ${CMAKE_BINARY_DIR}/bin/cppcheck ${CPPCHECK_ARGS}
            COMMENT "running cppcheck"
    )

endif ()

# Гугл тесты, подтягиваются с гита
option(BUILD_TESTS "Build all tests." OFF)
if (BUILD_TESTS)
    # Конфигурационный файлик для загрузки гугл тестов,
    # должен лежать в той же директории, что и CMakeLists.txt
    configure_file(CMakeLists.txt.in
            googletest-download/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/googletest-download)
    execute_process(COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/googletest-download)

    add_subdirectory(${CMAKE_BINARY_DIR}/googletest-src
            ${CMAKE_BINARY_DIR}/googletest-build)

    enable_testing()

    # Устанавливаем директорию с тестами и указываем исходники с тестам
    set(TEST_SRC_DIR test)
    list(TEST_SRC test/testing.cpp)

    foreach (file ${TEST_SRC})
        set(name)
        get_filename_component(name ${file} NAME_WE)
        add_executable("${name}_tests" ${file})
        target_link_libraries("${name}_tests" gtest_main)
        # Не забываем слинковать с тестируемыми библиотеками
        target_link_libraries("${name}_tests" hw_lib)
        add_test(NAME ${name} COMMAND "${name}_tests")
    endforeach ()
endif ()