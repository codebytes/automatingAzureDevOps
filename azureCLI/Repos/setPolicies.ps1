function set_policies(
    [String]$org,
    [String]$projectName,
    [String]$repoId,
    [String]$branch,
    [string[]]$requiredApprovers,
    [string[]]$optionalApprovers,
    [String]$buildId
)
{
    $policies = @()

    if($requiredApprovers)
    {
        $reviewersRequired = ''
        foreach($reviewer in $requiredApprovers)
        {
            $reviewersRequired= $reviewersRequired + $reviewer +';'
        }
        
        $reviewersRequired = $reviewersRequired.Substring(0,$reviewersRequired.Length-1)
        $reviewerPolicy = az repos policy required-reviewer create --org $org -p $projectName --branch $branch --repository-id $repoId --blocking true --enabled true --message 'Required reviewers policy added' --required-reviewer-ids $reviewersRequired -o json | ConvertFrom-Json
        $policies += $reviewerPolicy
    }    
    # set optional reviewers
    if($optionalApprovers)
    {
        $reviewersOptional = ''
        foreach($reviewer in $optionalApprovers)
        {
            $reviewersOptional= $reviewersOptional + $reviewer +';'
        }
        $reviewersOptional = $reviewersOptional.Substring(0,$reviewersOptional.Length-1)
        $reviewerPolicy = az repos policy required-reviewer create --org $org -p $projectName --branch $branch --repository-id $repoId --blocking false --enabled true --message 'Optional reviewers policy added' --required-reviewer-ids $reviewersOptional -o json | ConvertFrom-Json
        $policies += $reviewerPolicy
    }

    if($buildId)
    {
        $buildPolicy = az repos policy build create --org $org -p $projectName --branch $branch --repository-id $repoId --blocking true --build-definition-id $buildId --manual-queue-only false --enabled true --queue-on-source-update-only false --display-name "CI Build" --valid-duration 0 -o json | ConvertFrom-Json
        $policies += $buildPolicy
    }
    $approverCountPolicy = az repos policy approver-count create --org $org -p $projectName --branch $branch --repository-id $repoId --blocking true --enabled true --minimum-approver-count 2 --creator-vote-counts false --reset-on-source-push true --allow-downvotes false -o json | ConvertFrom-Json
    $policies += $approverCountPolicy
    $commentPolicy = az repos policy comment-required create --org $org -p $projectName --branch $branch --repository-id $repoId --blocking true --enabled true -o json | ConvertFrom-Json
    $policies += $commentPolicy
    $workItemPolicy = az repos policy work-item-linking create --org $org -p $projectName --branch $branch --repository-id $repoId --blocking true --enabled true -o json | ConvertFrom-Json
    $policies += $workItemPolicy
    return $policies
}
