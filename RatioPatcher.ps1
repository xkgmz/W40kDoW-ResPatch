param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [ValidateSet("4:3", "16:9", "16:10", "21:9 (3440x1440)", "3:2", "5:4", "15:9", "1.85:1", "21:9 (2560x1080)", "21:9 (3840x1600)", "2.39:1", "2.76:1", "32:9", "32:10", "3x4:3", "3x5:4", "3x15:9", "3x16:9", "3x16:10")]
    [string]$AspectRatio = '16:9',
    [System.Object]$ResFps = @('1920', '1080', '60'),
    [switch]$Save
)

class GameFile {
    [string]$Name
    [string]$Path

    GameFile([string]$name) {
        $this.Name = $name
        $this.Path = $null
    }

    [void] findFileInPath([string]$path) {
        $this.Path = Get-ChildItem -LiteralPath $path -Filter $this.Name
    }

}

class DllFile : GameFile {
    [System.Object]$Offsets
    [System.Collections.ArrayList]$OffsetValues
    [string]$Ratio

    DllFile([string]$name, [System.Object]$offset) : base($Name) {
        $this.Offsets = $offset
        $this.OffsetValues = @()
        $this.Ratio = $null
    }

    readOffsetValues() {
        $read = [System.IO.File]::ReadAllBytes($this.Path)
        foreach ($offset in $this.Offsets) {
            $ofv = @()
            $ofv += $read[($offset)]
            $ofv += $read[($offset + 1)]
            $ofv += $read[($offset + 2)]
            $ofv += $read[($offset + 3)]
            $this.OffsetValues += , @($ofv)
        }
    }

    getAspectRatio() {
        foreach ($ofv in $this.OffsetValues) {
            $byteString = ($ofv -join ' ')
            switch ($byteString) {
                @(0xAB, 0xAA, 0xAA, 0x3F) { $this.Ratio = '4:3' } # Default
                @(0x39, 0x8E, 0xE3, 0x3F) { $this.Ratio = '16:9' }
                @(0xCD, 0xCC, 0xCC, 0x3F) { $this.Ratio = '16:10' }
                @(0x8E, 0xE3, 0x18, 0x40) { $this.Ratio = '21:9 (3440x1440)' }
                @(0x00, 0x00, 0xC0, 0x3F) { $this.Ratio = '3:2' }
                @(0x00, 0x00, 0xA0, 0x3F) { $this.Ratio = '5:4' }
                @(0x55, 0x55, 0xD5, 0x3F) { $this.Ratio = '15:9' }
                @(0xCD, 0xCC, 0xEC, 0x3F) { $this.Ratio = '1.85:1' }
                @(0x26, 0xB4, 0x17, 0x40) { $this.Ratio = '21:9 (2560x1080)' }
                @(0x9A, 0x99, 0x19, 0x40) { $this.Ratio = '21:9 (3840x1600)' }
                @(0xC3, 0xF5, 0x18, 0x40) { $this.Ratio = '2.39:1' }
                @(0xD7, 0xA3, 0x30, 0x40) { $this.Ratio = '2.76:1' }
                @(0x39, 0x8E, 0x63, 0x40) { $this.Ratio = '32:9' }
                @(0xCD, 0xCC, 0x4C, 0x40) { $this.Ratio = '32:10' }
                @(0x00, 0x00, 0x80, 0x40) { $this.Ratio = '3x4:3' }
                @(0x00, 0x00, 0x70, 0x40) { $this.Ratio = '3x5:4' }
                @(0x00, 0x00, 0xA0, 0x40) { $this.Ratio = '3x15:9' }
                @(0xAB, 0xAA, 0xAA, 0x40) { $this.Ratio = '3x16:9' }
                @(0x9A, 0x99, 0x99, 0x40) { $this.Ratio = '3x16:10' }
                Default { $this.Ratio = 'unknown' }
            }
        }
    }

