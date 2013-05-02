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

public class Contractor.MimeTypeManager : Object {
    private string[] values;
    private bool is_conditional = false;

    public MimeTypeManager (string serialized_mimetypes) {
        string[] mime_types = serialized_mimetypes.split (";", 0);

        if ("!" in serialized_mimetypes) { // See if we have a conditional mimetype
            is_conditional = true;
            mime_types[0] = mime_types[0].replace ("!", ""); // remove the '!'
        }

        values = validate_mime_types (mime_types);
    }

    public bool is_type_supported (string mime_type) {
        bool has_mimetype = contains_mimetype (mime_type);
        return is_conditional ? !has_mimetype : has_mimetype;
    }

    /**
     * Removes duplicate and empty strings from mime_types.
     */
    public static string[] validate_mime_types (string[] mime_types) {
        var mimetypes = new Gee.HashSet<string> ();

        foreach (string mime_type in mime_types) {
            if (mime_type != null) {
                string actual_mime_type = mime_type.strip ();

                if (actual_mime_type != "" && !mimetypes.contains (actual_mime_type))
                    mimetypes.add (actual_mime_type);
            }
        }

        return mimetypes.to_array ();
    }

    private bool contains_mimetype (string mime_type) {
        foreach (string local_mime_type in values) {
            if (compare_mimetypes (mime_type, local_mime_type))
                return true;
        }

        return false;
    }

    private static bool compare_mimetypes (string mime_type, string ref_mime_type) {
        return ref_mime_type in mime_type
            || ContentType.equals (mime_type, ref_mime_type)
            || ContentType.is_a (mime_type, ref_mime_type);
    }
}
