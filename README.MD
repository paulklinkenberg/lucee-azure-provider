#Installing the Lucee Azure CFML resource provider

1. add to lucee-web.xml.cfm in {your web root}/WEB-INF/lucee/:  

    ```  <resource-provider arguments="case-sensitive:false;logging:false" component="AzureBlobResourceProvider" scheme="azure"/>```

2. Copy the contents of WEB-INF/lucee/components/ to {your web root}/WEB-INF/lucee/components/
3. Copy the contents of WEB-INF/lucee/lib/ to {your web root}/WEB-INF/lucee/lib/
3. Copy the contents of test/ to {your web root}/test/
4. Run /test/index.cfm

##Azure blob storage case-sensitivity

In the ``<resource-provider>`` tag, you probably noticed we set ``case-sensitive:false``.
That's actually a lie, the Azure blob storage system _is_ case-sensitive.
 
Setting it to _false_ is necessary to work around a feature of Lucee, which was probably created for local
filesystems, not (slower) remote ones.
The feature is: _if we check for existence of a file or directory, and it does not seem to exist,
Lucee will retrieve a full directory listing to check if the file/directory exists with different case.
(eg. fileExists('test.txt') will match TeSt.TXT, even on a case-sensitive filesystem)_

If you work with large blob containers, containing hundreds or thousands of files/directories inside a directory/root,
then keep the _case-sensitive_ setting to _false_. If you set it to true, you might be waiting multiple seconds on a
simple ``fileExists``/``directoryExists`` call.
