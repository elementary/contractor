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
	public class ContractFileService : Object{
        // all contract files with conditional
		private Gee.List<ContractFileInfo> contracts_files;
        // only conditional contract files
        public Gee.List<ContractFileInfo> conditional_contracts_files;
        public bool initialized { get; private set; default = false; }
		public ContractFileService (){
            contracts_files = new Gee.ArrayList<ContractFileInfo> ();
            conditional_contracts_files = new Gee.ArrayList<ContractFileInfo> ();
            load_contracts_files();
            initialized = true;
        }

        /* 
        *   status: create_maps need to be implemented
        */
        private Gee.ArrayList<FileMonitor> monitors;
		private void load_contracts_files (bool should_monitor=true){
			message("loading necessary files");
            var count = 0;
            monitors = new Gee.ArrayList<FileMonitor>();
            //get paths from enviroment
            var paths = Environment.get_system_data_dirs ();
            paths.resize (paths.length + 1);
            paths[paths.length - 1] = Environment.get_user_data_dir ();
            foreach(var path in paths){
                var directory = File.new_for_path(path+"/contractor/");
                message(directory.get_path());
                if (directory.query_exists()){
                    process_directory(directory);
                    if (should_monitor){
                        try{
                            monitors.add(directory.monitor_directory(FileMonitorFlags.NONE, null));
                        } catch (IOError e){
                            error("%s monitor failed: %s", directory.get_path(), e.message);
                        }
                        monitors[count].changed.connect(contract_file_directory_changed);
                        count =+ 1;
                    }
                }           
                create_maps ();
            }
		}

        /* 
        *   status: needs comments and documentary
        */
		private void process_directory(File directory)
        {
            try {
                var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
                FileInfo f = null;
                while ((f = enumerator.next_file ()) != null) {
                    unowned string name = f.get_name ();
                    if (f.get_file_type () == FileType.REGULAR && name.has_suffix (".contract"))
                    {
                        load_contract_file (directory.get_child(name));
                    }
                }
             } catch (Error err) {
                 warning ("%s name %s", err.message, directory.get_path());
             }
        }
        /*  loads the specifi contractor file parses it and  
        *   adds it to the list of contracts
        *   status: needs comment and documentary
        */
        private void load_contract_file(File file)
        {
            try {
                uint8[] contents;
                bool success = file.load_contents (null, out contents, null);
                var contents_str = (string)contents;
                size_t len = contents_str.length;

                if (success && len>0)
                {
                    var keyfile = new KeyFile();
                    keyfile.load_from_data (contents_str, len, 0);
                    var cfi = new ContractFileInfo.for_keyfile(file.get_path (), keyfile);
                    if (cfi.is_valid) {
                        contracts_files.add(cfi);
                    }
                    if (cfi.is_conditional) {
                        conditional_contracts_files.add(cfi);
                    }
                }
            } catch (Error err) {
                warning ("%s", err.message);
            }
        }

        private Gee.Map<unowned string, Gee.List<ContractFileInfo> > mimetype_map;
        private Gee.Map<string, Gee.List<ContractFileInfo> > exec_map;
        private Gee.Map<string, ContractFileInfo> contract_id_map;
        public Gee.Map<string, ContractFileInfo> name_id_map;
        public Gee.Map<string, ContractFileInfo> exec_string_map;
        private void create_maps (){
            // create mimetype maps
            mimetype_map = new Gee.HashMap<unowned string, Gee.List<ContractFileInfo> > ();
            // and exec map
            exec_map = new Gee.HashMap<string, Gee.List<ContractFileInfo> > ();
            // and exec string map
            exec_string_map = new Gee.HashMap<string, ContractFileInfo> ();
            // and desktop id map
            contract_id_map = new Gee.HashMap<string, ContractFileInfo> ();
            // and name id map
            name_id_map = new Gee.HashMap<string, ContractFileInfo> ();
            Regex exec_re;
            try {
                exec_re = new Regex ("%[fFuU]");
            } catch (Error err) {
                critical ("%s", err.message);
                return;
            }

            foreach (var cfi in contracts_files)
            {
                message ("create_map %s", cfi.name);
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
        /*
        * status: TODO
        */
        private void reload_contract_files ()
        {
            debug ("Reloading contract files...");
            contracts_files.clear ();
            conditional_contracts_files.clear ();
            load_contracts_files(false);
        }
        /*
        * status: TODO
        */
        private void add_cfi_for_mime (string mime, Gee.Set<ContractFileInfo> ret)
        {
            var cfis = mimetype_map[mime];
            if (cfis != null) ret.add_all (cfis);
        }
        /*
        * status: TODO
        */
        public Gee.List<ContractFileInfo> get_contract_files_for_type (string mime_type)
        {
            var cfi_set = new Gee.HashSet<ContractFileInfo> ();
            add_cfi_for_mime (mime_type, cfi_set);
            var ret = new Gee.ArrayList<ContractFileInfo> ();
            ret.add_all (cfi_set);
            return ret;
        }
        /*
        * status: broken
        
        public void get_contracts_for_string ()
        {
            GLib.HashTable<string,string>[] filtered = null;
            //GLib.HashTable<string,string>[] filtered = null;
            //foreach (ContractFileInfo cfi in exec_string_map)
            foreach (var cfi in exec_string_map.values) {
                filtered += get_filtered_entry_for_string (cfi);
                message ("exec_string %s", cfi.name);
            }
        }*/
        /* 
        *   status: needs comments and documentery
        */
        private uint timer_id = 0;
        private void contract_file_directory_changed (File file, File? other_file, FileMonitorEvent event){
            message("%s changed", file.get_path());
            if (timer_id != 0){
                Source.remove (timer_id);
            }
            timer_id = Timeout.add (1000, () =>{
                timer_id = 0;
                reload_contract_files ();
                return false;
            });
        }
       /*   nice return of the avaible contracts
       *    status: done
       */
        public string list_all_contracts(){
            foreach(var contract in contracts_files){
               return(contract.name + " contract. description: " + contract.description);
            }
        return "nothing there";
        }
	}
}