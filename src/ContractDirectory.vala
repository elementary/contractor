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
 */

public class Contractor.ContractDirectory : Object {
    public signal void contract_file_found (File contract_file);
    public signal void changed ();

    private const int DIRECTORY_RELOAD_TIMEOUT_MS = 500;

    private File contract_directory;
    private FileMonitor monitor;

    private bool update_pending = false;

    public ContractDirectory (File directory) {
        contract_directory = directory;
        set_monitor ();
    }

    public void lookup_contract_files () {
        process_directory (contract_directory);
    }

    private void set_monitor () {
        try {
            monitor = contract_directory.monitor_directory (FileMonitorFlags.NONE, null);
            monitor.changed.connect (on_change_event);
        } catch (IOError e) {
            critical ("Could not set up monitor for '%s': %s", contract_directory.get_path (), e.message);
        }
    }

    private void process_directory (File directory) {
        message ("Looking up contracts in: %s", directory.get_path ());

        try {
            string[] QUERY_ATTRIBUTES = {
                FileAttribute.STANDARD_NAME,
                FileAttribute.STANDARD_TYPE
            };

            string attributes = string.joinv (",", QUERY_ATTRIBUTES);

            var enumerator = directory.enumerate_children (attributes, FileQueryInfoFlags.NONE);

            FileInfo f;

            while ((f = enumerator.next_file ()) != null) {
                unowned string name = f.get_name ();
                var file_type = f.get_file_type ();
                var child = directory.get_child (name);

                if (file_type == FileType.REGULAR) {
                    if (ContractFile.is_valid_filename (name))
                        contract_file_found (child);
                } else if (file_type == FileType.DIRECTORY) {
                    process_directory (child);
                } else {
                    warning ("'%s' is not a regular file or directory. Skipping it...", child.get_path ());
                }
            }
         } catch (Error err) {
             warning ("Could not process directory '%s': %s", directory.get_path (), err.message);
         }
    }

    private async void on_change_event (File file, File? other_file, FileMonitorEvent event) {
        if (update_pending)
            return;

        update_pending = true;

        Timeout.add (DIRECTORY_RELOAD_TIMEOUT_MS, on_change_event.callback);
        yield;

        changed ();

        update_pending = false;
    }
}
