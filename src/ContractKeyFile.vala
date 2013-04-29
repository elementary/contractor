/*
 * Copyright (C) 2013 elementary Developers
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Contractor.ContractKeyFile : Object {
    private const string FILE_GROUP = "Contractor Entry";
    private const string GROUP = KeyFileDesktop.GROUP;
    private const string NAME_KEY = "Name";
    private const string ICON_KEY = "Icon";
    private const string DESCRIPTION_KEY = "Description";
    private const string MIMETYPE_KEY = "MimeType";

    private const string[] SUPPORTED_GETTEXT_DOMAIN_KEYS = {
        "Gettext-Domain",
        "X-Ubuntu-Gettext-Domain",
        "X-GNOME-Gettext-Domain"
    };

    private string text_domain;
    private KeyFile keyfile;

    public ContractKeyFile (ContractFile contract_file) throws Error {
        string contract_file_contents = contract_file.get_contents ();
        string contents = preprocess_contents (contract_file_contents);

        keyfile = new KeyFile ();
        keyfile.load_from_data (contents, contents.length, KeyFileFlags.NONE);

        // Add this so that we can use the key file with GDesktopAppInfo.
        keyfile.set_string (KeyFileDesktop.GROUP,
                            KeyFileDesktop.KEY_TYPE,
                            KeyFileDesktop.TYPE_APPLICATION);

        text_domain = get_text_domain ();
    }

    public AppInfo get_app_info () {
        return new DesktopAppInfo.from_keyfile (keyfile);
    }

    public string get_name () throws Error {
        return get_locale_string (NAME_KEY, text_domain);
    }

    public string get_description () throws Error {
        return get_locale_string (DESCRIPTION_KEY, text_domain);
    }

    public string get_icon () throws Error {
        return keyfile.get_string (GROUP, ICON_KEY);
    }

    public string get_mimetypes () throws Error {
        return keyfile.get_string (GROUP, MIMETYPE_KEY);
    }

    private string get_text_domain () throws Error {
        foreach (var domain_key in SUPPORTED_GETTEXT_DOMAIN_KEYS) {
            if (keyfile.has_key (GROUP, domain_key))
                return keyfile.get_string (GROUP, domain_key);
        }

        return "";
    }

    private string get_locale_string (string key, string text_domain) throws Error {
        string value = keyfile.get_locale_string (GROUP, key);
        return dgettext (text_domain, value).dup ();
    }

    private static string preprocess_contents (string contents) {
        // replace [Contractor Entry] with [Desktop Entry] so that we can use
        // GLib's implementation of GDesktopAppInfo.
        return contents.replace (FILE_GROUP, GROUP);
    }
}

