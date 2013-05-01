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
        public string icon { get; private set; }
        public string description { get; private set; }

        private MimeTypeManager mimetype_manager;
        private ContractKeyFile keyfile;

        public Contract (File file) throws Error {
            var contract_file = new ContractFile (file);
            id = contract_file.get_id ();

            keyfile = new ContractKeyFile (contract_file);
            name = keyfile.get_name ();
            description = keyfile.get_description ();
            icon = keyfile.get_icon ();

            string mimetypes = keyfile.get_mimetypes ();
            mimetype_manager = new MimeTypeManager (mimetypes);
        }

        public bool supports_mime_type (string mime_type) {
            return mimetype_manager.is_type_supported (mime_type);
        }

        public void launch_uris (List<string>? uris) throws Error {
            keyfile.get_app_info ().launch_uris (uris, null);
        }

        public GenericContract get_generic () {
            var generic = GenericContract ();

            generic.id = id;
            generic.name = name;
            generic.description = description;
            generic.icon = icon;

            return generic;
        }
    }
}
