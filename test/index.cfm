<h3>test to see if the Azure mapping works</h3>

<p>The mapping is <i>/azuremapping</i>, pointing to "azure://..." if everything is correct.</p>

<cfdump eval="expandPath('/azuremapping')"/>

<cfif find('azure://', expandPath('/azuremapping')) neq 1>
	<h3 style="color: #f00;">Oops! Does not work!</h3>
	<cfexit method="exittemplate" />
</cfif>

<cfdump eval="fileExists('/azuremapping/test.txt')" />
<cfdump eval="fileWrite('/azuremapping/test.txt', 'Hello world')" />
<cfdump eval="fileAppend('/azuremapping/test.txt', ' and beyond')" />
<cfdump eval="fileRead('/azuremapping/test.txt')" />

<cfloop from="1" to="10" index="i">
	<cfdump eval="fileWrite('/azuremapping/test#i#.pdf', 'File nr. #i#')" />
</cfloop>

<cfdump eval="directoryList('/azuremapping')" />

<cfdump eval="fileDelete('/azuremapping/test.txt')" />
