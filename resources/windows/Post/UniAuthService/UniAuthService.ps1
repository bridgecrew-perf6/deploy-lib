Import-module '.\scripts\sideFunctions.psm1'

$IPAddress = (Get-NetIPAddress -AddressFamily ipv4 |  Where-Object -FilterScript { $_.interfaceindex -ne 1}).IPAddress.trim()

$UniRuConfig = "C:\inetpub\ClientWorkPlace\uniru\Web.config"
$webdoc = [Xml](Get-Content $UniRuConfig)
$logoutService = $webdoc.configuration.Grpc.Services.add | Where-Object name -eq "LogoutServiceClient"
$logoutService.host = $IPAddress
$logoutService.port = 5307

$authUrl = $webdoc.configuration.connectionStrings.add | Where-Object name -eq "UniAuthServiceUrl"
$authUrl.connectionString = "https://$($env:COMPUTERNAME).bb-webapps.com:450"
$webdoc.Save($UniRuConfig)

$WebsiteRuConfig = "C:\inetpub\Website\Web.config"
$webdoc = [Xml](Get-Content $WebsiteRuConfig)
$logoutService = $webdoc.configuration.Grpc.Services.add | Where-Object name = "LogoutServiceClient"
$logoutService.host = $IPAddress
$logoutService.port = 5307
$webdoc.Save($WebsiteRuConfig)