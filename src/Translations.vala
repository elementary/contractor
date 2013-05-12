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
 */

public class Contractor.Translations {
    private const string archive_name = N_("Archives");
    private const string archive_desc = N_("Extract here");
    private const string archive_compress = N_("Compress");
    private const string wallpaper_name = N_("Wallpaper");
    private const string wallpaper_desc = N_("Set as Wallpaper");

    private static Gee.HashSet<string> domains;

    public static void init () {
        domains = new Gee.HashSet<string> ();
        Intl.setlocale (LocaleCategory.ALL, "");
    }

    public static string get_string (string domain, string to_translate) {
        add_domain (domain);
        return dgettext (domain, to_translate).dup ();
    }

    private static void add_domain (string domain) {
        if (domains.contains (domain))
            return;

        domains.add (domain);
        Intl.textdomain (domain);
    }
}