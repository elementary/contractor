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

public class Contractor.ContractFileEnumerator : Object {
    private const string[] QUERY_ATTRIBUTES = {
        FileAttribute.STANDARD_NAME,
        FileAttribute.STANDARD_TYPE
    };

    private static string attributes;

    private File directory;

    static construct {
        attributes = string.joinv (",", QUERY_ATTRIBUTES);
    }

    public ContractFileEnumerator (File directory) {
        this.directory = directory;
    }

    public Gee.List<File> enumerate_files () {
        var files = new Gee.LinkedList<File> ();

        message ("Looking up contracts in: %s", directory.get_path ());

        try {
            var enumerator = directory.enumerate_children (attributes, FileQueryInfoFlags.NONE);

            FileInfo f;

            while ((f = enumerator.next_file ()) != null) {
                unowned string name = f.get_name ();
                var file_type = f.get_file_type ();
                var child = directory.get_child (name);

                if (file_type == FileType.REGULAR) {
                    if (ContractFile.is_valid_filename (name)) {
                        files.add (child);
                    }
                } else {
                    warning ("'%s' is not a regular file. Skipping it...", child.get_path ());
                }
            }
        } catch (Error err) {
            warning ("Could not process directory '%s': %s", directory.get_path (), err.message);
        }

        return files;
    }
}
