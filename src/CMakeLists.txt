# Vala stuff

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.10" MINIMUM)
include(ValaPrecompile)


configure_file (${CMAKE_CURRENT_SOURCE_DIR}/config.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/config.vala)
# pkgconfig, real C code
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED glib-2.0 gio-2.0 gthread-2.0 gee-1.0)
set(CFLAGS
	${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER}
)
set(LIB_PATHS
	${DEPS_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})


add_definitions(${CFLAGS})
vala_precompile(VALA_C contractor.vala config.vala
PACKAGES
    glib-2.0
    gio-2.0
    gee-1.0
OPTIONS
    --thread)

add_executable(contractor
    ${VALA_C} )

target_link_libraries(contractor ${DEPS_LIBRARIES})

install(TARGETS contractor RUNTIME DESTINATION bin)
