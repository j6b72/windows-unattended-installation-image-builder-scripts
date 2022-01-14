#Requires -RunAsAdministrator

function Write-To-Console {
    param (
        $Text
    )
    Write-Output "" ("!! " + $Text)
}

function Download-7Zip {
    $parent_path = (Join-Path (Get-Location) "background-executables")
    if ((Test-Path (Join-Path $parent_path 7-Zip\7z.dll)) -and (Test-Path (Join-Path $parent_path 7-Zip\7z.exe))) {
        return
    }
    Write-To-Console "downloading 7-Zip"
    New-Item .\background-executables\7-Zip -ItemType Directory -Force
    Invoke-WebRequest "https://7-zip.org/a/7z2107-x64.msi" -OutFile (Join-Path $parent_path 7-Zip.msi)
    Start-Process -FilePath msiexec -ArgumentList "/a",("`"" + (Join-Path $parent_path 7-Zip.msi) + "`""),"/qb",("TARGETDIR=`"" + (Join-Path $parent_path 7-Zip-ext) + "`""),"/quiet" -Wait
    $new_dir = (Join-Path $parent_path 7-Zip-ext\Files\7-Zip\)
    Copy-Item (Join-Path $new_dir "7z.dll"),(Join-Path $new_dir "7z.exe") -Destination (Join-Path $parent_path 7-Zip)
    Remove-Item -Recurse (Join-Path $parent_path 7-Zip.msi),(Join-Path $parent_path 7-Zip-ext)
}

function Download-Debloat-Scripts {
    $setup_scripts_folder = Join-Path (Get-Location) "setup-scripts"
    if (Test-Path (Join-Path $setup_scripts_folder "debloat")) {
        return
    }
    Write-To-Console Downloading debloat scripts
    $current_commit = "cd54358ed76267cd83fb5d04d160c7870c7779e8"
    $debloatScriptsDownloadURL = "https://github.com/W4RH4WK/Debloat-Windows-10/archive/" + $current_commit + ".zip"
    $zip_file_path = Join-Path $setup_scripts_folder "debloat.zip"
    Invoke-WebRequest $debloatScriptsDownloadURL -OutFile $zip_file_path
    Expand-Archive $zip_file_path -DestinationPath $setup_scripts_folder -Force
    Rename-Item (Join-Path $setup_scripts_folder ("Debloat-Windows-10-" + $current_commit)) (Join-Path $setup_scripts_folder "debloat")
    Remove-Item $zip_file_path
}

if (Test-Path (Join-Path (Get-Location) "working-directory")) {
    Remove-Item -Recurse -Force .\working-directory
}

New-Item .\working-directory\new-iso -ItemType Directory -Force
New-Item .\working-directory\wim-mount -ItemType Directory -Force

Download-7Zip
Download-Debloat-Scripts

Write-To-Console "extracting iso"
.\background-executables\7-Zip\7z.exe x -o"working-directory\new-iso" "original-image.iso"

Write-To-Console "mounting wim"
dism /Mount-image /imagefile:working-directory\new-iso\sources\install.wim /Name:"Windows 10 Pro" /MountDir:"working-directory\wim-mount"

Write-To-Console "copying setup resources"
Copy-Item -Recurse .\setup-scripts working-directory\wim-mount\setup-scripts\

Write-To-Console "unmounting and saving wim"
dism /Unmount-image /Commit /MountDir:"working-directory\wim-mount"

Write-To-Console "copying autounattend.xml"
Copy-Item .\autounattend.xml .\working-directory\new-iso

Write-To-Console "making .iso file"
$oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
& $oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,b`".\working-directory\new-iso\boot\etfsboot.com`"#pEF,e,b`".\working-directory\new-iso\efi\microsoft\boot\efisys.bin`" `".\working-directory\new-iso`" modified-image.iso