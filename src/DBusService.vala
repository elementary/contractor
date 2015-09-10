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
 *
 * Authors: ammonkey <am.monkeyd@gmail.com>,
 *          lampe2 <michael@lazarski.me>,
 *          Victor Martinez <victoreduardm@gmail.com>
 *
 * The original Contractor implementation in Python was created by:
 *          Allen Lowe <lallenlowe@gmail.com>
 */

namespace Contractor {
    [DBus (name = "org.elementary.ContractorError")]
    public errordomain ContractorError {
        NO_MIMETYPES_GIVEN
    }

    [DBus (name = "org.elementary.Contractor")]
    public class DBusService : Object {
        public signal void contracts_changed ();

        private ContractSource contract_source;

        public DBusService () {
            contract_source = new ContractSource ();
            contract_source.changed.connect (() => contracts_changed ());
        }

        public GenericContract[] get_contracts_by_mime (string mime_type) throws Error {
            string[] mime_types = { mime_type };
            return get_contracts_by_mimelist (mime_types);
        }

        public GenericContract[] get_contracts_by_mimelist (string[] mime_types) throws Error {
            var all_contracts = contract_source.get_contracts ();
            var contracts = ContractMatcher.get_contracts_for_types (mime_types, all_contracts);
            return convert_to_generic_contracts (contracts);
        }

        public GenericContract[] get_contracts_by_file_size (int file_size) throws Error {
            var all_contracts = contract_source.get_contracts ();
            var contracts = ContractMatcher.get_contracts_for_file_size (file_size, all_contracts);
            return convert_to_generic_contracts (contracts);
        }

        public GenericContract[] get_contracts_by_mime_and_file_size (string mime_type, int file_size) throws Error {
            string[] mime_types = { mime_type };
            return get_contracts_by_mimelist_and_file_size (mime_types, file_size);
        }

        public GenericContract[] get_contracts_by_mimelist_and_file_size (string[] mime_types, int file_size) throws Error {
            var all_contracts = contract_source.get_contracts ();
            var contracts = ContractMatcher.get_contracts_for_types_and_file_size (mime_types, file_size, all_contracts);
            return convert_to_generic_contracts (contracts);
        }

        public void execute_with_uri (string id, string uri) throws Error {
            string[] uris = { uri };
            execute_with_uri_list (id, uris);
        }

        public void execute_with_uri_list (string id, string[] uris) throws Error {
            var contract = contract_source.lookup_by_id (id);
            contract.launch_uris (uris);
        }

        public GenericContract[] list_all_contracts () {
            var contracts = contract_source.get_contracts ();
            return convert_to_generic_contracts (contracts);
        }

        private static GenericContract[] convert_to_generic_contracts (Gee.Collection<Contract> contracts) {
            var generic_contracts = new GenericContract[0];

            foreach (var contract in contracts)
                generic_contracts += contract.get_generic ();

            return generic_contracts;
        }
    }
}
