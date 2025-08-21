#Requires -RunAsAdministrator
#Requires -Version 5.1

<#
.Synopsis
   Create and remove snapshot. For N2 Teams
.DESCRIPTION
   Create and remove snapshot. For N2 Teams
.EXAMPLE
   
.EXAMPLE
   Inserir posteriormente
.CREATEDBY
    Juliano Alves de Brito Ribeiro (find me at julianoalvesbr@live.com or https://github.com/julianoabr or https://youtube.com/@powershellchannel)
.VERSION INFO
    0.6
.VERSION NOTES
    
.VERY IMPORTANT
    “Todos os livros científicos passam por constantes atualizações. 
    Se a Bíblia, que por muitos é considerada obsoleta e irrelevante, 
    nunca precisou ser atualizada quanto ao seu conteúdo original, 
    o que podemos dizer dos livros científicos de nossa ciência?” 

.NEXT IMPROVEMENTS
 1. get vm list from file
 2. generate report of remove snapshots

#>

Clear-Host

$outputFolder = "ScriptREport"

if (-not(Test-Path -Path ".\$outputFolder")){

    $runningPath = (Get-location).Path

    Write-Host "Report Folder does not exist in: $runningPath I Will create it" -ForegroundColor White -BackgroundColor Red

    New-Item -Path ".\" -Name 'ScriptReport' -ItemType Directory -Verbose

}
else{

    Write-Host "Report Folder does exist. I will continue" -ForegroundColor White -BackgroundColor DarkGreen

}

$completeOutputFolder = $runningPath + '\' + $outputFolder

$nowDate = (Get-date -Format "ddMMyyyy-HHmm").ToString()


#VALIDATE MODULE
$moduleExists = Get-Module -Name Vmware.VimAutomation.Core

if ($moduleExists){
    
    Write-Host "Vmware.VimAutomation.Core Module is already loaded." -ForegroundColor White -BackgroundColor DarkGreen
    
}#if validate module
else{
    
    Write-Host -NoNewline "Vmware.VimAutomation.Core Module is not loaded" -ForegroundColor DarkBlue -BackgroundColor White
    Write-Host -NoNewline " I need this Module to work" -ForegroundColor DarkCyan -BackgroundColor White
    
    Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop -Verbose
    
}#else validate module


Function Welcome-ToScript{

    $remoteSrvConnected = ($Env:CLIENTNAME)
    $localSrvConnected = ($env:COMPUTERNAME)
    $localUsrConnected = ($env:USERNAME)

    Write-Host "Welcome $localUsrConnected" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "You are connected to following computer: $localSrvConnected" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "You are connected from: $remoteSrvConnected" -ForegroundColor White -BackgroundColor DarkBlue
}


Function Choose-Status {
    $choice=Read-Host "
    1: Manual
    2: DALL
    3: D3
    4: D10
    Select the number of days of Snapshots to remove. D1: Removes snapshots one day and older. D3: Remove snapshot 3 days and older."
    Switch ($choice){
        1 {$script:choice_out="Manual"}
        2 {$script:choice_out="DALL"}
        3 {$script:choice_out="D3"}
        4 {$script:choice_out="D10"}
    }
    Write-Host "You choose the option: $choice_out"

    Return $choice_out

}#end of function choose-status


function DisplayStart-Sleep ($totalSeconds)
{

$currentSecond = $totalSeconds

while ($currentSecond -gt 0) {
    
    Write-Host "Script is running for $currentSecond seconds..." -ForegroundColor White -BackgroundColor DarkGreen
    
    Start-Sleep -Seconds 1 # Pause for 1 second
    
    $currentSecond--
    }

Write-Host "Countdown complete! Let's continue..." -ForegroundColor White -BackgroundColor DarkBlue

}#end of Function Display Start-Sleep


function Pause-PSScript
{

   Read-Host 'Press [ENTER] to continue' | Out-Null

}

#VALIDATE IF OPTION IS NUMERIC
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric

#FUNCTION CONNECT TO VCENTER
function Connect-vCenterServer
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Menu','Auto')]
        $methodToConnect = 'Menu',

        [Parameter(Mandatory=$true,
                   Position=1)]
        [System.String[]]$vCenterServerList, 
                
        [Parameter(Mandatory=$false,
                   Position=2)]
        [System.String]$dnsSuffix,
        
        [Parameter(Mandatory=$false,
                   Position=3)]
        [System.Boolean]$LastConnectedServers = $false,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [System.String]$connectionProtocol,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [ValidateSet('80','443')]
        [System.String]$port = '443'
    )

