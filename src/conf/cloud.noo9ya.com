upstream php-handler {
        server unix:/var/run/php/php8.3-fpm.sock;

}

# Set the `immutable` cache control options only for assets with a cache busting `v` argument
map $arg_v $asset_immutable {
        "" "";
        default "immutable";
}

server {
        # listen 443 ssl http2;
        # listen [::]:443 ssl http2;

        # server_name cloud.noo9ya.com;

        ssl_certificate /etc/letsencrypt/live/cloud.noo9ya.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/cloud.noo9ya.com/privkey.pem;
        ssl_trusted_certificate /etc/letsencrypt/live/cloud.noo9ya.com/chain.pem;
        ssl_dhparam /etc/ssl/certs/dhparam.pem;

        ssl_protocols TLSv1 TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA- AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE- RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE- ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256- SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE- RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA- AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3- SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128- SHA:AES256-SHA:DES-CBC3-SHA:!DSS";
        ssl_ecdh_curve secp384r1;
        ssl_session_timeout 10m;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off;
        ssl_stapling on;
        ssl_stapling_verify on;
        resolver 1.1.1.1 1.0.0.1 valid=300s;
        resolver_timeout 5s;

        access_log /var/www/cloud.noo9ya.com/logs/access.log;
        error_log /var/www/cloud.noo9ya.com/logs/error.log;

        root /var/www/cloud.noo9ya.com/public;
        #index index.php index.html;

        #Nextcloud
        # Prevent nginx HTTP Server Detection
        server_tokens off;

        # HSTS settings
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload" always;

        # set max upload size and increase upload timeout:
        client_max_body_size 512M;
        client_body_timeout 300s;
        fastcgi_buffers 64 4K;

        # Enable gzip but do not remove ETag headers
        gzip on;
        gzip_vary on;
        gzip_comp_level 4;
        gzip_min_length 256;
        gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        gzip_types application/atom+xml text/javascript application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/wasm application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

        # Pagespeed is not supported by Nextcloud, so if your server is built
        # with the `ngx_pagespeed` module, uncomment this line to disable it.
        #pagespeed off;

        # The settings allows you to optimize the HTTP2 bandwitdth.
        # See https://blog.cloudflare.com/delivering-http-2-upload-speed-improvements/
        # for tunning hints
        client_body_buffer_size 512k;

        # HTTP response headers borrowed from Nextcloud `.htaccess`
        add_header Referrer-Policy                   "no-referrer"       always;
        add_header X-Content-Type-Options            "nosniff"           always;
        #add_header X-Download-Options                "noopen"            always;
        add_header X-Frame-Options                   "SAMEORIGIN"        always;
        add_header X-Permitted-Cross-Domain-Policies "none"              always;
        add_header X-Robots-Tag                      "noindex, nofollow" always;
        add_header X-XSS-Protection                  "1; mode=block"     always;

        # Remove X-Powered-By, which is an information leak
        fastcgi_hide_header X-Powered-By;

        # Add .mjs as a file extension for javascript
        # Either include it in the default mime.types list
        # or include you can include that list explicitly and add the file extension
        # only for Nextcloud like below:
        include mime.types;

        # Specify how to handle directories -- specifying `/index.php$request_uri`
        # here as the fallback means that Nginx always exhibits the desired behaviour
        # when a client requests a path that corresponds to a directory that exists
        # on the server. In particular, if that directory contains an index.php file,
        # that file is correctly served; if it doesn't, then the request is passed to
        # the front-end controller. This consistent behaviour means that we don't need
        # to specify custom rules for certain paths (e.g. images and other assets,
        # `/updater`, `/ocs-provider`), and thus
        # `try_files $uri $uri/ /index.php$request_uri`
        # always provides the desired behaviour.
        index index.php index.html /index.php$request_uri;
        #types {
        #        text/javascript js mjs;
        #}
        # Rule borrowed from `.htaccess` to handle Microsoft DAV clients
        location = / {
                if ( $http_user_agent ~ ^DavClnt ) {
                        return 302 /remote.php/webdav/$is_args$args;
                }
        }

        location = /robots.txt {
                add_header  Content-Type  text/plain;
                return 200 "User-agent: *\nDisallow: /\n";
                # allow all;
                log_not_found off;
                access_log off;
        }


        # Make a regex exception for `/.well-known` so that clients can still
        # access it despite the existence of the regex rule
        # `location ~ /(\.|autotest|...)` which would otherwise handle requests
        # for `/.well-known`.
        location ^~ /.well-known {
                # The rules in this block are an adaptation of the rules
                # in `.htaccess` that concern `/.well-known`.

                location = /.well-known/carddav { return 301 /remote.php/dav/; }
                location = /.well-known/caldav  { return 301 /remote.php/dav/; }

                location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
                location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

                # Let Nextcloud's API for `/.well-known` URIs handle all other
                # requests by passing them to the front-end controller.
                return 301 /index.php$request_uri;
        }


        # Rules borrowed from `.htaccess` to hide certain paths from clients
        location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
        location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

        # Ensure this block, which passes PHP files to the PHP process, is above the blocks
        # which handle static assets (as seen below). If this block is not declared first,
        # then Nginx will encounter an infinite rewriting loop when it prepends `/index.php`
        # to the URI, resulting in a HTTP 500 error response.

        # to the URI, resulting in a HTTP 500 error response.
        location ~ \.php(?:$|/) {
                # Required for legacy support
                rewrite ^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|ocs-provider\/.+|.+\/richdocumentscode\/proxy) /index.php$request_uri;

                fastcgi_split_path_info ^(.+?\.php)(/.*)$;
                set $path_info $fastcgi_path_info;

                try_files $fastcgi_script_name =404;

                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $path_info;
                fastcgi_param HTTPS on;

                fastcgi_param modHeadersAvailable true;         # Avoid sending the security headers twice
                fastcgi_param front_controller_active true;     # Enable pretty urls
                fastcgi_pass php-handler;

                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;

                fastcgi_max_temp_file_size 0;
        }
        # Javascript mimetype fixes for nginx
        # Note: The block below should be removed, and the js|mjs section should be
        # added to the block below this one. This is a temporary fix until Nginx 
        # upstream fixes the js mime-type
        location ~* \.(?:js|mjs)$ {
            types { 
                text/javascript js mjs;
            } 
            default_type "text/javascript";
            try_files $uri /index.php$request_uri;
            add_header Cache-Control "public, max-age=15778463, $asset_immutable";
            access_log off;
        }

        # Serve static files
        location ~ \.(?:css|svg|gif|png|jpg|ico|wasm|tflite|map|ogg|flac)$ {
            try_files $uri /index.php$request_uri;
            add_header Cache-Control "public, max-age=15778463, $asset_immutable";
            access_log off;     # Optional: Don't log access to assets

            location ~ \.wasm$ {
                default_type application/wasm;
            }
        }
        location ~ \.woff2?$ {
                try_files $uri /index.php$request_uri;
                expires 7d;         # Cache-Control policy borrowed from `.htaccess`
                access_log off;     # Optional: Don't log access to assets
        }

        # Rule borrowed from `.htaccess`
        location /remote {
                return 301 /remote.php$request_uri;
        }

        location / {
                try_files $uri $uri/ /index.php$request_uri;
        }
}

server {
        listen 80;
        listen [::]:80;

        server_name cloud.noo9ya.com;
        # Prevent nginx HTTP Server Detection
        server_tokens off;

        return 301 https://cloud.noo9ya.com$request_uri;
}