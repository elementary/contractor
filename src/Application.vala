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
 */

public class Contractor.Application : GLib.Application {
    private const string DBUS_NAME = "org.elementary.Contractor";
    private const string DBUS_PATH = "/org/elementary/contractor";

    private DBusService dbus_service;

    construct {
        application_id = DBUS_NAME;
        flags = ApplicationFlags.IS_SERVICE;
    }

    public override void startup () {
        base.startup ();

        init_service ();
        hold ();
    }

    private void init_service () {
        Bus.own_name (BusType.SESSION, DBUS_NAME, BusNameOwnerFlags.NONE,
                      on_bus_aquired,
                      () => {},
                      () => on_bus_not_aquired);
    }

    private void on_bus_aquired (DBusConnection conn) {
        dbus_service = new DBusService ();

        try {
            conn.register_object (DBUS_PATH, dbus_service);
        } catch (IOError e) {
            warning ("Could not register service: %s.", e.message);
            release ();
            return;
        }

        dbus_service.init ();
    }

    private void on_bus_not_aquired () {
        critical ("Could not aquire Session bus for contractor.");
        release ();
    }
}
