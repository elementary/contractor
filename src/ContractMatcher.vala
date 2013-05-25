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

public class Contractor.ContractMatcher : Object {
    private ContractSource contract_source;

    public ContractMatcher (ContractSource contract_source) {
        this.contract_source = contract_source;
    }

    public Gee.Collection<Contract> get_contracts_for_types (string[] mime_types) {
        var valid_contracts = new Gee.LinkedList<Contract> ();
        var all_contracts = contract_source.get_contracts ();
        var valid_mime_types = String.clean_array (mime_types);

        foreach (var contract in all_contracts) {
            // Check if the contract supports ALL the types listed in mime_types
            bool all_types_supported = true;

            foreach (string mime_type in valid_mime_types) {
                if (!contract.supports_mime_type (mime_type)) {
                    all_types_supported = false;
                    break;
                }
            }

            if (all_types_supported)
                valid_contracts.add (contract);
        }

        return valid_contracts;
    }
}
