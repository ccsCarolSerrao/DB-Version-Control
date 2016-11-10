
$settingFile    = [xml](Get-Content .\globalConfig.xml)
$serverName     = $settingFile.SelectSingleNode('setting/db-conn/ServerName').innerxml
$dataBaseName   = $settingFile.SelectSingleNode('setting/db-conn/DataBaseName').innerxml
$userName       = $settingFile.SelectSingleNode('setting/db-conn/UserName').innerxml
$password       = $settingFile.SelectSingleNode('setting/db-conn/Password').innerxml
$scriptPath     = $settingFile.SelectSingleNode('setting/script/path').innerxml

$scriptVersion
$scriptId

#region Querys para execução
$queryCreate= "BEGIN TRANSACTION
                BEGIN TRY
                IF (SELECT object_id ('tempdb..#CCS_DATABASE_VERSION')) IS NULL 
                    BEGIN
                        CREATE TABLE CCS_DATABASE_VERSION (ID_Version INT NOT NULL, 
                                                          ID_Script INT NOT NULL, 
                                                          MM_Script VARCHAR(MAX), 
                                                          /*MM_ScriptContent VARCHAR(MAX),*/
                                                          DT_Script DATETIME,
                                                          CONSTRAINT Version_Script UNIQUE (ID_Version,ID_Script))
                    END
               	COMMIT TRANSACTION
                END TRY
                BEGIN CATCH
                    ROLLBACK TRANSACTION
                END CATCH"
#endregion

#region Create version tables if not exists
try
{

        Push-Location
        
        Invoke-Sqlcmd -Query "$queryCreate" -ServerInstance $serverName -Database $dataBaseName -Username $userName -Password $password -QueryTimeout 0
                
        Pop-Location 
}
catch
{
        Write-Host "[ERRO] - " $_.Exception.ToString()
        Throw
}
#endregion

Get-ChildItem $scriptPath -Filter *.sql | 
Foreach-Object {

    try
    {
        $content = [string](Get-Content $_.FullName)
        $fileName = $_.Name
        $file = $_.FullName
        Write-Host "Executanto Script - " $frile

        #region Verify if the script version alredy exists in DataBade
        $scriptVersion = $fileName.Split('.')[0]
        $scriptId = $fileName.Split('.')[1]

        $queryExist=("SELECT COUNT(*) FROM CCS_DATABASE_VERSION WHERE ID_Version = {0} AND ID_Script = {1}" -f $ScriptVersao, $ScriptId)
                
        $count = Invoke-Sqlcmd -Query "$queryExist" -ServerInstance $serverName -Database $dataBaseName -Username $userName -Password $password -QueryTimeout 0
        #Write-Host $count.Column1
        #endregion

        If($count.Column1 -eq 0)
        {
            Push-Location
        
            Invoke-Sqlcmd -InputFile "$file" -ServerInstance $serverName -Database $dataBaseName -Username $userName -Password $password -QueryTimeout 0
            
            
            Pop-Location 

            $queryInsert= ("INSERT INTO CCS_DATABASE_VERSION VALUES ({0}, {1}, '{2}', GETDATE())" -f  $scriptVersion,$scriptId,$NomeArquivo)
            Invoke-Sqlcmd -Query "$queryInsert" -ServerInstance $serverName -Database $dataBaseName -Username $userName -Password $password-QueryTimeout 0    
            
            Write-Host "[OK] - SUCCESSFUL (Script Executado com Sucesso!)"
        }
        Else
        {
            Write-Host "[OPS] - Version and Scripts alredy in DataBase (VERSÃO E SCRIPT JÁ CADASTRADOS) - " $fileName
        }
    }
    catch
    {
        Write-Host "[ERROR] - " $_.Exception.ToString()
        break
    }
}
