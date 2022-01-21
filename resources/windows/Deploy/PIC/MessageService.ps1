import-module '.\scripts\sideFunctions.psm1'

## vars
$release_bak_folder = '\\server\tcbuild$\Testers\DB'


$dbs = @(
	@{
		DbName = "MessageService"
		BackupFile = "$release_bak_folder\MessageService.bak" 
        RelocateFiles = @(
			@{
				SourceName = "MessageService"
				FileName = "MessageService.mdf"
			}
			@{
				SourceName = "MessageService_log"
				FileName = "MessageService_log.ldf"
			}
        )      
	}
)
###restore DB
RestoreSqlDb -db_params $dbs
### fix logpaths
$logpath ="C:\Services\PersonalInfoCenter\MessageService\Log.config"
if (test-path $logpath){
	$svc = get-item $logpath
	$webdoc = [Xml](Get-Content $svc.Fullname)
	$webdoc.log4net.appender.file.value = "c:\logs\PersonalInfoCenter\$($svc.Directory.name)-"
	$webdoc.Save($svc.Fullname)
	$reportval =@"
	[MessageService]
	$logpath
		.log4net.appender.file.value = "c:\logs\PersonalInfoCenter\$($svc.Directory.name)-"
"@
}
else{
	Write-Host -ForegroundColor Green "[INFO] Edit BaltBet.messageservice configuration files..."
	$pathtojson = "C:\Services\PersonalInfoCenter\MessageService\appsettings.json"
	$config = Get-Content -Path $pathtojson -Encoding UTF8
	$json_appsetings = $config -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/' | ConvertFrom-Json

	$json_appsetings.Serilog.WriteTo| %{ if ($_.Name -like 'File'){
			$_.Args.path = "C:\logs\PersonalInfoCenter\MessageService-{Date}.log"   
		}
	}
	ConvertTo-Json $json_appsetings -Depth 4  | Format-Json | Set-Content $pathtojson -Encoding UTF8
	$reportval =@"
	[MessageService]
	$logpath
		.Serilog.WriteTo| %{ if (_.Name -like 'File'){
				_.Args.path = "C:\logs\PersonalInfoCenter\MessageService-{Date}.log"   
			}
"@

}

add-content -force -path "$($env:workspace)\$($env:config_updates)" -value $reportval -encoding utf8