#VALIDATE IF YOU ARE CONNECTED TO ANY VCENTER 
if ((Get-Datacenter) -eq $null)
    {
        Write-Host "You are not connected to any vCenter" -ForegroundColor White -BackgroundColor DarkMagenta
    }#enf of IF
else{
        
        $previousvCenterConnected = $global:DefaultVIServer.Name

        Write-Host "You are connected to vCenter:$previousvCenterConnected" -ForegroundColor White -BackgroundColor Green
        
        Write-Host -NoNewline "I will disconnect you before continue" -ForegroundColor White -BackgroundColor Red
            
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

}#end of else validate if you are connected. 


if ($methodToConnect -eq 'Auto'){
        
    foreach ($vCenterServer in $vCenterServerList){
            
        $Script:workingServer = ""
        
        $Script:workingServer = $vCenterServer + '.' + $suffix

        $vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $Port -WarningAction Continue -ErrorAction Stop

   }#end of foreach vcenter list
       
}#end of If Method to Connect
else{
        
    $workingLocationNum = ""
        
    $tmpWorkingLocationNum = ""
        
    $Script:WorkingServer = ""
        
    $iterator = 0

    #MENU SELECT VCENTER
    foreach ($vCenterServer in $vCenterServerList){
	   
        $vcServerValue = $vCenterServer
	    
        Write-Output "            [$iterator].- $vcServerValue ";	
	            
        $iterator++	
                
        }#end foreach	
                
            Write-Output "            [$iterator].- Sair do Script";

            while(!(isNumeric($tmpWorkingLocationNum)) ){
	                
                $tmpWorkingLocationNum = Read-Host "Type the number of vCenter you want to connect to."
                
            }#end of while

                $workingLocationNum = ($tmpWorkingLocationNum / 1)

                if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($iterator-1))  ){
	                
                    $Script:WorkingServer = $vCenterServerList[$WorkingLocationNum]
                
                }#end of IF
                else{
            
                    Write-Host "Exit selected or an invalid number entered. End of Script." -ForegroundColor Red -BackgroundColor White
            
                    Exit;
                }#end of else

        #Connect to Vcenter
        $Script:vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $port -WarningAction Continue -ErrorAction Stop -Verbose
  
    
    }#end of Else Method to Connect

}#End of Function Connect to vCenter

