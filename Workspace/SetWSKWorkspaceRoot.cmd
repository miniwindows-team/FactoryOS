@ECHO OFF
IF NOT DEFINED WSKContentRoot GOTO ERROR
SET WSKWorkspaceRoot=%~dp0
IF %WSKWorkspaceRoot:~-1%==\ SET WSKWorkspaceRoot=%WSKWorkspaceRoot:~0,-1%
SET OEMInputFileName=%~1
CD /d %~dp0
CALL:SetWSKOEMInputFileName
ECHO WSKWorkspaceRoot is now %WSKWorkspaceRoot%
GOTO EOF

REM Set the OEM Input file based on the corresponding XML configuration file.
REM If the user provides the path to the OEM input file to be used, it will be set.
REM Otherwise, if there is only a single XML Configuration file, automatically assumes that there is only one OEM input file, and choose that.
REM If there are more than one XML configuration file, then user should choose the OEM input file.
REM If no configuration file found the script will recreate the base configuration file based on the provided OEMInput file and architecture by OEM's.
:SetWSKOEMInputFileName
SETLOCAL EnableDelayedExpansion
SET /A FileCount=0

REM Count the number of XML files which ends with "_configuration.xml". These are the configuration files for each OEM input file.
FOR  %%G in ("*_Configuration.xml") DO (
	SET /A FileCount=FileCount + 1

	IF !FileCount! GTR 1 (
		REM If there are more than one configuration file, user should decide  which OEM input should be used.
		GOTO EvaluateFileCount
	)

	SET OEMInputConfigurationFileName=%%~nxG
)

:EvaluateFileCount
IF "%OEMInputFileName%"=="" (
	IF !FileCount! EQU 0 (
		ECHO Failed to find the Configuration file at !WSKWorkspaceRoot!.
		SET OEMInputFileName=
		powershell.exe Import-Module "'%WSKContentRoot%\Tools\Scripts\WSKScripts.psm1'"; Confirm-BaseConfiguration -BaseConfigurationFilePath $null 
		for /F "delims=" %%I in ('call powershell -executionpolicy bypass -command "&{[Environment]::GetEnvironmentVariable('_WSKOEMInputFileName','User')}"') do set OEMInputFileName=%%I
	) ELSE IF !FileCount! EQU 1 (
		SET OEMInputFileName=!OEMInputConfigurationFileName:_configuration.xml=.xml!
	) ELSE IF !FileCount! GTR 1 (
		SET /P "OEMInputFileName=Please enter the OEMInput file name:"
	)
)

IF NOT DEFINED OEMInputFileName (
	ECHO The OEMInput file name is required.
	SET OEMInputFileName=
) ELSE IF NOT EXIST !OEMInputFileName! (
	ECHO OEMInput file: !OEMInputFileName! does not exist.
	SET OEMInputFileName=
) ELSE (
	ECHO The WSKOEMInputFileName variable sets to !OEMInputFileName!
)

ENDLOCAL & SET WSKOEMInputFileName=%OEMInputFileName%
EXIT /B

:ERROR
	ECHO WSKContentRoot is not SET! Run LauchBuildEnv.bat from the WSK first.
:EOF
