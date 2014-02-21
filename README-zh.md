这个是什么 ?
-------------------------------
这个是Lua版本的[Tcp-DNS-proxy](https://github.com/henices/Tcp-DNS-proxy)。

如何使用 tcpdns.lua 脚本 ?
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
  $ sudo lua tcpdns.lua
  ```

### Windows

 1.    修改本机DNS为127.0.0.1

 2.    运行toexe.bat，生成tcpdns.exe

 2.    运行tcpdns.exe


脚本依赖
----------------------------

### lua模块
   * [luasocket] (http://w3.impa.br/~diego/software/luasocket/)
   * [struct] (http://www.inf.puc-rio.br/~roberto/struct/)

### lua模块安装

```bash
  sudo luarocks install luasocket
  sudo luarocks install struct
```

LICENSE
----------------------

TCP-DNS-proxy is distributed under the MIT license.