function Create-VMSnapshot
{
    [CmdletBinding()]
    Param
    (
        # VmwareName
        [Parameter(Mandatory=$true,
                   HelpMessage="Specifies the virtual machines you want to snapshot.",
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [System.String[]]$vmListName,
        

        # SnapshotName
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Specifies a name for the new snapshot.",
                   Position=2)]
        [System.String]$SnapName,

        #snapshot Description
        [Parameter(Mandatory=$true,
                   HelpMessage="Provide a description of the new snapshot."
                   )]
        [System.String]$SnapDescription,
        
        #snapshot Memory
        [Parameter(Mandatory=$false,
                   HelpMessage="If the value is true and if the virtual machine is powered on, the virtual machine's memory state is preserved with the memory"
                   )]
        [Switch]$SnapMemory,

        #snapshot Quiesce Memory
        [Parameter(Mandatory=$false,
                   HelpMessage="If the value is true and the virtual machine is powered on, VMware Tools are used to quiesce the file system of the
                                virtual machine. This assures that a disk snapshot represents a consistent state of the guest file systems. If the
                                virtual machine is powered off or VMware Tools are not available, the Quiesce parameter is ignored."
                   )]
        [Switch]$SnapQuiesceMem,

        #snapshot Confirm
        [Parameter(Mandatory=$false,
                   HelpMessage="If the value is true, indicates that the cmdlet asks for confirmation before running. If the value is false, the
                                cmdlet runs without asking for user confirmation."
                   )]
        [System.Boolean]$SnapshotConfirm = $false,

         
        [Parameter(Mandatory=$false,
        HelpMessage="Indicates that the command returns immediately without waiting for the task to complete.")]
        [Switch]$snapRunAsync  

    )

foreach ($vmName in $vmListName)
    {
        
        $snapCount = 0

        #validate if exists a snapshot for a VM
        $snapCount = (vmware.VimAutomation.Core\Get-vm -Name $vmName | Get-Snapshot).Count

        if ($snapCount -eq 0){
        
            Write-Host "VM: $vmName has $snapCount Snapshot(s)." -ForegroundColor White -BackgroundColor Green
            
            $vmObj = VMware.VimAutomation.Core\Get-VM -Name $vmName

            if ($vmObj.PowerState -eq 'PoweredOff'){
            
                New-Snapshot -VM $vmObj -Name $SnapName -Description $SnapDescription -Confirm:$true -Verbose
            
            }#verify powerstate
            else{
                
                if ($SnapMemory){
                
                    New-Snapshot -VM $vmObj -Name $SnapName -Memory -Description $SnapDescription -Confirm:$true -RunAsync -Verbose

                }#end of if snapmemory
                else{
                
                    New-Snapshot -VM $vmObj -Name $SnapName -Description $SnapDescription -Confirm:$true -RunAsync -Verbose
                
                }#end of else snapmemory
                
            
            }#end of else powerstate

                    
        }#end of if snap count
        else{
        
            Write-Host "VM: $vmName has $snapCount Snapshot(s)." -ForegroundColor White -BackgroundColor Red

            [System.Array]$vmSnapList=@()

            $vmSnapList = VMware.VimAutomation.Core\Get-Vm -Name $vmName | Get-Snapshot

            Write-Host "Please, before generating a new snapshot, remove the current one(s):" -ForegroundColor White -BackgroundColor Red


            foreach ($vmSnapItem in $vmSnapList)
            {
               
                Write-Host "Snapshot Details" -ForegroundColor White -BackgroundColor DarkGreen

                Write-Host "`n"

                Write-Host "VM Name: $vmName"

                Write-Host "Snapshot Name:" $vmSnapItem.Name

                Write-Host "Created Date" $vmSnapItem.Created
            
                Write-Host "Snapshot Size(MB):"([math]::Round($vmSnapItem.SizeMB,4))
            
                Write-Host "State of VM when the Snapshot was created:"$vmSnapItem.ExtensionData.State

                Write-Host "=======================================================" -ForegroundColor White -BackgroundColor Black

            }#end of ForEach Snapshot details
            
                    
        }#end of else snap count

        
    }#end of foreach


}#end of function


