/*
 * Copyright (C) 2013 Elementary Developers
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
 * Author: lampe2 mgoldhand@googlemail.com
 */
 
namespace Contractor{
	 public class ContractFileInfo: Object{
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
        private const string[] SUPPORTED_GETTEXT_DOMAINS_KEYS = {"X-Ubuntu-Gettext-Domain", "X-GNOME-Gettext-Domain"};
        private static const string GROUP = "Contractor Entry";

        public ContractFileInfo.for_keyfile(string path, KeyFile keyfile)
        {
            Object(filename: path);
            init_from_keyfile(keyfile);
        }

        private void init_from_keyfile(KeyFile keyfile)
        {
            try {
                name = keyfile.get_locale_string(GROUP, "Name");
                string? textdomain = null;
                foreach(var domain_key in SUPPORTED_GETTEXT_DOMAINS_KEYS){
                    if (keyfile.has_key (GROUP, domain_key)) {
                        textdomain = keyfile.get_string (GROUP, domain_key);
                        break;
                    }
                }
                if (textdomain != null)
                    name = GLib.dgettext (textdomain, name).dup ();

            } catch (Error e) { warning("Couldn't read Name field %s", e.message); is_valid = false;}
            try {
                exec = keyfile.get_string (GROUP, "Exec");
            } catch (Error e) { warning("Couldn't read Exec field %s", e.message); is_valid = false;}
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
            } catch (Error e) { warning("Couldn't read title field %s", e.message); is_valid = false;}
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
            } catch (Error e) { warning("Couldn't read MimeType field %s", e.message); is_valid = false;}
            try {
                if (keyfile.has_key (GROUP, "Icon"))
                {
                    icon_name = keyfile.get_locale_string (GROUP, "Icon");
                    if (!Path.is_absolute (icon_name) &&
                        (icon_name.has_suffix (".png") ||
                         icon_name.has_suffix (".svg") ||
                         icon_name.has_suffix (".xpm")))
                    {
                        icon_name = icon_name.substring (0, icon_name.length - 4);
                    }
                }
            } catch (Error e) { warning("Couldn't read Icon field %s", e.message); is_valid = false;}
            try {
                if (keyfile.has_key (GROUP, "ExecString"))
                    exec_string = keyfile.get_string (GROUP, "ExecString");
            } catch (Error e) { warning("Couldn't read ExecString field %s", e.message); is_valid = false;}
        }
    }
}