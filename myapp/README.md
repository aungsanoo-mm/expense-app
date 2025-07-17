# expense-app
my webapp
#To configure nginx server
pls write /etc/nginx/site-available/expense
(server {
    listen 80;
    server_name 47.129.235.128;

    root /var/www/html/expense-tracker;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /expense {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
    
)
And pls add the following line in /etc/nginx/ngxi.conf
pls remove default include

include /etc/nginx/sites-enabled/expense;

