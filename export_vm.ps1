########################################  
## BACKUP DAS MAQUINAS VIRTUAIS       ##
## HYPER-V                            ##
########################################

############## PARÂMETROS ##############

$pastaBase = "F:\" #deve terminar com "\"
$diasAManter = 3;

#$maquinasAIgnorar = ''

$eMailDe = 'EMPRESA | SRVHIPERV <notificacao@introduceti.com.br>'
$eMailPara = 'backup@introduceti.com.br'
$AssuntoMail = 'EMPRESA | Hyper-V Backup'
$servidorSMTP = 'smtp.gmail.com'
$portaSMTP = 587
$pwd = ConvertTo-SecureString "j!yQc&b_oe!oxDWGkKKg2gJF" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential notificacao@introduceti.com.br,$pwd
########################################

## Configurando demais variáveis...
$dataInicio = (Get-Date).AddDays(-1 * $diasAManter);
$pastaVM = "$($pastaBase)VMs\";
$pastaLogs = "$($pastaBase)Logs\";
$arqLogList = "$($pastaLogs)list.log"
$arqLogBackUp = "$($pastaLogs)backup.log"
$arqLogVMs = "$($pastaLogs)VMs.log"
$arqLogScript = "$($pastaBase)Logs\errorlog.log";
$pastaVMComData = "$($pastaVM)$(get-date -f yyyy-MM-dd)\"

# Apagando e criando o log do script
cls;
if (Test-Path $arqLogScript) { Remove-Item $arqLogScript -Force -ErrorAction Ignore; }
Start-Transcript -Path $arqLogScript;

# Criando a pastaVM
if (!(Test-Path $pastaVM)) { New-Item $pastaVM -ItemType Directory; }
Set-Location $pastaVM;

# Deletando pastas mais antigas que o $dataInicio
Get-ChildItem -Path $pastaVM -Recurse | Where-Object {$_.PSIsContainer -and $_.CreationTime -lt $dataInicio } | Remove-Item -Force -Recurse

# Deletando diretorios vazios após exclusao dos arquivos
Get-ChildItem -Path $pastaVM -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse			
		
## Criando pastas necessárias
if (Test-Path $pastaLogs) { 
    ## Deletando logs antigos
    if (Test-Path $arqLogList  ) { Remove-Item $arqLogList;   }
    if (Test-Path $arqLogBackUp) { Remove-Item $arqLogBackUp; }
    if (Test-Path $arqLogVMs   ) { Remove-Item $arqLogVMs;    }    
}
else {
    New-Item $pastaLogs -ItemType Directory;
}


if (!(Test-Path $pastaVMComData)) { New-Item $pastaVMComData -ItemType Directory; }

# Setting a variable to get a list of all the VMs running on the host
$listaVMs = Get-VM -ComputerName $env:COMPUTERNAME

## Registra no Log inicio do Backup
$horarioInicioBackup = Get-Date -uformat "%d-%m-%Y %H:%M:%S"
Add-Content $arqLogBackUp "$horarioInicioBackup :: Iniciando Backup"
Add-Content $arqLogBackUp " "

foreach ($vm in [array] $listaVMs)
{
    $nomeVM = $vm.VMName
	
	if ($maquinasAIgnorar -contains $nomeVM) {
		Add-Content $arqLogBackUp "Ignorando maquina virtual $nomeVM..."
	}
	else {
		## Registra no Log inicio do Backup
		$horarioInicioExportacao = Get-Date -uformat "%d-%m-%Y %H:%M:%S"
		Add-Content $arqLogBackUp "$horarioInicioExportacao :: $nomeVM : Exportacao Iniciada"

		if ($vm.State -eq "running") {
			Save-VM   -VM $vm;
			Export-VM -VM $vm -Path $pastaVMComData;
			Start-VM  -VM $vm;
		}
		else {
			Export-VM $vm -Path $pastaVMComData;
		}

		## Registra Fim da exportacao
		$horarioTerminoExportacao = Get-Date -uformat "%d-%m-%Y %H:%M:%S"
		Add-Content $arqLogBackUp "$horarioTerminoExportacao :: $nomeVM : Exportacao completa"
		Add-Content $arqLogBackUp " "
	}
}	

## Registra Fim do backup
$horarioTerminoBackup = get-date -uformat "%d-%m-%Y %H:%M:%S"
Add-Content $arqLogBackUp "$horarioTerminoBackup :: Backup Finalizado"
Add-Content $arqLogBackUp ""

# Listagem de backups
Set-Location $pastaVM
Get-ChildItem -Path $pastaVMComData -Directory | Where-Object { $_.PSIsContainer } | ForEach-Object { $_.FullName } | Out-File $arqLogList

## Verifica tamanho pasta backup
Add-Content $arqLogBackUp "Análise dos dados:"
Add-Content $arqLogBackUp ""

foreach($vm in [array] $listaVMs) {
    $tamanhoGB = '<erro>';
    $tamanhoGB = "{0:N2}" -f ((Get-ChildItem "$pastaVMComData$($vm.Name)" -Recurse -Force | Measure-Object -Property Length -Sum ).Sum / 1GB);
    Add-Content $arqLogBackUp "Tamanho da pasta da VM <b>$($vm.Name)</b> $tamanhoGB GB";
}

Add-Content $arqLogBackUp ""
Add-Content $arqLogBackUp ""

foreach($diretorio in (Get-ChildItem $pastaVM -Directory)) {
    $tamanhoGB = '<erro>';
    $tamanhoGB = "{0:N2}" -f ( ( Get-ChildItem "$($diretorio.FullName)" -Recurse -Force | Measure-Object -Property Length -Sum ).Sum / 1GB)
    Add-Content $arqLogBackUp "Tamanho da pasta do dia <i>$($diretorio.Name)</i> <b>$tamanhoGB</b> GB"
}
$tamanhoGB = '<erro>';
$tamanhoGB = "{0:N2}" -f ( ( Get-ChildItem F: -Recurse -Force | Measure-Object -Property Length -Sum ).Sum / 1TB)
Add-Content $arqLogBackUp " "
Add-Content $arqLogBackUp "Utilizacao da unidade de backup F: <b>$tamanhoGB</b> TB de <b>4TB</b>"

##Obtendo informações das Máquinas VIRTUAIS
Get-VM | Format-List | Out-File $arqLogVMs;

Stop-Transcript

##Enviando Email 

$file1 = (Get-Content $arqLogBackUp) -join '<BR>';
$file2 = (Get-Content $arqLogList) -join '<BR>';
$file3 = (Get-Content $arqLogVMs) -join '<BR>';
$body =
"<br><br><font size=3><FONT COLOR=18a19a><b>Backup Hyper-V, verificar log abaixo:</b></font></font><br><br>
$file1<br><br>
<b>Listagem de backups existentes:</b><br><br>
$file2<br><br>
<b>Informacoes das maquinas virtuais pos-backup: </b><br>
$file3<br><br>
<b>Verifique o arquivo em anexo para eventuais erros</b><br>"


foreach($destinatario in $eMailPara) {
    $param = @{
        SmtpServer = $servidorSMTP
        Port = $portaSMTP
		UseSsl = $true
		Credential = $cred
        From = $eMailDe
        To = $destinatario
        Subject = $AssuntoMail
        Attachments = $arqLogScript
    }
 
    Send-MailMessage @param -Body $body -BodyAsHtml
}
