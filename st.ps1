<#
.NOTES
    Author         : Emad Adel
    GitHub         : https://github.com/emadadel4
#>

$currentPid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [System.Security.Principal.WindowsPrincipal]$currentPid
$administrator = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $principal.IsInRole($administrator))
{
    Start-Process -FilePath "PowerShell" -ArgumentList $myInvocation.MyCommand.Definition -Verb "runas"
    exit
}

function Install-Dependencies {

    $ytdlp = Get-Command yt-dlp -ErrorAction SilentlyContinue
    $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
    $choco = Get-Command choco -ErrorAction SilentlyContinue

    if (-not $ytdlp -or -not $ffmpeg) {

        # Check if Chocolatey is installed
        if (-not $choco) {
            Write-Host "Installing missing dependencies for the first time; it won't take a minute..." -ForegroundColor Yellow
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) *> $null
        }

        # Install missing dependencies
        if (-not $ytdlp) {
            choco install yt-dlp -y  *> $null
        }

        if (-not $ffmpeg) {
            choco install ffmpeg -y *> $null
        }

        Write-Host "You good to go!" -ForegroundColor Yellow
        Clear-Host

    } else {
        #Write-Host "You good to go!"
    }
}

Install-Dependencies

$DownloadsFolder = "C:\Users\$Env:USERNAME\Documents\ShellTube"

# Check if the folder exists, and create it if it doesn't
if (-not (Test-Path -Path $DownloadsFolder)) {
    New-Item -Path $DownloadsFolder -ItemType Directory -Force | Out-Null
}

# Set the location to the folder
Set-Location -Path $DownloadsFolder

do {

Write-Host " 
 ____  _   _ _____ _     _       _____ _   _ ____  _____ 
/ ___|| | | | ____| |   | |     |_   _| | | | __ )| ____|
\___ \| |_| |  _| | |   | |       | | | | | |  _ \|  _|  
 ___) |  _  | |___| |___| |___    | | | |_| | |_) | |___ 
|____/|_| |_|_____|_____|_____|   |_|  \___/|____/|_____|

                 Made by Emad Adel
            Github & Telegram | @emadadel4
                #StandWithPalestine 
" -ForegroundColor Yellow

# functions
function Download-MP3 {

    <#
        .SYNOPSIS
        Downloads an MP3 file from a given URL.

        .DESCRIPTION
        This function uses yt-dlp to download an audio file in MP3 format with the highest available quality (320k).
        You need to provide the URL of the video/audio and specify the format as an optional parameter.
    #>

    param (
        [string]$url,
        [string]$format
    )

    # Start download
    yt-dlp -x --audio-format mp3 --console-title --audio-quality 320k "$url"
    
}

function Download-Video {

     <#
        .SYNOPSIS
        Downloads a video from a given URL with specified quality.

        .DESCRIPTION
        This function downloads a video using yt-dlp. You can provide the URL of the video, the desired video quality, and the format.
        The video will be downloaded in the best available quality up to the specified resolution and merged with the best available audio.
        The final output is saved in MP4 format.
    #>

    param (
        [string]$url,
        [string]$quality,
        [string]$format
    )

    # Start download
    yt-dlp -f "bestvideo[height<=$quality]+bestaudio" --merge-output-format mp4 --console-title "$url"
    
}

function Get-Quality {

    <#
        .SYNOPSIS
        Fetches available video quality options from a given URL.

        .DESCRIPTION
        This function retrieves the available video qualities using yt-dlp for the specified URL.
        It displays the available quality options to the user, prompts for a selection, and returns the chosen quality.
        The user must enter a number corresponding to the desired video quality.
    #>

    param($url)
    
    Write-Host "fetching quality..." -ForegroundColor Yellow
    $availableQualities = yt-dlp -F $url | Select-String -Pattern '(\d+)p' | ForEach-Object { $_.Matches.Groups[1].Value }


    # Create a hashtable for quality options
    $quality = @{}
    $i = 1

    foreach ($q in $availableQualities | Sort-Object -Unique) {
        $quality[$i] = $q
        $i++
    }

    # User selection
    do {
        Write-Host "Which quality do you want?"
        foreach ($key in $quality.Keys | Sort-Object) {
            Write-Host "$key - $($quality[$key])"
        }
        $choice = Read-Host "Enter the number corresponding to the quality"
        if ([int]$choice -in $quality.Keys) {
            $Q = $quality[[int]$choice]
        } else {
            Write-Host "Invalid choice. Please select a valid option."
        }
    } until ([int]$choice -in $quality.Keys)

    return $Q

}


do {

    $input = Read-Host "`n` Enter youtube Video or Playlist link"
    
    if (-not [string]::IsNullOrWhiteSpace($input) -and $input.StartsWith("https://")) {
    } else {
        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Host "Cannot be empty. Please try again." -ForegroundColor Yellow
        } else {
            Write-Host "This is not a video link. Please try again." -ForegroundColor Yellow
        }
    }
} while ([string]::IsNullOrWhiteSpace($input) -or -not $input.StartsWith("https://"))


$format = @{

    1 = "mp4"
    2 = "mp3" 
}

do {
    Write-Host "Which format do you want?"
    foreach ($key in $format.Keys | Sort-Object) {
        Write-Host "$key - $($format[$key])"
    }
    $choice = Read-Host "Enter the number corresponding to the format"
    if ([int]$choice -in $format.Keys) {
        $f = $format[[int]$choice]
    } else {
        Write-Host "Invalid choice. Please select a valid option."
    }
} until ([int]$choice -in $format.Keys)


switch ($f) {
    "mp3" { 
        Download-MP3 -url $input
     }
    "mp4" { 
        $q = Get-Quality -url $input
        Write-Host "Downloading, it depends on your internet speed." -ForegroundColor Yellow
        Download-Video -url $input -quality $q
     }
    Default { Write-Host "NOTHING!" }
}

Write-Host "Download Complate." -ForegroundColor Green
Write-Host "Saved in $DownloadsFolder" -ForegroundColor Green



$continue = Read-Host "Do you want to download another file? (y/n)"
} while ($continue -eq "y" )

Start-Process ($DownloadsFolder)