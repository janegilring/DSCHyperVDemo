workflow Get-SCSMRBInput {

param (
    [string]$RBID,
    [string]$AnswerAttribute = "DisplayName"
)


$SCSMCredential = Get-AutomationPSCredential -Name 'Cred-CrayonDemoServiceManager'
$SCSMServerName = Get-AutomationVariable -Name 'Var-CrayonDemoSCSMProdServer'
$SMTPServerName = Get-AutomationVariable -Name 'Var-CrayonDemoSMTPServer'

$SCSMResult = inlinescript {
    $AnswerAttribute = $using:AnswerAttribute
    $SCSMCredential = $using:SCSMCredential
    $SCSMServerName = $using:SCSMServerName
    $RBID = $using:RBID

    New-SCSMManagementGroupConnection -ComputerName $SCSMServerName -Credential $SCSMCredential

    $RBClass = Get-SCSMClass -Name System.WorkItem.Activity.SMARunbookActivity
    $SRClass = Get-SCSMClass -Name System.WorkItem.servicerequest

    $RB = Get-SCSMObject -Class $RBClass -Filter "ID -eq $RBID" -ComputerName $SCSMServerName

    $SRRelationship = Get-SCSMRelationshipClass system.workitemcontainsactivity -computername $scsmservername

    $RBRelation = Get-SCSMRelationshipObject -TargetRelationship $SRRelationship -TargetObject $RB -computername $scsmservername
    $SR = $RBRelation.SourceObject

    $ServiceRequest = Get-ScsmPxServiceRequest -Name $SR.Name

    if ($ServiceRequest) {
        [xml]$UserInput = $ServiceRequest.UserInput
        [xml]$UserInputAnswer = $UserInput.UserInputs.UserInput.Answer
        $CreatedByUser = Get-ScsmPxRelatedObject -Source $ServiceRequest -RelationshipClassName System.WorkItemCreatedByUser
    }

    [pscustomobject]@{
    ServiceRequest = $SR.DisplayName
    CreatedByUser = $CreatedByUser.UPN
    UserInputAnswerValue = $UserInputAnswer.Values.Value.$AnswerAttribute
    }

  
} -PSComputerName $SCSMServerName -PSCredential $SCSMCredential


$UserEmailAddress = $null
if ($SCSMResult.CreatedByUser) {
    $UPN = $SCSMResult.CreatedByUser
    $UserEmailAddress = get-aduser -Filter "UserPrincipalName -eq '$UPN'" -Properties mail | Select-Object -ExpandProperty mail

}

add-member -InputObject $SCSMResult -MemberType NoteProperty -Name "emailaddress" -Value $UserEmailAddress
$SCSMResult


}