    [System.Object]convertRatioToHex([string]$ratio) {
        $result = $null

        switch ($ratio) {
            '4:3' { $result = @(0xAB, 0xAA, 0xAA, 0x3F) }
            '16:9' { $result = @(0x39, 0x8E, 0xE3, 0x3F) }
            '16:10' { $result = @(0xCD, 0xCC, 0xCC, 0x3F) }
            '21:9 (3440x1440)' { $result = @(0x8E, 0xE3, 0x18, 0x40) }
            '3:2' { $result = @(0x00, 0x00, 0xC0, 0x3F) }
            '5:4' { $result = @(0x00, 0x00, 0xA0, 0x3F) }
            '15:9' { $result = @(0x55, 0x55, 0xD5, 0x3F) }
            '1.85:1' { $result = @(0xCD, 0xCC, 0xEC, 0x3F) }
            '21:9 (2560x1080)' { $result = @(0x26, 0xB4, 0x17, 0x40) }
            '21:9 (3840x1600)' { $result = @(0x9A, 0x99, 0x19, 0x40) }
            '2.39:1' { $result = @(0xC3, 0xF5, 0x18, 0x40) }
            '2.76:1' { $result = @(0xD7, 0xA3, 0x30, 0x40) }
            '32:9' { $result = @(0x39, 0x8E, 0x63, 0x40) }
            '32:10' { $result = @(0xCD, 0xCC, 0x4C, 0x40) }
            '3x4:3' { $result = @(0x00, 0x00, 0x80, 0x40) }
            '3x5:4' { $result = @(0x00, 0x00, 0x70, 0x40) }
            '3x15:9' { $result = @(0x00, 0x00, 0xA0, 0x40) }
            '3x16:9' { $result = @(0xAB, 0xAA, 0xAA, 0x40) }
            '3x16:10' { $result = @(0x9A, 0x99, 0x99, 0x40) }
            Default { $result = 'unknown' }
        }
        return $result
    }

    setAspectRatio($targetRatio) {
        $bytes = [System.IO.File]::ReadAllBytes($this.Path)

        for ($i = 0; $i -le 3; $i++) {
            foreach ($offset in $this.Offsets) {
                $bytes[$offset + $i] = $targetRatio[$i]
            }
        }

        [System.IO.File]::WriteAllBytes($this.Path, $bytes)
        $this.OffsetValues = @()
        $this.readOffsetValues()
        $this.getAspectRatio()
    }
}


class IniFile : GameFile {
    [string]$ScreenWidth
    [string]$ScreenHeight
    [string]$RefreshRate
    [hashtable]$IniSettings

    IniFile([string]$name) : base($name) {
        $this.ScreenWidth = $null
        $this.ScreenHeight = $null
        $this.RefreshRate = $null
        $this.IniSettings = $null
    }

    [void] readIniFile() {
        $ReadFile = Get-Content -Path $this.Path
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

        $this.IniSettings = $ini
    }

    [void] getResolution() {
        $this.readIniFile()
        $this.ScreenWidth = $this.iniSettings.global.screenwidth
        $this.screenHeight = $this.iniSettings.global.screenheight
        $this.RefreshRate = $this.iniSettings.global.screenrefresh
    }

    [void] setResolution($res) {
        $this.IniSettings.global.screenwidth = $res[0]
        $this.IniSettings.global.screenheight = $res[1]
        $this.IniSettings.global.screenrefresh = $res[2]
    }

    [void] saveIniFile() {
        $output = @()

        foreach ($section in $this.IniSettings.Keys) {
            $output += "[$section]"
            foreach ($key in ($this.IniSettings[$section].Keys | Sort-Object)) {
                $output += "$key=$($this.IniSettings[$section][$key])"
            }
            $output += ""  # Blank line between sections (if there are multiple for some reason)
        }

        $output | Set-Content -Path $this.Path
    }
}

$platform = [DllFile]::new('Platform.dll', 0x1D808)
$spDx9 = [DllFile]::new('spDx9.dll', 0x15FA6C)
$userInterface = [DllFile]::new('UserInterface.dll', @(0x7943C, 0x79ED8))
$w40k = [DllFile]::new('W40k.exe', 0x5F0350)
$localini = [IniFile]::new('Local.ini')

$fileList = @($platform, $spDx9, $userInterface, $w40k, $localini)

foreach ($file in $fileList) {
    $file.findFileInPath($Path)
    if ($file.GetType() -eq [DllFile]) {
        $file.readOffsetValues()
        $file.getAspectRatio()
        if ($Save) {
            $targetRatioValues = $file.convertRatioToHex($AspectRatio)
            $file.setAspectRatio($targetRatioValues)
        }
    }
    elseif ($file.GetType() -eq [IniFile]) {
        $file.getResolution()
        if ($save) {
            $file.setResolution($ResFps)
            $file.saveIniFile()
            $file.getResolution()
        }
    }
}

$fileList
