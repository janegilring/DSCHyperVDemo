function Get-EncryptionCertificate {
    [CmdletBinding() ]
    param ($ComputerName,
    $PublicKeyFolder,
    $Credential
    )

    

    $returnValue= Invoke-Command -ComputerName $computerName -ScriptBlock {
            $certificates = dir Cert:\LocalMachine\my
            $certcount = 0
            $certificates | %{
                   
                   if ($certcount -gt 0) {break}
                   
                    # Verify the certificate is for Encryption and valid
                    #if ($_.PrivateKey.KeyExchangeAlgorithm -and $_.Verify())
                    if ($_.PrivateKey.KeyExchangeAlgorithm)
                    {

                        $certcount ++

                        # Return the thumbprint, and exported certificate path
                        return @($_.Thumbprint, $_.Export('CER'))
                        #return @($_.Thumbprint)
                    }
                  }
        } -Credential $Credential
    Write-Verbose "Identified and exported cert..."



    # Copy the exported certificate locally
    $destinationPath = join-path -Path $publicKeyFolder -childPath "$computername.cer"

    [system.IO.file]::WriteAllBytes($destinationPath,($returnValue[1]) )

    # Return the thumbprint
    return $returnValue[0]
}