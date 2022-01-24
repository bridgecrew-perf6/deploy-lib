$CurrentIpAddr =(Get-NetIPAddress -AddressFamily ipv4 |  Where-Object -FilterScript { $_.interfaceindex -ne 1}).IPAddress.trim()
$Config = 'C:\inetpub\WebsiteCom-Public\Web.config'
$webdoc = [Xml](Get-Content $Config)
($webdoc.configuration.appSettings| %{$_.add} |? {
	$_.key -like 'ServerAddress'}).value = $CurrentIpAddr+ ':8082'
$webdoc.configuration."system.serviceModel".client.endpoint |% {
	$_.address= $_.address.replace('localhost', $CurrentIpAddr) }
$attrs = @{
 'cookieless' =  "UseCookies"
 'cookieName' = "mySessionCookie"
 'mode' = "StateServer" 
 'stateConnectionString' = "tcpip=localhost:42424"
 'timeout' = "20"
 'useHostingIdentity' = "false"
}
$webdoc.configuration.'system.web'.sessionState.RemoveAllAttributes()
foreach ($attr in $attrs.GetEnumerator()) {    
    $webdoc.configuration.'system.web'.SelectSingleNode('//sessionState').SetAttribute($attr.Name, $attr.Value)
}
$webdoc.Save($Config)

$reportval =@"
[WebMobile]
$Config

(.configuration.appSettings| %{_.add} |? {
	_.key -like 'ServerAddress'}).value = $CurrentIpAddr+ ':8082'
.configuration."system.serviceModel".client.endpoint |% {
	_.address= _.address.replace('localhost', $CurrentIpAddr) }
	foreach (attr in attrs.GetEnumerator()) {    
		.configuration.'system.web'.SelectSingleNode('//sessionState').SetAttribute(attr.Name, attr.Value)
	}
$('='*60)

"@
add-content -force -path "$($env:workspace)\$($env:config_updates)" -value $reportval -encoding utf8

Write-Host -ForegroundColor Green "[INFO] Done"

