Import-module '.\scripts\sideFunctions.psm1'

#get release params
###vars
$targetDir = "C:\inetpub\ClientWorkPlace\UniRu"
$webConfig = "$targetDir\Web.config"
$IPAddress = (Get-NetIPAddress -AddressFamily ipv4 |  Where-Object -FilterScript { $_.interfaceindex -ne 1}).IPAddress.trim()
###
#XML values replace UniRu
####
Write-Host -ForegroundColor Green "[INFO] Edit web.config of $webConfig"
$webdoc = [Xml](Get-Content $webConfig)
($webdoc.configuration.connectionStrings.add | where {
	$_.name -eq 'DataContext' 
	}).connectionString = "data source=localhost;initial catalog=UniRu;Integrated Security=true;MultipleActiveResultSets=True;"
($webdoc.configuration.connectionStrings.add | where {
	$_.name -eq 'UniPaymentsServiceUrl' 
	}).connectionString = "https://${env:COMPUTERNAME}.bb-webapps.com:54381"
($webdoc.configuration.connectionStrings.add | where {
	$_.name -eq 'UniEventServiceUrl' 
	}).connectionString = "https://${env:COMPUTERNAME}.bb-webapps.com:4435"
$webdoc.configuration.cache.db.connection = "data source=localhost;initial catalog=UniRu;Integrated Security=true;MultipleActiveResultSets=True;"
($webdoc.configuration.Grpc.services.add | where {$_.name -eq 'DefaultService' }).host = $IPAddress
($webdoc.configuration.Grpc.services.add | where {$_.name -eq 'PromocodeAdminService' }).host = $IPAddress
#configuration.appSettings.SelectNodes add node enable swagger   
$targetNode = $webdoc.configuration.appSettings.SelectNodes("add[@key='webapi:EnableSwagger']")
if($targetNode.Count){
    write-host 'remove old nodes'
    foreach($node in $targetNode){$node.ParentNode.RemoveChild($node)}
}
write-host 'creating node'
$webdoc.configuration.appSettings.add| fc
$new = $webdoc.CreateElement("add")
$new.SetAttribute("key","webapi:EnableSwagger")
$new.SetAttribute( "value","false")
$webdoc.configuration.appSettings.AppendChild($new)
(($webdoc.configuration.ckfinder.backends.backend|	where {
	$_.name -ilike "default"
	}).option| where {
		$_.name -ilike 'root'}).value = 'c:\inetpub\images'
$webdoc.Save($webConfig)

$reportval =@"
[UniRu]
$webConfig
	add-content -force -path "$($env:workspace)\$($env:config_updates)" -value $reportval -encoding utf8

	(.configuration.connectionStrings.add | where {
		_.name -eq 'DataContext' 
		}).connectionString = "data source=localhost;initial catalog=UniRu;Integrated Security=true;MultipleActiveResultSets=True;"
	(.configuration.connectionStrings.add | where {
		_.name -eq 'UniPaymentsServiceUrl' 
		}).connectionString = "https://${env:COMPUTERNAME}.bb-webapps.com:54381"
	(.configuration.connectionStrings.add | where {
		_.name -eq 'UniEventServiceUrl' 
		}).connectionString = "https://${env:COMPUTERNAME}.bb-webapps.com:4435"	
	$.configuration.cache.db.connection = "data source=localhost;initial catalog=UniRu;Integrated Security=true;MultipleActiveResultSets=True;"
	(.configuration.Grpc.services.add | where {$_.name -eq 'DefaultService' }).host = $IPAddress
	(.configuration.Grpc.services.add | where {$_.name -eq 'PromocodeAdminService' }).host = $IPAddress
$('='*60)

"@
add-content -force -path "$($env:workspace)\$($env:config_updates)" -value $reportval -encoding utf8
Write-Host -ForegroundColor Green "[INFO] Done"

