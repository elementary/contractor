# Vala stuff
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)

set(GETTEXT_PACKAGE "contractor")

add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# pkgconfig, real C code
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gee-1.0 glib-2.0 gio-2.0 gio-unix-2.0)

set(CFLAGS ${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER})
set(LIB_PATHS ${DEPS_LIBRARY_DIRS})

link_directories(${LIB_PATHS})
add_definitions(${CFLAGS})

vala_precompile(
VALA_C
    main.vala
    Application.vala
    Contract.vala
    GenericContract.vala
    ContractFile.vala
    ContractKeyFile.vala
    MimeTypeManager.vala
    ContractManager.vala
    DBusService.vala
    ContractDirectory.vala
    FileService.vala
PACKAGES
    gee-1.0
    glib-2.0
    gio-2.0
    gio-unix-2.0
)

add_executable(contractor ${VALA_C})
target_link_libraries(contractor ${DEPS_LIBRARIES})
install(TARGETS contractor RUNTIME DESTINATION bin)

