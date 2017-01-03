/*
 * Copyright (C) 2013-2017 elementary Developers
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

namespace Contractor.String {
    public bool is_empty (string? str) {
        return str == null || str.strip () == "";
    }

    public List<string>? array_to_list (string[] array) {
        List<string>? list = null;

        if (array != null && array.length > 0) {
            list = new List<string> ();

            foreach (var str in array) {
                list.prepend (str);
            }

            list.reverse ();
        }

        return list;
    }

    /**
     * Removes duplicate and empty strings from the given array.
     */
    public string[] clean_array (string[] str_array) {
        var container = new Gee.HashSet<string> ();

        foreach (string str in str_array) {
            if (str != null) {
                string clean_str = str.strip ();

                if (clean_str != "" && !container.contains (clean_str)) {
                    container.add (clean_str);
                }
            }
        }

        return container.to_array ();
    }
}
