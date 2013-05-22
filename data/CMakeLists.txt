configure_file(org.elementary.contractor.service.cmake ${CMAKE_CURRENT_BINARY_DIR}/org.elementary.contractor.service)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.elementary.contractor.service DESTINATION ${CMAKE_INSTALL_PREFIX}/share/dbus-1/services)
add_subdirectory (contracts)