function Remove-SnapshotAutomatic
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        #List of VMs 
        [Parameter(Mandatory=$true,
                   HelpMessage="Specifies the virtual machines you want to snapshot.",
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [System.String[]]$vmListName,
        
        
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Manual','DALL','D3','D5','D10')]
        [System.String]$cutOffDate
 
       )

$trimDate = $null

if ($cutOffDate -ne 'Manual'){

    switch ($cutoffDate)
        {
        'D3' {
    
            [System.DateTime]$trimDate = (Get-Date).AddHours(-72)

            Write-Host "You chose 'D3'. All snapshots 3 days or older will be removed." -ForegroundColor DarkMagenta -BackgroundColor white
    
        }#end of d3
        'D5' {
    
            [System.DateTime]$trimDate = (Get-Date).AddHours(-120)
            
            Write-Host "You chose 'D5'. All snapshots 5 days or older will be removed." -ForegroundColor DarkMagenta -BackgroundColor white

        }#end of d5
       'D10' {
    
            [System.DateTime]$trimDate = (Get-Date).AddHours(-240)

            Write-Host "You chose 'D10'. All snapshots 10 days or older will be removed." -ForegroundColor DarkMagenta -BackgroundColor white
    
        }#end of d10
       'DALL' {
            
            Write-Host "You chose 'DALL'. All snapshots will be removed." -ForegroundColor DarkMagenta -BackgroundColor white
        
        }#end of DALL

    }#end of switch
    
}#end of IF CUTOFFDATE
else{
    
    Write-Host "You choose 'Manual'. Select the Snapshots that you desire to remove" -ForegroundColor DarkMagenta -BackgroundColor white
    

}#end of else CUTOFFDATE


foreach ($vmName in $vmListName)
{
    
    if ($cutoffDate -eq 'Manual'){
        
        [System.Array]$snapshotList = @()

        $snapshotList = VMware.VimAutomation.Core\Get-vm -Name $vmName | Get-Snapshot

        if ($snapshotList){
        
            foreach ($Snap in $snapshotList)
            {
               
                Write-Host "Snapshot Details:" -ForegroundColor White -BackgroundColor DarkGreen

                Write-Host "`n"

                Write-Host "VM Name: $vmName"

                Write-Host "Snapshot Name:" $Snap.Name

                Write-Host "Created Date" $Snap.Created
            
                Write-Host "Snapshot Size(MB):"([math]::Round($Snap.SizeMB,4))
            
                Write-Host "=======================================================" -ForegroundColor White -BackgroundColor Black
                
            }#end of ForEach Snapshot details
        
                [System.String]$snapToRemove = Read-Host "Enter the name of the Snapshot you want to remove"
                
                $vMObj = $Snap.VM

                [System.Boolean]$mountedTools = $vMObj.ExtensionData.Runtime.ToolsInstallerMounted

                #Validate if VM has VmTools mounted
                If ($mountedTools){
     
                    Write-Output "VM: $vmName has VMTOOLs attached to CD/DVD Driver. I will unmount before continue"

                    $vMObj | Dismount-Tools -Verbose
        
                    DisplayStart-Sleep -totalSeconds 20
     
                }#End of IF

                Write-Host "Removing snapshot: $snapToRemove of the VM $vmName..."
                
                VMware.VimAutomation.Core\Get-vm -Name $vmName | Get-Snapshot -Name $snapToRemove | Remove-Snapshot -Confirm:$true -RunAsync -Verbose 
                
        
        }#end of IF snapshot list is not null
        else{
        
            Write-Host "VM: $vmName does not have snapshots. Checking the next one"            
              
            
        }#end of Else snapshot list is null
               
        
    }#enf of IF
    else{
        
        if ($cutOffDate -eq 'DALL')
        {
            
            $snapshotList = VMware.VimAutomation.Core\Get-Vm -Name $vmName | Get-Snapshot
        
            foreach ($snap in $snapshotList){
    
                [System.String]$snapName = $snap.Name
     
                [System.String]$vmName = $snap.VM.Name

                $vMObj = $snap.VM

                [System.Boolean]$mountedTools = $vMObj.ExtensionData.Runtime.ToolsInstallerMounted
     
                #Validate if VM has VmTools mounted
                If ($mountedTools){
     
                    Write-Output "VM: $vmName has VMTOOLs attached to CD/DVD Driver. I will unmount it before continue"

                    $vMObj | Dismount-Tools -Verbose
        
                    DisplayStart-Sleep -totalSeconds 20  
     
                }#End of IF
     
                Write-Output "Removing the Snapshot: $snapName of VM $vmName ..." 
       
                VMware.VimAutomation.Core\Get-VM -Name $vmName | Get-Snapshot -Name $snapName | Remove-Snapshot -RunAsync -RemoveChildren -Confirm:$false -Verbose

            }#end forEach snap

        }#end of IF DALL
        else{
            
            $snapshotList = VMware.VimAutomation.Core\Get-Vm | Get-Snapshot | Where-Object -FilterScript {$PSItem.Created -lt "$trimdate"}
        
            foreach ($snap in $snapshotList){
    
                [System.String]$snapName = $snap.Name
     
                [System.String]$vmName = $snap.VM.Name

                $vMObj = $snap.VM

                [System.Boolean]$mountedTools = $vMObj.ExtensionData.Runtime.ToolsInstallerMounted
     
                #Validate if VM has VmTools mounted
                If ($mountedTools){
     
                    Write-Output "VM: $vmName has VMTOOLs attached to CD/DVD Driver. I will unmount it before continue"

                    $vMObj | Dismount-Tools -Verbose
        
                    DisplayStart-Sleep -totalSeconds 20  
     
                }#End of IF
     
                Write-Output "Removing the Snapshot: $snapName of VM $vmName ..." 
       
                VMware.VimAutomation.Core\Get-VM -Name $vmName | Get-Snapshot -Name $snapName | Remove-Snapshot -RunAsync -RemoveChildren -Confirm:$false -Verbose

            }#end forEach snap
            
        
        }#end of else DALL (other options)

    
    }#enf of else CUTOFFDATE

    DisplayStart-Sleep -totalSeconds 15

    $vMObjARS = VMware.VimAutomation.Core\Get-vm -Name $vmName

    $consolidationNeeded = $vmObjARS.ExtensionData.Runtime.ConsolidationNeeded

    if ($consolidationNeeded -like 'False'){ 
        
        Write-Host "VM: $vmName doesn't need disk consolidation" -ForegroundColor DarkBlue -BackgroundColor White

        }#end of IF Consolidation
    else{
         
        Write-Host "VM: $vmName need disk consolidation" -ForegroundColor Red -BackgroundColor White

        $vmObjARS.ExtensionData.ConsolidateVMDisks()
                 
        }#end of Else Consoolidation
        
    }#end of main foreach

}#end of function remove Snapshot

