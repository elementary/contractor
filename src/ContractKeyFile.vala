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
    private const string CONTRACTOR_GROUP = "Contractor Entry";
    private const string DESKTOP_GROUP = KeyFileDesktop.GROUP;

    private const string NAME_KEY = KeyFileDesktop.KEY_NAME;
    private const string DESCRIPTION_KEY = "Description";
    private const string ICON_KEY = KeyFileDesktop.KEY_ICON;
    private const string MIMETYPE_KEY = KeyFileDesktop.KEY_MIME_TYPE;
    private const string MAX_FILE_SIZE_KEY = "MaxFileSize";
    private const string EXEC_KEY = KeyFileDesktop.KEY_EXEC;
    private const string TRY_EXEC_KEY = KeyFileDesktop.KEY_TRY_EXEC;

    private const string[] SUPPORTED_GETTEXT_DOMAIN_KEYS = {
        "Gettext-Domain",
        "X-Ubuntu-Gettext-Domain",
        "X-GNOME-Gettext-Domain"
    };

    private string text_domain;
    private KeyFile keyfile;

    /**
     * the constructor to create a ContractKeyFile object which loads the
     * content of the passed ContractFile object and sets up an internally
     * stored KeyFile object to access individual contract fields
     */
    public ContractKeyFile (ContractFile contract_file) throws Error {
        string contract_file_contents = contract_file.get_contents ();
        string contents = preprocess_contents (contract_file_contents);

        keyfile = new KeyFile ();
        keyfile.load_from_data (contents, contents.length, KeyFileFlags.NONE);

        verify_exec ();

        // Add this so that we can use the key file with GDesktopAppInfo.
        keyfile.set_string (KeyFileDesktop.GROUP,
                            KeyFileDesktop.KEY_TYPE,
                            KeyFileDesktop.TYPE_APPLICATION);

        text_domain = get_text_domain ();

        get_app_info (); // perform initial validation
    }

    public AppInfo get_app_info () throws Error {
        var app_info = new DesktopAppInfo.from_keyfile (keyfile);

        if (app_info == null) {
            throw new FileError.NOENT ("%s's file is probably missing.", TRY_EXEC_KEY);
        }

        return app_info;
    }

    /**
     * gets the contracts name from the key file
     *
     * @return the contracts name
     */
    public string get_name () throws Error {
        return get_locale_string (NAME_KEY);
    }

    /**
     * gets the contracts description from the key file
     *
     * @return the contracts description
     */
    public string get_description () throws Error {
        return get_locale_string (DESCRIPTION_KEY);
    }

    /**
     * gets the contracts icon from the key file
     *
     * @return the contracts icon, e.g. add-files-to-archive
     */
    public string get_icon () throws Error {
        return keyfile.get_string (DESKTOP_GROUP, ICON_KEY);
    }

    /**
     * gets the contracts supported MIME types from the key file
     *
     * @return an array of MIME type strings, e.g. text, image
     */
    public string[] get_mimetypes () throws Error {
        return keyfile.get_string_list (DESKTOP_GROUP, MIMETYPE_KEY);
    }

    /**
     * gets the contracts supported maximal file size from the key file
     * the return value can be used directly in GLib
     *
     * @return the maximal file size in bytes as int64
     */
    public int64 get_max_file_size () throws Error {
        return keyfile.get_int64 (DESKTOP_GROUP, MAX_FILE_SIZE_KEY);
    }

    private void verify_exec () throws Error {
        string exec = keyfile.get_string (DESKTOP_GROUP, EXEC_KEY);
        verify_string (exec, EXEC_KEY);
    }

    private string get_text_domain () throws Error {
        foreach (var domain_key in SUPPORTED_GETTEXT_DOMAIN_KEYS) {
            if (keyfile.has_key (DESKTOP_GROUP, domain_key)) {
                return keyfile.get_string (DESKTOP_GROUP, domain_key);
            }
        }

        return "";
    }

    private string get_locale_string (string key) throws Error {
        string locale_string = keyfile.get_locale_string (DESKTOP_GROUP, key);
        verify_string (locale_string, key);
        return Translations.get_string (text_domain, locale_string);
    }

    private static void verify_string (string? str, string key) throws Error {
        if (String.is_empty (str)) {
            throw new KeyFileError.INVALID_VALUE ("%s key is empty.", key);
        }
    }

    private static string preprocess_contents (string contents) {
        // replace [Contractor Entry] with [Desktop Entry] so that we can use
        // GLib's implementation of GDesktopAppInfo.
        return contents.replace (CONTRACTOR_GROUP, DESKTOP_GROUP);
    }
}
