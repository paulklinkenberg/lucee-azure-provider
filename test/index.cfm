<h3>test to see if the Azure mapping works</h3>

<p>The mapping is <i>/azuremapping</i>, pointing to "azure://..." if everything is correct.</p>

<cftimer type="outline" label="timer">
	<cfdump eval="expandPath('/azuremapping')"/>
</cftimer>

<cfif find('azure://', expandPath('/azuremapping')) neq 1>
	<h3 style="color: #f00;">Oops! Does not work!</h3>
	<cfexit method="exittemplate" />
</cfif>

<cftimer type="outline" label="timer">
	<cfdump eval="fileExists('/azuremapping/test.txt')" />
</cftimer>
<cftimer type="outline" label="timer">
	<cfdump eval="fileWrite('/azuremapping/test.txt', 'Hello world')" />
</cftimer>
<cftimer type="outline" label="timer">
	<cfdump eval="fileAppend('/azuremapping/test.txt', ' and beyond')" />
</cftimer>
<cftimer type="outline" label="timer">
	<cfdump eval="fileRead('/azuremapping/test.txt')" />
</cftimer>

<cfloop from="1" to="10" index="i">
	<cftimer type="outline" label="timer">
		<cfdump eval="fileWrite('/azuremapping/test#i#.pdf', 'File nr. #i#')" />
	</cftimer>
</cfloop>

<cftimer type="outline" label="timer">
	<cfdump eval="directoryList('/azuremapping')" />
</cftimer>

<cftimer type="outline" label="timer">
	<cfdump eval="fileDelete('/azuremapping/test.txt')" />
</cftimer>
