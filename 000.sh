#!/bin/bash
apt-get update && apt-get upgrade -y
rm OpenVPN-BetaV2.0.sh
 # First thing to do is check if this machine is Debian
 source /etc/os-release
if [[ "$ID" != 'debian' ]]; then
 echo -e "[\e[1;31mError\e[0m] OS not supported, exting..." 
 exit 1
fi
 #Some workaround for OpenVZ machines for "Startup error" openvpn service
 if [[ "$(hostnamectl | grep -i Virtualization | awk '{print $2}' | head -n1)" == 'openvz' ]]; then
 sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn*
 systemctl daemon-reload
fi
 # If you're on sudo user, run `sudo su -` first before running this script
 if [[ $EUID -ne 0 ]];then
 ScriptMessage
 echo -e "[\e[1;31mError\e[0m] This script must be run as root, exiting..."
 exit 1
fi

function ip_address(){
  IP="$( ip addr | grep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  local IP
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
  [ -z "${IP}" ] && echo "${IP}" || echo
}
ip_address
IPADDR="$(ip_address)"
apt-get update && apt-get update
#Install Privoxy
function privoxy(){
  apt-get install privoxy -y
sed -i 's/[::]:8118/#[::]:8118/g' /etc/privoxy/config
sed -i 's/localhost:8118/0.0.0.0:8080/g' /etc/privoxy/config
service privoxy restart
}
privoxy
#Openvpn Port
Openvpn_Port1='110'
#Provoxy_Port
Privoxy_Port1='8080'
echo $Privoxy_Port1
Privoxy_Port2='8000'
echo $Privoxy_Port2
 # Iptables Rule for OpenVPN server
 PUBLIC_INET="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
 IPCIDR='10.200.0.0/16'
 iptables -I FORWARD -s $IPCIDR -j ACCEPT
 iptables -t nat -A POSTROUTING -o "$PUBLIC_INET" -j MASQUERADE
 iptables -t nat -A POSTROUTING -s "$IPCIDR" -o "$PUBLIC_INET" -j MASQUERADE
 # Some workaround for OpenVZ machines for "Startup error" openvpn service
 if [[ "$(hostnamectl | grep -i Virtualization | awk '{print $2}' | head -n1)" == 'openvz' ]]; then
 sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn*
 systemctl daemon-reload
fi
 # Allow IPv4 Forwarding
 sed -i '/net.ipv4.ip_forward.*/d' /etc/sysctl.conf
 echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/20-openvpn.conf
 sysctl --system &> /dev/null
 # Enabling IPv4 Forwarding
 echo 1 > /proc/sys/net/ipv4/ip_forward
