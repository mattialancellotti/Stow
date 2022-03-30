# TODO:
#   - Better parameter validation:
#       + The path must exists;
#       + The package to chain should not exists;
#       + If the chained package already exists it cannot be unchained if not
#         root is found.
#   - Better error handling and better messages to the user;
[CmdletBinding(DefaultParameterSetName = 'A')]
Param(
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Path,
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Target,
     [Parameter(ParameterSetName='A', Mandatory)][string] $Chain,
     [Parameter(ParameterSetName='B', Mandatory)][string] $Unchain
)

# Getting the user's current role and the administrative role
$userRole = [Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

# Checking if the user has administrative privilages
$userStatus = New-Object Security.Principal.WindowsPrincipal($userRole)
if ( !($userStatus.IsInRole($adminRole)) ) {
     Write-Host "You gotta be administrator boyo!! Get off me."
     exit
}

# Choosing what the program should do based on the current parameter set.
# Basically if the user wants to Chain or Unchain.
switch ($PSCmdlet.ParameterSetName) {
     "A" { Write-Host "Chaining files."; Break }
     "B" { Write-Host "Unchaining files."; Break }
}

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
