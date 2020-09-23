# Discord Webhook Uri
$Uri = 'https://discordapp.com/api/webhooks/XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
$StatusPage = 'https://status.plex.tv'
$Loop = $null

while ($Loop -ne 'Ended'){

$WebRequest = Invoke-WebRequest -Uri $StatusPage
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

#Send to Discord
$UserPayload = [PSCustomObject]@{content = $DCContent}
Invoke-RestMethod -Uri $uri -Body ($UserPayload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'Application/Json'

sleep 60
}