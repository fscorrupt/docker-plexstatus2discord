# Enter the path to the config file for Tautulli and Discord
[string]$strPathToConfig = "$PSScriptRoot\config\config.json"

if (test-path $strPathToConfig){

  # Script name MUST match what is in config.json under "ScriptSettings"
  [string]$strScriptName = 'PlexStatus'

  # Parse the config file and assign variables
  [object]$objConfig = Get-Content -Path $strPathToConfig -Raw | ConvertFrom-Json
  [string]$strDiscordWebhook = $objConfig.ScriptSettings.$strScriptName.Webhook
  [string]$strDiscordWebhookAnnounce = $objConfig.ScriptSettings.$strScriptName.WebhookAnnounce

  # Discord Webhook Uri
  $Uri = $strDiscordWebhook
  $AnnouncementUri = $strDiscordWebhookAnnounce
  $StatusPage = 'https://status.plex.tv'
  $Loop = $null

  # First Status Call
  $WebRequest = Invoke-WebRequest -Uri $StatusPage
  $Status = ($WebRequest.AllElements | ? { $_.Class -eq 'status font-large' } | select innerText).innertext
  $Incident = ($WebRequest.AllElements | ? { ($_.Class -eq 'incident-title font-large') -or ($_.class -eq 'page-status status-major') -or ($_.class -eq 'page-status status-minor')  } | select innerText).innertext

  if ($Status -match 'All Systems Operational' ){
    $Content = '```DIFF'+"`n"+"!"+$Status+"`n"+'```'
  }
  Else{
    $Content = '```DIFF'+"`n"+"-"+$Incident+"`n"+'```'
  }

  $DCContent = @"
  **Current status of [plex.tv](https://status.plex.tv):**$Content
"@

  #Send to Discord, each time the Script is starting
  $UserPayload = [PSCustomObject]@{content = $DCContent}
  Invoke-RestMethod -Uri $uri -Body ($UserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'


  # Loop for status.plex.tv, only posts to channel when status is 'Bad'

  while ($Loop -ne 'Ended'){

    $WebRequest = Invoke-WebRequest -Uri $StatusPage
    $Status = ($WebRequest.AllElements | ? { $_.Class -eq 'status font-large' } | select innerText).innertext
    $Incident = ($WebRequest.AllElements | ? { ($_.Class -eq 'incident-title font-large') -or ($_.class -eq 'page-status status-major')  -or ($_.class -eq 'page-status status-minor') } | select innerText).innertext

    if ($Status -match 'All Systems Operational' ){
      $Content = '```DIFF'+"`n"+"!"+$Status+"`n"+'```'
      $Stat = "Good"
    }
    Else{
      $Content = '```DIFF'+"`n"+"-"+$Incident+"`n"+'```'
      $Stat = "Bad"
    }


          $DCContent = @"
  **Current status of [plex.tv](https://status.plex.tv):**$Content
"@
          $ADCContent = @"
 **Current status of [plex.tv](https://status.plex.tv):**$Content
"@

    if ($Stat -eq 'Bad'){

          #Send to Discord Announcement Channel
          $AUserPayload = [PSCustomObject]@{content = $ADCContent}
          Invoke-RestMethod -Uri $AnnouncementUri -Body ($AUserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'
      do {
        $WebRequest = Invoke-WebRequest -Uri $StatusPage
        $Status = ($WebRequest.AllElements | ? { $_.Class -eq 'status font-large' } | select innerText).innertext
        $Incident = ($WebRequest.AllElements | ? { ($_.Class -eq 'incident-title font-large') -or ($_.class -eq 'page-status status-major')  -or ($_.class -eq 'page-status status-minor') } | select innerText).innertext

        if ($Status -match 'All Systems Operational' ){
          $Content = '```DIFF'+"`n"+"!"+$Status+"`n"+'```'
          $DCContent = @"
  **Current status of [plex.tv](https://status.plex.tv):**$Content
"@
          $ADCContent = @"
 **Current status of [plex.tv](https://status.plex.tv):**$Content
"@
          #Send to Discord
          $UserPayload = [PSCustomObject]@{content = $DCContent}
          Invoke-RestMethod -Uri $uri -Body ($UserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'

          #Send to Discord Announcement Channel
          $AUserPayload = [PSCustomObject]@{content = $ADCContent}
          Invoke-RestMethod -Uri $AnnouncementUri -Body ($AUserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'
          $Stat = "Good"
        }
        Else{
          $Content = '```DIFF'+"`n"+"-"+$Incident+"`n"+'```'
          $DCContent = @"
  **Current status of [plex.tv](https://status.plex.tv):**$Content
"@
          #Send to Discord
          $UserPayload = [PSCustomObject]@{content = $DCContent}
          Invoke-RestMethod -Uri $uri -Body ($UserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'
          $Stat = "Bad"
        }
        sleep 300
      }
      Until($Stat -eq 'Good')
    }
    sleep 60  
  }
}
Else {
  write-host "Stopping Container - Config file not Found!" -ForegroundColor Red
  Write-Host ""
  write-host "Please check config file, and fill out all variables - '/opt/appdata/plexstatus2discord/config/config.json'" -ForegroundColor Yellow
}
