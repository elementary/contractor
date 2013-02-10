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

using GLib;
using Contractor;
namespace Contractor{
    // the main constractor class where everything comes together
    [DBus (name = "org.elementary.Contractor")]
    public class Contractor : Object {
        private ContractFileService cfs;
        GLib.HashTable<string,string>[] filtered;
        construct{
            message("starting Contractor...");
            GLib.Intl.setlocale (GLib.LocaleCategory.ALL, "");
            GLib.Intl.textdomain (Build.GETTEXT_PACKAGE);
            cfs = new ContractFileService ();
        }
        public void ping (string msg) {
        stdout.printf ("%s\n", msg);
        }
        public signal void pong ();

        public string list_all_contracts(){
           return cfs.list_all_contracts();
        }

        private bool all_native;
        private bool is_native;
        private string common_parent;
        private string cmd_uris;

        //GLib.HashTable<string,string>[] filtered;

        /* generate possible contracts for list of arguments and filter them by
           common parent mimetype and all.
           We don't want to waste time and ressources determining the common contracts
           for each files one by one */
        public GLib.HashTable<string,string>[]? GetServicesByLocationsList (GLib.HashTable<string,string>[] locations)
        {
            filtered = null;
            if (!cfs.initialized)
                return null;

            var nbargs = locations.length;
            //message ("locationslist %d", nbargs);

            if (nbargs == 1) {
                GLib.HashTable<string,string> location = locations[0];
                return GetServicesByLocation (location.lookup ("uri"));
            }

            analyse_similarities (locations);

            //message ("common parent %s", common_parent);
            var list_for_all = cfs.get_contract_files_for_type ("all");
            if (list_for_all.size > 0)
            {
                foreach (var entry in list_for_all) {
                    multi_args_add_contract_to_filtered_table (entry);
                }
            }

            if (common_parent != null)
            {
                var list_for_parent = cfs.get_contract_files_for_type (common_parent);
                if (list_for_parent.size > 0)
                {
                    foreach (var entry in list_for_parent) {
                        multi_args_add_contract_to_filtered_table (entry);
                    }
                }
            }

            /* conditional contracts are contracts which own mime_type entries containing special conditional character(s) like ! for negation. Thoses conditionnals characters can apply to another contract mime group, a parent_mime or a mime type. At the moment it's relatively simple but maybe later we can extend conditionals to characters like & | () */
            foreach (var cc in cfs.conditional_contracts_files) {
                debug ("CC %s %s", cc.name, cc.conditional_mime);
                var len = cc.conditional_mime.length;
                if (len >= 2) {
                    string str = cc.conditional_mime.slice (1, len);
                    /* check if the conditional target another contract name, check if the first letter is a maj */
                    if (str.get_char (0) >= 'A' && str.get_char (0) <= 'Z') {
                        /* check if the contract exist */
                        var contract_target = cfs.name_id_map[str];
                        if (contract_target != null && !is_contract_in_filtered (str))
                        {
                            /* check if the contract isn't filtered
                               and the matches on corresponding mimetype */
                            if (!is_contract_in_filtered (str)
                                && contract_target.mime_types != null)
                            {
                                bool ret;
                                if (cc.strict_condition)
                                    ret = are_locations_mimes_match_strict_conditional_contract_mimes (contract_target.mime_types, locations);
                                else
                                    ret = are_locations_mimes_match_conditional_contract_mimes (contract_target.mime_types, locations);
                                if (ret)
                                    multi_args_add_contract_to_filtered_table (cc);
                            }
                        } else {
                            warning ("%s, Conditional MimeType %s doesn't match anything", cc.name, cc.conditional_mime);
                        }
                    } else if (str.contains("/")) {
                        /* could be a mimetype */
                        if (are_locations_match_conditional_mime (locations, str)) {
                            multi_args_add_contract_to_filtered_table (cc);
                        }
                    } else {
                        /* could be a parent */
                        if (common_parent != null && common_parent != str) {
                            multi_args_add_contract_to_filtered_table (cc);
                        }
                    }
                }
            }

            return filtered;
        }

