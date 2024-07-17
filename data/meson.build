conf_data = configuration_data()
conf_data.set('EXEC_PATH', join_paths (libexecdir, meson.project_name()))

dbus = dependency('dbus-1')
session_bus_services_dir = dbus.get_pkgconfig_variable('session_bus_services_dir', define_variable: ['datadir', datadir])

configure_file(
    input: 'org.elementary.contractor.service.in',
    output: '@BASENAME@',
    configuration: conf_data,
    install_dir: session_bus_services_dir
)
