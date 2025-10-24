FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/nginx.conf

RUN echo '<h1>Custom Nginx with Metrics</h1><p>Metrics available at <a href="/basic_status">/basic_status</a></p>' > /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
