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

/**
 * used to access the Contracts File object and read its content
 */
public class Contractor.ContractFile : Object {
    /**
     * contract files filename extension
     */
    private const string EXTENSION = ".contract";

    /**
     * the File object used to access its content
     */
    private File file;

    /**
     * the constructor to create ContractFile object which contains the passed
     * File object
     *
     * @param file the file to contain
     */
    public ContractFile (File file) {
        this.file = file;
    }

    /**
     * get the contract ID from the filename, e.g. file-roller-compress
     * (file-roller-compress.contract)
     *
     * @return the contracts ID, e.g. file-roller-compress
     */
    public string get_id () {
        return remove_extension (file.get_basename ());
    }

    /**
     * loads and returns the internally stored files content
     *
     * @return the files content as string
     */
    public string get_contents () throws Error {
        uint8[] file_data;

        if (file.load_contents (null, out file_data, null)) {
            return (string) file_data;
        }

        return "";
    }

    /**
     * checks if the filename extension is '.contract'
     *
     * @param filename the full filename incl. the filename extension
     *
     * @return true if the filename extension is '.contract'; false otherwise
     */
    public static bool is_valid_filename (string filename) {
        return filename[- EXTENSION.length : filename.length] == EXTENSION;
    }

    /**
     * removes the filename extension and returns the result
     *
     * @param file_name the filename incl. the filename extesnion
     *
     * @return the filename without the filename extension
     */
    private static string remove_extension (string file_name) {
        return file_name[0 : - EXTENSION.length];
    }
}

