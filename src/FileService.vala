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
 *          Victor Martinez <victoreduardm@gmail.com>
 *
 * Initial implementation of FileService was heavily inspired by
 * Synapse DesktopFileService. Kudos to the Synapse's developers!
 *
 * The original Contractor implementation in Python was created by:
 *          Allen Lowe <lallenlowe@gmail.com>
 */

namespace Contractor {

    public class FileService : Object {
        public signal void contract_files_changed ();
        public signal void contract_found (File contract_file);

        private const string CONTRACT_DATA_DIR_NAME = "contractor";

        private Gee.List<FileMonitor> monitors;

        public FileService () {
            monitors = new Gee.LinkedList<FileMonitor> ();
        }

        public void load_files () {
            // get paths from enviroment
            var paths = Environment.get_system_data_dirs ();

            foreach (var path in paths) {
                var directory = File.new_for_path (path).get_child (CONTRACT_DATA_DIR_NAME);

                if (directory.query_exists ())
                    process_directory (directory);

                    try {
                        var monitor = directory.monitor_directory (FileMonitorFlags.NONE, null);
                        monitor.changed.connect (contract_directory_changed);
                        monitors.add (monitor);
                    } catch (IOError e) {
                        critical ("%s monitor failed: %s", directory.get_path (), e.message);
                    }
            }
        }

        private void process_directory (File directory) {
            message ("Looking up contracts in: %s.", directory.get_path ());

            try {
                string attributes = "%s,%s".printf (FileAttribute.STANDARD_NAME,
                                                    FileAttribute.STANDARD_TYPE);

                var enumerator = directory.enumerate_children (attributes, FileQueryInfoFlags.NONE);
                FileInfo f = null;

                while ((f = enumerator.next_file ()) != null) {
                    unowned string name = f.get_name ();
                    var file_type = f.get_file_type ();
                    var child = directory.get_child (name);

                    if (file_type == FileType.REGULAR) {
                        if (name.has_suffix ("." + ContractFile.SUFFIX))
                            contract_found (child);
                    } else if (file_type == FileType.DIRECTORY) {
                        process_directory (child);
                    } else {
                        warning ("File '%s' is neither a regular file or directory.", child.get_path ());
                    }
                }
             } catch (Error err) {
                 warning ("Could not process directory '%s': %s", directory.get_path (), err.message);
             }
        }

        private void reload_files () {
            contract_files_changed ();
        }

        /*
         * Schedule a reload of contracts when the contracts directory has been changed.
         */
        private uint timer_id = 0;
        private void contract_directory_changed (File file, File? other_file, FileMonitorEvent event) {
            debug ("%s changed", file.get_path ());

            if (timer_id != 0)
                Source.remove (timer_id);

            timer_id = Timeout.add (1000, () =>{
                timer_id = 0;
                reload_files ();
                return false;
            });
        }
    }
}
