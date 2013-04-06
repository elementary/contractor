/*
 * Copyright (C) 2011-2013 elementary Developers
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
 *
 * Authors: ammonkey <am.monkeyd@gmail.com>,
 *          lampe2 <michael@lazarski.me>,
 *          Akshay Shekher <voldyman666@gmail.com>,
 *          Sergey "Shnatsel" Davidoff <sergey@elementaryos.org>
 *
 * The original Contractor implementation in Python was created by:
 *          Allen Lowe <lallenlowe@gmail.com>
 */

namespace Contractor {
    /*
        This representation of a contract is returned to clients via D-bus API
    */
    public struct GenericContract {
           string id;
           string display_name;
           string description;
           string icon_path;
    }

    public class FileInfo: Object {
        public string id { get; construct set; }
        public string name { get; construct set; }
        public string exec { get; set; }
        public string exec_string { get; set; }
        public string description { get; set; }
        public string[] mime_types = null;
        public string conditional_mime;
        public string icon_name { get; construct set; default = ""; }
        public bool take_multi_args { get; set; }
        public bool take_uri_args { get; set; }
        public string filename { get; construct set; }
        public bool is_valid { get; private set; default = true; }
        public bool is_conditional { get; private set; default = false; }
        /* used in the context of multiples arguments. If true, all arguments should respect the condition. If false, at least one argument should respect it. Default true */
        public bool strict_condition { get; private set; default = true; }
        private const string[] SUPPORTED_GETTEXT_DOMAINS_KEYS = { "Gettext-Domain", "X-Ubuntu-Gettext-Domain", "X-GNOME-Gettext-Domain" };
        private static const string GROUP = "Contractor Entry";
        /*
        *
        * status: TODO
        */
        public FileInfo(File file) {
            try {
                uint8[] contents;
                // check if there is a file
                bool success = file.load_contents (null, out contents, null);
                // parse content to string
                var contents_str = (string) contents;
                // get the length of the
                size_t len = contents_str.length;
                if (success && len > 0) {
                    // creating a new KeyFile
                    var keyfile = new KeyFile ();
                    keyfile.load_from_data (contents_str, len, 0);
                    // addin a ID
                    this.id = get_contract_id (file);
                    //initing the keyfile
                    init_from_keyfile (keyfile);
                }else {
                    throw new IOError.NOT_FOUND ("something went wrong on this %s file",this.id);
                }
            } catch (Error err) {
                 warning ("%s", err.message);
            }
        }
        /*
        *
        * status: TODO
        */
        private void init_from_keyfile (KeyFile keyfile) {
            try {
                name = keyfile.get_locale_string (GROUP, "Name");
                string? textdomain = null;
                foreach (var domain_key in SUPPORTED_GETTEXT_DOMAINS_KEYS) {
                    if (keyfile.has_key (GROUP, domain_key)) {
                        textdomain = keyfile.get_string (GROUP, domain_key);
                        break;
                    }
                }
                if (textdomain != null)
                    name = GLib.dgettext (textdomain, name).dup ();

            } catch (Error e) {
                warning ("Couldn't read Name field %s", e.message);
                is_valid = false;
            }

            try {
                exec = keyfile.get_string (GROUP, "Exec");
            } catch (Error e) {
                warning ("Couldn't read Exec field %s", e.message);
                is_valid = false;
            }

            try {
                description = keyfile.get_locale_string (GROUP, "Description");
                string? textdomain = null;
                foreach (var domain_key in SUPPORTED_GETTEXT_DOMAINS_KEYS) {
                    if (keyfile.has_key (GROUP, domain_key)) {
                        textdomain = keyfile.get_string (GROUP, domain_key);
                        break;
                    }
                }
                if (textdomain != null)
                    description = GLib.dgettext (textdomain, description).dup ();
            } catch (Error e) {
                warning ("Couldn't read title field %s", e.message);
                is_valid = false;
            }

            try {
                conditional_mime = keyfile.get_string (GROUP, "MimeType");
                if (conditional_mime.contains ("!")) {
                    is_conditional = true;
                    strict_condition = keyfile.get_boolean (GROUP, "StrictCondition");
                    if (conditional_mime.contains (";"))
                        warning ("%s: multi arguments in conditional mimetype are not currently supported: %s", name, conditional_mime);
                } else {
                    mime_types = keyfile.get_string_list (GROUP, "MimeType");
                }
            } catch (Error e) {
                warning ("Couldn't read MimeType field %s",e.message);
                is_valid = false;}

            try {
                if (keyfile.has_key (GROUP, "Icon")) {
                    icon_name = keyfile.get_locale_string (GROUP, "Icon");
                    if (!Path.is_absolute (icon_name) &&
                       (icon_name.has_suffix (".png") ||
                        icon_name.has_suffix (".svg") ||
                        icon_name.has_suffix (".xpm"))) {
                        icon_name = icon_name.substring (0, icon_name.length - 4);
                    }
                }
            } catch (Error e) {
                warning ("Couldn't read Icon field %s", e.message);
                is_valid = false;
            }

            try {
                if (keyfile.has_key (GROUP, "ExecString"))
                    exec_string = keyfile.get_string (GROUP, "ExecString");
            } catch (Error e) {
                warning ("Couldn't read ExecString field %s", e.message);
                is_valid = false;
            }
        }
        /*
        *
        * status: TODO
        */
        private string get_contract_id (File file) {
            GLib.FileInfo q_info = new GLib.FileInfo ();
            try {
                q_info = file.query_info ("*", FileQueryInfoFlags.NONE);
            } catch (Error e) { warning (e.message);}
            return get_parent_until (file, "contractor") + strip_file_extension (q_info.get_name (), "contract");
        }
        /*
        *
        * status: TODO
        */
        private string strip_file_extension (string filename, string extension) {
            //usage: strip_file_extension ("/path/to/file.extension", "extension")
            var index_of_last_dot = filename.last_index_of (".");
            if (filename.slice (index_of_last_dot, filename.length) == "." + extension) {
                return filename.slice (0, index_of_last_dot);
            } else {
                return filename;
            }
        }
        /*
        *
        * status: TODO
        */
        private string get_parent_until (File file, string until_dir) {
            File parent = file.get_parent ();
            if (parent.get_basename ().down () == until_dir.down ())
                return "";
            else
                return parent.get_basename () + "/" + get_parent_until (parent, until_dir);
        }
        /*
        *
        * status: TODO
        */
        public GenericContract to_generic_contract () {
            return GenericContract () {
                id = this.id,
                display_name = this.name,
                description = this.description,
                icon_path = this.icon_name
            };
        }
    }
}
