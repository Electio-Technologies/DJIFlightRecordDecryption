cmake_minimum_required(VERSION 3.5)

set(current_project_name "FlightRecordStandardizationCpp")
project(${current_project_name})

# root directory
set(all_project_root_path "${CMAKE_CURRENT_SOURCE_DIR}/../../../")

# Pour in the File Filter traversal tool.
include(${all_project_root_path}/build/FileFilter.cmake)

# Added source files
file(GLOB_RECURSE All_SOURCES *.h *.hpp *.cpp *.cc)

# Adding file paths and header files
source_group_by_dir(All_SOURCES ${CMAKE_CURRENT_SOURCE_DIR})
include_file_directory(All_SOURCES)

Message(STATUS "✅ Build Static Lib in ${current_project_name}")
add_library(${current_project_name} STATIC ${All_SOURCES})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --std=c++11 -O3 -fPIC")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} --std=c++11 -O0")

# Folder path to introduce FlightRecordStandardizationCpp
target_include_directories(
    ${current_project_name}
    PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/../FlightRecordStandardizationCpp"
    "${all_project_root_path}/dji-flightrecordengine/source/"
)

# include FlightRecordStandardization Header
file(GLOB_RECURSE StandardizationHeader ${all_project_root_path}/dji-flightrecord-kit/source/FlightRecordStandardization/*.h)
include_file_directory(StandardizationHeader)

# Adding repositories
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../FlightRecordStandardization StandardizationBuild)
target_link_libraries(${current_project_name} FlightRecordStandardization)

# Use system-installed protobuf (apt: libprotobuf-dev). The committed *.pb.cc/.pb.h
# require protobuf >= 3.21.0; Ubuntu 24.04+ ships 3.21.12, which matches.
find_package(Protobuf REQUIRED)
target_include_directories(${current_project_name} PUBLIC ${Protobuf_INCLUDE_DIRS})
target_link_libraries(${current_project_name} protobuf::libprotobuf)

