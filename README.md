# Contractor

## Building, Testing, and Installation

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`

    sudo make install

## Writing Contract Files
elementary Files, Photos and other apps support adding options to the context menu by the way of Contract files. 

These Contract files can be made system wide available by adding them to:
`/usr/share/contractor`
or for specific users by adding them to:
`~/.local/share/contractor`

Simple .contract file example:
```
[Contractor Entry]
Name=Mount
MimeType=application/x-cd-image;application/x-raw-disk-image
Exec=gnome-disk-image-mounter %f
```

- `Name`: Text displayed in the right click context menu.
- `MimeType`: Mimetype(s) of files it should be shown for.
- `Exec`: Command to execute. [More info](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#exec-variables).

Tips:
- Use `pkexec` to ask for root permissions. Example: `Exec=pkexec chmod +x %U`
