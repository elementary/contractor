/*
 * Copyright (C) 2011-2017 elementary Developers
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
    public signal void changed ();

    private const int DIRECTORY_RELOAD_TIMEOUT_MS = 500;

    private File contract_directory;
    private FileMonitor monitor;

    private bool update_pending = false;

    public ContractDirectory (File directory) {
        contract_directory = directory;
        set_monitor ();
    }

    public Gee.List<File> lookup_contract_files () {
        var file_enumerator = new ContractFileEnumerator (contract_directory);
        return file_enumerator.enumerate_files ();
    }

    private void set_monitor () {
        try {
            monitor = contract_directory.monitor_directory (FileMonitorFlags.NONE, null);
            monitor.changed.connect (on_change_event);
        } catch (IOError e) {
            critical ("Could not set up monitor for '%s': %s", contract_directory.get_path (), e.message);
        }
    }

    private async void on_change_event (File file, File? other_file, FileMonitorEvent event) {
        if (update_pending) {
            return;
        }

        update_pending = true;

        Timeout.add (DIRECTORY_RELOAD_TIMEOUT_MS, on_change_event.callback);
        yield;

        changed ();

        update_pending = false;
    }
}
