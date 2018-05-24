project(
    'contractor',
    'vala', 'c',
    version: '0.3.3'
)

i18n = import('i18n')
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

subdir('src')
subdir('data')
