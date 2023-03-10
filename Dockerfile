# https://cloud.google.com/community/tutorials/deploy-react-nginx-cloud-run

# build environment
FROM node:14-alpine as react-build
WORKDIR /app
COPY . ./

# declare required arguments to pass into Docker for build
ARG REACT_APP_ENV
ARG REACT_APP_BUILD_ID
ARG REACT_APP_SHORT_SHA

# set arguments as build time env variables
ENV REACT_APP_ENV=${REACT_APP_ENV}
ENV REACT_APP_BUILD_ID=${REACT_APP_BUILD_ID}
ENV REACT_APP_SHORT_SHA=${REACT_APP_SHORT_SHA}

# build react app
RUN yarn
RUN yarn build

# server environment
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/configfile.template

COPY --from=react-build /app/build /usr/share/nginx/html

ENV PORT 8080
ENV HOST 0.0.0.0
EXPOSE 8080

CMD sh -c "envsubst '\$PORT' < /etc/nginx/conf.d/configfile.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
# \$_REACT_APP_ENV \$BUILD_ID \$SHORT_SHA