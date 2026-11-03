# Contractor

## Building, Testing, and Installation

You'll need the following dependencies:
* libdbus-1-dev
* libgee-0.8-dev
* libglib2.0-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install

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
- `Submenu`: Optional menu path. Contracts that share the same value are grouped under that submenu by the client. `/` separates nested labels (`Archive/Compress`). A missing or empty value keeps the item at the top level. Localized keys work the same way as `Name` (`Submenu[pt_BR]=Arquivo`). The Contractor service returns the translated path; the client draws the submenu and hides a group when none of its contracts match the current files.

`Submenu` is available from `list_all_contract_entries` and `get_contract_entries_by_mimelist_and_file_size`. The older methods still return a flat list without this field.

Tips:
- Use `pkexec` to ask for root permissions. Example: `Exec=pkexec chmod +x %U`

## Examples
- [Send by Email](https://github.com/elementary/mail/blob/master/data/mail-attach.contract)
- [Print](https://github.com/elementary/pantheon-print/blob/master/data/print.contract)
- [Send files via Bluetooth](https://github.com/codygarver/os-patch-gnome-bluetooth-xenial/blob/master/debian/gnome-bluetooth.contract)
- [Compress](https://github.com/codygarver/os-patch-file-roller-xenial/blob/master/data/file-roller-compress.contract)
- [Extract Here](https://github.com/codygarver/os-patch-file-roller-xenial/blob/master/data/file-roller-extract-here.contract)
- [Write onto removable device](https://github.com/artemanufrij/imageburner/blob/master/data/com.github.artemanufrij.imageburner.contract)
- [QR Share](https://github.com/mubitosh/qrshare/blob/master/data/com.github.mubitosh.qrshare.contract)
- [Wallpaperize](https://github.com/Philip-Scott/wallpaperize/blob/master/data/com.github.philip-scott.wallpaperize.contract)
- [Show checksum](https://github.com/artemanufrij/hashit/blob/1d295b2a340d840898999059dd808439294aa89a/data/com.github.artemanufrij.hashit.contract)
- [GPG Encrypt/Decrypt](https://github.com/phocean/contracts-gpg)
