######################################
#Script feito por Marcelo Biegelmeyer#
######################################

#!/bin/bash

substitui="#substitui"

substituiwhite="#whitesub"

opcao=9


while [ $opcao -ne 5 ]; do


echo ""
echo "####################################"
echo "#       Alimentador de SPAM        #"
echo "#        ViaWeb Informatica        #"
echo "####################################"
echo ""
echo "0-White list"
echo "1-Dominio"
echo "2-Capeta"
echo "3-Dominio Acess"
echo "4-Dominio Sender"
echo "5-Sair"
echo ""
read opcao


if [ $opcao = "0" ];then

    echo "Dominio"
    read dominiowhite
    echo "Pontuacao"
    read white

    grep $dominiowhite /etc/amavisd/amavisd.conf > /dev/null

        if [ $? -eq 0 ];then
            echo "DOMINIO JA EXISTENTE"
    else
            sed -i "s/#whitesub/     '$dominiowhite'                 =>  "-"$white,\n$substituiwhite/g" /etc/amavisd/amavisd.conf
        fi

elif [ $opcao = "1" ];then

    echo "Dominio"
    read dominio
    echo "Pontuacao"
    read pontos

    grep $dominio /etc/amavisd/amavisd.conf > /dev/null

        if [ $? -eq 0 ];then
            echo "DOMINIO JA EXISTENTE"
    else
            sed -i "s/#substitui/     '$dominio'                 =>  $pontos,\n$substitui/g" /etc/amavisd/amavisd.conf
        fi

elif [ $opcao = "2" ];then

    echo "Palavra"
    read palavra

    grep $palavra /etc/mail/spamassassin/local.cf > /dev/null

        if [ $? -eq 0 ];then
                echo "PALAVRA JA EXISTENTE"
        else
                sed -i "s/substituicaodecapeta/$palavra|substituicaodecapeta/g" /etc/mail/spamassassin/local.cf
        fi

elif [ $opcao == "4" ];then
    echo "Nao esquece de adicionar OK ou REJECT"
    echo "Dominio Sender"
    read dominio_sender
    grep "$dominio_sender" /etc/postfix/sender_access > /dev/null

        if [ $? -eq 0 ];then
                echo "DOMINIO JA EXISTENTE"
        else
                sed -i "s/#substituidominio/$dominio_sender \n#substituidominio/g" /etc/postfix/sender_access
        fi

elif [ $opcao == "3" ];then
    echo "Nao esquece de adicionar OK ou REJECT"
    echo "Dominio Acess"
    read dominio_acess

    grep "$dominio_acess" /etc/postfix/client_access > /dev/null

        if [ $? -eq 0 ];then
                echo "DOMINIO JA EXISTENTE"
        else
                sed -i "s/#substituidominio/.$dominio_acess \n#substituidominio/g" /etc/postfix/client_access
        fi
fi

done

postmap /etc/postfix/sender_access
postmap /etc/postfix/client_access
systemctl restart amavisd
