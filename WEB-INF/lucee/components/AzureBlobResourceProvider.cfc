component
{
	// For S3 ref, see:
	// https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/type/s3/S3ResourceProvider.java

	variables.scheme = "azure";
	variables.caseSensitive = true;

	this.root = getNullValue();
	// this.root = new AzureBlobResource(provider=this);

	function debuglog(txt) {
		log text=txt type="information" file="azure";
	}

	public function init(string scheme, struct args)
	{
		debuglog("AzureBlobResourceProvider init #serialize(arguments)#");
		if (not isNull(arguments.scheme) and trim(arguments.scheme) neq "")
			variables.scheme = arguments.scheme;

		if (structKeyExists(arguments, "args")) {
			if (structKeyExists(arguments.args, "case-sensitive") and isBoolean(arguments.args['case-sensitive']))
			{
				variables.caseSensitive = arguments.args['case-sensitive'] ? true:false;
			/* old notation with a '=' results in a key without value */
			} else if (findNoCase('case-sensitive=false', structKeyList(arguments.args))) {
				variables.caseSensitive = false;
			}
		}
		return this;
	}
	
	public function getNullValue(){ return; }

	/**
	* returns a resource that match the given path
	*/
	public component function getResource(required string path)
	{
		debuglog("AzureBlobResourceProvider getResource #serialize(arguments)#");
		local.settings = new AzureBlobSettings();
		local.pathData = _parsePath(arguments.path, local.settings);

		/* don't want to be instantiating gazillion objects, so passing it along */
		try {
			local.storageHandler = new com.railodeveloper.azure.BlobStorage(
				  accountName=local.settings.getAccountName()
				, accountKey=local.settings.getAccessKey()
				, container = local.settings.getContainer());

			local.ret = new AzureBlobResource(local.settings, this, local.storageHandler);
		} catch(any e) {
			debuglog("AzureBlobResourceProvider getResource ERROR: #e.message# #e.detail#");
/*
			savecontent variable="local.debugtext" {
				writeDump(e);
			};
			fileWrite(expandPath('/debug.html'), debugText);
*/
			rethrow;
		}

		return local.ret;
	}

	
	public string function getScheme()
	{
		debuglog("AzureBlobResourceProvider getScheme #serialize(arguments)#");
		return variables.scheme;
	}
	
	

	public boolean function isCaseSensitive() {
		debuglog("AzureBlobResourceProvider isCaseSensitive #serialize(arguments)#");
		return variables.caseSensitive;
	}

	public boolean function isModeSupported() {
		debuglog("AzureBlobResourceProvider isModeSupported #serialize(arguments)#");
		return false;/* ? */
	}

	/* PK ToDo: find out if this method is for file attributes / metadata. If so, some can be set and get, like content-type and public/private */
	public boolean function isAttributesSupported() {
		debuglog("AzureBlobResourceProvider isAttributesSupported #serialize(arguments)#");
		return false;
	}


	private void function _parsePath(required String path, required AzureBlobSettings ab)
	{
		debuglog("AzureBlobResourceProvider _parsePath #serialize(arguments)#");
		// abs://accessKey@account-name.blob.core.windows.net/container-name/folder/file.txt
		// Note: access-key can contain slashes!

		/* clean path, remove scheme
		    Apparently, we receive the full path, but without scheme. We do get a starting slash for free though */
		local.pathNoScheme = replaceNoCase(arguments.path, getScheme() & "://", "");
		if (left(local.pathNoScheme, 1) eq '/')
			local.pathNoScheme = mid(local.pathNoScheme, 2);
		local.pathNoScheme = replace(local.pathNoScheme, '\', '/', 'all');

		local.accessKey = listFirst(local.pathNoScheme, '@');
		local.uri = listDeleteAt(local.pathNoScheme, 1, '@');

		if (local.accessKey eq "" or local.uri eq "" or listLen(local.uri, '/') lt 2
				or not find('blob.core.windows.net/', local.uri))
		{
			throw('The Azure Blob Storage resource has an invalid path [#arguments.path#]. It should be in the form of [azure://accessKey@account-name.blob.core.windows.net/container-name]');
		}
		ab.setAccessKey(local.accessKey);
		ab.setAccountName(listFirst(local.uri, '.'));
		ab.setContainer(listGetAt(local.uri, 2, '/'));
		ab.setFileName(listRest(listRest(local.uri, '/'), '/'));
		return;
	}
}