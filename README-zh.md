如何使用 dnsforwarder.lua 脚本 ?
-------------------------------

### Linux/Mac

 1.    修改本机DNS为127.0.0.1

  ```bash
  $ vi /etc/resolve.conf
  nameserver 127.0.0.1
  ```
 2.    重启网络

  ```bash
  $ sudo /etc/init.d/networking restart
  ```
 3.    运行脚本

  ```bash
  $ sudo lua dnsforwarder.lua
  ```

### Windows

 1.    修改本机DNS为127.0.0.1

 2.    运行toexe.bat，生成dnsforwarder.exe

 2.    运行dnsforwarder.exe


脚本依赖
----------------------------

### lua模块
   * [luasocket] (http://w3.impa.br/~diego/software/luasocket/)

### lua模块安装

```bash
  sudo luarocks install luasocket
```

LICENSE
----------------------

DNSForwarder is distributed under the MIT license.