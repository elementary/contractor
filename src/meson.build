files = files(
    'Application.vala',
    'ContractDirectory.vala',
    'ContractFile.vala',
    'ContractKeyFile.vala',
    'ContractMatcher.vala',
    'ContractSorter.vala',
    'ContractSource.vala',
    'Contract.vala',
    'DBusService.vala',
    'FileEnumerator.vala',
    'FileService.vala',
    'GenericContract.vala',
    'main.vala',
    'MimeTypeManager.vala',
    'String.vala',
    'Translations.vala'
)

dependencies = [
    dependency('gee-0.8'),
    dependency('gio-2.0'),
    dependency('gio-unix-2.0'),
    dependency('glib-2.0'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('m', required : false)
]

executable(
    meson.project_name(),
    files,
    dependencies: dependencies,
    install : true
)
