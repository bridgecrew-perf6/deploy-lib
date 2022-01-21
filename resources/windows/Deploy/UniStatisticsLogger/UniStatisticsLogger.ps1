# Сервис статистики
$WebConfig =  "C:\services\UniStatisticsLogger\Web.config"

Write-Host "[INFO] Edit Web.config of $WebConfig"
$webdoc = [Xml](Get-Content $WebConfig -Encoding utf8)
$webdoc.configuration.log4net.appender | % { $_.file.value = $_.file.value.replace("logs", "c:/logs/UniStatisticsLogger")}
$webdoc.Save($WebConfig)

$reportval =@"
[UniStatisticsLogger]
$ConfigPath
    .configuration.log4net.appender | % { $_.file.value = $_.file.value.replace("logs", "c:/logs/UniStatisticsLogger")}
"@
add-content -force -path "$($env:workspace)\$($env:config_updates)" -value $reportval -encoding utf8

Write-Host -ForegroundColor Green "[INFO] Done"

