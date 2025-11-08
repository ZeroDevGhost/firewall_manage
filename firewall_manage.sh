#!/bin/bash
# Rocky Linux firewall management tool (firewalld wrapper)
# 用于增删查防火墙规则（端口/IP/IP段/服务）
# ----------------------------------------------------------
# | 功能                     | 示例命令                                      |
# | ------------------------ | --------------------------------------------- |
# | 放行端口                 | ./firewall_manage.sh add port 8080/tcp        |
# | 删除端口                 | ./firewall_manage.sh remove port 8080/tcp     |
# | 放行单个 IP 所有端口     | ./firewall_manage.sh add ip 1.1.1.1           |
# | 放行单个 IP 访问 22 端口 | ./firewall_manage.sh add ip 1.1.1.1 22        |
# | 放行整个网段所有端口     | ./firewall_manage.sh add subnet 1.1.1.0/24    |
# | 删除 IP 规则             | ./firewall_manage.sh remove ip 1.1.1.1        |
# | 放行服务（如 http）      | ./firewall_manage.sh add service http         |
# | 删除服务规则             | ./firewall_manage.sh remove service https     |
# | 查看所有规则             | ./firewall_manage.sh list                     |
# | 添加端口转发             | ./firewall_manage.sh add forward 8080:192.168.1.100:80 |
# | 删除端口转发             | ./firewall_manage.sh remove forward 8080:192.168.1.100:80 |
# ----------------------------------------------------------

# ZONE="public"
ZONE=$(firewall-cmd --get-default-zone)

show_help() {
    echo "用法: $0 {add|remove|list} [类型] [值] [端口]"
    echo
    echo "类型:  port | ip | subnet | service | forward"
    echo
    echo "示例:"
    echo "  $0 add port 8080/tcp                  # 开放端口"
    echo "  $0 remove port 8080/tcp               # 删除端口"
    echo "  $0 add service http                   # 放行 http 服务"
    echo "  $0 remove service https               # 删除 https 服务"
    echo "  $0 add ip 1.1.1.1                     # 放行单个IP"
    echo "  $0 add subnet 1.1.1.0/24              # 放行整个网段"
    echo "  $0 add ip 1.1.1.1 22                  # 放行单个IP访问22端口"
    echo "  $0 add drop 1.1.1.1                   # 丢弃单个IP"
    echo "  $0 add drop 1.1.1.0/24                # 丢弃整个网段"
    echo "  $0 add forward 8080:192.168.1.100:80  # 本机8080转发到192.168.1.100:80 (TCP+UDP)"
    echo "  $0 list                               # 查看所有规则"
    echo
    exit 1
}

# 确保 firewalld 正在运行
systemctl is-active --quiet firewalld || {
    echo "❌ firewalld 未启动，正在启动..."
    sudo systemctl start firewalld
}

action=$1
type=$2
value=$3
port=$4

case "$action" in
    add)
        case "$type" in
            port)
                echo "📜 当前区域: $ZONE"
                sudo firewall-cmd --permanent --zone=$ZONE --add-port=$value
                ;;
            service)
                echo "📜 当前区域: $ZONE"
                sudo firewall-cmd --permanent --zone=$ZONE --add-service=$value
                ;;
            ip)
                echo "📜 当前区域: $ZONE"
                if [ -n "$port" ]; then
                    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$value' port port='$port' protocol='tcp' accept"
                    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$value' port port='$port' protocol='udp' accept"
                else
                    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$value' accept"
                fi
                ;;
            subnet)
                echo "📜 当前区域: $ZONE"
                if [ -n "$port" ]; then
                    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$value' port port='$port' protocol='tcp' accept"
                else
                    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$value' accept"
                fi
                ;;
            drop)
                echo "📜 当前区域: $ZONE"
                # 阻止单个 IP 或网段
                sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$value' drop"
                ;;
            forward)
                echo "📜 当前区域: $ZONE"
                local_port=$(echo $value | cut -d: -f1)
                to_addr=$(echo $value | cut -d: -f2)
                to_port=$(echo $value | cut -d: -f3)

                # 自动开放本机端口
                echo "开放 ${local_port}/tcp 端口"
                sudo firewall-cmd --permanent --zone=$ZONE --add-port=${local_port}/tcp
                echo "开放 ${local_port}/udp 端口"
                sudo firewall-cmd --permanent --zone=$ZONE --add-port=${local_port}/udp

                # 创建 TCP 和 UDP 转发
                for proto in tcp udp; do
                    echo "创建 $proto 转发规则"
                    sudo firewall-cmd --permanent --zone=$ZONE --add-forward-port=port=$local_port:proto=$proto:toport=$to_port:toaddr=$to_addr
                done
                ;;
            *)
                show_help
                ;;
        esac
        echo "⚠️ 重载防火墙配置"
        sudo firewall-cmd --reload
        echo "✅ 已添加规则。"
        ;;
    remove)
        case "$type" in
            port)
                echo "📜 当前区域: $ZONE"
                sudo firewall-cmd --permanent --zone=$ZONE --remove-port=$value
                ;;
            service)
                echo "📜 当前区域: $ZONE"
                sudo firewall-cmd --permanent --zone=$ZONE --remove-service=$value
                ;;
            ip)
                echo "📜 当前区域: $ZONE"
                if [ -n "$port" ]; then
                    sudo firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$value' port port='$port' protocol='tcp' accept"
                    sudo firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$value' port port='$port' protocol='udp' accept"
                else
                    sudo firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$value' accept"
                fi
                ;;
            subnet)
                echo "📜 当前区域: $ZONE"
                if [ -n "$port" ]; then
                    sudo firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$value' port port='$port' protocol='tcp' accept"
                else
                    sudo firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$value' accept"
                fi
                ;;
            drop)
                echo "📜 当前区域: $ZONE"
                sudo firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$value' drop"
                ;;
            forward)
                echo "📜 当前区域: $ZONE"
                local_port=$(echo $value | cut -d: -f1)
                to_addr=$(echo $value | cut -d: -f2)
                to_port=$(echo $value | cut -d: -f3)

                # 删除 TCP 和 UDP 转发
                for proto in tcp udp; do
                    echo "删除 $proto 转发规则"
                    sudo firewall-cmd --permanent --zone=$ZONE --remove-forward-port=port=$local_port:proto=$proto:toport=$to_port:toaddr=$to_addr
                done

                # 关闭本机端口
                echo "删除 ${local_port}/tcp 端口"
                sudo firewall-cmd --permanent --zone=$ZONE --remove-port=${local_port}/tcp
                echo "删除 ${local_port}/udp 端口"
                sudo firewall-cmd --permanent --zone=$ZONE --remove-port=${local_port}/udp
                ;;
            *)
                show_help
                ;;
        esac
        echo "⚠️ 重载防火墙配置"
        sudo firewall-cmd --reload
        echo "🗑️ 已删除规则。"
        ;;
    list)
        echo "📜 当前区域: $ZONE"
        echo "---- 开放端口 ----"
        firewall-cmd --zone=$ZONE --list-ports
        echo
        echo "---- 开放服务 ----"
        firewall-cmd --zone=$ZONE --list-services
        echo
        echo "---- 富规则（IP/IP段） ----"
        firewall-cmd --list-rich-rules
        echo
        echo "---- 端口转发 ----"
        firewall-cmd --zone=$ZONE --list-forward-ports
        ;;
    *)
        show_help
        ;;
esac
