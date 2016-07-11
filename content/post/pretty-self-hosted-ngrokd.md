+++
date = "2016-07-10T11:13:12+08:00"
title = "搭建并配置优雅的 ngrok 服务实现内网穿透"

+++

## 问题

随着互联网生态圈的发展，现今的 Web 项目中开始越来越多的使用第三方服务，通常这些第三方服务都是由 Client 通过 Server 的 API 主动发起请求，但是 Server 回调 Client 这种方式也是很多服务中不可避免的一种方式。这样的场景下，对于开发者就有个比较麻烦的问题：

**如何在开发的过程中让处于内网的开发机收到回调？**

## 古老的解决方案

### 方案一

传统解决方案中，如果没有固定 ip 首先需要动态域名，然后需要维护一份外网到内网的端口映射表，最后如果 Client 中有取 Host 信息的操作还需要响应的 Hack（这点后面会提到）。当然，如果你连公网 ip 都没有，那么就可以直接放弃这个方案了。

### 方案二

一种更为有效的解决方案是：使用一台拥有公网 IP 的主机，通过隧道来实现转发。其实在很早之前，为了让处于校园网内网的服务器在外网可以访问，我通常通过 SSH Tunnel 来解决这个问题。

```bash
# 将远程主机的 10086 转发到本地的 3000
ssh -C -f -N -g -R 10086:127.0.0.1:3000 user@Tunnel_Server
```

这种方式虽然使用简单，但是稳定性并不理想，一段时间内没有请求 Tunnel 就会自动断开。而且使用者必须有 Tunnel_Server 的 ssh 登录权限，每开一个服务就需要占用 Tunnel_Server 一个端口。

## Ngrok

正当我苦于写 SSH Tunnel 的各种连接脚本和守护脚本的时候，第一次接触到了 Ngrok。（2013年）那个时候 ngrok 还是一个很冷门的小工具，它所依赖的 Go 也一样，加上文档有限，各种尝试之后并没有把这套服务搭起来。

再后来，国内出现了金数据团队维护的 tunnel.mobi，默默的为国内的开发者提供了很长一段时间的便利。国内 ngrok 的快速普及，个人觉得很大程度上都得益与 tunnel.mobi 的影响。然而这样一个优秀的服务，在维持一年之后（2014.10-2015.10），选择了关闭。

此后，国内各种 ngrok 服务提供者如雨后春笋般出现，我司对于 ngrok 的依赖也比较大，于是我也在我们自己的服务器上搭了一套 ngrok，不觉然都快过去一年了。在这段时间的使用里，也发现了一些不方便或不够友好的地方，加上之前的搭建的那台服务器如今已不堪重负，于是趁周末的时候重新搭建了一份，并做了一点点配置上的优化。

* * *

### 服务端

我使用的环境是 Aliyun ECS + Ubuntu 14.04，双网卡（内网网卡+外网网卡）

#### 源码安装

首先装必要的工具：

```bash
sudo apt-get install build-essential golang mercurial git
```

获取 ngrok 源码：

```bash
git clone https://github.com/inconshreveable/ngrok.git ngrok
### 请使用下面的地址，修复了无法访问的包地址
git clone https://github.com/tutumcloud/ngrok.git ngrok
cd ngrok
```

编译&安装：

```bash
sudo make release-server
sudo cp bin/ngrokd /usr/local/bin/ngrokd
```


#### Apt-get 安装（二选一）

```bash
sudo apt-get install ngrok-server
```

#### 域名

选定你要使用的域名，比如：yii.im，添加两条解析到你的服务器

- yii.im
- *.yii.im

#### 证书

ngrok 通讯依赖 TLS 证书来加密，所以启动的时候需要指定你的域名和对应的证书

既然依赖证书的话，那你应该先有一份证书。在搭建 ngrok 服务的时候，对于证书的处理有多种方式可选：

- 使用 CA 颁发的证书，也就是正式的 TLS 证书
- 使用自签名证书，并自行编译分发带自签名证书的客户端
- 使用自签名证书，使用通用的客户端，但需要用户把自签名证书添加到自己根证书