function Show-MainMenu {
    Clear-Host
    Write-Host "######### MAIN MENU - SNAPSHOT #######" -ForegroundColor White -BackgroundColor Blue
    Write-Host "1. Generate Snapshot"
    Write-Host "2. Remove Snapshot"
    Write-Host "3. Exit"
    Write-Host ""
}#end of function main menu

function Handle-MainMenuChoice {
    param($Choice)

    switch ($Choice) {
        "1" {
            Write-Host "Your selected Generate Snapshot"
            
                $vmResponse = 'Y'
                
                $tmpVMName = $Null
                
                $tmpVMlist = @()
    
            Do 
                { 
                #Read VM Name - não aceita valor nulo
                Do {
                
                    [System.STring]$tmpVMName = Read-Host 'Enter the name of the VM to generate Snapshot (cannot be null)'
                
                }until (-not [string]::IsNullOrEmpty($tmpVMName))
                            
                Do{
                    
                    $vmResponse = Read-Host -Prompt "Would you like to add more VMs to the list? Press 'Y' for Yes or 'N' for No"

                    $vmResponse = $vmResponse.ToLower() # Convert to lowercase for case-insensitivity

                }While ($vmResponse -ne 'Y' -and $vmResponse -ne 'N')
            
                $tmpVMlist += $tmpVMName

                }#end of DO
            Until ($vmResponse -eq 'n')

                ################call function to generate snapshot########################
                                
                [System.String]$tmpSnapName = Read-Host "Enter the snapshot name (suggestion: change number) without spaces (example: ChangeXYZ)"
                
                [System.String]$tmpSnapDEscription =  Read-Host "Enter the description without space between words (example: UpgradeVMTools)"

                $totalVMs = 0

                [System.Int32]$totalVMs = $tmpVMlist.Count

                $memChoice = ""

                do{
                
                    Write-host "Do you want to Generate Snapshot(s) with Memory Option (Y) or without Memory Option (N)? " -ForegroundColor Yellow -BackgroundColor Black
  
                    Write-Output "`n"

                    $memChoice = Read-Host " Type ( Y ou N ) " 

                    if ($memChoice -notmatch "^(?:Y\b|N\b)"){
    
                        Write-Host "You entered an invalid option. Enter only Y or N." -ForegroundColor White -BackgroundColor Red
    
                        }#END OF IF

                }while ($memChoice -notmatch "^(?:Y\b|N\b)")#end of do while Y or N regex


                if ($totalVMs -eq 1){
                
                    if ($memChoice -eq 'Y'){
                    
                        Create-VMSnapshot -vmListName $tmpVMlist -SnapName $tmpSnapName -SnapDescription $tmpSnapDEscription -SnapMemory -Verbose
                                           
                    }#end of if
                    else{
                    
                        Create-VMSnapshot -vmListName $tmpVMlist -SnapName $tmpSnapName -SnapDescription $tmpSnapDEscription -Verbose

                    }#end of if Y or N 
                    
                    Pause-PSScript                        
                                                
                }#end of IF Total VMs
                else{
                
                     if ($memChoice -eq 'Y'){
                    
                        Create-VMSnapshot -vmListName $tmpVMlist -SnapName $tmpSnapName -SnapDescription $tmpSnapDEscription -SnapMemory -snapRunAsync -Verbose

                    }#end of if
                    else{
                    
                        Create-VMSnapshot -vmListName $tmpVMlist -SnapName $tmpSnapName -SnapDescription $tmpSnapDEscription -snapRunAsync -Verbose
                        
                    }#end of if Y or N   

                    Pause-PSScript
                
                }#end of else
                
                #export snapshot report
                Write-Host "I'll generate a report with the snapshots generated. Wait for the count..."
                DisplayStart-Sleep -totalSeconds 10

                foreach ($tmpVM in $tmpVMlist)
                {
                    
                    VMware.VimAutomation.Core\Get-VM -Name $tmpVM | Get-Snapshot | Select-Object -Property VM,PowerState,Name,Quiesced,@{label='Size(GB)';expression={[math]::Round(($PSItem.SizeGB),2)}} | 
                    Format-table -AutoSize | Out-File -Width 2048 -FilePath "$completeOutputFolder\$tmpSnapName-$nowDate-report.txt" -Append -Verbose

                }#export snapshot report
                           
                
            Show-MainMenu # Return to main menu after action
        }
        "2" {
            Write-Host "You selected Remove Snapshot"
            
            
                $vmResponse = 'Y'
                
                $tmpVMName = $Null
                
                $tmpVMlist = @()
    
            Do{ 
                
                Do {
                
                    [System.STring]$tmpVMName = Read-Host 'Enter the name of the VM to remove the Snapshot(s) from (cannot be null)'
                
                }until (-not [string]::IsNullOrEmpty($tmpVMName))
                
                
                
                Do{
                    
                    $vmResponse = Read-Host -Prompt "Would you like to add more VMs to the list? Press 'Y' for Yes or 'N' for No"
                
                    $vmResponse = $vmResponse.ToLower() # Convert to lowercase for case-insensitivity

                }While ($vmResponse -ne 'Y' -and $vmResponse -ne 'N')

                
                $tmpVMlist += $tmpVMName
                }#end of DO
             Until ($vmResponse -eq 'n')


             #call function to remove snapshot
                
                Write-Host "Select an option corresponding to the number of days to remove snapshots. `nExample: D3,`nMeans that all snapshots that are 3 or more days old will be removed" -ForegroundColor White -BackgroundColor Red
                
                Write-Host -NoNewline "Select the Manual Option" -ForegroundColor White -BackgroundColor Green; Write-Host -NoNewline " to select the snapshot you want to remove by name" -ForegroundColor Black -BackgroundColor White
                
                [System.String]$userChoice=Choose-Status
                
                Write-Host "You choose remove: $userChoice" -ForegroundColor White -BackgroundColor Red
                                
                $totalVMs = 0

                [System.Int32]$totalVMs = $tmpVMlist.Count

                if ($totalVMs -eq 1){
                
                    Remove-SnapshotAutomatic -vmListName $tmpVMlist -cutOffDate $userChoice -Verbose

                    Pause-PSScript
                            
                }#end of IF
                else{
                
                     Remove-SnapshotAutomatic -vmListName $tmpVMlist -cutoffDate $userChoice -Verbose

                     Pause-PSScript
                
                }#end of else

                           
            
            Show-MainMenu # Return to main menu after action
        }
        "3" {
            Write-Host "Exiting..."
            return $false # Indicate to exit the loop
        }
        default {
            Write-Host "Invalid Option. Please try again."
            Pause
            Show-MainMenu # Return to main menu after invalid input
        }
    }
    return $true # Indicate to continue the loop
}#end of function Handle-MainMenuChoice