# Generating openvpn dh.pem file using openssl
 openssl dhparam -out /etc/openvpn/dh.pem 1024
 # Checking if openvpn folder is accidentally deleted or purged
 if [[ ! -e /etc/openvpn ]]; then
  mkdir -p /etc/openvpn
 fi
 # Removing all existing openvpn server files
 rm -rf /etc/openvpn/*

#Install Openvpn
apt-get install openvpn -y
cp -r /usr/share/easy-rsa /etc/openvpn/
 # Getting some OpenVPN plugins for unix authentication
 #wget -qO /etc/openvpn/b.zip 'https://raw.githubusercontent.com/Bonveio/BonvScripts/master/openvpn_plugin64'
 #unzip -qq /etc/openvpn/b.zip -d /etc/openvpn
 rm -f /etc/openvpn/b.zip
#unzip server.crt.gz
gunzip /usr/share/doc/openvpn/examples/sample-keys/server.crt.gz
rm -Rf /usr/share/doc/openvpn/examples/sample-keys/server.crt.gz
#make directories
mkdir /etc/openvpn/easy-rsa/keys
#Setup CA
cat <<EOT3>> /etc/openvpn/easy-rsa/keys/ca.crt
-----BEGIN CERTIFICATE-----
MIIE6DCCA9CgAwIBAgIJAISjqDk245utMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYD
VQQGEwJQSDEWMBQGA1UECBMNTnVldmEgVml6Y2F5YTEOMAwGA1UEBxMFRHVwYXgx
ETAPBgNVBAoTCFBFUlNPTkFMMREwDwYDVQQLEwhQRVJTT05BTDEUMBIGA1UEAxML
UEVSU09OQUwgQ0ExDjAMBgNVBCkTBWlEZXJmMSUwIwYJKoZIhvcNAQkBFhZ4Zm9j
dXMubWUwMDFAZ21haWwuY29tMB4XDTIxMDIyODE3NTE1MVoXDTMxMDIyNjE3NTE1
MVowgagxCzAJBgNVBAYTAlBIMRYwFAYDVQQIEw1OdWV2YSBWaXpjYXlhMQ4wDAYD
VQQHEwVEdXBheDERMA8GA1UEChMIUEVSU09OQUwxETAPBgNVBAsTCFBFUlNPTkFM
MRQwEgYDVQQDEwtQRVJTT05BTCBDQTEOMAwGA1UEKRMFaURlcmYxJTAjBgkqhkiG
9w0BCQEWFnhmb2N1cy5tZTAwMUBnbWFpbC5jb20wggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQDGHPWgctAjH40SFKdYPUhqRQ3By7dwCKLmLcz3TfCsNJy5
uuDJ4VteBFUtbS9mcyoQu97T88OsCzzA4w7LTnU5gFiV1slOpapQwmlpOKyICosF
/5ba9dzjYEDYQAHNE1315O9zhr72pUKAOw1awyVEhKjjxiODZjCNljsMF55wgrP6
4p35LOTcXyqWBE7Cvh//80+WEudo3KwlvQORu0UKnYYuQoZQDT+EXo8wHCzacmq/
IxJnOgl00vlfJ1Mus1khkqsDocRWSSEkp1NHBASriufjJmDqiHuHnKsh/wlja6An
SbqrfZwCkCHmZrk5d84xswrfGcfXLAW5639IxPUlAgMBAAGjggERMIIBDTAdBgNV
HQ4EFgQUT/qlddonZQ1NSedOVs1K7R5zUIQwgd0GA1UdIwSB1TCB0oAUT/qlddon
ZQ1NSedOVs1K7R5zUIShga6kgaswgagxCzAJBgNVBAYTAlBIMRYwFAYDVQQIEw1O
dWV2YSBWaXpjYXlhMQ4wDAYDVQQHEwVEdXBheDERMA8GA1UEChMIUEVSU09OQUwx
ETAPBgNVBAsTCFBFUlNPTkFMMRQwEgYDVQQDEwtQRVJTT05BTCBDQTEOMAwGA1UE
KRMFaURlcmYxJTAjBgkqhkiG9w0BCQEWFnhmb2N1cy5tZTAwMUBnbWFpbC5jb22C
CQCEo6g5NuObrTAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAeAIF3
jE5N3GESiEnkqOf4VfEX5V8I1cycvYWJKbuHQLFQy1DbYW/HNYIXQy7j0VdZ3tCl
rhG4XDBXu3m6svPGRDsOpY4h9hJMJI+0c9O5iLosWcDoes3JkFIUwsB5JRZkH70n
kjwD1r974bUy96kLqvn2FnQeJYFE/M/QWBfx0HcS1sOaWidMSVepbpQJVMYZ9jVx
n2mKPwrIrH9l8Fah+RFIYwCXFoNwyBSPWzHH3Od8JKz6Q+6N1hTUEHj8TI2iyB/z
bUkl2LOZ9BkVg7hfkH+WrACZRymLXHrjePDhBRjJ57U+d4bmLr+aQz3R6aI/gTjX
LIBsEs5oIQrq435Y
-----END CERTIFICATE-----
EOT3
#Setup Server.crt
cat <<EOT5>> /etc/openvpn/easy-rsa/keys/ca.key
-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDGHPWgctAjH40S
FKdYPUhqRQ3By7dwCKLmLcz3TfCsNJy5uuDJ4VteBFUtbS9mcyoQu97T88OsCzzA
4w7LTnU5gFiV1slOpapQwmlpOKyICosF/5ba9dzjYEDYQAHNE1315O9zhr72pUKA
Ow1awyVEhKjjxiODZjCNljsMF55wgrP64p35LOTcXyqWBE7Cvh//80+WEudo3Kwl
vQORu0UKnYYuQoZQDT+EXo8wHCzacmq/IxJnOgl00vlfJ1Mus1khkqsDocRWSSEk
p1NHBASriufjJmDqiHuHnKsh/wlja6AnSbqrfZwCkCHmZrk5d84xswrfGcfXLAW5
639IxPUlAgMBAAECggEBALqZTEFz4tcyQI1nJrfWAP8XS33dg0ni2Iw1V3kX0Dhi
1buaaV+9A3HqYtAGpz63+kcIrTi1wPerHe4P7z9PBtrCKK35QGLzZxfqBZ814kvA
onFj65MRQJxpbKpCn2+pbjbNCzylDfkCb0CYXlu+srt2uBzR42FAPzsc5UDefj05
NhLG/r7X8SLVeqoOOoYq6nGCBdUQZbHZGZ3UL1sbaVIxj2zot+UZvgidKPqkqr0N
pyYGhlyRPJfJmiLjbS8pze3pWLD5skhYRofe5uM5JQ7my1dGc3JK915wxEnZmxkE
VkHXY/zqVtU7iEtOYJqnvA64pPkdxN265K2bQcUiAYECgYEA6OA6b9pIzo3WBsxm
0ce8OYmHp8Y90yKaIH4k34aJbFJNFBIJ/wg0yCkV5MX/AUkAlj5D4GZZiErzF+mu
6WFZomy1p2BhnFv9IPobkPO1HSk4SJuaZOzDY5lF9gRncikKQEFK2hk76I77uMzJ
/TaQVL3YgVEQTSzZ3MgPMOMy9fMCgYEA2ckNO8QFusH3kODNgrw2Yo/7au8xVdMS
UuRRnc8qIYWjyB0MtrvlD5ENRVKRRSydm30ZZ3kl8N54BrLs//RFr7UIQC11oBKs
BZtT9YsL+8fQdNHkD2Wwe7DcEisjLrUCBkruqYttz9p8zFb2qcrdj0G8VIeF1oUp
rEss7k/sNocCgYAefcWJAbbIvM+KQlcwHovpqLVHZXCQ5ZXyrTGcxtvVgA0xlI8U
gnmOv7prIvWZsHpQMcTna99LNi0QM3vAeQuodb1vNfJx66WAHN9hIlfTgqMo9p7H
miyXLOl5Jeh5jSAXe7UWS3mJoLca4k2MRwms3tKrU/bjc/zuqI88onL4uwKBgQCl
LJgN0RDrYPtLdURIuEijHkJ4CuunBQurtKC2CI4SmJHsTyP6X61Nzhx7jDDDfyAV
8p5W3QpKkeAEbKXVRkWoCqw0SIYinqa7JeBapVe0YQqX3yySBPUCCtQOL4tifEQJ
08EI88eYUkQ+kmJHyqWZZijZD2QRnDNMCkQMhq9HdwKBgQDI5uydra1mZMYf2MfX
WHYxDaIOTS2kSPzjHP593hgO+54RM/SeEPfwZ4n/tprNQiaj3sPS+bNwb2cUVYKV
Pa3tMAgJo6l7fJwFB7FVf4z/HHzcOeGvTU6CF1QDJ9Osmi2BZXPr7Z+2ex5C/LKj
NMd3E7BVs9RZhtlC1WHpCPpr7w==
-----END PRIVATE KEY-----
EOT5
cat <<EOF4>> /etc/openvpn/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=PH, ST=Nueva Vizcaya, L=Dupax, O=PERSONAL, OU=PERSONAL, CN=PERSONAL CA/name=iDerf/emailAddress=xfocus.me001@gmail.com
        Validity
            Not Before: Feb 28 17:51:51 2021 GMT
            Not After : Feb 26 17:51:51 2031 GMT
        Subject: C=PH, ST=Nueva Vizcaya, L=Dupax, O=PERSONAL, OU=PERSONAL, CN=server/name=iDerf/emailAddress=xfocus.me001@gmail.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:bf:ae:50:d7:cd:3c:77:90:ae:bd:36:6d:20:40:
                    82:f3:6f:c3:d1:5a:3f:21:22:eb:20:ad:13:db:c3:
                    ae:b1:39:d4:0b:ba:b9:f1:79:35:04:a7:95:65:d9:
                    38:ae:b8:b0:db:ad:d5:07:fc:f3:90:22:a4:9c:5b:
                    22:9f:81:aa:96:8f:be:5f:a7:67:86:62:31:ae:bc:
                    17:9b:9b:e7:d6:6e:15:47:3a:ce:21:67:51:3e:c8:
                    7a:40:9e:b0:8e:bb:bf:6d:c7:db:12:b5:66:31:bd:
                    4a:c1:cd:fe:fc:76:08:a1:5a:db:7b:df:5c:6c:8c:
                    d0:85:f1:d0:cd:82:0c:e8:bc:24:cd:69:6a:4f:93:
                    34:43:28:fa:a7:1c:0f:70:dd:25:c9:d4:43:6c:49:
                    03:a7:ff:c7:a6:08:92:55:36:91:98:54:cd:b2:3f:
                    6d:12:23:f0:d4:08:06:dc:94:4f:6e:b8:d8:ba:fb:
                    fe:35:b3:6b:e7:ef:35:08:93:93:99:f1:8c:9a:7d:
                    4c:33:a1:03:a6:be:fc:0c:8f:fd:09:41:18:2d:4c:
                    78:4a:ab:6c:af:82:aa:33:9f:b3:34:2c:32:2f:9a:
                    5e:71:6b:81:15:58:ff:48:a0:6d:d1:48:e7:19:77:
                    19:cc:15:09:81:78:5f:0e:96:fc:a8:5e:9d:05:33:
                    a8:f1
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Cert Type:
                SSL Server
            Netscape Comment:
                Easy-RSA Generated Server Certificate
            X509v3 Subject Key Identifier:
                2B:91:66:83:0B:A9:08:90:EC:15:30:AB:2A:F7:B9:53:51:E1:77:98
            X509v3 Authority Key Identifier:
                keyid:4F:FA:A5:75:DA:27:65:0D:4D:49:E7:4E:56:CD:4A:ED:1E:73:50:84
                DirName:/C=PH/ST=Nueva Vizcaya/L=Dupax/O=PERSONAL/OU=PERSONAL/CN=PERSONAL CA/name=iDerf/emailAddress=xfocus.me001@gmail.com
                serial:84:A3:A8:39:36:E3:9B:AD

            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Key Usage:
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name:
                DNS:server
    Signature Algorithm: sha256WithRSAEncryption
         3c:d8:48:2c:af:68:aa:f6:bc:5b:c7:83:6b:94:1b:18:a9:01:
         ce:a7:f8:13:c9:63:59:d4:82:a5:a6:6a:b5:a6:76:4e:98:69:
         25:78:f0:d9:96:33:bf:d6:32:80:b6:4e:ce:92:71:9c:57:0b:
         64:db:f8:53:f9:d8:cc:c2:fd:80:50:b7:7d:d3:aa:8f:e0:ad:
         a3:c1:46:19:70:4c:b6:1a:b1:cf:d4:8c:a0:39:89:87:2c:94:
         65:90:c9:ac:fe:b8:2f:ae:98:a7:12:8e:28:c3:c5:24:10:ea:
         09:f6:d0:97:33:77:9d:13:cf:1c:18:4e:29:a9:05:91:57:c4:
         ab:3e:82:32:44:cc:81:1d:35:2d:c7:19:c8:93:ab:fc:36:e2:
         86:fb:34:96:30:6b:e7:90:c3:74:44:9f:2e:f7:f6:a3:ae:11:
         ac:2e:a4:37:3b:53:1a:97:07:68:87:c2:da:2a:e6:16:f9:2c:
         7e:f5:c0:d1:16:d2:01:6f:54:9d:1c:08:b6:3a:79:a3:7e:86:
         83:ee:ab:de:f7:63:24:d5:c4:9b:43:b6:e3:37:20:a5:8b:b9:
         cf:13:a2:07:a9:ef:e5:e2:87:89:03:09:1c:70:3d:e6:c9:d1:
         9d:1a:9b:a7:82:82:45:08:fa:b1:5d:e4:05:d4:1a:6a:61:65:
         d2:d5:63:20
-----BEGIN CERTIFICATE-----
MIIFVjCCBD6gAwIBAgIBATANBgkqhkiG9w0BAQsFADCBqDELMAkGA1UEBhMCUEgx
FjAUBgNVBAgTDU51ZXZhIFZpemNheWExDjAMBgNVBAcTBUR1cGF4MREwDwYDVQQK
EwhQRVJTT05BTDERMA8GA1UECxMIUEVSU09OQUwxFDASBgNVBAMTC1BFUlNPTkFM
IENBMQ4wDAYDVQQpEwVpRGVyZjElMCMGCSqGSIb3DQEJARYWeGZvY3VzLm1lMDAx
QGdtYWlsLmNvbTAeFw0yMTAyMjgxNzUxNTFaFw0zMTAyMjYxNzUxNTFaMIGjMQsw
CQYDVQQGEwJQSDEWMBQGA1UECBMNTnVldmEgVml6Y2F5YTEOMAwGA1UEBxMFRHVw
YXgxETAPBgNVBAoTCFBFUlNPTkFMMREwDwYDVQQLEwhQRVJTT05BTDEPMA0GA1UE
AxMGc2VydmVyMQ4wDAYDVQQpEwVpRGVyZjElMCMGCSqGSIb3DQEJARYWeGZvY3Vz
Lm1lMDAxQGdtYWlsLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AL+uUNfNPHeQrr02bSBAgvNvw9FaPyEi6yCtE9vDrrE51Au6ufF5NQSnlWXZOK64
sNut1Qf885AipJxbIp+BqpaPvl+nZ4ZiMa68F5ub59ZuFUc6ziFnUT7IekCesI67
v23H2xK1ZjG9SsHN/vx2CKFa23vfXGyM0IXx0M2CDOi8JM1pak+TNEMo+qccD3Dd
JcnUQ2xJA6f/x6YIklU2kZhUzbI/bRIj8NQIBtyUT2642Lr7/jWza+fvNQiTk5nx
jJp9TDOhA6a+/AyP/QlBGC1MeEqrbK+CqjOfszQsMi+aXnFrgRVY/0igbdFI5xl3
GcwVCYF4Xw6W/KhenQUzqPECAwEAAaOCAYwwggGIMAkGA1UdEwQCMAAwEQYJYIZI
AYb4QgEBBAQDAgZAMDQGCWCGSAGG+EIBDQQnFiVFYXN5LVJTQSBHZW5lcmF0ZWQg
U2VydmVyIENlcnRpZmljYXRlMB0GA1UdDgQWBBQrkWaDC6kIkOwVMKsq97lTUeF3
mDCB3QYDVR0jBIHVMIHSgBRP+qV12idlDU1J505WzUrtHnNQhKGBrqSBqzCBqDEL
MAkGA1UEBhMCUEgxFjAUBgNVBAgTDU51ZXZhIFZpemNheWExDjAMBgNVBAcTBUR1
cGF4MREwDwYDVQQKEwhQRVJTT05BTDERMA8GA1UECxMIUEVSU09OQUwxFDASBgNV
BAMTC1BFUlNPTkFMIENBMQ4wDAYDVQQpEwVpRGVyZjElMCMGCSqGSIb3DQEJARYW
eGZvY3VzLm1lMDAxQGdtYWlsLmNvbYIJAISjqDk245utMBMGA1UdJQQMMAoGCCsG
AQUFBwMBMAsGA1UdDwQEAwIFoDARBgNVHREECjAIggZzZXJ2ZXIwDQYJKoZIhvcN
AQELBQADggEBADzYSCyvaKr2vFvHg2uUGxipAc6n+BPJY1nUgqWmarWmdk6YaSV4
8NmWM7/WMoC2Ts6ScZxXC2Tb+FP52MzC/YBQt33Tqo/graPBRhlwTLYasc/UjKA5
iYcslGWQyaz+uC+umKcSjijDxSQQ6gn20Jczd50TzxwYTimpBZFXxKs+gjJEzIEd
NS3HGciTq/w24ob7NJYwa+eQw3REny739qOuEawupDc7UxqXB2iHwtoq5hb5LH71
wNEW0gFvVJ0cCLY6eaN+hoPuq973YyTVxJtDtuM3IKWLuc8Togep7+Xih4kDCRxw
PebJ0Z0am6eCgkUI+rFd5AXUGmphZdLVYyA=
-----END CERTIFICATE-----
EOF4
############

cat <<EOT4>> /etc/openvpn/server.key
-----BEGIN PRIVATE KEY-----
MIIEwAIBADANBgkqhkiG9w0BAQEFAASCBKowggSmAgEAAoIBAQC/rlDXzTx3kK69
Nm0gQILzb8PRWj8hIusgrRPbw66xOdQLurnxeTUEp5Vl2TiuuLDbrdUH/POQIqSc
WyKfgaqWj75fp2eGYjGuvBebm+fWbhVHOs4hZ1E+yHpAnrCOu79tx9sStWYxvUrB
zf78dgihWtt731xsjNCF8dDNggzovCTNaWpPkzRDKPqnHA9w3SXJ1ENsSQOn/8em
CJJVNpGYVM2yP20SI/DUCAbclE9uuNi6+/41s2vn7zUIk5OZ8YyafUwzoQOmvvwM
j/0JQRgtTHhKq2yvgqozn7M0LDIvml5xa4EVWP9IoG3RSOcZdxnMFQmBeF8Olvyo
Xp0FM6jxAgMBAAECggEBAIwudq8sSLGEnVaBjFNO+rYAIexknNCmEeEm0uQg+wxf
p2UgnUYtB4os6UTAFQUqyyUNv0OFSbc6rrouqGaQ1Oohm++mpT6RZ5ZLttQ1s9qN
TYB3UDL7tV4+DbJem+72/avSwrOu+Fsd/aM4/Oczh2JB6UxxcM1uOj4LOFJjbv9w
/FXbCVLn6OeqjFzSRtOiPshlXQHENvEYRDiYkmGeNsr5iHwvXYWYe+4i0/sLXDWj
A1vuiCASNKm9CIkegAp0RgzI/rCA2eQbtpt+hW+qwWptDRxnPyF2Y/g0cT0vMY8f
T1gMlsu1bmbxN67Z8Iy6um1t+AG8njQyDQbQqCQV2dUCgYEA74GzI6wRTfz0LFO9
7Srzp1o5UClPf01gSdmGL7WkO8/aQMPSzlTgwWQG2WFQqb9L3vsBzcKfor6Bf/5L
LiwLfne5JWpJ5tYylht0RgKXmVm+JgiT0fRw5bUwbahwSeqKsvdN07qXmO9Z86EK
z+hD1lZd49B+6dJEYFME0UPfOwsCgYEAzOF9KUHC96mHiULzYAuBW+VnyM8NfUvs
PkVd1HiArhwvTlw8S03ZgDcMBmv3EuyXoXWo8uN5+Gkik3AJ2BsXgcto/Bt8Toqv
7J1V7e7SuVVS9hkcwt3HgC/fo183xZp9VsH+RuGgMVh9/v9zz4Jelzx6BRLvRyLt
2jp0OX4CSXMCgYEAv5H6e5nx7XNayungjIdChKWCGkAwuh5l2iwHTLn5N241oIAB
adAyRf2ADPft0RiV0zDqbG4zybSfWIVKFRBd0TZp/SdbHSxPIgmroyQHpj1F/p31
voXKl7GpnsyPpE/ZyPROaABjqYwpYtl5EHszZ4mFZ+co3FW3I2TEAa5MK6kCgYEA
pQAEeLGJf0N88EKHFpate4DpcIOv7XSzsgLTakYR/CaewpDtzgfIXsX2XUWeGhOI
mnPTuKkSlci2G99jTjOjXtiemEradbajr/+WMKTh+HiK87+NtjI+dTIY/c21cOLW
hoR9cEBNbvBBqJe6gSgRXeNKscNqCPRMcjAZYiPlW5kCgYEAhN8utwfoJpy0DfNh
v9VJLWEMPuBUbMMOuR119P8YArNPPx7PTXi4XzbPv7rf99lfuizXZBzmGjKqEOWH
EMtP6kaosO6oZcU6L3w8izeFqYFn+hxL9DENC11xKpCoqFkYKNkKuqghi9KIjoVt
TVxXp5vGwz5umT+nrSnjrkgO6h8=
-----END PRIVATE KEY-----
EOT4
cat <<EOF5>> /etc/openvpn/easy-rsa/keys/client.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 2 (0x2)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=PH, ST=Nueva Vizcaya, L=Dupax, O=PERSONAL, OU=PERSONAL, CN=PERSONAL CA/name=iDerf/emailAddress=xfocus.me001@gmail.com
        Validity
            Not Before: Feb 28 17:51:52 2021 GMT
            Not After : Feb 26 17:51:52 2031 GMT
        Subject: C=PH, ST=Nueva Vizcaya, L=Dupax, O=PERSONAL, OU=PERSONAL, CN=client/name=iDerf/emailAddress=xfocus.me001@gmail.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:ba:38:23:3c:29:fd:78:78:de:e1:fc:33:3e:0a:
                    01:5f:e8:ff:5d:d6:3d:ad:64:85:c0:b0:4b:1b:4b:
                    7a:86:57:b3:af:85:4a:e2:38:b3:5e:05:3a:45:1f:
                    79:d4:ac:9c:b6:1f:6c:95:c9:76:78:5e:dc:9e:0b:
                    ab:d7:53:d6:bc:0c:9d:93:13:f9:06:50:f5:3d:6c:
                    a3:52:92:b5:fd:06:d9:27:75:07:79:f5:e0:65:14:
                    b8:cf:20:12:a6:8d:13:76:48:89:4d:61:8d:3f:13:
                    c1:9d:10:66:9c:b9:08:f5:e0:e3:9d:2a:f4:50:e4:
                    0a:0b:ba:94:12:b7:8f:6c:87:d1:7c:30:d6:d7:fb:
                    c0:b6:22:00:54:80:09:8e:a0:d8:fb:8a:bd:ae:68:
                    46:d5:00:66:e2:ef:a1:b5:23:0a:3a:49:22:4a:39:
                    3b:9d:72:d3:92:e2:3d:00:17:67:1e:8e:e8:32:e0:
                    09:74:92:3d:ec:e4:e8:fd:f3:76:e9:ad:0a:d9:2a:
                    a8:3c:6b:e2:24:c3:63:61:a6:61:43:3b:be:e6:2a:
                    18:ab:4f:01:5b:d4:31:bf:cb:21:08:7a:13:29:fd:
                    c8:ea:91:d6:84:60:5b:17:55:4f:ba:5a:92:68:49:
                    a4:dd:29:63:7b:f8:1e:74:b2:9d:32:42:5c:58:09:
                    bf:3b
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Comment:
                Easy-RSA Generated Certificate
            X509v3 Subject Key Identifier:
                2E:14:96:C7:18:64:E9:D1:98:18:60:C4:79:49:85:6B:7D:77:5B:9A
            X509v3 Authority Key Identifier:
                keyid:4F:FA:A5:75:DA:27:65:0D:4D:49:E7:4E:56:CD:4A:ED:1E:73:50:84
                DirName:/C=PH/ST=Nueva Vizcaya/L=Dupax/O=PERSONAL/OU=PERSONAL/CN=PERSONAL CA/name=iDerf/emailAddress=xfocus.me001@gmail.com
                serial:84:A3:A8:39:36:E3:9B:AD

            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Key Usage:
                Digital Signature
            X509v3 Subject Alternative Name:
                DNS:client
    Signature Algorithm: sha256WithRSAEncryption
         6d:ad:20:ee:ab:23:b5:75:d1:a4:c6:8c:41:0b:46:2d:3f:f9:
         65:ff:92:0d:9d:0e:11:00:c0:a9:4d:60:58:66:be:6a:26:a0:
         d2:b0:24:dc:30:1f:c2:63:ed:c9:14:03:d8:1d:c0:60:d6:15:
         20:9d:c8:f0:2c:5c:33:09:d5:95:97:27:53:d7:31:f7:42:bc:
         e0:eb:ed:c1:5f:f4:b7:ec:7d:83:23:26:05:2f:5f:7b:ed:15:
         e0:78:bc:79:e9:03:a4:44:dc:9e:78:c3:e4:3e:91:b0:53:11:
         89:5b:8a:f3:26:90:9d:89:2a:28:a5:ab:f0:5a:95:28:c7:0e:
         1f:65:78:b1:70:55:89:0c:1e:27:8a:2b:fe:8c:a7:d2:7e:4e:
         a3:cc:ee:c8:be:dd:4d:fe:50:9a:aa:48:6f:62:5a:cf:f5:88:
         0e:fa:27:55:4a:49:54:64:c1:91:63:a8:2f:8e:e5:77:45:72:
         f9:2e:93:0b:14:bb:c5:c0:cc:9c:78:dd:fc:51:50:80:39:a8:
         d1:d2:b9:64:9f:0f:15:69:a1:d5:31:8d:99:14:14:b5:eb:a1:
         bd:5f:b8:c3:74:c4:44:ee:6b:35:dc:09:56:f5:74:32:5c:6c:
         5c:66:fa:00:ee:8d:07:98:dd:15:69:d2:f4:48:8b:4a:1f:99:
         8e:75:3e:e0
-----BEGIN CERTIFICATE-----
MIIFPDCCBCSgAwIBAgIBAjANBgkqhkiG9w0BAQsFADCBqDELMAkGA1UEBhMCUEgx
FjAUBgNVBAgTDU51ZXZhIFZpemNheWExDjAMBgNVBAcTBUR1cGF4MREwDwYDVQQK
EwhQRVJTT05BTDERMA8GA1UECxMIUEVSU09OQUwxFDASBgNVBAMTC1BFUlNPTkFM
IENBMQ4wDAYDVQQpEwVpRGVyZjElMCMGCSqGSIb3DQEJARYWeGZvY3VzLm1lMDAx
QGdtYWlsLmNvbTAeFw0yMTAyMjgxNzUxNTJaFw0zMTAyMjYxNzUxNTJaMIGjMQsw
CQYDVQQGEwJQSDEWMBQGA1UECBMNTnVldmEgVml6Y2F5YTEOMAwGA1UEBxMFRHVw
YXgxETAPBgNVBAoTCFBFUlNPTkFMMREwDwYDVQQLEwhQRVJTT05BTDEPMA0GA1UE
AxMGY2xpZW50MQ4wDAYDVQQpEwVpRGVyZjElMCMGCSqGSIb3DQEJARYWeGZvY3Vz
Lm1lMDAxQGdtYWlsLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
ALo4Izwp/Xh43uH8Mz4KAV/o/13WPa1khcCwSxtLeoZXs6+FSuI4s14FOkUfedSs
nLYfbJXJdnhe3J4Lq9dT1rwMnZMT+QZQ9T1so1KStf0G2Sd1B3n14GUUuM8gEqaN
E3ZIiU1hjT8TwZ0QZpy5CPXg450q9FDkCgu6lBK3j2yH0Xww1tf7wLYiAFSACY6g
2PuKva5oRtUAZuLvobUjCjpJIko5O51y05LiPQAXZx6O6DLgCXSSPezk6P3zdumt
CtkqqDxr4iTDY2GmYUM7vuYqGKtPAVvUMb/LIQh6Eyn9yOqR1oRgWxdVT7pakmhJ
pN0pY3v4HnSynTJCXFgJvzsCAwEAAaOCAXIwggFuMAkGA1UdEwQCMAAwLQYJYIZI
AYb4QgENBCAWHkVhc3ktUlNBIEdlbmVyYXRlZCBDZXJ0aWZpY2F0ZTAdBgNVHQ4E
FgQULhSWxxhk6dGYGGDEeUmFa313W5owgd0GA1UdIwSB1TCB0oAUT/qlddonZQ1N
SedOVs1K7R5zUIShga6kgaswgagxCzAJBgNVBAYTAlBIMRYwFAYDVQQIEw1OdWV2
YSBWaXpjYXlhMQ4wDAYDVQQHEwVEdXBheDERMA8GA1UEChMIUEVSU09OQUwxETAP
BgNVBAsTCFBFUlNPTkFMMRQwEgYDVQQDEwtQRVJTT05BTCBDQTEOMAwGA1UEKRMF
aURlcmYxJTAjBgkqhkiG9w0BCQEWFnhmb2N1cy5tZTAwMUBnbWFpbC5jb22CCQCE
o6g5NuObrTATBgNVHSUEDDAKBggrBgEFBQcDAjALBgNVHQ8EBAMCB4AwEQYDVR0R
BAowCIIGY2xpZW50MA0GCSqGSIb3DQEBCwUAA4IBAQBtrSDuqyO1ddGkxoxBC0Yt
P/ll/5INnQ4RAMCpTWBYZr5qJqDSsCTcMB/CY+3JFAPYHcBg1hUgncjwLFwzCdWV
lydT1zH3Qrzg6+3BX/S37H2DIyYFL1977RXgeLx56QOkRNyeeMPkPpGwUxGJW4rz
JpCdiSoopavwWpUoxw4fZXixcFWJDB4niiv+jKfSfk6jzO7Ivt1N/lCaqkhvYlrP
9YgO+idVSklUZMGRY6gvjuV3RXL5LpMLFLvFwMyceN38UVCAOajR0rlknw8VaaHV
MY2ZFBS166G9X7jDdMRE7ms13AlW9XQyXGxcZvoA7o0HmN0VadL0SItKH5mOdT7g
-----END CERTIFICATE-----
EOF5
cat <<EOF6>>/etc/openvpn/easy-rsa/keys/client.key
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC6OCM8Kf14eN7h
/DM+CgFf6P9d1j2tZIXAsEsbS3qGV7OvhUriOLNeBTpFH3nUrJy2H2yVyXZ4Xtye
C6vXU9a8DJ2TE/kGUPU9bKNSkrX9BtkndQd59eBlFLjPIBKmjRN2SIlNYY0/E8Gd
EGacuQj14OOdKvRQ5AoLupQSt49sh9F8MNbX+8C2IgBUgAmOoNj7ir2uaEbVAGbi
76G1Iwo6SSJKOTudctOS4j0AF2cejugy4Al0kj3s5Oj983bprQrZKqg8a+Ikw2Nh
pmFDO77mKhirTwFb1DG/yyEIehMp/cjqkdaEYFsXVU+6WpJoSaTdKWN7+B50sp0y
QlxYCb87AgMBAAECggEBAI7Q+wTrV0ALwzQhzdLorYE3GpKG+qp+i63qBtAaJQ/f
NymH2pSA099ptvTIXRFkiJOMqiR+a+OJLT3wyYvM+sUiD7968+OKN2syZFexuO0j
UWvXbzJ0BfK/37TKbkNZsvFmVBcKl98mcbjZmTjdGCgqn6YsCU/4dFPmdiWcrdyX
RoAtRQ99dvd9sxHrjFWzUeFDp2d2pOVgpTCh+8BvayhiEg3UncTzMRvGA1nmtukW
okr+CngfNF3VPzix1kTBDUF+qYMH74v/bn9hUK2e+6sdqFWClCEFs6IKWsQYRvBE
fK7o5b+JUfONoJBBKqCXBJupkeTfWhtsao2UFJ2X0WECgYEA3ISEVxY4kPz0ySdI
nd8y5kZrwXpKi14TxjiqB4bYatsGqjTvcAxeKXJYWjEKNgjmD41WAIodyPFZMhib
6WmdVyFLxhe56TuFk2qaAZM/MiPEag5C/Bk8zuFqRKx6fBKrxsVO8ZfYnqQLAxQ2
OYJ+NrRiBnQR9OCyLws1KsyAxokCgYEA2C7Qr5GrMdEh1Y9m9dcOpOjHnw0piWhJ
2kjKRVgxe+naQfjqRF9AyFNVZhWQIF6OrhQiNywmbMmKpk/1wZoPoXNqvZXKNqmp
aT/KvbcjplPIurrG7TDwVRucNtB07LT2FFeIz9XepqgexXkeVSkPCGbTFyiXfw9w
xLqKWGs7JqMCgYB2D2CG+3eXcEZht21yUEAA9yzTrfRg/yIZGtc1JmWRd+fukl6q
n4R+LiDNULoFyefZ5bJooYlmvoghgPlgEtJRBpt519QJ4XsXPJhtRXctEecjXLVS
IPTkUdzCHZGKAbkDtzkXsVMhQ/Q9VsHdMlb+VL6yc8v1TaM3+okhe9Fp+QKBgCrG
AIZsdQnzThV6PS3xMjWQ1UZ0DT7hwpMNCfB0hb31xDh/bqK+kgvQ6Tm8lHrDGsn4
s9hkxOmLawKDGaYHvIX+VyVRyOPN5/YqKAwne0dClpnTsN5na3X7c4oo7qmTGIln
1GsC7v3cj9IUp9rDt/S6m5OedXMvc+mI2yypctevAoGBAKgSk+8KmJ06QCciYVP0
XrQVkG486cWGSBztL3ijfl7jCg3fJtL4En4lsvNxZcFb9mVaiz8jjZwS7qjZf1RQ
ioxIq2Eb7hyIo3ucTIuTolzu6H/CrliOX4Yu0HZYAaVbst1Lk5AfEir8STFs9ffD
hb0xY5XrFAZdHmFTG+AKEceu
-----END PRIVATE KEY-----
EOF6
#Configure Openvpn Server
cat <<EOT1>> /etc/openvpn/server.conf
port $Openvpn_Port1
proto tcp
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/tecadmin-server.crt
key /etc/openvpn/server/tecadmin-server.key
dh /etc/openvpn/server/dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1"

push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
duplicate-cn
cipher AES-256-CBC
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256
auth SHA512
auth-nocache
keepalive 20 60
persist-key
persist-tun
compress lz4
daemon
user nobody
group nogroup
log-append /var/log/openvpn.log
verb 2
EOT1
#Configure Openvpn Client
cat <<EOT2>> /etc/openvpn/client/client.ovpn
client
dev tun
proto tcp
remote $IPADDR $Openvpn_Port1
ca ca.crt
cert client.crt
key client.key
cipher AES-256-CBC
auth SHA512
auth-nocache
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256
resolv-retry infinite
compress lz4
nobind
persist-key
persist-tun
mute-replay-warnings
verb 2
EOT2
systemctl start openvpn@server
systemctl enable openvpn@server
systemctl status openvpn@server
q
