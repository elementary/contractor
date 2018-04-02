executable(
    meson.project_name(),
    'main.vala',
    'Application.vala',
    'Contract.vala',
    'ContractDirectory.vala',
    'ContractFile.vala',
    'ContractKeyFile.vala',
    'ContractMatcher.vala',
    'ContractSorter.vala',
    'ContractSource.vala',
    'DBusService.vala',
    'FileEnumerator.vala',
    'FileService.vala',
    'GenericContract.vala',
    'MimeTypeManager.vala',
    'String.vala',
    'Translations.vala',
   
    
    dependencies: [
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gio-unix-2.0'),

        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install : true
)
