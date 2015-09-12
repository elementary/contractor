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

namespace Contractor.ContractMatcher {
    public Gee.Collection<Contract> get_contracts_for_types (string[] mime_types,
        Gee.Collection<Contract> contracts_to_filter) throws ContractorError
    {
        var valid_contracts = new Gee.LinkedList<Contract> ();
        var valid_mime_types = String.clean_array (mime_types);

        if (valid_mime_types.length == 0)
            throw new ContractorError.NO_MIMETYPES_GIVEN ("No mimetypes were provided.");

        foreach (var contract in contracts_to_filter) {
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

    public Gee.Collection<Contract> get_contracts_for_file_size (int64 file_size,
        Gee.Collection<Contract> contracts_to_filter) throws ContractorError
    {
        var valid_contracts = new Gee.LinkedList<Contract> ();

        foreach (var contract in contracts_to_filter) {
            bool file_size_supported = true;

            if (!contract.supports_file_size (file_size)) {
                file_size_supported = false;
            }

            if (file_size_supported)
                valid_contracts.add (contract);
        }

        return valid_contracts;
    }

    public Gee.Collection<Contract> get_contracts_for_types_and_file_size (string[] mime_types,
        int64 file_size, Gee.Collection<Contract> contracts_to_filter) throws ContractorError
    {
        var contracts_for_types = get_contracts_for_types (mime_types, contracts_to_filter);
        var valid_contracts = get_contracts_for_file_size (file_size, contracts_for_types);

        return valid_contracts;
    }
}
