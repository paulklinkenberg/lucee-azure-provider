<?xml version="1.0" encoding="UTF-8"?>
<cfLuceeConfiguration salt="FFFFFFFF-DA8E-4254-94E977FB2D4B3B33" version="5.0">
	<setting/>
	<data-sources></data-sources>


	<resources>
		<!--- the following 2 are default: --->
    	<resource-provider arguments="case-sensitive:true;lock-timeout:1000;" class="lucee.commons.io.res.type.ram.RamResourceProvider" scheme="ram"/>
    	<resource-provider arguments="lock-timeout:10000;" class="lucee.commons.io.res.type.s3.S3ResourceProvider" scheme="s3"/>

<!--- Add the following line to your lucee-web.xml.cfm: --->
	    <resource-provider arguments="case-sensitive:true;" component="AzureBlobResourceProvider" scheme="azure"/>
<!--- end Add --->
	</resources>



    <remote-clients directory="{lucee-web}remote-client/"/>
	<file-system deploy-directory="{lucee-web}/cfclasses/" fld-directory="{lucee-web}/library/fld/" temp-directory="{lucee-web}/temp/" tld-directory="{lucee-web}/library/tld/"></file-system>
	<scope client-directory="{lucee-web}/client-scope/" client-directory-max-size="100mb"/>
	<mail></mail>
	<scheduler directory="{lucee-web}/scheduler/"/>
	<mappings>
		<mapping archive="{lucee-web}/context/lucee-context.lar" physical="{lucee-web}/context/" primary="physical" readonly="yes" toplevel="yes" trusted="true" virtual="/lucee/"/>
	</mappings>
	<custom-tag>
		<mapping physical="{lucee-web}/customtags/" trusted="yes"/>
	</custom-tag>
	<ext-tags>
		<ext-tag class="lucee.cfx.example.HelloWorld" name="HelloWorld" type="java"/>
	</ext-tags>
	<component base="/lucee/Component.cfc" data-member-default-access="public" use-shadow="yes"></component>
	<regional/>
	<debugging template="/lucee/templates/debugging/debugging.cfm"/>
	<application cache-directory="{lucee-web}/cache/" cache-directory-max-size="100mb"/>
	<logging>
		<logger appender="resource" appender-arguments="path:{lucee-config}/logs/remoteclient.log" layout="classic" level="info" name="remoteclient"/>
		<logger appender="resource" appender-arguments="path:{lucee-config}/logs/requesttimeout.log" layout="classic" name="requesttimeout"/>
		<logger appender="resource" appender-arguments="path:{lucee-config}/logs/mail.log" layout="classic" name="mail"/>
		<logger appender="resource" appender-arguments="path:{lucee-config}/logs/scheduler.log" layout="classic" name="scheduler"/>
		<logger appender="resource" appender-arguments="path:{lucee-config}/logs/trace.log" layout="classic" name="trace"/>
		<logger appender="resource" appender-arguments="path:{lucee-config}/logs/application.log" layout="classic" level="info" name="application"/>
		<logger appender="resource" appender-arguments="path:{lucee-config}/logs/exception.log" layout="classic" level="info" name="exception"/>	
	</logging>
	<datasource/>
	<rest/>
	<gateways/>
	<orm/>
	<search/>
</cfLuceeConfiguration>