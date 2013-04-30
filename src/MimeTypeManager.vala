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

    public MimeTypeManager (string mimetypes) {
        values = mimetypes.split (";", 0);

        if ("!" in mimetypes) { // See if we have a conditional mimetype
            if (values.length == 1) {
                is_conditional = true;
                values[0] = values[0].replace ("!", ""); // remove the '!'
            } else {
                warning ("Conditional mimetypes must contain a single value.");
            }
        }
    }

    public bool is_type_supported (string mime_type) {
        if (is_conditional) {
            string conditional_mime_type = values[0];
            return !compare_mimetypes (mime_type, conditional_mime_type);
        }

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

