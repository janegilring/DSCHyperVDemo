Configuration CrayonBaseCompositeDSCResource {
param (
[string]$WindowsUpdateMode
)

Import-DscResource -ModuleName CrayonDSCResources

Firewall CrayonRDP {   

Name = 'Remote Desktop - User Mode (TCP-In)'
DisplayGroup = 'Remote Desktop'
Ensure = 'Present'
State = 'Enabled'
Access = 'Allow'
Profile = 'Domain'
Description = 'Inbound rule for the Remote Desktop service to allow RDP traffic. (Created by DSC)'
LocalPort = '3389'
Protocol = 'TCP'
Direction = 'Inbound'
ApplicationPath = '%SystemRoot%\system32\svchost.exe'

}

Firewall CrayonRDPUserMode {   

Name = 'Remote Desktop (TCP-In)'
DisplayGroup = 'Remote Desktop'
Ensure = 'Present'
State = 'Enabled'
Access = 'Allow'
Profile = 'Domain'
Description = 'Inbound rule for the Remote Desktop service to allow RDP traffic. (Created by DSC)'
LocalPort = '3389'
Protocol = 'TCP'
Direction = 'Inbound'
ApplicationPath = 'System'

}

Firewall CrayonICMP {   

Name = 'File and Printer Sharing (Echo Request - ICMPv4-In)'
DisplayGroup = 'File and Printer Sharing'
Ensure = 'Present'
State = 'Enabled'
Access = 'Allow'
Profile = 'Domain'
Description = 'Echo Request messages are sent as ping requests to other nodes. (Created by DSC)'
Protocol = 'ICMPv4'
Direction = 'Inbound'

}

Firewall CrayonSMBIn {   

Name = 'File and Printer Sharing (SMB-In)'
DisplayGroup = 'File and Printer Sharing'
Ensure = 'Present'
State = 'Enabled'
Access = 'Allow'
Profile = 'Domain'
Description = 'Inbound rule for File and Printer Sharing to allow Server Message Block transmission and reception via Named Pipes. (Created by DSC)'
Protocol = 'TCP'
LocalPort = '445'
ApplicationPath = 'System'
Direction = 'Inbound'

}

WindowsUpdateMode CrayonHyperV {

UpdateMode = $WindowsUpdateMode

}


RemoteDesktopAdmin CrayonCommon {

UserAuthentication = 'Secure'
Ensure = 'Present'

}

}