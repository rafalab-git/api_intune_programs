# Definir o nome da tarefa agendada a ser verificada
$taskName = "WenzPostScript"

# Função para verificar se a tarefa agendada existe
function Check-TaskExists {
    try {
        # Tenta obter a tarefa agendada
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        return $true  # Retorna verdadeiro se a tarefa for encontrada
    } catch {
        return $false  # Retorna falso se a tarefa não for encontrada
    }
}

# Verifica se a tarefa agendada existe
$taskExists = Check-TaskExists

# Comportamento para Intune (detecção do aplicativo Win32):
# 0 indica que a tarefa existe e o aplicativo está instalado corretamente.
# 1 indica que a tarefa não existe e o aplicativo está fora de conformidade ou não foi instalado corretamente.
if ($taskExists) {
    Write-Host "Tarefa agendada '$taskName' encontrada. Status: Aplicativo instalado."
    exit 0  # Tarefa encontrada, o aplicativo está instalado
} else {
    Write-Host "Tarefa agendada '$taskName' não encontrada. Status: Aplicativo não instalado."
    exit 1  # Tarefa não encontrada, o aplicativo não foi instalado corretamente
}
