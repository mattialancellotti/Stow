# These are the necessary parameters to make this little script work.
# Gonna expand it? Yes
# Gonna do cooler things? Yes
# Do I have the time now? No
# Do I know how to make them in powershell? No
Param(
     [Parameter(Mandatory=$true)][string] $Target,
     [Parameter(Mandatory=$true)][string] $Path
)

# Test
Write-Host $Target
Write-Host $Path
