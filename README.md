# windows unattended installation image builder scripts
A little collection of scripts for creating a custom, self-installing Windows iso image.
```diff
- CAUTION: When booting off the built image, it per default repartitions and formats the first drive without asking any more questions or for confirmation right after starting the machine. This behavior can be customized by modifying the "Disk Configuration" part of the autounattend.xml
```

## What this does by default
- Quick installation (~16 mins) without any questions asked whatsoever
- Installation of [Chocolatey](https://chocolatey.org/) as package manager
- Installation of the chocolatey packages firefox, virtualbox-guest-additions-guest.install, 7zip, irfanview and microsoft-windows-terminal
- Automatic debloat of the system using [W4RH4WK's Debloat-Windows-10 scripts](https://github.com/W4RH4WK/Debloat-Windows-10)

## Building

### Prerequisites
- Download and install a [suitable](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install#choose-the-right-adk-for-your-scenario) version of the [Windows ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install) (only the Deployment Tools need to be selected when running the installer)
- Acquire a Windows installation image (tested: Windows 10 21H1; windows 11 may work but is unsupported as of now) and save it as `.\original-image.iso`
- During the building process, multiple tools will be downloaded. If you want to build without having an internet connection (a internet connection will still be required during the installation of the final image), you can do so by downloading (and if required extracting) the following resources to their respective locations
  - [7-Zip](https://www.7-zip.org/)'s 7z.exe and 7z.dll (to `.\background-executables\7-Zip`)
  - [W4RH4WK's Debloat-Windows-10 scripts](https://github.com/W4RH4WK/Debloat-Windows-10) (to `.\setup-scripts\debloat`) 

### Running the build script
- The `build.ps1` script has to be run from the root of the repository and as administrator
- After the build finished, the result can be found at `.\modified-image.iso` and is a modified ready-to-boot-off-of windows installation image including the set modifications

## Customization
Note that image can also be built and used without any further customization.
### Locations worth taking a look at
- autounattend.xml ([Answer file](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/answer-files-overview), can be edited with a text editor or using the [Windows System Image Manager](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/windows-system-image-manager-technical-reference))
  - Regional settings (`amd64_Microsoft-Windows-International-Core-WinPE__neutral`, `amd64_Microsoft-Windows-International-Core__neutral`); Default: en-US
  - Disk Configuration (`amd64_Microsoft-Windows-Setup__neutral\Disk Configuration`)
  - Edition selection (`amd64_Microsoft-Windows-Setup__neutral\Image Install`), Product Key (`amd64_Microsoft-Windows-Setup__neutral\User Data\Key`); Default: Windows 10 Pro using a generic key
  - Scripts to be run before the first login (`amd64_Microsoft-Windows-Deployment__neutral\RunSynchronous`); Default: `.\setup-scripts\before-first-login.ps1`
  - Scripts to be run on first login (`amd64_Microsoft-Windows-Shell-Setup__neutral\FirstLogonCommands`); Default: `.\setup-scripts\on-first-login.ps1`
  - User accounts and passwords (Passwords are blank `amd64_Microsoft-Windows-Shell-Setup__neutral\UserAccounts`)
  - ...and anything else that can fit inside such an answer file
- the `.\setup-scripts` folder
  - The whole folder will be copied to `C:\setup-scripts` in the installed system
  - `before-first-login.ps1` and `on-first-login.ps1` by default are run as their names imply

### Legacy Boot & EFI

While the image can be booted both using Legacy boot and EFI, the disks can only be configured for one. The current default is legacy boot, but the configuration can easily be switched out.

autounattend.xml: `WinPE` -> `Microsoft-Windows-Setup`:

**EFI**
```xml
<DiskConfiguration>
    <Disk wcm:action="add">
        <CreatePartitions>
            <CreatePartition wcm:action="add">
                <Type>EFI</Type>
                <Size>512</Size>
                <Order>1</Order>
            </CreatePartition>
            <CreatePartition wcm:action="add">
                <Order>2</Order>
                <Type>MSR</Type>
                <Size>16</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
                <Order>4</Order>
                <Extend>true</Extend>
                <Type>Primary</Type>
            </CreatePartition>
            <CreatePartition wcm:action="add">
                <Order>3</Order>
                <Size>400</Size>
                <Type>Primary</Type>
            </CreatePartition>
        </CreatePartitions>
        <ModifyPartitions>
            <ModifyPartition wcm:action="add">
                <Order>3</Order>
                <PartitionID>3</PartitionID>
                <TypeID>DE94BBA4-06D1-4D40-A16A-BFD50179D6AC</TypeID>
                <Label>WinRe</Label>
                <Format>NTFS</Format>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
                <Label>System</Label>
                <Order>1</Order>
                <PartitionID>1</PartitionID>
                <Format>FAT32</Format>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
                <Order>2</Order>
                <PartitionID>2</PartitionID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
                <Order>4</Order>
                <PartitionID>4</PartitionID>
                <Label>Windows</Label>
                <Format>NTFS</Format>
            </ModifyPartition>
        </ModifyPartitions>
        <WillWipeDisk>true</WillWipeDisk>
        <DiskID>0</DiskID>
    </Disk>
</DiskConfiguration>
<ImageInstall>
    <OSImage>
        <InstallFrom>
            <MetaData wcm:action="add">
                <Key>/image/name</Key>
                <Value>Windows 10 Pro</Value>
            </MetaData>
        </InstallFrom>
        <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>4</PartitionID>
        </InstallTo>
    </OSImage>
</ImageInstall>
```

**Legacy boot**
```xml
<DiskConfiguration>
    <Disk wcm:action="add">
        <CreatePartitions>
            <CreatePartition wcm:action="add">
                <Order>1</Order>
                <Size>300</Size>
                <Type>Primary</Type>
            </CreatePartition>
            <CreatePartition wcm:action="add">
                <Extend>true</Extend>
                <Order>2</Order>
                <Type>Primary</Type>
            </CreatePartition>
        </CreatePartitions>
        <ModifyPartitions>
            <ModifyPartition wcm:action="add">
                <Order>1</Order>
                <PartitionID>1</PartitionID>
                <Label>System</Label>
                <Format>NTFS</Format>
                <Active>true</Active>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
                <Order>2</Order>
                <PartitionID>2</PartitionID>
                <Label>Windows</Label>
                <Letter>C</Letter>
                <Format>NTFS</Format>
            </ModifyPartition>
        </ModifyPartitions>
        <WillWipeDisk>true</WillWipeDisk>
        <DiskID>0</DiskID>
    </Disk>
</DiskConfiguration>
<ImageInstall>
    <OSImage>
        <InstallFrom>
            <MetaData wcm:action="add">
                <Key>/image/name</Key>
                <Value>Windows 10 Pro</Value>
            </MetaData>
        </InstallFrom>
        <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>2</PartitionID>
        </InstallTo>
    </OSImage>
</ImageInstall>
```