        public GLib.HashTable<string,string>[]? GetServicesByLocation (string strlocation)
        {
            File file = File.new_for_commandline_arg (strlocation);

            filtered = null;
            if (!cfs.initialized)
                return null;

            is_native = file.is_native ();

            /*if (file.query_exists ()) {
              message ("file exist");
              }*/
            string mimetype;
            string parent_mime = null;
            string file_mime = null;
            if (file_mime == null || file_mime.length <= 0)
                mimetype = query_content_type (file);
            else
                mimetype = file_mime;

            //message ("test path %s %s %s", file.get_path (), file.get_uri (), mimetype);
            if (mimetype != null)
            {
                var list_for_all = cfs.get_contract_files_for_type ("all");
                if (list_for_all.size > 0)
                {
                    foreach (var entry in list_for_all)
                    {
                        single_arg_add_contract_to_filtered_table (entry, file);
                    }
                }
                parent_mime = get_parent_mime (mimetype);
                if (parent_mime != null)
                {
                    var list_for_parent = cfs.get_contract_files_for_type (parent_mime);
                    if (list_for_parent.size > 0)
                    {
                        foreach (var entry in list_for_parent) {
                            single_arg_add_contract_to_filtered_table (entry, file);
                        }
                    }
                }
                var list_for_mimetype = cfs.get_contract_files_for_type (mimetype);
                if (list_for_mimetype.size > 0)
                {
                    foreach (var entry in list_for_mimetype) {
                        single_arg_add_contract_to_filtered_table (entry, file);
                    }
                }
            }

            /* conditional contracts are contracts which own mime_type entries containing special conditional character(s) like ! for negation. Thoses conditionnals characters can apply to another contract mime group, a parent_mime or a mime type. At the moment it's relatively simple but maybe later we can extend conditionals to characters like & | () */
            foreach (var cc in cfs.conditional_contracts_files) {
                debug ("CC %s %s", cc.name, cc.conditional_mime);
                var len = cc.conditional_mime.length;
                if (len >= 2) {
                    string str = cc.conditional_mime.slice (1, len);
                    /* check if the conditional target another contract name, check if the first letter is a maj */
                    if (str.get_char (0) >= 'A' && str.get_char (0) <= 'Z') {
                        /* check if the contract exist */
                        var contract_target = cfs.name_id_map[str];
                        if (contract_target != null) {
                            /* check is the contract isn't filtered and the matches on corresponding mimetype */
                            if (!is_contract_in_filtered (str)
                                && contract_target.mime_types != null
                                && is_mime_match_conditional_contract_mimes (contract_target.mime_types, mimetype))
                            {
                                single_arg_add_contract_to_filtered_table (cc, file);
                            }
                        } else {
                            warning ("%s, Conditional MimeType %s doesn't match anything", cc.name, cc.conditional_mime);
                        }
                    } else if (str.contains("/")) {
                        /* could be a mimetype */
                        if (mimetype != str) {
                            single_arg_add_contract_to_filtered_table (cc, file);
                        }
                    } else {
                        /* could be a parent */
                        if (parent_mime != null && parent_mime != str) {
                            single_arg_add_contract_to_filtered_table (cc, file);
                        }
                    }
                }
            }

            return filtered;
        }

        public GLib.HashTable<string,string>[] GetServicesForString ()
        {
            GLib.HashTable<string,string>[] filtered = null;

            //message ("GetServicesForString");
            foreach (var cfi in cfs.exec_string_map.values) {
                filtered += get_filtered_entry_for_string (cfi);
                //message ("exec_string %s", cfi.name);
            }

            return filtered;
        }

        private void multi_args_add_contract_to_filtered_table (ContractFileInfo entry)
        {
            if (!(!all_native && !entry.take_uri_args)
                && !(!entry.take_multi_args))
            {
                var filtered_entry = get_filtered_entry_for_list (entry);
                //debug ("desc: %s exec: %s", filtered_entry.lookup ("Description"), filtered_entry.lookup ("Exec"));
                filtered += filtered_entry;
            }
        }

        private void single_arg_add_contract_to_filtered_table (ContractFileInfo entry, File file)
        {
            if (!(!is_native && !entry.take_uri_args))
            {
                var filtered_entry = get_filtered_entry (entry, file);
                //debug ("desc: %s exec: %s", filtered_entry.lookup ("Description"), filtered_entry.lookup ("Exec"));
                filtered += filtered_entry;
            }
        }

        private void analyse_similarities (GLib.HashTable<string,string>[] locations)
        {
            string[] pmimes = null;
            bool[] natives = null;

            all_native = true;
            common_parent = null;
            cmd_uris = "";

            foreach (var location in locations) {
                var uri = location.lookup ("uri");
                cmd_uris += uri + " ";
                File file = File.new_for_commandline_arg (uri);
                string mimetype = location.lookup ("mimetype");
                if (mimetype == null || mimetype.length <= 0)
                    mimetype = query_content_type (file);
                pmimes += get_parent_mime (mimetype);
                natives += file.is_native ();
            }

            foreach (var pmime in pmimes) {
                if (pmime != null) {
                    if (common_parent == null)
                        common_parent = pmime;
                    else {
                        if (pmime != common_parent) {
                            common_parent = null;
                            break;
                        }
                    }
                }else {
                    common_parent = null;
                    break;
                }
            }

            foreach (var native in natives) {
                if (!native) {
                    all_native = false;
                    break;
                }
            }
        }

