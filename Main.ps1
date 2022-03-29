# These are the necessary parameters to make this little script work.
# Gonna expand it? Yes
# Gonna do cooler things? Yes
# Do I have the time now? No
# Do I know how to make them in powershell? No
Param(
     [Parameter(Mandatory=$true)][string] $Target,
     [Parameter(Mandatory=$true)][string] $Path
)

# Checking if the user has root permissions
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( !($currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) ) {
     # Funny message and exiting
     Write-Host "You gotta be administrator boyo!! Get off me."
     exit
}

# Test
Write-Host $Target
Write-Host $Path

Start-Sleep -seconds 20

function Link-Files {
}
