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

public class Contractor.ContractManager : Object {
    private FileService file_service;
    private Gee.List<Contract> contracts;

    public ContractManager () {
        file_service = new FileService ();
        contracts = new Gee.LinkedList<Contract> ();

        file_service.contract_file_found.connect (load_contract);
        file_service.contract_files_changed.connect (load_contracts);

        load_contracts ();
    }

    public Gee.Collection<Contract> get_contracts_for_types (string[] mime_types) {
        var valid_contracts = new Gee.LinkedList<Contract> ();
        var all_contracts = get_all_contracts ();
        var valid_mime_types = MimeTypeManager.validate_mime_types (mime_types);

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

    public Contract? get_contract_for_id (string id) {
        foreach (var contract in contracts) {
            if (contract.id == id)
                return contract;
        }

        warning ("Client requested invalid contract: %s.", id);
        return null;
    }

    public Gee.Collection<Contract> get_all_contracts () {
        return contracts;
    }

    private void load_contracts () {
        contracts.clear ();
        file_service.load_contract_files ();
    }

    private void load_contract (File file) {
        Contract? contract = null;

        try {
            contract = new Contract (file);
        } catch (Error err) {
            warning ("Could not load contract: %s", err.message);
            return;
        }

        contracts.add (contract);

        // Sort contracts here so that clients don't have to sort them again
        contracts.sort (ContractSorter.compare_func);

        message ("Contract file '%s' (%s) loaded successfully.", file.get_basename (), contract.id);
    }
}
