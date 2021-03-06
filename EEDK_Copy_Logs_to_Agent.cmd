::@echo off
:: Version 1.0.1
::     .AUTHORS
::        steen_pedersen@ - 2022
:: Copy the ENS, Solidcore and MDE logs to the Agent folder 
:: so they can be pulled from ePO use the "Single System Troubleshooting"
:: This script is intented to be deployed from ePO using and EEDK package
:: Script can also be used as an EDR reaction
:: Note: The Agent Self Protection has to be disabled while the copy is performed
::
pushd "%~dp0"
setlocal ENABLEEXTENSIONS
setlocal EnableDelayedExpansion
:: Set the ISO Date to yyyymmddhhmmss using wmic
:: this is not possible using %date% as the format can be different based on date settings
for /F "tokens=2 delims==." %%I in ('wmic os get localdatetime /VALUE') do set "l_MyDate=%%I"
set ISO_DATE_TIME=%l_MyDate:~0,14%
set l_EEDK_Debug_log=%temp%\EEDK_Debug.log
echo %ISO_DATE_TIME% >>!l_EEDK_Debug_log!
set l_results=Logs_copied_to_Agent_Logs_%ISO_DATE_TIME%
:: ################################################
:: Must use ProgramW6432 as the ProgramFiles will point to C:\Program Files (x86) 
:: when The Agent (32bit) is executing the script
:: ################################################
::echo !ProgramW6432! >>%temp%\EEDK_Debug.log 2>>&1
set l_copy_from_ENS="%programdata%\McAfee\Endpoint Security\Logs\*.*" 
set l_copy_from_SOLIDCORE1="%programdata%\McAfee\Solidcore\Logs\s3diag.log" 
set l_copy_from_SOLIDCORE2="%programdata%\McAfee\Solidcore\Logs\solidcore.log" 
set l_copy_from_MDE="%ProgramW6432%\McAfee\Endpoint Encryption Agent\MdeEpe.log" 
set l_copy_destination="%programdata%\McAfee\Agent\logs"
echo !l_copy_from_ENS!
echo !l_copy_destination!
copy !l_copy_from_ENS! !l_copy_destination! 1>>!l_EEDK_Debug_log! 2>>&1
if exist !l_copy_from_SOLIDCORE1! (
copy !l_copy_from_SOLIDCORE1! !l_copy_destination! 1>>!l_EEDK_Debug_log! 2>>&1
) else (
Echo File not found: !l_copy_from_SOLIDCORE1! 1>>!l_EEDK_Debug_log! 2>>&1   
)
if exist !l_copy_from_SOLIDCORE2! (
copy !l_copy_from_SOLIDCORE2! !l_copy_destination! 1>>!l_EEDK_Debug_log! 2>>&1
) else (
Echo File not found: !l_copy_from_SOLIDCORE2! 1>>!l_EEDK_Debug_log! 2>>&1   
)
if exist !l_copy_from_MDE! (
copy !l_copy_from_MDE! !l_copy_destination! 1>>!l_EEDK_Debug_log! 2>>&1
) else (
Echo File not found: !l_copy_from_MDE! 1>>!l_EEDK_Debug_log! 2>>&1   
)
:: ---------------------------
:: Find path to McAfee Agent
::Read information from 64 bit
set KEY_NAME0=HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Network Associates\ePolicy Orchestrator\Agent
set VALUE_NAME0=Installed Path
FOR /F "skip=2 tokens=1,3*" %%A IN ('REG QUERY "%KEY_NAME0%" /v "%VALUE_NAME0%" 2^>nul') DO (set agent_path=%%C)
if [!agent_path!] == [] goto :Read_32_bit_information
::set Value1=%agent_path%\..\
::set agent_path=!Value1!
set agent_path=!agent_path!\..\
GOTO :Value_is_set
 
:Read_32_bit_information
set KEY_NAME0=HKEY_LOCAL_MACHINE\SOFTWARE\Network Associates\ePolicy Orchestrator\Agent
set VALUE_NAME0=Installed Path
FOR /F "skip=2 tokens=1,3*" %%A IN ('REG QUERY "%KEY_NAME0%" /v "%VALUE_NAME0%" 2^>nul') DO (set agent_path=%%C)
if [!agent_path!] == [] goto :no_value
:: --------------------------- 
  
:Value_is_set
:: Write results to Custom Props
::echo agent_path
::echo Agent Location: %agent_path%
::DEBUG TEST
::set l_results=Status method
%comspec% /c ""!agent_path!\maconfig.exe" -custom -prop8 "!l_results!""
%comspec% /c "%agent_path%\cmdagent.exe" -p
 
goto end_of_file
 
:no_value
echo No reg Value found
 
:end_of_file
:: Exit and pass proper exit to agent

popd
Exit /B 0