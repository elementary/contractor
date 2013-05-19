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

    [DBus (name = "org.elementary.Contractor")]
    public class DBusService : Object {
        public DBusService () {
            Idle.add (delayed_contract_load);
        }

        public GenericContract[] get_contracts_by_mime (string mime_type) {
            string[] mime_types = { mime_type };
            return get_contracts_by_mimelist (mime_types);
        }

        public GenericContract[] get_contracts_by_mimelist (string[] mime_types) {
            var contracts = ContractManager.get_instance ().get_contracts_for_types (mime_types);
            return convert_to_generic_contracts (contracts);
        }

        public void execute_with_uri_list (string id, string[] uris) throws Error {
            var contract = ContractManager.get_instance ().get_contract_for_id (id);

            if (contract != null)
                contract.launch_uris (uris);
        }

        public void execute_with_uri (string id, string uri) throws Error {
            string[] uris = { uri };
            execute_with_uri_list (id, uris);
        }

        public GenericContract[] list_all_contracts () {
            var contracts = ContractManager.get_instance ().get_all_contracts ();
            return convert_to_generic_contracts (contracts);
        }

        private static bool delayed_contract_load () {
            ContractManager.get_instance ();
            return false;
        }

        private static GenericContract[] convert_to_generic_contracts (Gee.Collection<Contract> contracts) {
            var generic_contracts = new GenericContract[0];

            foreach (var contract in contracts)
                generic_contracts += contract.get_generic ();

            return generic_contracts;
        }
    }
}
