# Check http://elementaryos.org/docs/developer-guide/cmake for documentation

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)
project(contractor)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

add_subdirectory (src)
add_subdirectory (data)
add_subdirectory (po)

