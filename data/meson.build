conf_data = configuration_data()
conf_data.set('EXEC_PATH', join_paths (get_option('prefix'), get_option('bindir'), meson.project_name()))

dbus = dependency('dbus-1')

configure_file(
    input: 'org.elementary.contractor.service.in',
    output: '@BASENAME@',
    configuration: conf_data,
    install_dir: dbus.get_pkgconfig_variable('session_bus_services_dir')
)
