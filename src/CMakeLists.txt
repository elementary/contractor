# Vala stuff
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)

set(EXEC_NAME "contractor")
set(GETTEXT_PACKAGE "contractor")

add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# pkgconfig, real C code
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gee-1.0 glib-2.0 gio-2.0 gio-unix-2.0)

set(CFLAGS ${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER})
set(LIB_PATHS ${DEPS_LIBRARY_DIRS})

link_directories(${LIB_PATHS})
add_definitions(${CFLAGS})

vala_precompile(VALA_C ${EXEC_NAME}
    main.vala
    Application.vala
    Contract.vala
    GenericContract.vala
    ContractFile.vala
    ContractKeyFile.vala
    MimeTypeManager.vala
    ContractMatcher.vala
    ContractSource.vala
    DBusService.vala
    ContractDirectory.vala
    FileService.vala
    FileEnumerator.vala
    ContractSorter.vala
    Translations.vala
    String.vala
PACKAGES
    gee-1.0
    glib-2.0
    gio-2.0
    gio-unix-2.0
)

add_executable(${EXEC_NAME} ${VALA_C})
target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})
install(TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

