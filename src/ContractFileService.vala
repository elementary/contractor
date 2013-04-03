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
 *
 * Author: lampe2 michael@lazarski.me
 */

namespace Contractor {

    public class ContractFileService : Object {
        public List<ContractFileInfo> contracts;
        public bool initialized { get; private set; default = false; }

        public ContractFileService () {
            contracts = new List<ContractFileInfo> ();
            load_contracts_files ();
            initialized = true;
        }

        /*
        *   status: need review and documentation
        */
        private List<FileMonitor> monitors;

        private void load_contracts_files (bool should_monitor=true) {
            debug ("loading necessary files...");
            var count = 0;
            monitors = new List<FileMonitor> ();

            //get paths from enviroment
            var paths = Environment.get_system_data_dirs ();
            paths.resize (paths.length + 1);
            paths[paths.length - 1] = Environment.get_user_data_dir ();

            foreach (var path in paths) {
                var directory = File.new_for_path (path + "/contractor/");

                if (directory.query_exists ()) {
                    process_directory (directory);
                }

                if (should_monitor) {
                    try {
                        monitors.append (directory.monitor_directory (FileMonitorFlags.NONE, null));
                    } catch (IOError e) {
                        error ("%s monitor failed: %s", directory.get_path (), e.message);
                    }

                    monitors.nth_data (count).changed.connect (contract_file_directory_changed);
                    count =+ 1;
                }
            }

            debug ("load contracts files done");
        }

        /*
        *   status: needs comments and documentary
        */
        private void process_directory (File directory) {
            try {
                var enumerator = directory.enumerate_children ("%s,%s".printf(FileAttribute.STANDARD_NAME,
                                                                              FileAttribute.STANDARD_TYPE), 0);
                FileInfo f = null;

                while ((f = enumerator.next_file ()) != null) {
                    unowned string name = f.get_name ();
                    if (f.get_file_type () == FileType.REGULAR && name.has_suffix (".contract")) {
                        load_contract_file (directory.get_child (name));
                    }
                }
             } catch (Error err) {
                 warning ("%s name %s", err.message, directory.get_path ());
             }
        }

        /*  loads the specifi contractor file parses it and
        *   adds it to the list of contracts
        *   status: needs comment and documentary
        */
        private void load_contract_file (File file) {
            try {
                uint8[] contents;
                bool success = file.load_contents (null, out contents, null);
                var contents_str = (string) contents;
                size_t len = contents_str.length;

                if (success && len > 0) {
                    var keyfile = new KeyFile ();
                    keyfile.load_from_data (contents_str, len, 0);

                    var cfi = new ContractFileInfo.for_keyfile (file.get_path (), keyfile);

                    if (cfi.is_valid) {
                        contracts.append (cfi);
                    }
                }
            } catch (Error err) {
                warning ("%s", err.message);
            }
        }

        private void reload_contract_files () {
            debug ("Reloading contract files...");
            contracts = null;
            contracts = new List<ContractFileInfo> ();
            load_contracts_files (false);
        }

        /*
        * status: TODO
        */
        public ContractFileInfo[] get_contract_files_for_type (string mime_type) {
            List<ContractFileInfo> cont =  filter (contracts, (contract) => {
                foreach (string con_mime_type in contract.mime_types) {
                    if (con_mime_type == mime_type)
                        return true;
                }

                return false;
            });

            return to_CFI_array (cont);
        }

        private delegate bool ContractFilterFunc (ContractFileInfo contr);
        private List<ContractFileInfo> filter (List<ContractFileInfo> conts, ContractFilterFunc fn) {
            List<ContractFileInfo> ret = new List<ContractFileInfo> ();
            conts.foreach ((cont) => {
                if (fn (cont)) {
                    ret.append (cont);
                }
            });
            return ret.copy ();
        }

        private ContractFileInfo[] to_CFI_array (List<ContractFileInfo> list_of_contracts) {
            ContractFileInfo[] cont_arr = {};

            list_of_contracts.foreach ((cont) => {
                cont_arr += cont;
            });

            return cont_arr;
        }

        public ContractFileInfo[] list_all_contracts () {
            return to_CFI_array (this.contracts);
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
        private void contract_file_directory_changed (File file, File? other_file, FileMonitorEvent event) {
            debug ("%s changed", file.get_path ());

            if (timer_id != 0) {
                Source.remove (timer_id);
            }

            timer_id = Timeout.add (1000, () =>{
                timer_id = 0;
                reload_contract_files ();
                return false;
            });
        }
    }
}
