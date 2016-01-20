component accessors="true"
{
	property name="blobObject" type="any";
	property name="isDirectory" type="boolean" default="false";
	property name="isFile" type="boolean" default="false";

	function debuglog(txt) {
		var extra = '| isDirectory:#getIsDirectory()#, isFile:#getIsFile()#';
		log text="#txt##extra#" type="information" file="azure";
	}

	public void function setIsDirectory(required boolean b)
	{
		variables.isDirectory = b;
		if (arguments.b) {
			variables.isFile = false;
		}
		debuglog("AzureBlobinfo setIsDirectory #b# AFTER");
	}

	public void function setIsFile(required boolean b)
	{
		variables.isFile = b;
		if (arguments.b) {
			variables.isDirectory = false;
		}
		debuglog("AzureBlobinfo setIsFile #b# AFTER");
	}


	public void function setBlobObject(required any obj)
	{
		variables.blobObject = arguments.obj;
		if (variables.blobObject.exists()) {
			debuglog("AzureBlobinfo setBlobObject > exists()=true");
			setIsFile(true);
		}
		debuglog("AzureBlobinfo setBlobObject [object] AFTER");
	}


	public boolean function exists() {
		return getIsDirectory() || (getIsFile() && (isNull(getBlobObject()) || getBlobObject().exists()));
	}
}
