conf_data = configuration_data()
conf_data.set('PREFIX', get_option('prefix'))
service_config = configure_file(
    input: 'org.elementary.contractor.service.in',
    output: 'org.elementary.contractor.service',
    configuration: conf_data
)

install_data(
    service_config,
    install_dir: join_paths(get_option('datadir'), 'dbus-1', 'services')
)


