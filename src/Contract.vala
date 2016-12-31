/*
 * Copyright (C) 2011-2017 elementary Developers
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

namespace Contractor {
    /**
     * a contract which defines an action available for certain files
     */
    public class Contract : Object {
        /**
         * the contracts ID based on the file name, e.g. file-roller-compress
         * (file-roller-compress.contract)
         */
        public string id { get; private set; }
        /**
         * the name displayed in the GUI
         */
        public string name { get; private set; }
        public string icon { get; private set; default = ""; }
        public string description { get; private set; default = ""; }
        /**
         * the maximal file size a file or list of files are allowed to have to
         * be applicable for this contract
         */
        public int64 max_file_size { get; private set; default = -1; }

        private MimeTypeManager mimetype_manager;
        /**
         * the object used to get individual fields from the .contract file
         */
        private ContractKeyFile keyfile;

        /**
         * the constructor used to create a Contract object containing a
         * ContractFile object based on the passed File object
         *
         * @param file the file of which a ContractFile object should be created
         */
        public Contract (File file) throws Error {
            var contract_file = new ContractFile (file);
            keyfile = new ContractKeyFile (contract_file);

            id = contract_file.get_id ();

            load_mandatory_fields ();
            load_non_mandatory_fields ();
        }

        /**
         * returns true if the MIME type is supported by this contract; false
         * otherwise
         *
         * @param mime_type the MIME type of the file or list of files on which the contract should be applied
         *
         * @return true if the MIME type is supported by this contract; false otherwise
         */
        public bool supports_mime_type (string mime_type) {
            return mimetype_manager.is_type_supported (mime_type);
        }

        /**
         * returns true if the file size is supported by this contract; false
         * otherwise
         *
         * @param file_size the file size of the file or list of files on which the contract should be applied
         *
         * @return true if the file size is supported by this contract; false otherwise
         */
        public bool supports_file_size (int64 file_size) {
            return file_size == -1 || file_size <= max_file_size;
        }

        public void launch_uris (string[] uris) throws Error {
            var uri_list = String.array_to_list (uris);
            keyfile.get_app_info ().launch_uris (uri_list, null);
        }

        /**
         * creates and returns a new GenericContract object and fills it with
         * data from this Contract object (id, name, description, icon)
         */
        public GenericContract get_generic () {
            return GenericContract () {
                id = id,
                name = name,
                description = description,
                icon = icon
            };
        }

        /**
         * loads mandatory fields from the key file
         */
        private void load_mandatory_fields () throws Error {
            name = keyfile.get_name ();

            string[] mimetypes = keyfile.get_mimetypes ();
            mimetype_manager = new MimeTypeManager (mimetypes);
        }

        /**
         * loads non-mandatory fields from the key file
         */
        private void load_non_mandatory_fields () {
            try {
                description = keyfile.get_description ();
            } catch (Error err) {
                warning ("Contract '%s' does not provide a description (%s)", id, err.message);
            }

            try {
                icon = keyfile.get_icon ();
            } catch (Error err) {
                warning ("Contract '%s' does not provide an icon (%s)", id, err.message);
            }

            try {
                max_file_size = keyfile.get_max_file_size ();
            } catch (Error err) {
                debug ("Contract '%s' does not provide a max file size (%s)", id, err.message);
            }
        }
    }
}
