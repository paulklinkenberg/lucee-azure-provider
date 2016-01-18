component {
	this.name = "azure-blob-storage-testing";

	public function onRequestStart()
	{
		/* reload the page, if this was the very first request in this web context */
		if (structKeyExists(request, "reloadRequest")) {
			location url="#cgi.script_name#?#cgi.query_string#" addtoken="no";
		}
		
		addMappings();
	}

	public function onApplicationStart()
	{
		// make sure the azure mappings work, by instantiating the main class
		// (maybe it only works this way, because the <resource-provider> is only loaded
		//  if the given "component" attribute is already compiled into byte code / available as a .class ...?)
		local.x = new AzureBlobResourceProvider();
		/* reload the page for the user */
		request.reloadRequest = 1;
	}

	private function addMappings() {
		// Azure settings
		local.accessKey = "";
				throw("You need to add an accessKey to the Azure storage account! Or ask Paul Klinkenberg if he sent this test stuff to you.");
		local.storageName = "luceetesting";
		local.containerName = "mycontainer";

		this.mappings['/azuremapping'] = "azure://#local.accessKey#@#local.storageName#.blob.core.windows.net/#local.containername#";
	}
}
