param (
       [parameter(Mandatory=$True,Position=1)][string][ValidateNotNullOrEmpty()]$InputFolder,
       [parameter(Mandatory=$True,Position=2)][string][ValidateNotNullOrEmpty()]$DBUserName,
       [parameter(Mandatory=$True,Position=3)][string][ValidateNotNullOrEmpty()]$DBPwd,
       [parameter(Mandatory=$True,Position=4)][string][ValidateNotNullOrEmpty()]$DBServerAndInstance,
       [parameter(Mandatory=$True,Position=5)][string][ValidateNotNullOrEmpty()]$DBName
      )
      

$ExecutionOrder = "$InputFolder\ExecutionOrder.txt"
$strCurrDir = split-path -parent $MyInvocation.MyCommand.Definition

$ObjInputFolder = Get-Item $InputFolder -Force -ErrorAction SilentlyContinue

$AllFolder = Get-ChildItem $InputFolder -Recurse -ErrorAction SilentlyContinue | ?{($_.psiscontainer)} -ErrorAction SilentlyContinue
$FolderCount = $null

ForEach ($Folder in $AllFolder)
{
    if ((Get-ChildItem $Folder.FullName -Recurse -Filter "*.sql" -ErrorAction SilentlyContinue ) -ne $null)
    {
        $FolderCount = $FolderCount + 1
    }
}

pushd

If (($FolderCount -ne $null) -and (Test-Path $ExecutionOrder))                          #Multiple folder having SQL files
{
    $ListOfFolder= Get-Content $ExecutionOrder
	foreach ($strFolder in $ListOfFolder)
	{
        $Folder= Get-Item "$InputFolder\$strFolder"
        $AllSqlFile = Get-ChildItem $Folder.FullName -Filter "*.sql" -Recurse

	    if ($AllSqlFile.Length -gt 0)
	    {
	        $FolderPath = $Folder.FullName
	        ForEach ($SQlFile in $AllSqlFile)
	        {
	            cd $SQlFile.Directory
                $File = $SQLFile.FullName
                Write-Output "Executing file: `"$File`""
                $Output = & sqlcmd -U $DBUserName -P $DBPwd -S $DBServerAndInstance -d $DBName -i `"$File`"
                Write-Output $Output
                if  ($output -like "*error*")
                {
                    Write-Error "Error in executing file: `"$File`".`nQuiting with error code 911."
                    popd
                    Exit 911
                }
	        }
	    }
	}
	Write-Output "Execution of databse script sccesfully quiting with exit code 0"
    popd
	Exit 0
}
ElseIf (Test-Path $ExecutionOrder)              #Assumed file order as no folder found
{
	
	$ListOfiles = Get-Content $ExecutionOrder
	ForEach ($strFile in $ListOfiles)
	{
		cd $InputFolder
		$File = Get-Item "$InputFolder\$strFile"
		Write-Output "Executing file: `"$File`""
		$Output = & sqlcmd -U $DBUserName -P $DBPwd -S $DBServerAndInstance -d $DBName -i `"$File`"
        Write-Output $Output
        if  ($output -like "*error*")
        {
            Write-Error "Error in executing file: `"$File`".`nQuiting with error code 911."
            popd
            Exit 911
        }
	}
	Write-Output "Execution of databse script sccesfully quiting with exit code 0"
    popd
	Exit 0
}
Else
{
	write-output "No order defined, Executing all files"
	$AllSqlFile = Get-ChildItem $ObjInputFolder.FullName -Filter "*.sql" -Recurse

	if ($AllSqlFile.Length -gt 0)
	{
	    $FolderPath = $ObjInputFolder.FullName
	    ForEach ($SQlFile in $AllSqlFile)
	    {
	        cd $SQlFile.Directory
            $File = $SQLFile.FullName
            Write-Output "Executing file: `"$File`""
            $Output = & sqlcmd -U $DBUserName -P $DBPwd -S $DBServerAndInstance -d $DBName -i `"$File`"
            Write-Output $Output
            if  ($output -like "*error*")
            {
                Write-Error "Error in executing file: `"$File`".`nQuiting with error code 911."
                popd
                Exit 911
            }
	    }
	}
    Write-Output "Execution of databse script sccesfully quiting with exit code 0"
    popd
	Exit 0
}
