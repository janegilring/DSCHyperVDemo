Configuration DSCLCMPullSettings {
    param(
        [Parameter(Mandatory)]
        $NodeName,
        $CertificateID,
        $ConfigurationID,
        $PullServerURL
    )
    Node $NodeName {
        LocalConfigurationManager {
            ConfigurationID = $ConfigurationID
            CertificateID = $CertificateID
            ConfigurationMode = 'ApplyandAutoCorrect'
            ConfigurationModeFrequencyMins = 60
            RebootNodeIfNeeded = $false
            RefreshFrequencyMins = 30
            RefreshMode = 'PULL'
            AllowModuleOverwrite = $True
            DownloadManagerName = 'WebDownloadManager'
            DownloadManagerCustomData = (@{ServerURL = $PullServerURL;AllowUnsecureConnection = 'false'})
            DebugMode = 'None'
        }
    }
}