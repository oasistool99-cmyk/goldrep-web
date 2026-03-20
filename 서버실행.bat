@echo off
chcp 65001 >nul 2>nul
title GoldERP Pro 로컬 서버
echo.
echo  ============================================
echo    GoldERP Pro 로컬 서버
echo  ============================================
echo.
echo  잠시만 기다려주세요...
echo.

:: PowerShell로 간단한 웹서버 실행 (Python/Node 불필요!)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process 'http://localhost:8080/login.html'; ^
   $listener = New-Object System.Net.HttpListener; ^
   $listener.Prefixes.Add('http://localhost:8080/'); ^
   $listener.Start(); ^
   Write-Host ''; ^
   Write-Host '  [성공] 서버가 시작되었습니다!'; ^
   Write-Host ''; ^
   Write-Host '  브라우저에서 접속하세요:'; ^
   Write-Host '  http://localhost:8080/login.html'; ^
   Write-Host ''; ^
   Write-Host '  종료하려면 Ctrl+C 또는 이 창을 닫으세요.'; ^
   Write-Host '  ============================================'; ^
   $basePath = (Get-Location).Path; ^
   $mimeTypes = @{'.html'='text/html;charset=utf-8'; '.js'='application/javascript;charset=utf-8'; '.css'='text/css;charset=utf-8'; '.json'='application/json;charset=utf-8'; '.sql'='text/plain;charset=utf-8'; '.md'='text/plain;charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg'; '.ico'='image/x-icon'}; ^
   while ($listener.IsListening) { ^
     $context = $listener.GetContext(); ^
     $url = $context.Request.Url.LocalPath; ^
     if ($url -eq '/') { $url = '/login.html' }; ^
     $filePath = Join-Path $basePath ($url -replace '/', '\'); ^
     if (Test-Path $filePath -PathType Leaf) { ^
       $ext = [System.IO.Path]::GetExtension($filePath).ToLower(); ^
       $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { 'application/octet-stream' }; ^
       $context.Response.ContentType = $contentType; ^
       $context.Response.Headers.Add('Access-Control-Allow-Origin', '*'); ^
       $bytes = [System.IO.File]::ReadAllBytes($filePath); ^
       $context.Response.OutputStream.Write($bytes, 0, $bytes.Length); ^
     } else { ^
       $context.Response.StatusCode = 404; ^
       $msg = [System.Text.Encoding]::UTF8.GetBytes('Not Found'); ^
       $context.Response.OutputStream.Write($msg, 0, $msg.Length); ^
     }; ^
     $context.Response.Close(); ^
   }"

pause
