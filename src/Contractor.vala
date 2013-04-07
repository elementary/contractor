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
 *          lampe2 <michael@lazarski.me>
 *
 * The original Contractor implementation in Python was created by:
 *          Allen Lowe <lallenlowe@gmail.com>
 */

using GLib;

namespace Contractor {

    // the main constractor class where everything comes together
    [DBus (name = "org.elementary.Contractor")]
    public class Contractor : GLib.Object {
        private FileService cfs;

        construct {
            debug ("starting Contractor...");
            GLib.Intl.setlocale (GLib.LocaleCategory.ALL, "");
            GLib.Intl.textdomain (Build.GETTEXT_PACKAGE);
            cfs = new FileService ();
        }

        /*
         * Gets all the contracts loaded and converts them to GenericContract then
         * from GLib.List they are converted to an array
         */
        public GenericContract[] get_contracts_by_mime (string mime_type) {
            return cfs.to_GenericContract_arr (cfs.get_contract_files_for_type (mime_type));
        }

        /*
        /  return:
        /  status: TODO
        */
        public GenericContract[] get_contracts_by_mimelist (string[] mime_types) {
            FileInfo[] info_list = {};
            int[] count = {};

            foreach (var mime in mime_types) {
                    FileInfo[] info = cfs.get_contract_files_for_type (mime);

                    foreach (var c in info) {
                            bool found = false;
                            for (var i = 0; i < info_list.length; i++) {
                                    if (c == info_list[i]) {
                                            count[i] += 1;
                                            found = true;
                                            break;
                                    }
                            }
                            if (found)
                                    continue;

                            info_list += c;
                            count += 1;
                    }
            }

            FileInfo[] final = {};

            for (var i = 0; i < info_list.length; i++) {
                    if (count[i] == mime_types.length)
                            final += info_list[i];
            }
            return cfs.to_GenericContract_arr (final);
        }

        /*
        /  return:
        /  status: TODO
        */
        public int execute_with_uri_list (string id, string[] uris) {
            FileInfo contract = cfs.get_contract_for_id (id);
            List<string> uris_list = new List<string> ();
            foreach (var uri in uris) {
                uris_list.append (uri);
            }
            if (execute_with_uris (contract.exec, uris_list) == true ) {
                return 0;
            } else {
                return 1;
            }
        }
        /*
        /  return:
        /  status: TODO
        */
        public int execute_with_uri (string id, string uri) {
            FileInfo contract = cfs.get_contract_for_id (id);
            List<string> uri_list = new List<string> ();
            uri_list.append (uri);
            if (execute_with_uris (contract.exec, uri_list) == true ) {
                return 0;
            } else {
                return 1;
            }
        }

        public GenericContract[] list_all_contracts () {
            var cts = cfs.list_all_contracts ();
            return cfs.to_GenericContract_arr (cts);
        }
        private bool execute_with_uris (string exec_str, List<string>? uris) {
            try {
                debug (exec_str);
                return AppInfo.create_from_commandline (exec_str, null, AppInfoCreateFlags.NONE).launch_uris (uris, null);
            } catch (Error e) {
                    warning (e.message);
            }
            return false;
        }
    }
    /* starts the contractor goodnes
       creates a new Bus and enters the main loops
    */
    private MainLoop loop;
    void main (string[] args) {
        foreach (string arg in args) {
            if (arg == "-l") {
                Contractor contractor = new Contractor ();
                Process.exit (0);
            };
        };

        Bus.own_name (BusType.SESSION, "org.elementary.Contractor", BusNameOwnerFlags.NONE,
                      on_bus_aquired,
                      () => {},
                      () => on_bus_not_aquired);
        loop = new MainLoop ();
        loop.run ();
    }

    // trys to aquire the bus
    private void on_bus_aquired (DBusConnection conn) {
        try {
            conn.register_object ("/org/elementary/contractor", new Contractor ());
        } catch (IOError e) {
            stderr.printf ("Could not register service because: %s \n", e.message);
        }
    }

    private void on_bus_not_aquired () {
        stderr.printf ("Could not aquire Session bus for contractor\n");
        loop.quit ();
    }
}

namespace Translations {
    const string archive_name = N_("Archives");
    const string archive_desc = N_("Extract here");
    const string archive_compress = N_("Compress");
    const string wallpaper_name = N_("Wallpaper");
    const string wallpaper_desc = N_("Set as Wallpaper");
}
