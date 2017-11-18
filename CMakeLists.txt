# Check http://elementaryos.org/docs/developer-guide/cmake for documentation

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)
project(contractor)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )
include(GNUInstallDirs)

set (VERSION "0.3.2")

add_subdirectory (src)
add_subdirectory (data)

install (DIRECTORY DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/contractor)
