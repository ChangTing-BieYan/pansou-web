FROM nginx:alpine

# 安装必要的运行时依赖
RUN apk add --no-cache ca-certificates tzdata curl bash

# 设置时区
ENV TZ=Asia/Shanghai

# 设置默认环境变量
ENV PANSOU_PORT=8888
ENV PANSOU_HOST=127.0.0.1

# 数据目录统一配置（所有持久化数据都在/app/data下）
ENV CACHE_PATH=/app/data/cache
ENV LOG_PATH=/app/data/logs

# 默认插件配置
ENV ENABLED_PLUGINS=labi,zhizhen,shandian,duoduo,muou,wanou,hunhepan,jikepan,panwiki,pansearch,panta,qupansou,hdr4k,pan666,susu,xuexizhinan,panyq,ouge,huban,cyg,erxiao,miaoso,fox4k,pianku,clmao,wuji,cldi,xiaozhang,libvio,leijing,xb6v,xys,ddys,hdmoli,clxiong,jutoushe,sdso,xiaoji,xdyh,haisou,bixin,djgou,nyaa,xinjuc,aikanzy,qupanshe,xdpan,discourse,yunsou,ahhhhfs,nsgame,quark4k,quarksoo,sousou,ash,feikuai,kkmao,alupan,ypfxw,mikuclub,daishudj,dyyj,meitizy,jsnoteclub,mizixing,lou1,yiove

# 默认Telegram频道配置
ENV CHANNELS=tgsearchers3,tianyirigeng,tyypzhpd,cloudtianyi,tianyifc,ydypzyfx,yunpan139,ucquark,ucwpz,yyunpanuc,zyzhpd123,xx123pan,yp123pan,yggpan,zyfb123

# 默认性能配置
ENV CACHE_ENABLED=true
ENV CACHE_TTL=60
ENV MAX_CONCURRENCY=200
ENV MAX_PAGES=30

# 健康检查配置
ENV HEALTH_CHECK_INTERVAL=30
ENV HEALTH_CHECK_TIMEOUT=10
ENV HEALTH_CHECK_RETRIES=3

# 创建应用目录
WORKDIR /app

# 获取架构信息
ARG TARGETARCH
ARG TARGETVARIANT

# 复制对应架构的后端二进制文件
COPY pansou-${TARGETARCH}${TARGETVARIANT} /app/pansou
RUN chmod +x /app/pansou

# 复制前端构建产物
COPY frontend-dist /app/frontend/dist/

# 复制启动脚本
COPY start.sh /app/
RUN chmod +x /app/start.sh

# 创建健康检查脚本（直接在镜像中创建，避免依赖外部文件）
RUN cat > /app/healthcheck.sh << 'EOF'
#!/bin/bash
# 健康检查脚本 - 检查nginx和后端服务是否正常

# 环境变量默认值
PANSOU_HOST=${PANSOU_HOST:-127.0.0.1}
PANSOU_PORT=${PANSOU_PORT:-8888}
HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-10}

# 检查nginx是否运行
if ! pgrep nginx >/dev/null 2>&1; then
    echo "❌ Nginx进程不存在"
    exit 1
fi

# 检查nginx是否响应（通过80端口）
if ! curl -sf --max-time ${HEALTH_CHECK_TIMEOUT} http://localhost/api/health >/dev/null 2>&1; then
    echo "❌ Nginx无法访问健康检查端点"
    exit 1
fi

# 检查后端服务是否响应
if ! curl -sf --max-time ${HEALTH_CHECK_TIMEOUT} http://${PANSOU_HOST}:${PANSOU_PORT}/api/health >/dev/null 2>&1; then
    echo "❌ 后端服务健康检查失败"
    exit 1
fi

# 所有检查通过
exit 0
EOF

RUN chmod +x /app/healthcheck.sh

# 创建必要的目录结构（统一在/app/data下）
RUN mkdir -p /app/data/cache \
             /app/data/logs/backend \
             /app/data/logs/nginx \
             /app/data/ssl

# 创建nginx配置目录
RUN mkdir -p /etc/nginx/conf.d

# 健康检查（检查nginx和后端）
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD /app/healthcheck.sh || exit 1

# 暴露端口
EXPOSE 80 443

# 设置卷挂载点（只挂载/app/data，所有数据都在这里）
VOLUME ["/app/data"]

# 设置启动命令
CMD ["/app/start.sh"]