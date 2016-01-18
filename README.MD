#Installing the Lucee Azure CFML resource provider

1. add to lucee-web.xml.cfm in {your web root}/WEB-INF/lucee/:  

    ```  <resource-provider arguments="case-sensitive:true;" component="AzureBlobResourceProvider" scheme="azure"/>```

2. Copy the contents of WEB-INF/lucee/components/ to {your web root}/WEB-INF/lucee/components/
3. Copy the contents of WEB-INF/lucee/lib/ to {your web root}/WEB-INF/lucee/lib/
3. Copy the contents of test/ to {your web root}/test/
4. Run /test/index.cfm
