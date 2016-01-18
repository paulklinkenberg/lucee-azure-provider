component accessors="true"
{
	property name="blobObject" type="any";
	property name="isDirectory" type="boolean";
	property name="isFile" type="boolean";

	function debuglog(txt) {
		var extra = '| isDirectory:#getIsDirectory()#, isFile:#getIsFile()#';
		log text="#txt##extra#" type="information" file="azure";
	}

	public void function setIsDirectory(required boolean b)
	{
		debuglog("AzureBlobinfo setIsDirectory #b#");
		variables.isDirectory = b;
		if (arguments.b) {
			variables.isFile = false;
		}
	}
	public void function setIsFile(required boolean b)
	{
		debuglog("AzureBlobinfo setIsFile #b#");
		variables.isFile = b;
		if (arguments.b) {
			variables.isDirectory = false;
		}
	}


	public boolean function exists() {
		return getIsFile() || getIsDirectory();
	}
}
