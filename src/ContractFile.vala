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

public class Contractor.ContractFile : Object {
    private const string EXTENSION = ".contract";

    private File file;

    public ContractFile (File file) {
        this.file = file;
    }

    public string get_id () {
        return remove_extension (file.get_basename ());
    }

    public string get_contents () throws Error {
        uint8[] file_data;

        if (file.load_contents (null, out file_data, null)) {
            return (string) file_data;
        }

        return "";
    }

    public static bool is_valid_filename (string filename) {
        return filename[- EXTENSION.length : filename.length] == EXTENSION;
    }

    private static string remove_extension (string file_name) {
        return file_name[0 : - EXTENSION.length];
    }
}

