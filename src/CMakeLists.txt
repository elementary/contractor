# Vala stuff
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)
set(GETTEXT_PACKAGE "contractor")

configure_file (${CMAKE_CURRENT_SOURCE_DIR}/config.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
# pkgconfig, real C code
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED glib-2.0 gio-2.0 gthread-2.0 gee-1.0)
set(
CFLAGS
    ${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER}
)
set(
LIB_PATHS
	${DEPS_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})
add_definitions(${CFLAGS})
vala_precompile(
VALA_C
    Contractor.vala
    ContractFileService.vala
    ContractorFileInfo.vala
    config.vala
PACKAGES
    glib-2.0
    gio-2.0
    gee-1.0
OPTIONS
    --thread
    -g
    --save-temps
)
add_executable(contractor ${VALA_C})
target_link_libraries(contractor ${DEPS_LIBRARIES})
install(TARGETS contractor RUNTIME DESTINATION bin)
