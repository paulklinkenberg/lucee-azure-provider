component accessors="true"
{
	property name="container" type="string";
	property name="fileName" type="string";
	property name="accessKey" type="string";
	property name="accountName" type="string";
	property name="logging" type="boolean";

	function debuglog(txt) {
		if (not getLogging())
			return;
		var extra = "| container: #getContainer()#, fileName: #getFileName()#, accessKey: #getAccessKey()#, accountame: #getAccountName()#";
		log text="#txt##extra#" type="information" file="azure";
	}


	public function init(boolean logging=false) {
		setLogging(arguments.logging);
		debuglog("AzureBlobSettings init #serialize(arguments)#");
		return this;
	}


	public component function clone()
	{
		debuglog("AzureBlobSettings clone #serialize(arguments)#");
		local.ret = new AzureBlobSettings(logging=getLogging());
		local.ret.setContainer(getContainer());
		local.ret.setFileName(getFileName());
		local.ret.setAccessKey(getAccessKey());
		local.ret.setAccountName(getAccountName());
		return local.ret;
	}
}
