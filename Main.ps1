# TODO:
#   - Better parameter validation:
#       + The path must exists;
#       + The package to chain should not exists;
#       + If the chained package already exists it cannot be unchained if not
#         root is found;
#       + Trim input and remove last '\'.
#   - Better error handling and better messages to the user;
#   - Rename `Path` to `Packdir`;
#   - Rename `Target` to `Source`.

# This sets the default parameter set to A (basically chains files)
[CmdletBinding(DefaultParameterSetName = 'Pack')]
Param(
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Path,
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Target,

     # These are the actions the program can do.
     # All of the are mandatory but since they are in differenet parameter sets
     # only one can be used
     [Parameter(ParameterSetName='Pack',Mandatory,Position=0)][string[]] $Pack,
     [Parameter(ParameterSetName='Unpack',Mandatory)][string[]] $Unpack
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
     "Pack" { Write-Host "Packing files."; Break }
     "Unpack" { Write-Host "Unpacking files."; Break }
}

# TODO
#   The real workflow would be:
#       - Check if the package exists;
#       - Take everything that it's in there:
#           + A directory (exists?):
#               - Yes: do not create and go deeper
#               - No: link it
#           + A file (exists?):
#               - Yes: warn the user
#               - No: Link it
function Link-Files {
     Param( [Parameter(Mandatory)][string[]] $Packages )

     $Packages | ForEach-Object {
          Write-Verbose "LINK ($_) => $Target\$_"
          New-Item -ItemType SymbolicLink -Path "$Path\$_" -Target "$Target\$_" | Out-Null
     }
}

# Tests
Link-Files $Pack
