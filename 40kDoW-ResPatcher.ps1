param (
    [ValidateSet("5:4", "4:3", "3:2", "16:10", "15:9", "16:9", "1.85:1", "21:9 (2560x1080)", "21:9 (3440x1440)", "2.39:1", "21:9 (3840x1600)", "2.76:1", "32:10", "32:9", "3x5:4", "3x4:3", "3x16:10", "3x15:9", "3x16:9")]
    [string]$AspectRatio = "16:9",
    [string]$ResFps = "1920x1080@60",
    [bool]$Patch = $false
)

$dllFiles = @(
    [PSCustomObject]@{
        Name    = 'Platform.dll'
        Offsets = 0x1D808
    },
    [PSCustomObject]@{
        Name    = 'spDx9.dll'
        Offsets = 0x15FA6C
    },
    [PSCustomObject]@{
        Name    = 'UserInterface.dll'
        Offsets = 0x7943C, 0x79ED8
    }
    [PSCustomObject]@{
        Name    = 'W40k.exe'
        Offsets = 0x5F0350
    }
)
$iniFile = 'Local.ini'


function Read-AspectRatioHex {
    # DONE

    param(
        $Filename,
        $Offset
    )
    
    $file = Get-ChildItem -Filter $Filename
    $read = [System.IO.File]::ReadAllBytes($file)

    $offsetValues = @()

    $offsetValues += $read[($Offset)]
    $offsetValues += $read[($Offset + 1)]
    $offsetValues += $read[($Offset + 2)]
    $offsetValues += $read[($Offset + 3)]

    return $offsetValues

}

function Read-GameFileValues {
    # DONE

    param (
        $FileObject
    )

    $allOffsets = @()

    foreach ($file in $FileObject) {
        $offsetVals = @()
        foreach ($offset in $file.offsets) {
            $eval = Read-AspectRatioHex -Filename $file.Name -Offset $offset
            $offsetVals += [PSCustomObject]@{
                Offset = $offset
                Value  = $eval
            }
        }
        $allOffsets += [PSCustomObject]@{
            File   = $file.Name
            Offset = $offsetVals
        }
    }

    return $allOffsets

}

function Convert-HexRatio {
    # DONE
    param (
        $HexString
    )

    $HexString = ($HexString -join ' ').ToUpper() # This magically converts the decimal values into hex

    switch ($HexString) {
        @(0x00, 0x00, 0xA0, 0x3F) { $result = '5:4' }
        @(0xAB, 0xAA, 0xAA, 0x3F) { $result = '4:3' } # Default
        @(0x00, 0x00, 0xC0, 0x3F) { $result = '3:2' }
        @(0xCD, 0xCC, 0xCC, 0x3F) { $result = '16:10' }
        @(0x55, 0x55, 0xD5, 0x3F) { $result = '15:9' }
        @(0x39, 0x8E, 0xE3, 0x3F) { $result = '16:9' }
        @(0xCD, 0xCC, 0xEC, 0x3F) { $result = '1.85:1' }
        @(0x26, 0xB4, 0x17, 0x40) { $result = '21:9 (2560x1080)' }
        @(0x8E, 0xE3, 0x18, 0x40) { $result = '21:9 (3440x1440)' }
        @(0xC3, 0xF5, 0x18, 0x40) { $result = '2.39:1' }
        @(0x9A, 0x99, 0x19, 0x40) { $result = '21:9 (3840x1600)' }
        @(0xD7, 0xA3, 0x30, 0x40) { $result = '2.76:1' }
        @(0xCD, 0xCC, 0x4C, 0x40) { $result = '32:10' }
        @(0x39, 0x8E, 0x63, 0x40) { $result = '32:9' }
        @(0x00, 0x00, 0x70, 0x40) { $result = '3x5:4' }
        @(0x00, 0x00, 0x80, 0x40) { $result = '3x4:3' }
        @(0x9A, 0x99, 0x99, 0x40) { $result = '3x16:10' }
        @(0x00, 0x00, 0xA0, 0x40) { $result = '3x15:9' }
        @(0xAB, 0xAA, 0xAA, 0x40) { $result = '3x16:9' }
        Default { $result = 'unknown' }
    }

    return $result
}

