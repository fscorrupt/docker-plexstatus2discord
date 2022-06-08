function recurse {
  sleep 180
  $elapsedTime = $(get-date) - $StartTime
  $totalTime = $elapsedTime.Days.ToString() +' Days '+ $elapsedTime.Hours.ToString() +' Hours '+ $elapsedTime.Minutes.ToString() +' Min ' + $elapsedTime.Seconds.ToString() +' Sec'
  write-host ""
  write-host "Container is running since: " -NoNewline
  write-host "$totalTime" -ForegroundColor Cyan
  recurse
}

$json = @"
{
   "ScriptSettings" : {
      "PlexStatus" : {
         "Webhook" : "https://discord.com/api/webhooks/<redacted>",
         "WebhookAnnounce" : "https://discord.com/api/webhooks/<redacted>"
      },
   }
}
"@

$json | Out-File "$PSScriptRoot\config\config.json.template"

if(-not (test-path "$PSScriptRoot\config\log")){
  $null = New-Item -Path "$PSScriptRoot\config\log" -ItemType Directory -ErrorAction SilentlyContinue
}

# Install 
cls
# Show integraded Scripts
$starttime = Get-Date

$scripts =  (get-childitem -Filter *.ps1 | where name -ne 'welcome.ps1').Name.replace('.ps1','')
Write-Host "##############################################################################" -ForegroundColor Green
Write-Host "Currently '$($scripts.count)' scripts integrated" -ForegroundColor Yellow
Write-Host  ''
Write-Host "Please create 'config.json' based on template, located here: " -ForegroundColor Yellow
Write-Host "           /opt/appdata/plexstatus2discord/config/config.json.template" -ForegroundColor Cyan 
Write-Host "Please fill out all required informations in 'config.json'" -ForegroundColor Yellow
Write-Host  ''
Write-Host " - Example on how to run the script manually: " -ForegroundColor Yellow
Write-Host "           docker exec -it plexstatus2discord pwsh PlexStatus.ps1" -ForegroundColor Cyan
Write-Host " - Example on how to run the script via cron: " -ForegroundColor Yellow
Write-Host "           * * * * * docker exec plexstatus2discord pwsh PlexStatus.ps1 >/dev/null 2>&1" -ForegroundColor Cyan
Write-Host "##############################################################################" -ForegroundColor Green
Write-Host  ''

foreach ($script in $scripts){
  write-host $script -ForegroundColor Cyan
}

# Call Recursive Function.
recurse
