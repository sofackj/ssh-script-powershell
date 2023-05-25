# Script's goal: Simplify ssh connection

####################################################################
# Cmdlets
####################################################################

# Cmdlets for this script '-remoteUser', '-ipAddress'
[CmdletBinding()]
param
(
    # user argument
    [Parameter(Mandatory = $false,
               HelpMessage = 'Type an IP address for the option -ipAddress')]
    [string]$remoteUser,
    # user argument
    [Parameter(Mandatory = $false,
               HelpMessage = 'Type an IP address for the option -ipAddress')]
    [ValidatePattern('(^(?:\d{1,3}\.){3}\d{1,3}$)')]
    [string]$ipAddress,
    # user argument
    [Parameter(Mandatory = $false,
               HelpMessage = 'Test for the next argument')]
    [string]$dnsName,
    # user argument
    [Parameter(Mandatory = $false,
               HelpMessage = 'Test for the next argument')]
    [string]$myCp,
    # user argument
    [Parameter(Mandatory = $false,
               HelpMessage = 'Test for the next argument')]
    [string]$remoteToLocal,
    # user argument
    [Parameter(Mandatory = $false,
               HelpMessage = 'Test for the next argument')]
    [string]$pathRemote,
    # user argument
    [Parameter(Mandatory = $false,
               HelpMessage = 'Test for the next argument')]
    [string]$pathLocal
)


####################################################################
# Function
####################################################################
#
Function default_value {
    param (
         [string]$parameter,
         [string]$defaultValue
    )
    #
    If($parameter -eq ""){
        # 
        $parameter = $defaultValue
    }
    #
    return $parameter
}
#
Function check_ip_address {
    param (
         [string]$dns,
         [string]$ip
    )
    
    #
    If($dns){
        try {
            #
            $ip = (Resolve-DnsName ${dns} -ErrorAction Stop).IPAddress
        } catch {
            #
            Write-Error -Message "${dns} n'est pas un DNS valide..." -ErrorAction Stop
        }
    #    
    }elseif(!$ip -and !$dns){
        #
        Write-Error -Message "Une des options -ipAddress ou -dnsName doit être spécifiée..." -ErrorAction Stop
    }

    #
    return $ip
}
#
Function ssh_command {
    param (
         [string]$cp,
         [string]$user,
         [string]$ip
     )

    #
    $command = "${cp}${link}${user}@${ip}${suffixBastion}"

    # Echo for the remote user and IP you want to connect
    Write-Host "#########################################################"
    Write-Host "You will be connected as ${user}"
    Write-Host "#########################################################"
    Write-Host "$command"

    # SSH command to launch
    ssh $command
}

Function scp_command {
    param (
         [string]$cp,
         [string]$user,
         [string]$ip,
         [string]$remotePath,
         [string]$localPath
     )

    # Check if one of tmhme armgs are empty to point a direction
    If($localPath -eq "" -or $remoteToLocal){ 
        $localToRemote = $false
    } elseif($remotePath -eq "" -or !$remoteToLocal){
        $localToRemote = $true
    }

    # Declare an array
    $my_array = @("C:\Users\${me}\${localPath}", "${cp}${link}${user}@${ip}${suffixBastion}:${remotePath}")

    # Declare variables for the source and the destination
    If($localToRemote){
        $source = $my_array[0]
        $destination = $my_array[1]
    } else {
        $source = $my_array[1]
        $destination = $my_array[0]
    }

    # Echo for the remote user and IP you want to connect
    Write-Host "#########################################################"
    Write-Host "Transferring file(s) :"
    Write-Host "From $source"
    Write-Host "To   $destination"
    Write-Host "#########################################################"
    Write-Host "$source -> $destination"

    # SCP command to launch
    scp $source $destination
}

####################################################################
# Variables needed in the script
####################################################################

# Path of the known_hosts file
$knownHostPath = "~\.ssh\known_hosts"
# CP to identify
$me = "yourComputerUsername"
$sncfCp = (default_value -parameter $myCp -defaultValue "")
$link = ""
$remoteUser = (default_value -parameter $remoteUser -defaultValue "")
$suffixBastion = ""

####################################################################
# Script
####################################################################

# Clean the file known_hosts
Set-Content -Path $knownHostPath -Value ""

# If one of the args pathRemote or pathLocal, ssh_command is initiated
If(!$pathRemote -and !$pathLocal){ 
  ssh_command -cp $sncfCp -user $remoteUser -ip (check_ip_address -dns $dnsName -ip $ipAddress)
} else {
  scp_command -cp $sncfCp -user $remoteUser -ip (check_ip_address -dns $dnsName -ip $ipAddress) -remotePath $pathRemote -localPath $pathLocal
}
