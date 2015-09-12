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

namespace Contractor {
    public class Contract : Object {
        public string id { get; private set; }
        public string name { get; private set; }
        public string icon { get; private set; default = ""; }
        public string description { get; private set; default = ""; }
        public int64 max_file_size { get; private set; default = -1; }

        private MimeTypeManager mimetype_manager;
        private ContractKeyFile keyfile;

        public Contract (File file) throws Error {
            var contract_file = new ContractFile (file);
            keyfile = new ContractKeyFile (contract_file);

            id = contract_file.get_id ();

            load_mandatory_fields ();
            load_non_mandatory_fields ();
        }

        public bool supports_mime_type (string mime_type) {
            return mimetype_manager.is_type_supported (mime_type);
        }

        public bool supports_file_size (int64 file_size) {
            return file_size == -1 || file_size <= max_file_size;
        }

        public void launch_uris (string[] uris) throws Error {
            var uri_list = String.array_to_list (uris);
            keyfile.get_app_info ().launch_uris (uri_list, null);
        }

        public GenericContract get_generic () {
            return GenericContract () {
                id = id,
                name = name,
                description = description,
                icon = icon
            };
        }

        private void load_mandatory_fields () throws Error {
            name = keyfile.get_name ();

            string[] mimetypes = keyfile.get_mimetypes ();
            mimetype_manager = new MimeTypeManager (mimetypes);
        }

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
                warning ("Contract '%s' does not provide a max file size (%s)", id, err.message);
            }
        }
    }
}
