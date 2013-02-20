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

using GLib;
using Xml;
namespace Contractor{

    // the main constractor class where everything comes together
    [DBus (name = "org.elementary.Contractor")]
    public class Contractor : GLib.Object {
        private ContractFileService cfs;
        //Gee.HashMultiMap<string, string> contracts;
        construct{
            debug("starting Contractor...");
            GLib.Intl.setlocale (GLib.LocaleCategory.ALL, "");
            GLib.Intl.textdomain (Build.GETTEXT_PACKAGE);
            cfs = new ContractFileService ();
        }

        public HashTable<string, string> list_all_contracts(){
           return cfs.list_all_contracts();
        }

        HashTable<string, string>[] table;
        public HashTable<string, string>[] xml_test(){
            table = new HashTable<string, string>[3];
            var t1 = new HashTable<string, string>(str_hash, str_equal);
            t1.insert ("1", "first string");
            table[0].insert (t1);
            table[1].insert ("2", "second string");
            table[2].insert ("3", "third string");
            return table;
        }
        // private string query_content_type (File file){
        //     string mimetype = null;
        //     try{
        //         var file_info = file.query_info ("standard::content-type", FileQueryInfoFlags.NONE);
        //         mimetype = file_info.get_content_type ();
        //     } catch (Error e){
        //         warning ("file query_info error %s: %s\n", file.get_uri (), e.message);
        //     }
        //     return mimetype;
        // }
    }

    /* starts the contractor goodnes
       creates a new Bus and enters the main loops
    */
    private MainLoop loop;
    void main(string[] args){
        foreach(string arg in args){
            if(arg == "-l"){
                Contractor contractor = new Contractor();
                Process.exit (0);
            };
        };
        Bus.own_name (BusType.SESSION, "org.elementary.Contractor", BusNameOwnerFlags.NONE,
                      on_bus_aquired,
                      () => {},
                      () => on_bus_not_aquired);
        loop = new MainLoop ();
        loop.run();
        }
    // trys to aquire the bus 
    private void on_bus_aquired(DBusConnection conn){
        try {
            conn.register_object("/org/elementary/contractor", new Contractor());
        } catch (IOError e) {
            stderr.printf("Could not register service because: %s \n",e.message);
        }
    }
    private void on_bus_not_aquired(){
        stderr.printf("Could not aquire Session bus for contractor\n");
        loop.quit();
    }
}

namespace Translations {
    const string archive_name = N_("Archives");
    const string archive_desc = N_("Extract here");
    const string archive_compress = N_("Compress");
    const string wallpaper_name = N_("Wallpaper");
    const string wallpaper_desc = N_("Set as Wallpaper");
}