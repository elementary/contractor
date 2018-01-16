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

## Examples
- [Send by Email](https://github.com/elementary/mail/blob/master/data/mail-attach.contract)
- [Print](https://github.com/elementary/pantheon-print/blob/master/data/print.contract)
- [Send files via Bluetooth](https://github.com/codygarver/os-patch-gnome-bluetooth-xenial/blob/master/debian/gnome-bluetooth.contract)
- [Compress](https://github.com/codygarver/os-patch-file-roller-xenial/blob/master/data/file-roller-compress.contract)
- [Extract Here](https://github.com/codygarver/os-patch-file-roller-xenial/blob/master/data/file-roller-extract-here.contract)
- [Set as Desktop Background](https://github.com/elementary/switchboard-plug-pantheon-shell/blob/master/set-wallpaper-contract/set-wallpaper.contract.in) (will be processed during the compilation process)
- [Write onto removable device](https://github.com/artemanufrij/imageburner/blob/master/data/com.github.artemanufrij.imageburner.contract)
- [QR Share](https://github.com/mubitosh/qrshare/blob/master/data/com.github.mubitosh.qrshare.contract)
- [Wallpaperize](https://github.com/Philip-Scott/wallpaperize/blob/master/data/com.github.philip-scott.wallpaperize.contract)
- [Show checksum](https://github.com/artemanufrij/hashit/blob/1d295b2a340d840898999059dd808439294aa89a/data/com.github.artemanufrij.hashit.contract)
