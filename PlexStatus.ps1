# Enter the path to the config file for Tautulli and Discord
[string]$strPathToConfig = "$PSScriptRoot\config\config.json"
  $json = @"
{
	"ScriptSettings": {
		"PlexStatus": {
			"Webhook": "https://discord.com/api/webhooks/<redacted>",
			"WebhookAnnounce": "https://discord.com/api/webhooks/<redacted>"
		}
	}
}
"@
$json | Out-File "$PSScriptRoot\config\config.json.template"

if (test-path $strPathToConfig){
  Import-Module PowerHTML
  # Script name MUST match what is in config.json under "ScriptSettings"
  [string]$strScriptName = 'PlexStatus'

  # Parse the config file and assign variables
  [object]$objConfig = Get-Content -Path $strPathToConfig -Raw | ConvertFrom-Json
  [string]$strDiscordWebhook = $objConfig.ScriptSettings.$strScriptName.Webhook
  [string]$strDiscordWebhookAnnounce = $objConfig.ScriptSettings.$strScriptName.WebhookAnnounce
  [string]$Messagetext = 'Overall System status'

  # Discord Webhook Uri
  $Uri = $strDiscordWebhook
  $AnnouncementUri = $strDiscordWebhookAnnounce
  $StatusPage = 'https://status.plex.tv'
  $Loop = $null

  # First Status Call
  $wc = New-Object System.Net.WebClient
  $res = $wc.DownloadString($($StatusPage))
  $html = ConvertFrom-Html -Content $res
  
  [string]$Status = ($html.SelectNodes('/html/body/div[1]/div[2]/div[1]/span[1]')).innertext -replace "`n|`r|            "
   
  if ($Status -match 'All Systems Operational' ){
    $Content = '```DIFF'+"`n"+"! "+$Status+"`n"+'```'
  }
  Else{
    $Content = '```DIFF'+"`n"+"- "+$Status+"`n"+'```'
  }

  $DCContent = @"
  **$Messagetext [plex.tv](https://status.plex.tv):**$Content
"@

  #Send to Discord, each time the Script is starting
  $UserPayload = [PSCustomObject]@{content = $DCContent}
  Invoke-RestMethod -Uri $uri -Body ($UserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'


  # Loop for status.plex.tv, only posts to channel when status is 'Bad'

  while ($Loop -ne 'Ended'){

    $res = $wc.DownloadString($($StatusPage))
    $html = ConvertFrom-Html -Content $res
    [string]$Status = ($html.SelectNodes('/html/body/div[1]/div[2]/div[1]/span[1]')).innertext -replace "`n|`r|            "

    if ($Status -match 'All Systems Operational' ){
      $Content = '```DIFF'+"`n"+"! "+$Status+"`n"+'```'
      $Stat = "Good"
    }
    Else{
      $Content = '```DIFF'+"`n"+"- "+$Status+"`n"+'```'
      $Stat = "Bad"
    }


    $DCContent = @"
  **$Messagetext [plex.tv](https://status.plex.tv):**$Content
"@
    $ADCContent = @"
 **$Messagetext [plex.tv](https://status.plex.tv):**$Content
"@

    if ($Stat -eq 'Bad'){

      #Send to Discord Announcement Channel
      $AUserPayload = [PSCustomObject]@{content = $ADCContent}
      Invoke-RestMethod -Uri $AnnouncementUri -Body ($AUserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'
      do {
        $res = $wc.DownloadString($($StatusPage))
        $html = ConvertFrom-Html -Content $res
        [string]$Status = ($html.SelectNodes('/html/body/div[1]/div[2]/div[1]/span[1]')).innertext -replace "`n|`r|            "

        if ($Status -match 'All Systems Operational' ){
          $Content = '```DIFF'+"`n"+"! "+$Status+"`n"+'```'
          $DCContent = @"
  **$Messagetext [plex.tv](https://status.plex.tv):**$Content
"@
          $ADCContent = @"
 **$Messagetext [plex.tv](https://status.plex.tv):**$Content
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
          $Content = '```DIFF'+"`n"+"- "+$Status+"`n"+'```'
          $DCContent = @"
  **$Messagetext [plex.tv](https://status.plex.tv):**$Content
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
  sleep 180
}
