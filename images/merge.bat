@echo off
REM ============================================================================
REM OmniAI 배포 이미지 복원 — Windows cmd
REM
REM 사용:
REM   merge.bat              모두 복원 (server + worker)
REM   merge.bat server       omniai-server 만
REM   merge.bat worker       rag-pipeline 만
REM ============================================================================
setlocal enabledelayedexpansion
cd /d %~dp0

set target=%~1
if "%target%"=="" set target=all

if /i "%target%"=="server" goto :do_server
if /i "%target%"=="worker" goto :do_worker
if /i "%target%"=="all"    goto :do_all
echo usage: %~nx0 [server^|worker^|all]
exit /b 1

:do_server
call :merge omniai-server-latest
goto :end

:do_worker
call :merge rag-pipeline-latest
goto :end

:do_all
call :merge omniai-server-latest
call :merge rag-pipeline-latest
goto :end

:merge
set name=%~1
set tar=%name%.tar

dir /b %name%.tar.part-* >nul 2>&1
if errorlevel 1 (
    echo [skip] no parts for %name%
    exit /b 0
)

echo [merge] %name% - combining parts...
copy /b /y %name%.tar.part-* "%tar%" >nul

echo [docker load] %tar%
docker load -i "%tar%"

del /q "%tar%"
echo [done] %name%
echo.
exit /b 0

:end
echo === loaded images ===
docker images | findstr /R "omniai/omniai-server omniai/rag-pipeline"
endlocal
