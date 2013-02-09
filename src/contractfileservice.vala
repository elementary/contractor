/*
 * Copyright (C) 2013 Elementary Developers
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
 * Author: lampe2 mgoldhand@googlemail.com
 */
 
namespace Contractor{
	public class ContractFileService : Object{
        // all contract files with conditional
		private Gee.List<ContractFileInfo> contracts_files;
        // only conditional contract files
        private Gee.List<ContractFileInfo> conditional_contracts_files;

		public ContractFileService (){
            contracts_files = new Gee.ArrayList<ContractFileInfo> ();
            conditional_contracts_files = new Gee.ArrayList<ContractFileInfo> ();
            load_contracts_files ();
        }
        /* status: TODO
        *
        */
        private uint timer_id = 0;
        private void contract_file_directory_changed (File file, File? other_file, FileMonitorEvent event){
            message ("file_directory_changed");
            if (timer_id != 0){
                Source.remove (timer_id);
            }

            timer_id = Timeout.add (1000, () =>{
                timer_id = 0;
             //   reload_contract_files ();
                return false;
            });
        }
        /* status: basicly done need review
        *
        */
		private void load_contracts_files (bool should_monitor=true){
			message("loading necessary files");
            var monitors = new Gee.ArrayList<FileMonitor>();
            var count = 0;
            //get paths from enviroment
            var paths = Environment.get_system_data_dirs ();
            paths.resize (paths.length + 1);
            paths[paths.length - 1] = Environment.get_user_data_dir ();
            foreach(var path in paths){
                var directory = File.new_for_path(path+"/contractor/");
                if (directory.query_exists()){
                    process_directory(directory);
                    if (should_monitor){
                        try{
                            monitors.add(directory.monitor_directory(FileMonitorFlags.NONE, null));
                        } catch (IOError e){
                            error("%s monitor failed: %s", directory.get_path(), e.message);
                        }
                        monitors[count].changed.connect(contract_file_directory_changed);
                        count =+ 1;
                    }
                }           
                // create_maps ();
            }
		}

        /* status: needs comments and documentary
        *
        */
		private void process_directory(File directory)
        {
            try {
                var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
                FileInfo f = null;
                while ((f = enumerator.next_file ()) != null) {
                    unowned string name = f.get_name ();
                    if (f.get_file_type () == FileType.REGULAR && name.has_suffix (".contract"))
                    {
                        load_contract_file (directory.get_child(name));
                    }
                }
             } catch (Error err) {
                 warning ("%s name %s", err.message, directory.get_path());
             }
        }
        /* status: done
        *
        */
        private void load_contract_file (File file)
        {
            try {
                uint8[] contents;
                bool success = file.load_contents (null, out contents, null);
                var contents_str = (string) contents;
                size_t len = contents_str.length;
                if (success && len>0)
                {
                    var keyfile = new KeyFile();
                    keyfile.load_from_data (contents_str, len, 0);
                    var cfi = new ContractFileInfo.for_keyfile (file.get_path (), keyfile);
                    if (cfi.is_valid) {
                        contracts_files.add(cfi);
                    }
                    if (cfi.is_conditional) {
                        conditional_contracts_files.add(cfi);
                    }
                }
            } catch (Error err) {
                warning ("%s", err.message);
            }
        }

        public void list_all_contracts(){
            foreach(var contract in contracts_files){
               message(contract.name + " contract. description: " + contract.description);
            }
        }
	}
}