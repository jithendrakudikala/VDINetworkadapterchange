<#
.synopsis
   <<synopsis goes here>>
.Description
  <<Description goes here>>
.Notes
  ScriptName  : PatchingListgenerater.PS1
  Requires    : Powershell Version 5.0
  Author      : Jithendra Kudikala
  EMAIL       : jithendra.kudikala@gmail.com
  Version     : 1.1 Script will change the network adapter of the VDI machines
.Parameter
   None
 .Example
   None
#>

Function update-NetworkAdapter
{
    param($presentnetworkadapter, $newnetworkadapter,$VIServer,$DDC,$cred)
    add-pssnapin Citrix*
    connect-viserver $VIServer -credential $cred

    $vms = get-cluster <#-Name "if you want to narrow the filter and search in only one cluster"#> | get-vm | get-networkadapter | Where-Object{$_.networkname -eq $presentnetworkadapter} | select @{Label = 'VM' ; Expression = {$_.parent.name}}, networkname
    $VMs_change = @()
    foreach($vm in $vms.VM)
    {
        $VMs_change += get-brokermachine -dnsname $vm* -adminaddress $DDC |Where-Object {$_.sessionstate -ne "Active"} | select machinename,registrationstate,sessionstate,IPAddress
    }

    $VMs_change | Export-Csv .\before_vms_networkchange.csv -Append

    foreach($temp in $VMs_change)
    {
        $vm = ($temp.machineName).split("\")[1]
        get-vm $vm | get-networkadapter | Where-Object{$_.networkname -eq $presentnetworkadapter} | set-networkadapter -networkname $newnetworkadapter -confirm:$false
    }
    $output = @()

    foreach($temp in $VMs_change)
    {
        $output += get-brokermachine -machinename $temp.machinename |select machinename,registrationstate,sessionstate,IPAddress
    }

    $output | Export-Csv .\after_vms_networkchange.csv -Append
    
}

$cred = Get-Credential
$ddc = "Enter DDC address"
$VIServer = "ENter Vcenter server address"
$presentnetworkadapter = "Enter the network address that you want to change"
$newnetworkadapter = "Enter new network address"

update-NetworkAdapter -presentnetworkadapter $presentnetworkadapter -newnetworkadapter $newnetworkadapter -VIServer $VIServer -DDC $ddc -cred $cred
