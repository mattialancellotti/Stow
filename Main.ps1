# TODO:
#   - Better parameter validation:
#       + The path must exists;
#       + The package to chain should not exists;
#       + If the chained package already exists it cannot be unchained if no
#         root is found;
#       + Trim input and remove last '\'.
#   - Better error handling and better messages to the user.

# This sets the default parameter set to A (basically chains files)
[CmdletBinding(DefaultParameterSetName = 'stow')]
Param(
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Stowdir,
     [Parameter(Mandatory)][ValidateScript({Test-Path $_})][string] $Sourcedir,

     # These are the actions the program can do.
     # All of the are mandatory but since they are in differenet parameter sets
     # only one can be used
     [Parameter(ParameterSetName='stow',Mandatory,ValueFromRemainingArguments)]
     [string[]] $Stow,
     [Parameter(ParameterSetName='unstow',Mandatory,ValueFromRemainingArguments)]
     [string[]] $Unstow
)

# Getting the user's current role and the administrative role
$userRole = [Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

# Checking if the user has administrative privilages
$userStatus = [Security.Principal.WindowsPrincipal]::new($userRole)
if (!($userStatus.IsInRole($adminRole))) {
     Write-Error -Category PermissionDenied 'You need administration permissions'
     exit 5 # 5 is the 'Access denied.' error code (net helpmsg 5)
}

# TODO: Documentation
# This function is needed because stow-package and unstow-package need to know
# if a file can be touched, if not this function will warn them.
function Check-Ownership {
     Param( [string] $File, [string] $Package )

     # Checking if the given file actually exists
     if (!(Test-Path $File)) { return 2 }

     # Information about the complete path of the package we are stowing
     $AbsPackage = (Resolve-Path $Sourcedir\$Package).ToString()
     $PkgLength  = $AbsPackage.Length

     # Complete path of the file
     $AbsFile = (Resolve-Path $File).ToString()

     # Checking if the 2 strings are identical and returning the result
     $PackageRoot = $AbsFile.Substring(0, $PkgLength)
     if ( $PackageRoot.Equals($AbsPackage) ) {
          return 0
     } else {
          return 1
     }
}

function Link-Ownership {
     Param( [string] $File, [string] $Package )

     # Checking if the file exists
     if (!(Test-Path $File)) { return 2 }

     # Getting Link and Target information about the given file. Then checking
     # if the file is a link. If it's not this function is useless.
     $LinkFile = (Get-Item $File | Select-Object -Property LinkType,Target)
     if ( [string]::isNullorEmpty($LinkFile.LinkType) ) { return -1 }

     # If the file is a link than check if it is linked to the right target 
     return Check-Ownership -File $LinkFile.Target -Package $Package
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
          # $Source is literally where files are, while $Destination is where
          # the link to them is going to appear.
          [Parameter(Mandatory)][string] $Source,
          [Parameter(Mandatory)][string] $Destination
     )

     # Listing all the files we might have to stow in $Destination
     begin { $Content = @(Get-ChildItem $Source) }

     process {
          foreach ($i in $Content) {
               # First we want to know whether the current file is already
               # present. This will eventually be useful for multiple reasons:
               #     - Avoid overwriting files/recreating directories;
               #     - Identify Stow's already present links.
               if (Test-Path $Destination\$i) {
                    # If the path points to a directory, we need to go deeper;
                    # If it points to a file, the program fails and exits;
                    # If it is a link to a directory, it depends whether the
                    # direcatory is part of a package to stow or not.
                    if ((Get-Item $Destination\$i) -is [System.IO.DirectoryInfo]) {
                         # TODO: If it is a link pointing to Stow's package then
                         # unstow it, create a new directory with the same
                         # name, restow the previous package and go deeper.
                         switch (Link-Ownership -File $Destination\$i -Package $Packages[$StowCount]) {
                              2 { Write-Error "() $Destination\$i| something went wrong"; exit 2 }
                              -1 { Stow-Package -Source $Source\$i -Destination $Destination\$i }
                              1 { Write-Host "$Destination\$i file's root is not"$Packages[$StowCount] }
                              0 {
                                   Write-Verbose "UNLINK ($Source\$i) => $Destination\$i"
                                   (Get-Item "$Destination\$i").Delete()
                                   Write-Verbose "LINK ($Source\$i) => $Destination\$i"
                                   New-Item -ItemType SymbolicLink -Path "$Destination\$i" -Target "$Source\$i" | Out-Null
                              }
                         }
                    } else {
                         switch (Link-Ownership -File $Destination\$i -Package $Packages[$StowCount]) {
                              1 { Write-Host "${i}: File exists and is not a link to $Source" }
                              0 {
                                   Write-Verbose "UNLINK ($Source\$i) => $Destination\$i"
                                   (Get-Item "$Destination\$i").Delete()
                                   Write-Verbose "LINK ($Source\$i) => $Destination\$i"
                                   New-Item -ItemType SymbolicLink -Path "$Destination\$i" -Target "$Source\$i" | Out-Null
                              }
                         }
                    }
               } else {
                    Write-Verbose "LINK ($Source\$i) => $Destination\$i"
                    New-Item -ItemType SymbolicLink -Path "$Destination\$i" -Target "$Source\$i" | Out-Null
               }

          }
     }
}

# TODO: Documentation
# Workflow:
#   foreach file in the given package/directory:
#       if (it is not present) || (it is present && is a link to the right package):
#           if yes, then proceed by deleting it;
#       if it is a directory: go deeper and restart the process;
#       if it is a link that poitns somewhere else:
#           if the link exists, exit with an error;
#           if it doesn't, tell the user to use -Force to delete it.
function Unstow-Package {
     [CmdletBinding()]
     param(
          [Parameter(Mandatory)][string] $Source,
          [Parameter(Mandatory)][string] $Packdir,
          [Parameter(Mandatory)][string] $Pkg
     )

     begin {
          $SrcDir = "$Source\$Pkg"
          $Content = $(Get-ChildItem $Pkg)
     }

     process {
          foreach ($i in $Content) {
               if (!(Test-Path "$Packdir\$i") -Or`
                    (Test-Path "$Packdir\$i")) {}
          }
     }
}

# Initializing stowing cunter
$StowCount = -1
$Packages = @(if ($Stow) { $Stow } else { $Unstow })

# Choosing what the program should do based on the current parameter set.
# Basically if the user wants to stow or unstow.
switch ($PSCmdlet.ParameterSetName) {
     'stow' { $Packages | %{ ++$StowCount; Stow-Package -Source $Sourcedir\$_ -Destination $Stowdir } }
     'unstow' { Write-Host "Unpacking files." }
}
