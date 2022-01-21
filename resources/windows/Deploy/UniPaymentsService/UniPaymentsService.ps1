import-module '.\scripts\sideFunctions.psm1'

# 4.2 Обновляем Uni.PaymentsService


$ConfigPath = "c:\Services\UniPaymentsService\appsettings.json"
Write-Host -ForegroundColor Green "[INFO] Change settings $ConfigPath"
$config = Get-Content -Raw -path $ConfigPath 
$json_appsettings = $config -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/' | ConvertFrom-Json
$json_appsettings.ConnectionStrings.UniSiteSettings = "data source=localhost;initial catalog=UniRu;Integrated Security=SSPI;MultipleActiveResultSets=True;"
$json_appsettings.Origins =@( 
		"https://$($env:COMPUTERNAME).bb-webapps.com:4443",
		"https://$($env:COMPUTERNAME).bb-webapps.com:4444",
		"https://$($env:COMPUTERNAME).bb-webapps.com:4445"
		)
$json_appsettings.Grpc.Services | % {
	if ($_.name -like "DefaultService" ){
		$_.Host = $env:COMPUTERNAME 
		$_.Port = 5003
	}
	if ($_.name -like "CupisInvoiceService" ){
		$_.Host = $env:COMPUTERNAME 
		$_.Port = 5003
	}
	if ($_.name -like "CupisPayoutService" ){
		$_.Host = $env:COMPUTERNAME 
		$_.Port = 5003
	}
}

ConvertTo-Json $json_appsettings -Depth 4 | Format-Json | Set-Content $ConfigPath -Encoding UTF8


$reportval =@"
[UniPaymentsService]
$ConfigPath
	.ConnectionStrings.UniSiteSettings = "data source=localhost;initial catalog=UniRu;Integrated Security=SSPI;MultipleActiveResultSets=True;"
	.Origins =@(
			"https://$($env:COMPUTERNAME).bb-webapps.com:4443",
			"https://$($env:COMPUTERNAME).bb-webapps.com:4444",
			"https://$($env:COMPUTERNAME).bb-webapps.com:4445")
	.Grpc.Services | % {
		if (_.name -like "DefaultService" ){
			_.Host = $env:COMPUTERNAME 
			_.Port = 5003
		}
		if (_.name -like "CupisInvoiceService" ){
			_.Host = $env:COMPUTERNAME 
			_.Port = 5003
		}
		if (_.name -like "CupisPayoutService" ){
			_.Host = $env:COMPUTERNAME 
			_.Port = 5003
		}
	}
"@
add-content -force -path "$($env:workspace)\$($env:config_updates)" -value $reportval -encoding utf8

Write-Host -ForegroundColor Green "[INFO] Done"

