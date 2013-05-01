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
        public signal void contract_file_found (File contract_file);

        private const string CONTRACT_DATA_DIR_NAME = "contractor";

        private Gee.List<ContractDirectory> directories;

        public FileService () {
            directories = new Gee.LinkedList<ContractDirectory> ();
            set_up_directories ();
        }

        public void load_contract_files () {
            foreach (var directory in directories)
                directory.lookup_contract_files ();
        }

        private void set_up_directories () {
            // get paths from enviroment
            var paths = Environment.get_system_data_dirs ();
            paths += Environment.get_user_data_dir ();

            foreach (var path in paths) {
                var directory = File.new_for_path (path).get_child (CONTRACT_DATA_DIR_NAME);

                if (directory.query_exists ()) {
                    var contract_dir = new ContractDirectory (directory);
                    contract_dir.contract_file_found.connect ((file) => contract_file_found (file));
                    contract_dir.changed.connect (() => contract_files_changed ());

                    directories.add (contract_dir);
                }
            }
        }
    }
}
