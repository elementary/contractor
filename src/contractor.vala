/*  
 * Copyright (C) 2011 Elementary Developers
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
 * Author: ammonkey <am.monkeyd@gmail.com>
 */ 

/* 
 * ContractFileService heavily inspired from Synapse DesktopFileService.
 * Kudos to the Synapse's developpers ! 
 */

using GLib;

namespace Contractor
{
    [DBus (name = "org.elementary.contractor")]
    public class Contractor : Object {
        construct {
            /*application_id = "org.elementary.contractor";
              flags = GLib.ApplicationFlags.IS_SERVICE;*/
            startup ();
        }

        private ContractFileService cfs;

        //protected override void startup () 
        private void startup () 
        {
            GLib.Intl.setlocale (GLib.LocaleCategory.ALL, GLib.Intl.get_language_names()[0]);
            GLib.Intl.textdomain (Build.GETTEXT_PACKAGE);
            cfs = new ContractFileService ();
        }
        

        private bool all_native;
        private bool is_native;
        private string common_parent;
        private string cmd_uris;

        GLib.HashTable<string,string>[] filtered;

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
                return GetServicesByLocation (location.lookup ("uri"),
                                              location.lookup ("mimetype"));
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
            foreach (var cc in cfs.conditional_contracts) {
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
        
        public GLib.HashTable<string,string>[]? GetServicesByLocation (string strlocation, string? file_mime = null) 
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
            foreach (var cc in cfs.conditional_contracts) {
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

    public class ContractFileInfo: Object
    {
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

        public ContractFileInfo.for_keyfile (string path, KeyFile keyfile)
        {
            Object (filename: path);

            init_from_keyfile (keyfile);
        }

        private void init_from_keyfile (KeyFile keyfile)
        {
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

    public class ContractFileService : Object
    {
        //private static unowned ContractFileService? cfservice;
        private List<File> directories;
        private FileMonitor monitor = null;

        private Gee.List<ContractFileInfo> all_contract_files;
        public Gee.List<ContractFileInfo> conditional_contracts;

        private Gee.Map<unowned string, Gee.List<ContractFileInfo> > mimetype_map;
        private Gee.Map<string, Gee.List<ContractFileInfo> > exec_map;
        private Gee.Map<string, ContractFileInfo> contract_id_map;

        public Gee.Map<string, ContractFileInfo> name_id_map;
        public Gee.Map<string, ContractFileInfo> exec_string_map;
        
        public bool initialized { get; private set; default = false; }

        public signal void initialization_done ();

        public ContractFileService ()
        {
            all_contract_files = new Gee.ArrayList<ContractFileInfo> ();
            conditional_contracts = new Gee.ArrayList<ContractFileInfo> ();
            initialize ();
        }

        private async void initialize ()
        {
            yield load_all_contract_files ();
            initialized = true;
            initialization_done ();
        }

        private async void load_all_contract_files (bool should_monitor=true)
        {
            Gee.Set<File> contract_file_dirs = new Gee.HashSet<File> ();

            directories = new List<File> ();
            var paths = Environment.get_system_data_dirs ();
            paths.resize (paths.length + 1); 
            paths[paths.length - 1] = Environment.get_user_data_dir ();
            foreach (var path in paths){
                debug ("Looking in "+path);
                var file = File.new_for_path (path+"/contractor/");
                directories.append (file);
                
                yield process_directory (file, contract_file_dirs);

                create_maps ();

                if (should_monitor) {
                    try {
                        monitor = file.monitor_directory (0);
                    } catch (IOError e) {
                        error ("directory monitor failed: %s", e.message);
                    }
                    monitor.changed.connect (contract_file_directory_changed);
                }
            }
        }

        private async void process_directory (File directory,
                                              Gee.Set<File> monitored_dirs)
        {
            try {
                /*bool exists = yield Utils.query_exists_async (directory);
                  if (!exists) return;*/
                var enumerator = yield directory.enumerate_children_async (
                                                                           FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE,
                                                                           0, 0);
                var files = yield enumerator.next_files_async (1024, 0);
                foreach (var f in files)
                {
                    unowned string name = f.get_name ();
                    if (f.get_file_type () == FileType.REGULAR && name.has_suffix (".contract"))
                    {
                        yield load_contract_file (directory.get_child (name));
                        message ("found: %s", name);
                    }
                }
            } catch (Error err) {
                warning ("%s", err.message);
            }
        }

        private async void load_contract_file (File file)
        {
            try {
                uint8[] contents;
                bool success = yield file.load_contents_async (null, out contents, null);
                var contents_str = (string) contents;
                size_t len = contents_str.length;
                
                if (success && len>0)
                {
                    var keyfile = new KeyFile ();
                    keyfile.load_from_data (contents_str, len, 0);
                    var cfi = new ContractFileInfo.for_keyfile (file.get_path (), keyfile);
                    if (cfi.is_valid) {
                        all_contract_files.add (cfi);
                    }
                    if (cfi.is_conditional) {
                        conditional_contracts.add (cfi);
                    }
                }
            } catch (Error err) {
                warning ("%s", err.message);
            }
        }

        private void create_maps ()
        {
            // create mimetype maps
            mimetype_map =
                new Gee.HashMap<unowned string, Gee.List<ContractFileInfo> > ();
            // and exec map
            exec_map =
                new Gee.HashMap<string, Gee.List<ContractFileInfo> > ();
            // and exec string map
            exec_string_map =
                new Gee.HashMap<string, ContractFileInfo> ();
            // and desktop id map
            contract_id_map =
                new Gee.HashMap<string, ContractFileInfo> ();
            // and name id map
            name_id_map =
                new Gee.HashMap<string, ContractFileInfo> ();

            Regex exec_re;
            try {
                exec_re = new Regex ("%[fFuU]");
            } catch (Error err) {
                critical ("%s", err.message);
                return;
            }

            foreach (var cfi in all_contract_files)
            {
                //message ("create_map %s", cfi.name);
                string exec = "";

                string[] parameter = null;
                MatchInfo info = null;

                try {
                    if (exec_re.match (cfi.exec, 0, out info)) {
                        parameter = info.fetch_all();
                        if (parameter.length != 1) {
                            warning ("argument definition eroned in %s", cfi.name);
                        } else {
                            var argt = parameter[0];
                            if (argt == "%u" || argt == "%f")
                                cfi.take_multi_args = false;
                            else
                                cfi.take_multi_args = true;
                            if (argt == "%u" || argt == "%U")
                                cfi.take_uri_args = true;
                            else
                                cfi.take_uri_args = false;
                            //cfi.args = parameter[0];
                        }
                    }
                    exec = exec_re.replace_literal (cfi.exec, -1, 0, "%s");
                    //message ("exec: %s", exec);
                } catch (RegexError err) {
                    error ("%s", err.message);
                }
                exec = exec.strip ();
                cfi.exec = exec;
                // update exec map
                Gee.List<ContractFileInfo>? exec_list = exec_map[exec];
                if (exec_list == null)
                {
                    exec_list = new Gee.ArrayList<ContractFileInfo> ();
                    exec_map[exec] = exec_list;
                }
                exec_list.add (cfi);

                // update exec sting map
                if (cfi.exec_string != null)
                    exec_string_map [Path.get_basename (cfi.filename)] = cfi;

                // update contract id map
                contract_id_map[Path.get_basename (cfi.filename)] = cfi;

                // update name id map
                name_id_map[cfi.name] = cfi;

                // update mimetype map
                if (cfi.mime_types == null) continue;

                foreach (unowned string mime_type in cfi.mime_types)
                {
                    Gee.List<ContractFileInfo>? list = mimetype_map[mime_type];
                    if (list == null)
                    {
                        list = new Gee.ArrayList<ContractFileInfo> ();
                        mimetype_map[mime_type] = list;
                    }
                    list.add (cfi);
                }
            }
        }

        private uint timer_id = 0;

        private void contract_file_directory_changed (File file, File? other_file, FileMonitorEvent event)
        {
            //message ("file_directory_changed");
            if (timer_id != 0)
            {
                Source.remove (timer_id);
            }

            timer_id = Timeout.add (1000, () =>
            {
                timer_id = 0;
                reload_contract_files ();
                return false;
            });
        }

        private async void reload_contract_files ()
        {
            debug ("Reloading contract files...");
            all_contract_files.clear ();
            conditional_contracts.clear ();
            yield load_all_contract_files (false);
        }

        private void add_cfi_for_mime (string mime, Gee.Set<ContractFileInfo> ret)
        {
            var cfis = mimetype_map[mime];
            if (cfis != null) ret.add_all (cfis);
        }

        public Gee.List<ContractFileInfo> get_contract_files_for_type (string mime_type)
        {
            var cfi_set = new Gee.HashSet<ContractFileInfo> ();
            add_cfi_for_mime (mime_type, cfi_set);
            var ret = new Gee.ArrayList<ContractFileInfo> ();
            ret.add_all (cfi_set);
            return ret;
        }

        /*public void get_contracts_for_string ()
        {
            GLib.HashTable<string,string>[] filtered = null;
            //GLib.HashTable<string,string>[] filtered = null;
            //foreach (ContractFileInfo cfi in exec_string_map)
            foreach (var cfi in exec_string_map.values) {
                filtered += get_filtered_entry_for_string (cfi);
                message ("exec_string %s", cfi.name);
            }
        }*/
    }

    void name_last_callback () {
        print ("could not aquire name\n\n");
        Process.exit (1);
    }
    void on_bus_aquired (DBusConnection conn) {
        try {
            conn.register_object ("/org/elementary/contractor", new Contractor ());
        } catch (IOError e) {
            error ("Could not register service\n");
        }
    }

    public static int main (string[] args) {
        //var app = new Contractor ();
        //app.run (args);
        Bus.own_name (BusType.SESSION, "org.elementary.contractor", BusNameOwnerFlags.NONE,
                      on_bus_aquired,
                      () => {},
                      name_last_callback);
        
        new MainLoop ().run ();

        return 0;
    }

}

namespace Translations {

    const string archive_name = N_("Archives");
    const string archive_desc = N_("Extract here");
    const string archive_compress = N_("Compress");
    const string wallpaper_name = N_("Wallpaper");
    const string wallpaper_desc = N_("Set as Wallpaper");

}