################## Main script logic ##############################

Welcome-ToScript

Write-Host "`n"

#DEFINE VCENTER LIST
$vcServerList = @();

#ADD OR REMOVE VCs        
$vcServerList = ('server1.yourdomain','server2.yourdomain.com','server3.yourdomain.com') | Sort-Object

#SELECT TYPE OF CONNECTIONS
Do
{
 
 $tmpMethodToConnect = Read-Host -Prompt "Type (Menu) if you want to choose the vCenter to connect to. 
 Type (Auto) if you want to enter the name of the vCenter to which you will connect"

    if ($tmpMethodToConnect -notmatch "^(?:menu\b|auto\b)"){
    
        Write-Host "You entered an invalid word. Type only (menu) or (auto)" -ForegroundColor White -BackgroundColor Red
    
    }
    else{
    
        Write-Host "You entered a valid word. I will proceed. =D" -ForegroundColor White -BackgroundColor DarkBlue
    
    }
    
}While ($tmpMethodToConnect -notmatch "^(?:menu\b|auto\b)")#end of while choose method to connect


if ($tmpMethodToConnect -match "^\bauto\b$"){

    [System.String]$tmpVC = Read-Host "Enter the Hostname or IP of the vCenter you want to connect to."

    $tmpSuffix = ""

    [System.String]$tmpSuffix = Read-Host "Enter the suffix of the vCenter you want to connect to"

    if ($tmpSuffix -like $null){
        
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -port 443 -Verbose
            
    }#end of IF
    else{
    
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -dnsSuffix $tmpSuffix -port 443 -Verbose
    
    }#end of Else
    

}#end of IF
else{

    Connect-vCenterServer -vCenterServerList $vcServerList -methodToConnect Menu -port 443 -Verbose

}#end of Else


#call main manu generate and remove snapshot
$ContinueMenu = $true
while ($ContinueMenu) {
    Show-MainMenu
    $UserChoice = Read-Host "Select an Option in Menu"
    $ContinueMenu = Handle-MainMenuChoice $UserChoice
}#end of while