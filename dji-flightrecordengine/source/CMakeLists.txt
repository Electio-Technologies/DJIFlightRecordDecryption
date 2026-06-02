cmake_minimum_required(VERSION 3.5)

set(current_project_name "FlightRecordEngine")
project(${current_project_name})

# root directory
set(all_project_root_path "${CMAKE_CURRENT_SOURCE_DIR}/../../")

# Pour in the File Filter traversal tool.
include(${all_project_root_path}/common/build/FileFilter.cmake)

file(GLOB_RECURSE All_SOURCES *.h *.hpp *.cpp)

source_group_by_dir(All_SOURCES ${CMAKE_CURRENT_SOURCE_DIR})
include_file_directory(All_SOURCES)
if (ENABLE_SHARED_LIB)
    Message("Build Shared Lib")
    add_library(${current_project_name} SHARED ${All_SOURCES})
else()
    Message("Build Static Lib")
    add_library(${current_project_name} STATIC ${All_SOURCES})
endif(ENABLE_SHARED_LIB)

set(root_directory_relative_current "${empty_param}")

set(MarcosArr LTC_PKCS_1 LTM_DESC)
foreach(item ${MarcosArr})
	add_definitions("-D${item}")
endforeach()

target_include_directories(
	${current_project_name}
	PUBLIC
	"${CMAKE_CURRENT_SOURCE_DIR}/."
)

string(TOLOWER ${platform} platformLowerStr)
Message(STATUS "✅ start ${platform} operation in ${current_project_name}")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --std=c++11 -O3 -fPIC")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} --std=c++11 -O0")

message(${platformLowerStr})

# Link against system-installed libtomcrypt/libtommath (apt: libtomcrypt-dev
# libtommath-dev). CMake ships no find module for these, so locate them with
# find_library and fail early if absent.
find_library(TOMCRYPT_LIB NAMES tomcrypt)
find_library(TOMMATH_LIB NAMES tommath)
if(NOT TOMCRYPT_LIB)
	message(FATAL_ERROR "libtomcrypt not found - install libtomcrypt-dev")
endif()
if(NOT TOMMATH_LIB)
	message(FATAL_ERROR "libtommath not found - install libtommath-dev")
endif()
target_link_libraries(${current_project_name} ${TOMCRYPT_LIB} ${TOMMATH_LIB})
