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
 * Author: lampe2 <michael@lazarski.me>,
 *         Akshay Shekher <voldyman666@gmail.com>
 */

using GLib;
[DBus (name = "org.elementary.Contractor")]
interface Demo : Object {
    public abstract GenericContract[] list_all_contracts () throws Error;
    public abstract GenericContract[] get_contracts_by_mime (string mime_type) throws Error;
    public abstract GenericContract[] get_contracts_by_mimelist (string[] mime_types) throws Error;
    public abstract int execute_with_uri (string id, string path) throws Error;
    public abstract int execute_with_uri_list (string id, string[] path) throws Error;
    public signal void pong (string msg);
}
public struct GenericContract {
    string id;
    string display_name;
    string description;
    string icon_path;
}
void main () {
    Demo demo = null;
    try {
        message("trying");
        demo = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.Contractor", "/org/elementary/contractor");
        demo.pong.connect((m) => {});
        print ("\n\nListAllContracts:\n");
        GenericContract[] contracts = demo.list_all_contracts ();
        foreach (var cont in contracts) {
            stdout.printf("%s\n", cont.display_name);
        }
        string id = null;
        print ("\n\nGetContractsForMime:\n");
        contracts = demo.get_contracts_by_mime ("image");
        foreach (var cont in contracts) {
            stdout.printf("%s: %s\n", cont.display_name, cont.description);
            id = cont.id;
        }
        print ("\n\nGetContractsForMimeList:\n");
        contracts = demo.get_contracts_by_mimelist ({"text"});
        foreach (var cont in contracts) {
            stdout.printf("(%s): %s: %s\n", cont.id, cont.display_name, cont.description);
        }
        demo.execute_with_uri (id,"/home/michael/Pictures/wallpaper.png");
    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
}
