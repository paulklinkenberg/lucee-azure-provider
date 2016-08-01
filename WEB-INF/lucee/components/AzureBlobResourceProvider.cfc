component
{
	// For S3 ref, see:
	// https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/type/s3/S3ResourceProvider.java

	variables.scheme = "azure";
	variables.caseSensitive = true;
	variables.logging = false;

	this.root = getNullValue();

	function debuglog(txt) {
		if (not variables.logging)
			return;
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
			if (structKeyExists(arguments.args, "logging") and isBoolean(arguments.args.logging)) {
				variables.logging = arguments.args.logging ? true : false;
			}
		}
		return this;
	}
	
	public function getNullValue(){ return; }


	variables._blobStorageObjects = {};
	private any function _getBlobStorageObject(required AzureBlobSettings blobSettings) {
		local.key = "/" & arguments.blobSettings.getAccessKey() & "@"  & arguments.blobSettings.getAccountName() & ".blob.core.windows.net/" & arguments.blobSettings.getContainer();
		debuglog("_getBlobStorageObject(#local.key#)");

		if (not structKeyExists(variables._blobStorageObjects, local.key)) {
			variables._blobStorageObjects[local.key] = new com.railodeveloper.azure.BlobStorage(
				  accountName =	arguments.blobSettings.getAccountName()
				, accountKey =	arguments.blobSettings.getAccessKey()
				, container = 	arguments.blobSettings.getContainer()
				, logging =		variables.logging
			);
		}
		return variables._blobStorageObjects[local.key];
	}


	/**
	* returns a resource that match the given path
	*/
	public component function getResource(required string path)
	{
		debuglog("AzureBlobResourceProvider getResource #serialize(arguments)#");
		local.settings = new AzureBlobSettings(logging=variables.logging);
		_parsePath(arguments.path, local.settings);

		local.storageHandler = _getBlobStorageObject(local.settings);
		// ToDo: caching the resources on a request-basis
		return new AzureBlobResource(settings=local.settings, provider=this, storageHandler=local.storageHandler
										, logging=variables.logging);
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
		// azure://accessKey@account-name.blob.core.windows.net/container-name/folder/file.txt
		// Note: access-key can contain slashes!

		/* clean path, remove scheme
		    Apparently, we receive the full path, but without scheme. We do get a starting slash for free though */
		local.pathNoScheme = replaceNoCase(arguments.path, getScheme() & "://", "");
		if (left(local.pathNoScheme, 1) eq '/')
			local.pathNoScheme = mid(local.pathNoScheme, 2);
		local.pathNoScheme = replace(local.pathNoScheme, '\', '/', 'all');

		local.accessKey = listFirst(local.pathNoScheme, '@');
		local.uri = listRest(local.pathNoScheme, '@');

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