# Check http://elementaryos.org/docs/developer-guide/cmake for documentation

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)
project(contractor)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

set (VERSION "0.3")

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.bzr/;/.bzrignore;~$;${CPACK_SOURCE_IGNORE_FILES}")

include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

add_subdirectory (src)
add_subdirectory (data)
add_subdirectory (po)

