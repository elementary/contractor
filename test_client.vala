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
[DBus (name = "org.elementary.Contractor")]
interface Demo : Object {
    public abstract HashTable<string, string> list_all_contracts() throws Error;
    public abstract HashTable<string, string>[] xml_test() throws Error;
    public signal void pong (string msg);
}

void main () {
    Demo demo = null;
    try {
        message("trying");
        demo = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.Contractor", "/org/elementary/contractor");
        demo.pong.connect((m) => {});
        var contract = demo.xml_test();
        var val = contract[0].get_values ();
        var key = contract[0].get_keys();
        foreach (string v in val) {
            stdout.printf ("%s\n", v);
        }
        foreach (string k in key) {
            stdout.printf ("%s\n", k);
        }
    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
}

