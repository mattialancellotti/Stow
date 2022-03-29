# TODO Validate parameters

[CmdletBinding(DefaultParameterSetName = 'A')]
Param(
     [Parameter(Mandatory)][string] $Path,
     [Parameter(Mandatory)][string] $Target,
     [Parameter(ParameterSetName='A', Mandatory)][string] $Chain,
     [Parameter(ParameterSetName='B', Mandatory)][string] $Unchain
)

function Check-Permissions {
     $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
     if ( !($currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) ) {
          Write-Host "You gotta be administrator boyo!! Get off me."
          exit
     }
}

<#
.NAME Link-Files

.Description
This is a PowerShell module that wants to emulate GNU Stow's behaviour on Windows

.PARAMETER Target
The target directory that contains the files you want to link.

.PARAMETER Path
The directory in which all the links are going to be created.

#>
function Link-Files {
     Param(
          [Parameter(Mandatory=$true)][string] $Target,
          [Parameter(Mandatory=$true)][string] $Path
     )

     # Checking if the user can execute this program
     Check-Permissions

     # List all files in the `Path` directroy and then linking the in the
     # `Target` directory with the same name.
     # TODO Support for directories
     Get-ChildItem -File | ForEach-Object {
          New-Item -ItemType SymbolicLink -Path "$Path\$_" -Target $Target
     }
}
