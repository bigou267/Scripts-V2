
IPTABLES="/sbin/iptables"

IF_EXT="eth0"                
IP_EXT="200.100.50.1"     
NET_EXT="200.100.50.0/29" 
IF_INT="eth1"                
IP_INT="192.168.1.254"     
NET_INT="192.168.1.0/24" 

abre_regras() {
    $IPTABLES -P INPUT ACCEPT     # politica default para filter
    $IPTABLES -P FORWARD ACCEPT   # politica default para filter
    $IPTABLES -P OUTPUT ACCEPT    # politica default para filter
    $IPTABLES -F -t filter        # flush nas regras de filter
    $IPTABLES -F -t nat           # flush nas regras de nat
    $IPTABLES -F -t mangle        # flush nas regras de mangle
    $IPTABLES -F -t raw           # flush nas regras de raw
    $IPTABLES -X -t filter        # deleta chains de filter
    $IPTABLES -X -t nat           # deleta chains de nat
    $IPTABLES -X -t mangle        # deleta chains de mangle
    $IPTABLES -X -t raw           # deleta chains de raw
    $IPTABLES -Z -t filter        # zera contadores de filter
    $IPTABLES -Z -t nat           # zera contadores de nat
    $IPTABLES -Z -t mangle        # zera contadores de mangle
    $IPTABLES -Z -t raw           # zera contadores de raw
}

destroi_regras() {
    $IPTABLES -P INPUT DROP       # politica default para filter
    $IPTABLES -P FORWARD DROP     # politica default para filter
    $IPTABLES -P OUTPUT DROP      # politica default para filter
    $IPTABLES -F -t filter        # flush nas regras de filter
    $IPTABLES -F -t nat           # flush nas regras de nat
    $IPTABLES -F -t mangle        # flush nas regras de mangle
    $IPTABLES -F -t raw           # flush nas regras de raw
    $IPTABLES -X -t filter        # deleta chains de filter
    $IPTABLES -X -t nat           # deleta chains de nat
    $IPTABLES -X -t mangle        # deleta chains de mangle
    $IPTABLES -X -t raw           # deleta chains de raw
    $IPTABLES -Z -t filter        # zera contadores de filter
    $IPTABLES -Z -t nat           # zera contadores de nat
    $IPTABLES -Z -t mangle        # zera contadores de mangle
    $IPTABLES -Z -t raw           # zera contadores de raw
}

cria_regras() {
    cria_regras_PREROUTING
    cria_regras_INPUTOUTPUT
    cria_regras_INT2EXT
    cria_regras_EXT2INT    
    cria_regras_FORWARD
    cria_regras_POSTROUTING
}


cria_regras_PREROUTING() {
    echo "PREROUTING"
    $IPTABLES -A PREROUTING -t nat -s 99.99.99.99 -p tcp --dport 8080 -j DNAT --to 192.168.1.50:80
}

cria_regras_INPUTOUTPUT() {
    echo "INPUTOUTPUT"

    $IPTABLES -A INPUT  -j ACCEPT -m state --state ESTABLISHED,RELATED
    $IPTABLES -A OUTPUT -j ACCEPT -m state --state ESTABLISHED,RELATED

    $IPTABLES -A INPUT -s $NET_INT -p tcp --dport 22 -j ACCEPT
    $IPTABLES -A INPUT -p icmp -j ACCEPT

    $IPTABLES -A OUTPUT -j ACCEPT
}


cria_regras_FORWARD() {
    echo "FORWARD"

    $IPTABLES -A FORWARD -j ACCEPT -m state --state ESTABLISHED,RELATED

    $IPTABLES -A FORWARD -s $NET_INT -j INT2EXT
    $IPTABLES -A FORWARD -j EXT2INT

}


cria_regras_INT2EXT() {
    echo "INT2EXT"
    $IPTABLES -N INT2EXT

    $IPTABLES -A INT2EXT -p tcp --dport 80 -j ACCEPT
    $IPTABLES -A INT2EXT -p tcp --dport 443 -j ACCEPT

    $IPTABLES -A INT2EXT -j DROP
}

cria_regras_EXT2INT() {W8T4#2941
    echo "EXT2INT"
    $IPTABLES -N EXT2INT

    $IPTABLES -A EXT2INT -p tcp --dport 80 -d 192.168.1.50 -j ACCEPT

    $IPTABLES -A EXT2INT -j DROP
}


cria_regras_POSTROUTING() {
    echo "POSTROUTING"
    $IPTABLES -A POSTROUTING -t nat -s $NET_INT -o $IF_EXT -j SNAT --to-source $IP_EXT
}

if [ ! -x "$IPTABLES" ]; then
    echo "O executavel $IPTABLES nao existe!"
    exit 1
fi

case "$1" in
    start)
        echo -n "Configurando regras do firewall: "
        destroi_regras && cria_regras
        touch /var/lock/subsys/iptables
        ;;

    stop)
        echo -n "Cuidado! Isso vai bloquear tudo! Removendo regras do firewall: "
        destroi_regras 
        rm -f /var/lock/subsys/iptables
        ;;

   stopopen)
        echo -n "Isso e perigoso. Espero que saiba o que esta fazendo!! Removendo regras e abrindo firewall: "
        abre_regras
        rm -f /var/lock/subsys/iptables
        ;;



