# TODO:
#   - Better parameter validation:
#       + The path must exists;
#       + The package to chain should not exists;
#       + If the chained package already exists it cannot be unchained if no
#         root is found;
#       + Trim input and remove last '\'.
#   - Better error handling and better messages to the user.

# This sets the default parameter set to A (basically chains files)
[CmdletBinding(DefaultParameterSetName = 'Pack')]
Param(
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Packdir,
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Source,

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

function Link-Files {
     Param( [Parameter(Mandatory, ValueFromPipeline)][string[]] $Packages )

     # Stowing each package
     process
     {
          foreach ($i in $Packages) {
               Stow-Package -Src $Source -Dst $Packdir -Pkg $i
          }
     }
}

# TODO
#   The real workflow would be:
#       - Take everything that it's in there:
#           + A directory (exists?):
#               - Yes: do not create and go deeper
#               - No: link it
#           + A file (exists?):
#               - Yes: warn the user
#               - No: Link it
function Stow-Package {
     [CmdletBinding()]
     Param(
          [Parameter(Mandatory)][string[]] $Pkg,
          [Parameter(Mandatory)][string] $Dst,
          [Parameter(Mandatory)][string] $Src
     )

     begin
     {
          $SrcDir = "$Src\$Pkg"
          $Content = @( Get-ChildItem $SrcDir )
     }

     process
     {
          foreach ($i in $Content) {
               # First we want to know whether the current file is already
               # present. This will eventually be useful for multiple reasons:
               #     - Avoid overwriting files/recreating directories;
               #     - Identify Stow's already present links.
               if (Test-Path $Dst\$i) {
                    # TODO: If it is a link pointing to Stow's package

                    # If the path points to a directory, we need to go deeper;
                    # If it points to a file, the program fails and exits;
                    # If it is a link to a directory, it depends whether the
                    # direcatory is part of a package to stow or not.
                    if ((Get-Item $Dst\$i) -is [System.IO.DirectoryInfo]) {
                         Stow-Package -Pkg $i -Dst $Dst\$i -Src $SrcDir
                    } else {
                         Write-Host "${i}: File already exists."
                         exit
                    }
               } else {
                    Write-Verbose "LINK ($i) => $Dst\$i"
                    New-Item -ItemType SymbolicLink -Path "$Dst\$i" -Target "$SrcDir\$i" | Out-Null
               }

          }
     }
}

# Tests
#$Pack | ForEach-Object { Link-Files -Pkg $_ -Dst $Packdir -Src $Source }
$Pack | Link-Files
