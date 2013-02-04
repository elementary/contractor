namespace Contractor{
	public class ContractFileService : Object{
		private Gee.List<string> all_contract_files;
        public Gee.List<string> conditional_contracts;
		public ContractFileService (){
            // all_contract_files = new Gee.ArrayList<ContractFileInfo> ();
            // conditional_contracts = new Gee.ArrayList<ContractFileInfo> ();
            all_contract_files = new Gee.ArrayList<string>();
            conditional_contracts = new Gee.ArrayList<string>();
            message("starting contractor");
            // initialize ();
        }
	}
}