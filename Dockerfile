# 用阿里云公共镜像源的 nginx
FROM registry.cn-hangzhou.aliyuncs.com/library/nginx:alpine

# 如果你有自定义 nginx 配置（可选）
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# 把静态文件拷进 nginx 默认目录
# 注意：把 dist 改成你真实的目录（比如 build）
COPY dist/ /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

