cmake_minimum_required(VERSION 3.5)

set(current_project_name "FlightRecordStandardization")
project(${current_project_name})

# root directory
set(all_project_root_path "${CMAKE_CURRENT_SOURCE_DIR}/../../../")

# Pour in the File Filter traversal tool.
include(${all_project_root_path}/build/FileFilter.cmake)

# Added source files
file(GLOB_RECURSE All_SOURCES *.h *.hpp *.cpp)

# Adding file paths and header files
source_group_by_dir(All_SOURCES ${CMAKE_CURRENT_SOURCE_DIR})
include_file_directory(All_SOURCES)

Message(STATUS "✅ Build Static Lib in ${current_project_name}")
add_library(${current_project_name} STATIC ${All_SOURCES})

target_link_libraries(${current_project_name} pthread)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --std=c++11 -O3 -fPIC")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} --std=c++11 -O0")

# Folder path to introduce FlightRecordEngine
target_include_directories(
    ${current_project_name}
    PUBLIC
    ${all_project_root_path}/dji-flightrecordengine/source/
)

# Introduction of the Engine library
add_subdirectory(${all_project_root_path}/dji-flightrecordengine/source EngineBuild)
target_link_libraries(${current_project_name} FlightRecordEngine)

# Link against system-installed third party libraries:
#   libcurl          -> libcurl4-openssl-dev (FindCURL)
#   libssl/libcrypto -> libssl-dev           (FindOpenSSL; OPENSSL_LIBRARIES = ssl + crypto)
find_package(CURL REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Threads)
target_include_directories(${current_project_name} PUBLIC ${CURL_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIR})
target_link_libraries(${current_project_name}
    ${CURL_LIBRARIES}
    ${OPENSSL_LIBRARIES}
    Threads::Threads
    dl
)



