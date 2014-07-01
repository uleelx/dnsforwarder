How to use this Lua script ?
-------------------------------

1.    change your dns server to 127.0.0.1

  ```bash
  $ vi /etc/resolve.conf  
  nameserver 127.0.0.1
  ```
2.    restart the network

  ```bash
  $ sudo /etc/init.d/networking restart
  ```
3.    run the script

  ```bash
  $ sudo lua dnsforwarder.lua
  ```
  
Dependencies
----------------------------

### lua moudules
   * [luasocket](http://w3.impa.br/~diego/software/luasocket/)

INSTALL
---------------------

```bash
  sudo luarocks install luasocket
```

LICENSE
----------------------

DNSForwarder is distributed under the MIT license.