本文中使用第一种方式，域名证书通过 [沃通CA免费SSL证书](http://www.wosign.com/Products/free_SSL.htm) 取得，这是一个包含一个域名(yii.im)的证书，所有的二级域名都不被支持。

由于 ngrok 工作是通过分配 subdomain 的方式，而证书又不支持子域名，所以这样搭建的 ngrok 服务并不支持 https。虽然不完美，但是日常使用并没有强制要求 https 的情况，能跑就够了，要什么自行车。

ㄟ( ▔, ▔ )ㄏ手动滑稽

关于第二种方式，可以参考：https://imququ.com/post/self-hosted-ngrokd.html

目前网上流行的 ngrok 服务或教程，基本上都是基于这种方式的。

第三种方式，除了需要用户添加根证书以外，基本跟本文一样，不需要单独编译客户端，并且支持 https。

#### 启动设定

前面生成了 ngrokd 就是 ngrok server ，指定证书、域名和端口就可以启动它了：

```bash
# 获取帮助信息
ngrokd -h

# Usage of ngrokd:
#   -domain="ngrok.com": Domain where the tunnels are hosted
#   -httpAddr=":80": Public address for HTTP connections, empty string to disable
#   -httpsAddr=":443": Public address listening for HTTPS connections, emptry string to disable
#   -log="stdout": Write log messages to this file. 'stdout' and 'none' have special meanings
#   -tlsCrt="": Path to a TLS certificate file
#   -tlsKey="": Path to a TLS key file
#   -tunnelAddr=":4443": Public address listening for ngrok client

# 试着启动
ngrokd -tlsKey=server.key -tlsCrt=server.crt -domain=yii.im -httpAddr=:8081 -httpsAddr=

```

到这一步，ngrok 服务已经跑起来了，可以通过屏幕上显示的日志查看更多信息。httpAddr、httpsAddr 分别是 ngrok 用来转发 http、https 服务的端口，可以随意指定。由于我不需要 https，所以留空了。 ngrokd 还会开一个 4443 端口用来跟客户端通讯（可通过 -tunnelAddr=":xxx" 指定），如果你配置了 iptables 规则，需要放行这几个端口上的 TCP 协议。

现在，通过 http://sub.yii.im:8081 就可以访问到 ngrok 提供的转发服务。在客户端连进来之前，你应该会看到：

> Tunnel sub.yii.im:8081 not found

这说明万事俱备，只差客户端来连了。

#### 端口问题（可选）

url 上带上端口通常来说并不会有什么影响，而且通过 nginx 隐藏起来也很简单：

```
# ngrokd.conf
server {
    server_name *.yii.im;
    listen 80;

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host:8081;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8081;
    }

}
```

这里就有一个很烦躁的地方了，ngrokd 里面有一层自己的 Host 处理，于是 `proxy_set_header Host` 必须带上你所指定的端口，否则就算请求被转发到 ngrokd，也没有办法被正确的处理。进而，就导致了另一个操蛋的问题：你请求的时候是 sub.yii.im，但是你在 web 应用中获取到的是 sub.yii.im:8081。

要完美的解决这个端口隐藏问题，就需要让 ngrokd 直接监听 80 端口。

通常来说 VPS 都是双网卡的（一内一外），直接让 ngrokd 监听外网的 80 多少还是有些浪费，这个端口还是留给 nginx 比较合理。所以比较理想的方式是：nginx 监听外网 80，ngrokd 监听内网 80，让 nginx 将对应的请求转发到内网 80 上来。

如： 

- 内网 ip: 10.160.xx.xx
- 外网 ip: 112.124.xx.xx

启动 ngrokd：

```
sudo ngrokd -tlsKey=server.key -tlsCrt=server.crt -domain=yii.im -httpAddr=10.160.xx.xx:80 -httpsAddr=
```

配置 nginx：

```
# ngrokd.conf
server {
    listen      112.124.xx.xx:80;
    server_name *.yii.im;

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect  off;
        proxy_pass      http://10.160.xx.xx:80;
    }
}

# the_others_need_80.conf
server {
    listen      112.124.xx.xx:80;
    #...
}
```

如果你是单网卡，那么还可以通过 docker 来解决： http://www.hteen.cn/docker/docker-ngrok.html

#### 维护脚本（可选）

由于 ngrokd 的启动命令老长老长，偶尔发现它死了需要重启，拼（找）命令都拼半天，于是我顺手写了一个维护脚本

> 注意： Ubuntu 适用，Centos 需要一点修改

``` bash
wget https://gist.githubusercontent.com/IvanChou/1be8b15b1b41bf0ce2e9d939866bbfec/raw/1a2445599fe7fd706505a6e103a9dc60b4d3a0ed/ngrokd -O ngrokd

# 修改 脚本中的配置
vi ngrokd

chomd +x ngrokd
sudo mv ngrokd /etc/init.d/ngrokd
```

#### TCP支持 - SSH etc.（可选）

ngrok 是 TCP 穿透，也就是说只要是基于 TCP 协议的通讯，它都能协助我们进行穿透，当然也包括 SSH 和 mstsc。

ngrok 在进行 TCP 连接的时候，是通过额外开启一个端口的方式，如果 Client 没有指定端口，ngrokd 将会随机开启一个大号端口。如指定 ngrokd 使用 10086 端口，连接建立后可通过 yii.im:10086 访问到 Client 的指定端口。

建议可以在 iptables 中放行少量 大口径端口 备用。

* * *

### 客户端

#### 下载

由于使用的是 CA 证书，所以不需要自行编译客户端，可以网上自行下载各种 ngrok v1.7 的客户端，理论上都是可用的（有的似乎对客户端做了修改，或许有其它未知原因而无法使用，请自行略过）

资源随后放出 ㄟ( ▔, ▔ )ㄏ

MAC & Linux 下，可以将 ngrok 放到 `/usr/local/bin/` 下备用


#### ngrok.yml

```yaml
server_addr: "yii.im:4443"
trust_host_root_certs: true
```

这段配置是用来指定 Server 和 认证方式 的：

- server_addr 中的 host 需要与 ngrokd 所使用的证书严格对应
- trust_host_root_certs 是否信任系统根证书，如果是带自签名证书编译的 ngrok 客户端，这个值应该设置为 false；如果使用 CA 证书，或者用户添加了根证书，这个值应该设置为 true。

更多关于 ngrok configuration file 的设定可以参考：https://ngrok.com/docs#config

> 由于官网现在只有 2.0 以上版本的支持，这里只能参照配置的写法，启动方式请勿参考。

#### Http 连接

```bash
ngrok -config path/to/ngrok.yml -proto=http -subdomain pub 3000
```

可以看到

```
ngrok                                               (Ctrl+C to quit)

Tunnel Status                 online
Version                       1.7/1.7
Forwarding                    http://pub.yii.im -> 127.0.0.1:3000
Web Interface                 127.0.0.1:4040
# Conn                        0
Avg Conn Time                 0.00ms
```

说明连接成功，现在访问 http://pub.yii.im 就可以访问到本机 3000 端口上的服务了

#### 界面管理（推荐）

在上面的运行时界面中，有一个 Web Interface 地址，这是 ngrok 提供的监控界面。通过这个界面可以看到远端转发过来的 http 详情，包括完整的 request/response 信息，相当于附带了一个抓包工具。


#### TCP 连接

指定 server 端口需要在 ngrok.yml 中配置才能实现

不指定端口 

```bash
ngrok -config path/to/ngrok.yml -proto=tcp 22
```

连接状态：

```
ngrok                                               (Ctrl+C to quit)

Tunnel Status                 online
Version                       1.7/1.7
Forwarding                    tcp://via.ichou.cn:17476 -> 127.0.0.1:22
Web Interface                 127.0.0.1:4040
# Conn                        0
Avg Conn Time                 0.00ms
```

##  -- EOF --

盗用 [Jerry Qu](https://imququ.com/post/self-hosted-ngrokd.html) 的一句话

> 实际上，由于 ngrok 可以转发 TCP，所以还有很多玩法，原理都一样，这里就不多写了。


