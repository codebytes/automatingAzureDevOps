# automatingAzureDevOps
Scripts for Automating Azure DevOps

To scaffold out a project in an org:
1) clone repo
2) from the scaffoldProject folder
   1) edit the org_details.txt file with information for your organization
   2) install the azure cli
   3) install the azure cli devops extension
   4) login (azure devops login)
   5) run .\scaffolding.ps1 .\org_details.txt

to cleanup:
1) .\cleanupProject.ps1 .\org_details.txt

