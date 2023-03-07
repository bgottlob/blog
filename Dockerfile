FROM klakegg/hugo:0.106.0-alpine-onbuild AS hugo

FROM nginx
COPY --from=hugo /target /usr/share/nginx/html
