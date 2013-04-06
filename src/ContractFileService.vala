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
 *          Akshay Shekher <voldyman666@gmail.com>
 *
 * Initial implementation of FileService was heavily inspired by
 * Synapse DesktopFileService. Kudos to the Synapse's developers!
 *
 * The original Contractor implementation in Python was created by:
 *          Allen Lowe <lallenlowe@gmail.com>
 */

namespace Contractor {

    public class FileService : Object {
        public List<FileInfo> contracts;
        public bool initialized { get; private set; default = false; }

        public FileService () {
            contracts = new List<FileInfo> ();
            load_contracts_files ();
            initialized = true;
        }

        /*
        *   status: need review and documentation
        */
        private List<FileMonitor> monitors;

        private void load_contracts_files (bool should_monitor=true) {
            debug ("loading necessary files...");
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
                    print ("Monitoring dir:"+directory.get_path ()+"\n");
                    try {
                        var mon = directory.monitor_directory (FileMonitorFlags.NONE, null);
                        mon.changed.connect (contract_file_directory_changed);
                        monitors.append ((owned) mon);
                    } catch (IOError e) {
                        error ("%s monitor failed: %s", directory.get_path (), e.message);
                    }
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
                GLib.FileInfo f = null;

                while ((f = enumerator.next_file ()) != null) {
                    unowned string name = f.get_name ();
                    if (f.get_file_type () == FileType.REGULAR && name.has_suffix (".contract")) {
                        load_contract_file (directory.get_child (name));
                    }
                    if (f.get_file_type () == FileType.DIRECTORY) {
                        var dir = File.new_for_uri (directory.get_uri () + "/" + f.get_name ());
                        process_directory (dir);
                    }
                }
             } catch (Error err) {
                 warning ("%s name %s", err.message, directory.get_path ());
             }
        }

        /*  loads the specifi contractor file parses it and
        *   adds it to the list of contracts
        *   status: TODO not clean implemented!
        */
        private void load_contract_file (File file) {
            try {
                var cfi = new FileInfo(file);
                if (cfi.is_valid) {
                    contracts.append (cfi);
                }
            } catch (Error err) {
                warning ("%s", err.message);
            }
        }

        private void reload_contract_files () {
            debug ("Reloading contract files...");
            contracts = null;
            contracts = new List<FileInfo> ();
            load_contracts_files ();
        }

        /*
         * Filters the contracts on the basis of mime_type matching.
         * TODO: add a better function instead of this lambda, to add better matching.
         */
        public FileInfo[] get_contract_files_for_type (string mime_type) {
            List<FileInfo> cont = filter (contracts, (contract) => {
                foreach (string con_mime_type in contract.mime_types) {
                    if (con_mime_type in mime_type)
                        return true;
                }
                return false;
            });
            return to_CFI_array (cont);
        }

        /*
         * Filters the contracts accoding to id
         * TODO: add a better function instead of this lambda, to add better matching.
         */
        public FileInfo[] get_contracts_for_id (string id) {
            List<FileInfo> cont =  filter (contracts, (contract) => {
                if (contract.id in id)
                    return true;
                else
                    return false;
            });

            return to_CFI_array (cont);
        }
        /*
         * Filters the contracts accoding to id
         * TODO: done.
         */
        public FileInfo get_contract_for_id (string id) {
            return get_contracts_for_id (id)[0];
        }
        /*
         * Function used to filter a list of FileInfo's based on a custom function.
         */
        private delegate bool ContractFilterFunc (FileInfo contr);
        private List<FileInfo> filter (List<FileInfo> contracts, ContractFilterFunc fn) {
            List<FileInfo> ret = new List<FileInfo> ();
            contracts.foreach ((cont) => {
                if (fn (cont)) {
                    ret.append (cont);
                }
            });
            return (owned) ret;
        }

        /*
         * Since GLib.List doesn't provide a way to convert it into an array.
         */
        private FileInfo[] to_CFI_array (List<FileInfo> list_of_contracts) {
            FileInfo[] cont_arr = new FileInfo[list_of_contracts.length ()];

            for (int i=0; i < list_of_contracts.length (); i++) {
                cont_arr[i] = list_of_contracts.nth_data (i);
            }

            return cont_arr;
        }

        public FileInfo[] list_all_contracts () {
            return to_CFI_array (this.contracts);
        }

        /*
         * Schedule a reload of contracts when the contracts directory has been changed.
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
        /*
         * Convert FileInfo class to struct GenericContract's as they are required
         * by the API.
         */
        public static GenericContract[] to_GenericContract_arr (FileInfo[] cts) {
            GenericContract[] cvci = new GenericContract[cts.length];

            for (int i=0; i< cts.length; i++) {
                cvci[i] = cts[i].to_generic_contract ();
            }

            return cvci;
        }
    }
}