        private bool are_locations_match_conditional_mime (GLib.HashTable<string,string>[] locations, string mime)
        {
            foreach (var location in locations) {
                if (location.lookup ("mimetype") == mime)
                    return false;
            }

            return true;
        }

        private bool is_mime_match_conditional_contract_mimes (string[] mime_types, string mime)
        {
            foreach (var umime in mime_types) {
                if (umime == mime)
                    return false;
            }

            return true;
        }

        private bool are_locations_mimes_match_strict_conditional_contract_mimes (string[] mime_types, GLib.HashTable<string,string>[] locations)
        {
            foreach (var location in locations) {
                var mime = location.lookup ("mimetype");
                foreach (var umime in mime_types)
                {
                    if (umime == mime)
                        return false;
                }
            }

            return true;
        }

        /* at least one arg should respect the condition */
        private bool are_locations_mimes_match_conditional_contract_mimes (string[] mime_types, GLib.HashTable<string,string>[] locations)
        {
            uint mlength = mime_types.length;
            foreach (var location in locations) {
                var mime = location.lookup ("mimetype");
                var count = 0;
                foreach (var umime in mime_types)
                {
                    if (umime != mime)
                        count++;
                }
                if (count == mlength)
                    return true;
            }

            return false;
        }

        private bool is_contract_in_filtered (string contract_name) {
            foreach (var entry in filtered) {
                if (entry.lookup ("Name") == contract_name)
                    return true;
            }

            return false;
        }

        private GLib.HashTable<string,string> get_filtered_entry_for_list (ContractFileInfo entry)
        {
            GLib.HashTable<string,string> filtered_entry;

            filtered_entry = new GLib.HashTable<string,string> (str_hash, str_equal);
            filtered_entry.insert ("Name", entry.name);
            filtered_entry.insert ("Description", entry.description);
            filtered_entry.insert ("Exec", entry.exec.printf (cmd_uris));
            filtered_entry.insert ("IconName", entry.icon_name);

            return filtered_entry;
        }

        private GLib.HashTable<string,string> get_filtered_entry (ContractFileInfo entry, File file)
        {
            GLib.HashTable<string,string> filtered_entry;

            filtered_entry = new GLib.HashTable<string,string> (str_hash, str_equal);
            filtered_entry.insert ("Name", entry.name);
            filtered_entry.insert ("Description", entry.description);
            filtered_entry.insert ("Exec", get_exec_from_entry (entry, file));
            filtered_entry.insert ("IconName", entry.icon_name);

            return filtered_entry;
        }

        private GLib.HashTable<string,string> get_filtered_entry_for_string (ContractFileInfo entry)
        {
            GLib.HashTable<string,string> filtered_entry;

            filtered_entry = new GLib.HashTable<string,string> (str_hash, str_equal);
            filtered_entry.insert ("Name", entry.name);
            filtered_entry.insert ("Description", entry.description);
            filtered_entry.insert ("Exec", entry.exec_string);
            filtered_entry.insert ("IconName", entry.icon_name);

            return filtered_entry;
        }

        private string get_exec_from_entry (ContractFileInfo cfi, File file)
        {
            if (cfi.take_uri_args)
                return (cfi.exec.printf (file.get_uri ()));
            else
                return (cfi.exec.printf (file.get_path ()));
        }

        private string get_parent_mime (string mimetype)
        {
            string parentmime = null;
            var arr = mimetype.split ("/", 2);
            if (arr.length == 2)
                parentmime = arr[0];

            return parentmime;
        }

        private string query_content_type (File file)
        {
            string mimetype = null;

            try {
                var file_info = file.query_info ("standard::content-type", FileQueryInfoFlags.NONE);
                mimetype = file_info.get_content_type ();
            } catch (Error e) {
                warning ("file query_info error %s: %s\n", file.get_uri (), e.message);
            }

            return mimetype;
        }
    }
    /* starts the contractor goodnes
       creates a new Bus and enters the main loops
    */
    private MainLoop loop;
    void main(){
        Bus.own_name (BusType.SESSION, "org.elementary.Contractor", BusNameOwnerFlags.NONE,
                      on_bus_aquired,
                      () => {},
                      () => on_bus_not_aquired);
        loop = new MainLoop ();
        loop.run();
        }
    // trys to aquire the bus 
    private void on_bus_aquired(DBusConnection conn){
        try {
            conn.register_object("/org/elementary/contractor", new Contractor());
        } catch (IOError e) {
            stderr.printf("Could not register service because: %s \n",e.message);
        }
    }
    private void on_bus_not_aquired(){
        stderr.printf("Could not aquire Session bus for contractor\n");
        loop.quit();
    }
}

namespace Translations {
    const string archive_name = N_("Archives");
    const string archive_desc = N_("Extract here");
    const string archive_compress = N_("Compress");
    const string wallpaper_name = N_("Wallpaper");
    const string wallpaper_desc = N_("Set as Wallpaper");
}