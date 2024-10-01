# Parte 1: Script para download e descompactação

# Caminhos e URL
$url = "https://viniciusm23.sg-host.com/executaveis/assistview/WenzPostScript.zip"
$destinationPath = "C:\ProgramData"
$executablePath = "$destinationPath\WenzPostScript\userassistview"
$logFile = "$destinationPath\loginstallWenzPostScript.txt"
$csvFilePath = "$executablePath\programs.csv"

# Função para executar o comando e gerar o CSV
function Execute-Command {
    Write-Host "Executando UserAssistView.exe para gerar o CSV..."
    Write-Log "Executando UserAssistView.exe para gerar o CSV..."
    $command = "$executablePath\UserAssistView.exe /scomma $csvFilePath"
    Invoke-Expression $command
    Start-Sleep -Seconds 5
    Write-Log "Comando executado com sucesso, CSV gerado."
}



# Função para escrever no log
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
}

# Cria diretório se não existir
if (-Not (Test-Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory
    Write-Log "Diretório $destinationPath criado."
}

# Função para verificar se o arquivo já existe e, caso contrário, baixar
function Check-And-Download {
    if (-Not (Test-Path $executablePath)) {
        Write-Log "UserAssistView.exe não encontrado. Iniciando download..."
        
        # Baixa o arquivo ZIP
        $zipPath = "$destinationPath\WenzPostScript.zip"
        try {
            Invoke-WebRequest -Uri $url -OutFile $zipPath
            Write-Log "Arquivo baixado com sucesso em $zipPath."
            
            # Descompacta o arquivo baixado
            Expand-Archive -Path $zipPath -DestinationPath $destinationPath -Force
            Write-Log "Arquivo descompactado com sucesso."

            # Remove o arquivo ZIP após a extração
            Remove-Item $zipPath
            Write-Log "Arquivo ZIP removido."
        } 
        catch {
            Write-Log "Erro ao baixar ou descompactar o arquivo: $_"
            throw $_
        }
    } else {
        Write-Log "UserAssistView.exe já existe. Pulando download."
    }
}

function Create-Task {
    # Defina os parâmetros da tarefa
    $taskName = "WenzPostScript"
    $scriptPath = "C:\ProgramData\WenzPostScript\scripts\post_script.ps1"
    # Verifica se o script de POST já existe
    if (-Not (Test-Path $scriptPath)) {
        Write-Log "O script de POST não foi encontrado. Verifique se ele foi criado corretamente."
        exit
    }

    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        <# Action when all if and elseif conditions are false #>
        Write-Log "Tarefa agendada ja existe: $taskName"
        Write-Host "Tarefa agendada ja existe !"
    }

    catch {
        # Adiciona log sobre a tentativa de criar a tarefa agendada
        Write-Log "Iniciando criação da tarefa agendada: $taskName"



        # Define o gatilho para executar a cada hora
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)

        # Usa o usuário atual para executar a tarefa sem privilégios elevados
        #$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

        # Define a ação que será tomada (executar o script com PowerShell sem janela)
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
        # # Define a ação que será tomada (executar o script com PowerShell)
        # $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`"" 

        # Cria a tarefa agendada
        try {
            Register-ScheduledTask -TaskName $taskName -Trigger $trigger  -Action $action -ErrorAction Stop
            Write-Log "Tarefa agendada criada com sucesso: $taskName"
            Write-Host "Tarefa agendada criada com sucesso!"
        } catch {
            $errorMessage = "Erro ao criar a tarefa agendada: $_"
            Write-Log $errorMessage
            Write-Host $errorMessage
        }
    }
}





# Inicia o processo
Check-And-Download
# Adjust-Permissions
Execute-Command
Create-Task
Write-Log "Download e permissões ajustadas com sucesso."
