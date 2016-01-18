component {

	variables.storageConnectionString="";
	variables.container = "";

	function debuglog(txt) {
		log text=txt type="information" file="azure";
	}

	public com.railodeveloper.azure.BlobStorage function init(required String accountName, required String accountKey, required String container, Boolean useHttps=true)
	{
		debuglog("BlobStorage init #serialize(arguments)#");
		// Define the connection-string with your values
		variables.storageConnectionString =
		    "DefaultEndpointsProtocol=http#arguments.useHttps ? 's':''#;" &
		    "AccountName=#arguments.accountName#;" &
		    "AccountKey=#arguments.accountKey#";
		variables.container = arguments.container;

		variables.mimeTypeObj = new com.railodeveloper.file.MimeType();

		return this;
	}


	public Boolean function directoryExists(required String directory)
	{
		debuglog("BlobStorage directoryExists #serialize(arguments)#");
		if (arguments.directory eq "/" or arguments.directory eq "")
			return true;
		/* ToDo: add new attribute maxFiles in method listFiles (directoryExists only needs to check if there's at least one file) */
		return not arrayIsEmpty(listDirectory(directory=arguments.directory, javaObjects=true, maxFiles=1));
	}


	public Array function listDirectory(required String directory, Boolean javaObjects=false, Boolean recurse=false, numeric maxFiles=-1)
	{
		debuglog("BlobStorage listDirectory #serialize(arguments)#");
		if (right(arguments.directory, 1) neq "/")
				arguments.directory &= "/";
		return listFiles(arguments.directory, arguments.javaObjects, arguments.recurse, arguments.maxFiles);
	}


	public Array function listFiles(String startsWith="", Boolean javaObjects=false, Boolean recurse=false, numeric maxFiles=-1)
	{
		debuglog("BlobStorage listFiles #serialize(arguments)#");
		/* sanitize: path cannot start with a slash */
		if (left(arguments.startsWith, 1) eq '/')
			arguments.startsWith = mid(arguments.startsWith, 2);

		local.container = getContainer();

		// ToDo: implement maxFiles
		if (arguments.recurse)
		{
			local.enumSet = createObject('java', 'java.util.EnumSet').noneOf(createJObject('BlobListingDetails').getClass());
			local.files = local.container.listBlobs(arguments.startsWith, arguments.recurse, local.enumSet, nullValue(), nullValue()).iterator();
		} else
		{
			local.files = local.container.listBlobs(arguments.startsWith).iterator();
		}

		local.ret = [];
		while (local.files.hasNext() && (arguments.maxFiles lt 1 or arguments.maxFiles lt local.ret.len()))
		{
			if (arguments.javaObjects)
				local.ret.append(local.files.next())
			else
			{
				local.o = local.files.next();
				if (local.o.getClass().getName() eq 'com.microsoft.windowsazure.services.blob.client.CloudBlockBlob')
					local.ret.append(local.o.getName());
				else
				{
					local.ret.append(rereplace(replace(local.o.getURI().toString(), local.container.getURI().toString(), ''), '(^/|/$)', '', 'all'));
				}

			}
		}
		debuglog("BlobStorage listFiles end, returns #local.ret.len()# files");
		return local.ret;
	}


	public Boolean function fileExists(required String filePath)
	{
		debuglog("BlobStorage fileExists #serialize(arguments)#");
		if (left(arguments.filePath, 1) eq '/')
			arguments.filePath = mid(arguments.filePath, 2);

		local.container = getContainer();
		local.blob = local.container.getBlockBlobReference(arguments.filePath);

		debuglog("BlobStorage fileExists blob class: #local.blob.getClass().getName()#, exists: #local.blob.exists()#");
		/* ToDo: test this! */
		return local.blob.exists();
	}


	public any function getFile(required String filePath)
	{
		debuglog("BlobStorage getFile #serialize(arguments)#");
		if (left(arguments.filePath, 1) eq '/')
			arguments.filePath = mid(arguments.filePath, 2);

		local.container = getContainer();
		return local.container.getBlockBlobReference(arguments.filePath);
	}


	public Void function writeFile(required String filepath, String filename, String mimeType)
	{
		debuglog("BlobStorage writeFile #serialize(arguments)#");
		if (not structKeyExists(arguments, 'filename') or arguments.filename eq '')
			arguments.filename = listLast(arguments.filePath, '/\#server.separator.file#');
		if (left(arguments.filename, 1) eq '/')
			arguments.filename = mid(arguments.filename, 2);

		// Create the blob client
		local.container = getContainer();

		local.blob = local.container.getBlockBlobReference(arguments.filename);

		// Create or overwrite the "myimage.jpg" blob with contents from a local file
		local.source = createObject('java', 'java.io.File').init(arguments.filepath);

		// save correct mimetype
		if (isNull(arguments.mimeType) or arguments.mimeType eq '') {
			arguments.mimeType = variables.mimeTypeObj.getMimeType(arguments.filepath);
		}
		blob.getProperties().setContentType(arguments.mimeType);

		local.blob.upload(createObject('java', 'java.io.FileInputStream').init(local.source), local.source.length());
	}


	public Void function deleteFile(required String filename)
	{
		debuglog("BlobStorage deleteFile #serialize(arguments)#");
		if (left(arguments.filename, 1) eq '/')
			arguments.filename = mid(arguments.filename, 2);
		// Create the blob client
		local.container = getContainer();

		// Retrieve reference to a previously created container
		local.blob = local.container.getBlockBlobReference(arguments.filename);
		local.blob.delete();
	}


	public String function downloadFile(required String filename, String destination)
		hint="I return the path to the downloaded file"
	{
		debuglog("BlobStorage downloadFile #serialize(arguments)#");
		if (left(arguments.filename, 1) eq '/')
			arguments.filename = mid(arguments.filename, 2);

		if (not structKeyExists(arguments, "destination")) {
			arguments.destination = getTempDirectory() & createUUID() & listLast(arguments.filename, '/\');
		}
		else if (directoryExists(arguments.destination)) {
			arguments.destination = rereplace(arguments.destination, '[/\\\#server.separator.file#]$', '') & server.separator.file & listLast(arguments.filename, '/\')
		}
		else if (right(arguments.destination, 1) eq "/" or right(arguments.destination, 1) eq "\"
				or not directoryExists(listDeleteAt(arguments.destination, listLen(arguments.destination, '/\'), '/\'))) {
			throw("Can't download file, destination directory [#arguments.destination#] does not exist");
		}

		// Create the blob client
		local.container = getContainer();

		local.blob = local.container.getBlockBlobReference(arguments.filename);

		local.fileOutputStream = createObject('java', 'java.io.FileOutputStream')
				.init(createObject('java', 'java.io.File').init(arguments.destination));
		local.blob.download(local.fileOutputStream);

		return arguments.destination;
	}


	public Void function setContainerAccess(required Boolean publicAccess)
	{
		debuglog("BlobStorage setContainerAccess #serialize(arguments)#");
		// Create a permissions object
		local.containerPermissions = createJObject('BlobContainerPermissions');

		local.accessType = arguments.publicAccess ? createJObject('BlobContainerPublicAccessType').CONTAINER
			: createJObject('BlobContainerPublicAccessType').OFF;
		// Include public access in the permissions object
		local.containerPermissions.setPublicAccess(local.accessType);

		// Set the permissions on the container
		getContainer().uploadPermissions(local.containerPermissions);
	}


	public Boolean function getContainerAccess()
	{
		debuglog("BlobStorage getContainerAccess #serialize(arguments)#");
		return getContainer().downloadPermissions().getPublicAccess().toString() eq
			createJObject('BlobContainerPublicAccessType').CONTAINER.toString();
	}


	public Any function getContainer()
	{
		debuglog("BlobStorage getContainer #serialize(arguments)#");
		if (not isNull(variables.containerObject))
			return variables.containerObject;
		// Get a reference to a container
		// The container name must be lower case
		local.container = createBlobClient().getContainerReference(lCase(variables.container));
		return variables.containerObject = local.container;
	}

	private Any function createBlobClient()
	{
		debuglog("BlobStorage createBlobClient #serialize(arguments)#");
		// Retrieve storage account from connection-string
		local.storageAccount = createJObject('CloudStorageAccount').parse(variables.storageConnectionString);

		// Create the blob client
		local.blobClient = storageAccount.createCloudBlobClient();
		return local.blobClient;
	}


	/*  // Include the following imports to use blob APIs
		import com.microsoft.windowsazure.services.core.storage.*;
		import com.microsoft.windowsazure.services.blob.client.*;
	*/
	variables.objectPaths = {
		  "BlobContainerPermissions" = "com.microsoft.windowsazure.services.blob.client.BlobContainerPermissions"
		, "BlobContainerPublicAccessType" = "com.microsoft.windowsazure.services.blob.client.BlobContainerPublicAccessType"
		, "BlobListingDetails" = "com.microsoft.windowsazure.services.blob.client.BlobListingDetails"
	};

	private Any function createJObject(required String name, Boolean clientPackage=false)
	{
		debuglog("BlobStorage createJObject #serialize(arguments)#");
		if (structKeyExists(variables.objectPaths, arguments.name))
			return createObject('java', variables.objectPaths[arguments.name]);
		return createObject('java', 'com.microsoft.windowsazure.services.core.storage.#arguments.name#');
	}
}
