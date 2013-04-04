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

using GLib;
using Gee;

namespace Contractor {

    // the main constractor class where everything comes together
    [DBus (name = "org.elementary.Contractor")]
    public class Contractor : GLib.Object {
        private ContractFileService cfs;
        //Gee.HashMultiMap<string, string> contracts;

        construct {
            debug ("starting Contractor...");
            GLib.Intl.setlocale (GLib.LocaleCategory.ALL, "");
            GLib.Intl.textdomain (Build.GETTEXT_PACKAGE);
            cfs = new ContractFileService ();
        }

        /*
        /  return:
        /  status: TODO
        */
        public GenericContract[] get_contracts_by_mime (string mime_type) {
            // need to add this to demo compile
            return ContractFileService.to_GenericContract_arr (cfs.get_contract_files_for_type (mime_type));
        }

        /*
        /  return:
        /  status: TODO
        */
        public GenericContract[] get_contracts_by_mimelist (string[] mime_types) {
            // need to add this to demo compile
            ContractFileInfo[] c_info_list = {};

            foreach (var mime in mime_types) {
                ContractFileInfo[] c_info =  cfs.get_contract_files_for_type (mime);

                foreach (var c in c_info) {
                    c_info_list += c;
                }
            }

            return ContractFileService.to_GenericContract_arr (c_info_list);
        }

        /*
        /  return:
        /  status: TODO
        */
        public int execute_with_file_list (string id, string[] file_path) {
            // need to add this to demo compile
            return 0;
        }
        /*
        /  return:
        /  status: TODO
        */
        public int execute_with_file (string id, string file_path) {
            // need to add this to demo compile
            return 0;
        }

        public GenericContract[] list_all_contracts () {
            var cts = cfs.list_all_contracts ();
            return ContractFileService.to_GenericContract_arr (cts);
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
