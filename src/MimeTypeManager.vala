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

    public MimeTypeManager (string[] mimetypes) throws Error {
        if ("!" in mimetypes[0]) { // See if we have a conditional mimetype
            is_conditional = true;
            mimetypes[0] = mimetypes[0].replace ("!", ""); // remove the '!'
        }

        values = String.clean_array (mimetypes);

        if (values.length == 0) {
            throw new KeyFileError.INVALID_VALUE ("No values specified for MimeType.");
        }
    }

    public bool is_type_supported (string mime_type) {
        bool has_mimetype = contains_mimetype (mime_type);
        return is_conditional ? !has_mimetype : has_mimetype;
    }

    private bool contains_mimetype (string mime_type) {
        foreach (string local_mime_type in values) {
            if (compare (mime_type, local_mime_type)) {
                return true;
            }
        }

        return false;
    }

    private static bool compare (string mime_type, string ref_mime_type) {
        return mime_type.has_prefix (ref_mime_type)
            || ContentType.equals (mime_type, ref_mime_type)
            || ContentType.is_a (mime_type, ref_mime_type);
    }
}
