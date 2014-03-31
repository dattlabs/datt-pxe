FROM datt/datt-base:latest
MAINTAINER John Albietz "inthecloud247@gmail.com"

#https://blog.dlasley.net/2013/01/setup-pxediskless-boot-ubuntu-12-10/

RUN apt-get -y install dnsmasq wget iptables
#RUN wget --no-check-certificate https://raw.github.com/jpetazzo/pipework/master/pipework
RUN wget --no-check-certificate https://raw.githubusercontent.com/cpuguy83/pipework/patch-2/pipework
RUN chmod +x pipework
RUN mkdir /tftp
WORKDIR /tftp
RUN bash -c "wget http://archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/{linux,initrd.gz,pxelinux.0}"
RUN mkdir pxelinux.cfg
RUN printf "DEFAULT linux\nKERNEL linux\nAPPEND initrd=initrd.gz\n" >pxelinux.cfg/default
ADD files/tftp/ /tftp/

CMD \
    supervisord &&\
    echo Setting up iptables... &&\
    iptables -t nat -A POSTROUTING -j MASQUERADE &&\
    echo Waiting for pipework to give us the eth1 interface... &&\
    /pipework --wait &&\
    echo Starting DHCP+TFTP server...&&\
    dnsmasq --interface=eth1 \
      --dhcp-range=192.168.242.2,192.168.242.99,255.255.255.0,1h \
      --dhcp-match=set:ipxe,175 \
      --dhcp-boot=tag:!ipxe,undionly.kpxe \
      --dhcp-boot=http://192.168.242.1/bootstrap.ipxe \
      --enable-tftp --tftp-root=/tftp/ --no-daemon

      # --pxe-service=x86PC,"Install Linux",pxelinux \
# --dhcp-boot=pxelinux.0,pxeserver,192.168.242.1 \

#EXPOSE 53 53/udp 67 67/udp 68 68/udp 69/udp 4011/udp

### Borrowed from http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq.conf.example
# Boot for iPXE. The idea is to send two different
# filenames, the first loads iPXE, and the second tells iPXE what to
# load. The dhcp-match sets the ipxe tag for requests from iPXE.
# Important Note: the 'set:' and 'tag:!ipxe' syntax requires dnsmasq 2.53 or above.
# dhcp-match=set:ipxe,175 # iPXE sends a 175 option.
# # load undionly.kpxe for clients not tagged with 'ipxe'.
# dhcp-boot=tag:!ipxe,undionly.kpxe
# # undionly.kpxe issues a second DHCP request and we then serve bootstrap.ipxe over http
# # using Robin Smidsrød's bootstrap method provided at https://gist.github.com/2234639
# dhcp-boot=http://10.37.129.3/bootstrap.ipxe
# Or, simply load your own menu
# dhcp-boot=menu.ipxe