function Convert-AspectHex {
    # DONE
    param (
        [string]$Ratio
    )

    $result = [Object[]]::new(4)
    
    switch ($Ratio) {
        "5:4" {
            # DONE
            # "00 00 A0 3F"
            $result[0] = 0x00
            $result[1] = 0x00
            $result[2] = 0xA0
            $result[3] = 0x3F
        }
        "4:3" {
            # DONE
            # "AB AA AA 3F"
            $result[0] = 0xAB
            $result[1] = 0xAA
            $result[2] = 0xAA
            $result[3] = 0x3F
        }
        "3:2" {
            # DONE
            # "00 00 C0 3F"
            $result[0] = 0x00
            $result[1] = 0x00
            $result[2] = 0xC0
            $result[3] = 0x3F
        }
        "16:10" {
            # DONE
            # "CD CC CC 3F"
            $result[0] = 0xCD
            $result[1] = 0xCC
            $result[2] = 0xCC
            $result[3] = 0x3F
        }
        "15:9" {
            # DONE
            # "55 55 D5 3F"
            $result[0] = 0x55
            $result[1] = 0x55
            $result[2] = 0xD5
            $result[3] = 0x3F
        }
        "16:9" {
            # DONE
            # "39 8E E3 3F"
            $result[0] = 0x39
            $result[1] = 0x8E
            $result[2] = 0xE3
            $result[3] = 0x3F
        }
        "1.85:1" {
            # DONE
            # "CD CC EC 3F"
            $result[0] = 0xCD
            $result[1] = 0xCC
            $result[2] = 0xEC
            $result[3] = 0x3F
        }
        "21:9 (2560x1080)" {
            # "26 B4 17 40"
            $result[0] = 0x26
            $result[1] = 0xB4
            $result[2] = 0x17
            $result[3] = 0x40
        }
        "21:9 (3440x1440)" {
            # DONE
            # "8E E3 18 40"
            $result[0] = 0x8E
            $result[1] = 0xE3
            $result[2] = 0x18
            $result[3] = 0x40
        }
        "2.39:1" {
            # DONE
            # "C3 F5 18 40"
            $result[0] = 0xC3
            $result[1] = 0xF5
            $result[2] = 0x18
            $result[3] = 0x40
        }
        "21:9 (3840x1600)" {
            # DONE
            # "9A 99 19 40"
            $result[0] = 0x9A
            $result[1] = 0x99
            $result[2] = 0x19
            $result[3] = 0x40
        }
        "2.76:1" {
            # DONE
            # "D7 A3 30 40"
            $result[0] = 0xD7
            $result[1] = 0xA3
            $result[2] = 0x30
            $result[3] = 0x40
        }
        "32:10" {
            # DONE
            # "CD CC 4C 40"
            $result[0] = 0xCD
            $result[1] = 0xCC
            $result[2] = 0x4C
            $result[3] = 0x40
        }
        "32:9" {
            # DONE
            # "39 8E 63 40"
            $result[0] = 0x39
            $result[1] = 0x8E
            $result[2] = 0x63
            $result[3] = 0x40
        }
        "3x5:4" {
            # "00 00 70 40"
            $result[0] = 0x00
            $result[1] = 0x00
            $result[2] = 0x70
            $result[3] = 0x40
        }
        "3x4:3" {
            # "00 00 80 40"
            $result[0] = 0x00
            $result[1] = 0x00
            $result[2] = 0x80
            $result[3] = 0x40
        }
        "3x16:10" {
            # "9A 99 99 40"
            $result[0] = 0x9A
            $result[1] = 0x99
            $result[2] = 0x99
            $result[3] = 0x40
        }
        "3x15:9" {
            # "00 00 A0 40"
            $result[0] = 0x00
            $result[1] = 0x00
            $result[2] = 0xA0
            $result[3] = 0x40
        }
        "3x16:9" {
            # "AB AA AA 40"
            $result[0] = 0xAB
            $result[1] = 0xAA
            $result[2] = 0xAA
            $result[3] = 0x40
        }
        Default {}
    }
    
    return $result

}

