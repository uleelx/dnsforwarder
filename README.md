What is it ?
-------------------------------
The Lua version of [Tcp-DNS-proxy](https://github.com/henices/Tcp-DNS-proxy).

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
  $ sudo lua tcpdns.lua
  ```
  
Dependencies
----------------------------

### lua moudules
   * [luasocket](http://w3.impa.br/~diego/software/luasocket/)
   * [struct](http://www.inf.puc-rio.br/~roberto/struct/)

INSTALL
---------------------

```bash
  sudo luarocks install luasocket
  sudo luarocks install struct
```

LICENSE
----------------------

TCP-DNS-proxy is distributed under the MIT license.