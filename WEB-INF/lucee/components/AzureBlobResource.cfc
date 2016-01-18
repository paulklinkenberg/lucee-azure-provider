component accessors="true" {

	TIME_ZERO=createDate(1970,1,1,'UTC');
	_isDirectory=false;
	_isFile=false;
	children=structNew('linked');
	_lastModified=TIME_ZERO;

	function debuglog(txt) {
		var extra = '';
		if (structKeyExists(variables, "settings")) {
			try {
				extra = "| container: #variables.settings.getContainer()#, fileName:  #variables.settings.getFileName()#";
			} catch(any e) {
				extra = '| ERROR: #e.message# #e.detail#';
			}
		}
		log text="#txt##extra#" type="information" file="azure";
	}

	// Ref, see:
	// https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/type/s3/S3Resource.java

	public function init(required AzureBlobSettings settings, required component provider
	                     , required component storageHandler)
	{
		variables.settings = arguments.settings;
		variables.provider = arguments.provider;
		variables.storageHandler = arguments.storageHandler;
		debuglog("azureblobresource init end");
		return this;
	}
	
/*  PK: not required? Can't be found in S3Resource

	public component function getChild(component parent,string name){
		if(structKeyExists(variables.children,arguments.name)) return variables.children[arguments.name];
		
		return children[name] = new RAM2Resource(variables.provider,arguments.parent,arguments.name);
	}
*/
	public component function getChild(component parent,string name){
		debuglog("azureblobresource getChild #serialize(arguments)#");
		throw('Not implemented');
	}

	
	
	public boolean function isReadable() {
		debuglog("azureblobresource isReadable");
		return true;
	}

	public boolean function isWriteable() {
		debuglog("azureblobresource isWriteable");
		return true;
	}


	public void function remove(boolean force) {
		debuglog("azureblobresource remove #serialize(arguments)#");
		if(isRoot()) {
			debuglog("You asked to remove the root of your Azure Blob container. That's not cool, the container itself would be gone. Not cool, not allowed.");
			throw("You asked to remove the root of your Azure Blob container. That's not cool, the container itself would be gone. Not cool, not allowed.");
		}

		if(!exists()) {
			debuglog("Sorry, can't remove resource ["&getInnerPath()&"], the resource does not exist.");
			throw("Sorry, can't remove resource ["&getInnerPath()&"], the resource does not exist.");
		}

		if (isDirectory())
		{
			local.aJavaFiles = variables.storageHandler.listFiles(getInnerPath(), true, true);
			if (!force && arrayLen(local.aJavaFiles)) {
				debuglog("Can't delete directory ["&getInnerPath()&"], the directory is not empty.");
				throw("Can't delete directory ["&getInnerPath()&"], the directory is not empty.");
			}

			loop array="#local.aJavaFiles#" index="local.cloudBlockBlob"
			{
				local.cloudBlockBlob.delete();
			}
			/* optionally remove 0-byte file {this-directory}/  */
			if (variables.storageHandler.fileExists(trailSlash(getInnerPath())))
			{
				variables.storageHandler.deleteFile(trailSlash(getInnerPath()));
			}

		} else
			variables.storageHandler.deleteFile(getInnerPath());
		debuglog("azureblobresource remove end");
	}
	

	public boolean function exists()
	{
		// return getInfo().exists();
		debuglog("azureblobresource exists {}");
		var info = getInfo();
		if (info.getIsDirectory()) {
			debuglog("azureblobresource exists says isDirectory==true");
			return true;
		}
		if (not isNull(info.getBlobObject())) {
			debuglog("azureblobresource exists end, info.getBlobObject().exists(): #info.getBlobObject().exists()#");
		} else {
			debuglog("azureblobresource exists ERROR: info.getBlobObject() is NULL, but is not a directory as well!");
		}
		return info.getIsFile();
	}


	public String function getName() {
		debuglog("azureblobresource getname {}");
		var ret = listLast(variables.settings.getFileName(), '/');
		debuglog("azureblobresource getname returns #ret# (full path: #variables.settings.getFileName()#)");
		return ret;
	}

	// https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/type/s3/S3Resource.java#L194
	public String function getParent()
	{
		debuglog("azureblobresource getparent {}");
		if(isRoot()) return nullValue();
		return getPrefix() & replace(getParentDirectory() & "/", '//', '/');
	}


	// https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/type/s3/S3Resource.java#L213
	public any function getParentResource()
	{
		debuglog("azureblobresource getParentResource {}");
		if(isRoot())
			return nullValue();
		local.parentSettings = variables.settings.clone();
		local.parentSettings.setFileName(getParentDirectory());
		return new AzureBlobResource(local.parentSettings, variables.provider, variables.storageHandler);
	}

	// https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/type/s3/S3Resource.java#L272
	public AzureBlobResource function getRealResource(String realpath)
		description="returns a resource that is relative to the current resource"
	{
		debuglog("azureblobresource getRealResource #serialize(arguments)#");
		if (left(arguments.realpath, 1) eq '/')
			arguments.realpath = mid(arguments.realpath, 2);

		if (find('../', arguments.realpath) eq 1)
			return nullValue();

		if (!isFile())// directory or root
			local.realPath = replace(getInnerPath() & "/" & arguments.realpath, '//', '/', 'all')
		else
			local.realPath = replace(getParentDirectory() & "/" & arguments.realpath, '//', '/', 'all');

		local.newSettings = variables.settings.clone();
		local.newSettings.setFilename(local.realPath);
		return new AzureBlobResource(local.newSettings, variables.provider, variables.storageHandler);
	}


	public String function getPath()
		description="Converts this abstract pathname into a pathname string."
	{
		debuglog("azureblobresource getPath {}");
		return getPrefix() & getInnerPath();
	}


	public boolean function isAbsolute() {
		debuglog("azureblobresource isAbsolute {}");
		return true;
	}

	public boolean function isDirectory()
	{
		debuglog("azureblobresource isdirectory {}");
		return getInfo().getIsDirectory();
	}

	public boolean function isFile()
	{
		var ret = getInfo().getIsFile();
		debuglog("azureblobresource isfile, return: #ret#");
		return ret;
	}


	public datetime function lastModified()
	{
		debuglog("azureblobresource lastmodified {}");
		if (isDirectory())
			return createDate(1970,1,1,'UTC');
		local.blob = getInfo().getBlobObject();
		if (isNull(local.blob.getProperties().getLastModified()))
			local.blob.downloadAttributes();
		return local.blob.getProperties().getLastModified();
	}


	public number function length()
	{
		debuglog("azureblobresource length {}");
		if(isFile() && exists())
		{
			local.blob = getInfo().getBlobObject();
			if (isNull(local.blob.getProperties().getLength()) or local.blob.getProperties().getLength() eq 0)
				local.blob.downloadAttributes();
			return local.blob.getProperties().getLength();
		}
		return 0;
	}


	public any function listResources()
		description="Returns an array of abstract pathnames denoting the files in the directory denoted by this abstract pathname."
	{
		debuglog("azureblobresource listResources {}");
		if (isFile())
			return nullValue();
		local.path = getInnerPath();
		if (right(local.path, 1) neq '/')
			local.path &= '/';

		local.listing = variables.storageHandler.listDirectory(local.path);
		var arr=[];
		loop array="#local.listing#" index="local.path"
		{
			local.newSettings = variables.settings.clone();
			local.newSettings.setFilename(local.path);
			arrayAppend(arr, new AzureBlobResource(local.newSettings, variables.provider, variables.storageHandler));
		}
		debuglog("azureblobresource listResources end");
		return arr;
	}


	public boolean function setLastModified(required datetime lastModified)
	{
		debuglog("azureblobresource setLastModified #serialize(arguments)#");
		if (!isFile())
			return;
			// throw("Can't set lastModified date on directory [#getInnerPath()#]. Azure Blob directories do not really exist; they are virtual (by looking at filenames with slashes in them)");
		local.blob = getInfo().getBlobObject();
		local.blob.getProperties().setLastModified(arguments.lastModified);
		local.blob.uploadProperties();
		return true;
	}


	public boolean function setWritable(boolean writable)
	{
		debuglog("azureblobresource setWritable #serialize(arguments)#");
		if(!arguments.writable)
			throw("setting writable to false is not supported");
		return true;
	}


	public boolean function setReadable(boolean readable) {
		debuglog("azureblobresource setReadable #serialize(arguments)#");
		if(!arguments.readable)
			throw("setting readable to false is not supported");
		return true;
	}

	public void function createFile(boolean createParentWhenNotExists)
	{
		debuglog("azureblobresource createFile #serialize(arguments)#");
		// checkCreateFileOK: https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/util/ResourceUtil.java#L1260
		if (exists())
		{
			if (isDirectory())
				throw("Can't create file [#getInnerPath()#], resource already exists as a directory");
			if (isFile())
				throw("Can't create file [#getInnerPath()#], the file already exists");
		}
		local.parent = getParentResource();
		if (not isNull(local.parent))
		{
			if (local.parent.isFile())
			{
				throw("Can't create file [#getInnerPath()#], parent is a file, not a directory")
			} else if (not local.parent.isDirectory() and not arguments.createParentWhenNotExists)
				throw("Can't create file [#getInnerPath()#], missing parent directory.");
		}

		local.emptyFile = createEmptyFile();

		variables.storageHandler.writeFile(local.emptyFile, getInnerPath(), 'application/octet-stream');

		tryDeleteFile(local.emptyFile);

		/* update info */
		getInfo(true);
		debuglog("azureblobresource createFile end");
	}



	public void function createDirectory(boolean createParentWhenNotExists)
	{
		debuglog("azureblobresource createDirectory #serialize(arguments)#");
		// add trailing slash to filename, if there isn't one yet
		if (right(variables.settings.getFileName(), 1) neq "/")
			variables.settings.setFileName( variables.settings.getFileName() & "/" );

		local.emptyFile = createEmptyFile();

		variables.storageHandler.writeFile(local.emptyFile, getInnerPath());

		tryDeleteFile(local.emptyFile);

		//throw("Can't create directory; directories in Azure Blob Storage are only virtual (file names can have slashes in them to mimic a directory structure)");
		debuglog("azureblobresource createDirectory end");
	}

	public boolean function isRoot()
	{
		debuglog("azureblobresource isroot {}");
/*
		if (isDefined("variables.settings.getFileName") and find('test.txt', variables.settings.getFileName())
				and not structKeyExists(request, "dumpNotExists2")) {
			request.dumpNotExists2 = 1;
		}
		else if (structKeyExists(request, "dumpNotExists2")
				and isDefined("variables.settings.getFileName") and find('notexists2.txt', variables.settings.getFileName())) {
			if (request.dumpNotExists2 eq 3)
				throw('dit zou ie niet moeten doen. waar komt het vandaan?');
			request.dumpNotExists2++;
		}
*/

		return variables.settings.getFileName() eq '' || variables.settings.getFileName() eq '/';
	}


	/* used when argument "use-stream" is set to true
	public function getInputStream() {}
	public function getOutputStream(boolean append) {}
	*/

	// used when argument "use-stream" is set to false
	public any function getBinary()
	{
		debuglog("azureblobresource getBinary #serialize(arguments)#");
		if (!exists())
			throw("Can't get file contents, path [#getInnerPath()#] does not exist");
		if (!isFile())
			throw("Can't get file contents, path [#getInnerPath()#] is a directory");

		/* ToDo: use inputstream and outputstream directly. Would save writing to disk, and reading it again!
			Personal hurdle: I don't know how to create an outputStream which would save the file to Azure when close() is called */

		local.filePath = variables.storageHandler.downloadFile(getInnerPath());
		local.data = fileReadBinary(local.filePath);
		tryDeleteFile(local.filePath);

		debuglog("azureblobresource getBinary end");
		return local.data;
	}
	
	// used when argument "use-stream" is set to false
	public void function setBinary(required any content)
	{
		debuglog("azureblobresource setBinary #serialize(arguments)#");
		if (exists() && !isFile())
			throw("Can't save file contents, path [#getInnerPath()#] is a directory");

		local.filePath = createTempFilePath();
		fileWrite(local.filePath, arguments.content);
		variables.storageHandler.writeFile(local.filePath, getInnerPath());

		tryDeleteFile(local.filePath);
	}




	// https://github.com/getrailo/railo/blob/master/railo-java/railo-core/src/railo/commons/io/res/type/s3/S3Resource.java#L169
	private String function getPrefix()
	{
		debuglog("azureblobresource getprefix #serialize(arguments)#");
		// abs://accessKey@account-name.blob.core.windows.net
		return variables.provider.getScheme() & "://" & variables.settings.getAccessKey() & "@"
			& variables.settings.getAccountName() & ".blob.core.windows.net/" & variables.settings.getContainer();
	}

	private String function getInnerPath()
	{
		debuglog("azureblobresource getInnerpath #serialize(arguments)#");
		if(isRoot()) return "/";
		return replace("/" & variables.settings.getFileName(), '//', '/');
	}

	private String function getParentDirectory()
	{
		debuglog("azureblobresource getParentDirectory #serialize(arguments)#");
		if(isRoot()) return nullValue();
		if (listLen(variables.settings.getFileName(), '/') eq 1)
			return "/";
		return listDeleteAt(variables.settings.getFileName(), listLen(variables.settings.getFileName(), '/'), '/');
	}

	private AzureBlobInfo function getInfo(Boolean reload=false)
	{
		debuglog("azureblobresource getInfo #serialize(arguments)#");
		if (!isNull(variables.infoObject) && !arguments.reload)
			return variables.infoObject;

		local.info = new AzureBlobInfo();
		local.info.setIsDirectory(variables.storageHandler.directoryExists(variables.settings.getFileName()));
		if (not local.info.getIsDirectory())
		{
			local.info.setBlobObject(variables.storageHandler.getFile(variables.settings.getFileName()));
			local.info.setIsFile( local.info.getBlobObject().exists() );
		}
		return variables.infoObject = local.info;
	}

	private String function trailSlash(required string path)
	{
		debuglog("azureblobresource trailSlash #serialize(arguments)#");
		if (right(arguments.path, 1) eq '/')
			return arguments.path;
		return arguments.path & '/';
	}


	private string function createEmptyFile() {
		local.path = createTempFilePath();
		fileWrite(local.path, '');
		return local.path;
	}


	private string function createTempFilePath() {
		return getTempDirectory() & createUUID() & listLast(variables.settings.getFileName(), '/');
	}


	private string function tryDeleteFile(required string filepath) {
		try {
			fileDelete(arguments.filepath);
		} catch(any e){}
	}
}