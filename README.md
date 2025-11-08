# 防火墙管理命令示例

| 功能                     | 示例命令                                      |
| ------------------------ | --------------------------------------------- |
| 放行端口                 | `./firewall_manage.sh add port 8080/tcp`      |
| 删除端口                 | `./firewall_manage.sh remove port 8080/tcp`   |
| 放行单个 IP 所有端口     | `./firewall_manage.sh add ip 1.1.1.1`         |
| 放行单个 IP 访问 22 端口 | `./firewall_manage.sh add ip 1.1.1.1 22`      |
| 放行整个网段所有端口     | `./firewall_manage.sh add subnet 1.1.1.0/24`  |
| 删除 IP 规则             | `./firewall_manage.sh remove ip 1.1.1.1`      |
| 放行服务（如 http）      | `./firewall_manage.sh add service http`       |
| 删除服务规则             | `./firewall_manage.sh remove service https`   |
| 添加端口转发             | `./firewall_manage.sh add forward 8080:192.168.1.100:80` |
| 删除端口转发             | `./firewall_manage.sh remove forward 8080:192.168.1.100:80` |
| 查看所有规则             | `./firewall_manage.sh list`                   |
