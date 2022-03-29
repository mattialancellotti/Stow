function Check-Permissions {
     $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
     if ( !($currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) ) {
          Write-Host "You gotta be administrator boyo!! Get off me."
          exit
     }
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
     Get-ChildItem -File | ForEach-Object {
          New-Item -ItemType SymbolicLink -Path "$Path\$_" -Target $Target
     }
}

Export-ModuleMember -Function Link-Files
