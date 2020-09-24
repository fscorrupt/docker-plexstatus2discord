# Discord Webhook Uri
$Uri = 'https://discordapp.com/api/webhooks/XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
$StatusPage = 'https://status.plex.tv'
$Loop = $null

# First Status Call
$WebRequest = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $StatusPage
$Status = ($WebRequest.AllElements | ? { $_.Class -eq 'status font-large' } | select innerText).innertext
$Incident = ($WebRequest.AllElements | ? { $_.Class -eq 'incident-title font-large' } | select innerText).innertext

  if ($Status -match 'All Systems Operational' ){
    $Content = '```CSS'+"`n"+"-"+$Status+"`n"+'```'
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

  $WebRequest = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $StatusPage
  $Status = ($WebRequest.AllElements | ? { $_.Class -eq 'status font-large' } | select innerText).innertext
  $Incident = ($WebRequest.AllElements | ? { $_.Class -eq 'incident-title font-large' } | select innerText).innertext

  if ($Status -match 'All Systems Operational' ){
    $Content = '```CSS'+"`n"+"-"+$Status+"`n"+'```'
    $Stat = "Good"
  }
  Else{
    $Content = '```DIFF'+"`n"+"-"+$Incident+"`n"+'```'
    $Stat = "Bad"
  }

  $DCContent = @"
  **Current status of [plex.tv](https://status.plex.tv):**$Content
"@

  if ($Stat -eq 'Bad'){
    while ($Stat -ne 'Good'){
      $WebRequest = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $StatusPage
      $Status = ($WebRequest.AllElements | ? { $_.Class -eq 'status font-large' } | select innerText).innertext
      $Incident = ($WebRequest.AllElements | ? { $_.Class -eq 'incident-title font-large' } | select innerText).innertext

      if ($Status -match 'All Systems Operational' ){
         $Content = '```CSS'+"`n"+"-"+$Status+"`n"+'```'
         
         #Send to Discord
         $UserPayload = [PSCustomObject]@{content = $DCContent}
         Invoke-RestMethod -Uri $uri -Body ($UserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'
         $Stat = "Good"
      }
      Else{
        $Content = '```DIFF'+"`n"+"-"+$Incident+"`n"+'```'
        
        #Send to Discord
        $UserPayload = [PSCustomObject]@{content = $DCContent}
        Invoke-RestMethod -Uri $uri -Body ($UserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'
        $Stat = "Bad"
      }
      sleep 60
    }
  }
  sleep 60  
}