function Set-AspectRatio {
    # DONE
    param(
        $GameFile,
        $AspectRatio
    )

    $targetRatio = Convert-AspectHex -Ratio $AspectRatio

    $file = Get-ChildItem -Path $GameFile -Filter $GameFile

    $bytes = [System.IO.File]::ReadAllBytes($file)
    switch ($GameFile) {
        "Platform.dll" {
            $bytes[0x1D808] = $targetRatio[0]
            $bytes[0x1D809] = $targetRatio[1]
            $bytes[0x1D80A] = $targetRatio[2]
            $bytes[0x1D80B] = $targetRatio[3]
        }
        "spDx9.dll" {
            $bytes[0x15FA6C] = $targetRatio[0]
            $bytes[0x15FA6D] = $targetRatio[1]
            $bytes[0x15FA6E] = $targetRatio[2]
            $bytes[0x15FA6F] = $targetRatio[3]
        }
        "UserInterface.dll" {
            $bytes[0x7943C] = $targetRatio[0]
            $bytes[0x7943D] = $targetRatio[1]
            $bytes[0x7943E] = $targetRatio[2]
            $bytes[0x7943F] = $targetRatio[3]
            $bytes[0x79ED8] = $targetRatio[0]
            $bytes[0x79ED9] = $targetRatio[1]
            $bytes[0x79EDA] = $targetRatio[2]
            $bytes[0x79EDB] = $targetRatio[3]
        }
        "W40k.exe" {
            $bytes[0x5F0350] = $targetRatio[0]
            $bytes[0x5F0351] = $targetRatio[1]
            $bytes[0x5F0352] = $targetRatio[2]
            $bytes[0x5F0353] = $targetRatio[3]
        }
        Default {}
    }

    [System.IO.File]::WriteAllBytes($gameFile, $bytes)
}

function Get-Ratios {
    # DONE
    param (
        $fileObj
    )

    $aspectRatios = @()

    $fileObj | ForEach-Object {
        if (($_.Offset).count -gt 1) {
            foreach ($off in $_.Offset) {
                $aspectRatios += Convert-HexRatio -HexString $off.Value
            }
        }
        elseif (($_.Offset).count -eq 1) {
            $aspectRatios += Convert-HexRatio -HexString $_.Offset.Value
        }
    }

    $firstRatio = $aspectRatios[0]

    foreach ($ratio in $aspectRatios) {
        if ($ratio -ne $firstRatio) {
            return "Mismatched aspect ratios, get clean files or force patch."
        }
    }

    return $firstRatio
}

function Open-IniFile {
    # DONE
    param (
        [string]$FilePath
    )

    $ReadFile = Get-Content -Path $FilePath
    $ini = @{}
    $section = ""

    foreach ($line in $ReadFile) {

        # Identify section headers
        if ($line -match "^\[(.+)\]") {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        # Identify key-value pairs
        elseif ($line -match "^(.+?)=(.+)$") {
            $key, $value = $matches[1], $matches[2]
            $ini[$section][$key.Trim()] = $value.Trim()
        }
    }
    return $ini
}

function Save-IniFile {
    # DONE
    param (
        [hashtable]$ini, 
        [string]$filePath
    )

    $output = @()

    foreach ($section in $ini.Keys) {
        $output += "[$section]"
        foreach ($key in ($ini[$section].Keys | Sort-Object)) {
            $output += "$key=$($ini[$section][$key])"
        }
        $output += ""  # Blank line between sections (if there are multiple for some reason)
    }
    $output | Set-Content -Path $filePath
}

function Get-Resolution {
    # DONE
    param(
        $ini
    )

    $iniObj = Open-IniFile -FilePath $ini

    return "$($iniObj.global.screenwidth)x$($iniObj.global.screenheight)@$($iniObj.global.screenrefresh)hz"
}

function Get-UserInputRes {
    # DONE
    param(
        [string]$userinput
    )
    $ResFps = $userinput

    $width = ($ResFps.Split('x'))[0]
    $height = (($ResFps.Split('x')[1]).Split('@'))[0]
    $fps = (($ResFps.Split('x')[1]).Split('@'))[1]

    return @{"width" = $width; "height" = $height; "fps" = $fps }
}

$dllValues = Read-GameFileValues -FileObject $dllFiles
$inivals = Open-IniFile -FilePath $iniFile

if ($Patch -eq $true) {
    $dllValues | ForEach-Object {
        Set-AspectRatio -GameFile $_.File -AspectRatio $AspectRatio
    }

    $dllValues = Read-GameFileValues -FileObject $dllFiles

    $ResFpsHash = Get-UserInputRes -userinput $ResFps
    $inivals.global.screenwidth = $ResFpsHash.width
    $inivals.global.screenheight = $ResFpsHash.height
    $inivals.global.screenrefresh = $ResFpsHash.fps

    Save-IniFile -ini $inivals -filePath $iniFile
}

Get-Ratios -fileObj $dllValues
Get-Resolution -ini $iniFile