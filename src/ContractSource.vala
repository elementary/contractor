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

public class Contractor.ContractSource : Object {
    private FileService file_service;
    private Gee.List<Contract> sorted_contracts;
    private Gee.HashMap<string, Contract> contracts;

    public ContractSource () {
        file_service = new FileService ();
        sorted_contracts = new Gee.LinkedList<Contract> ();
        contracts = new Gee.HashMap<string, Contract> ();

        load_contracts ();

        file_service.contract_files_changed.connect (load_contracts);
    }

    public Gee.Collection<Contract> get_contracts () {
        return sorted_contracts;
    }

    public Contract? lookup (string contract_id) {
        return contracts.get (contract_id);
    }

    private void load_contracts () {
        clear_loaded_contracts ();

        var contract_files_to_load = file_service.load_contract_files ();

        foreach (var contract_file in contract_files_to_load)
            load_contract (contract_file);
    }

    private void load_contract (File file) {
        try {
            var contract = new Contract (file);
            add_contract (contract);
            message ("Contract file '%s' loaded successfully.", file.get_basename ());
        } catch (Error err) {
            warning ("Could not load contract at '%s': %s", file.get_path (), err.message);
        }
    }

    private void add_contract (Contract contract) {
        string contract_id = contract.id;

        if (contracts.has_key (contract_id)) {
            warning ("A contract with ID '%s' exists already. Not adding another one.", contract_id);
            return;
        }

        contracts.set (contract_id, contract);
        sorted_contracts.add (contract);

        // Sort contracts here so that clients don't have to sort them again
        sorted_contracts.sort (ContractSorter.compare_func);
    }

    private void clear_loaded_contracts () {
        contracts.clear ();
        sorted_contracts.clear ();
    }
}
