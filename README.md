## 앱 배포하기

* 4주차 과제 / AWS EC2를 이용하여 앱 배포하기

* 프록시 서버로 Nginx, 백엔드 서버로 NestJS를 사용했고 배포에는 docker-compose를 활용했습니다.

<br>
<br>

### 구현 과정

---

* AWS EC2 인스턴스를 생성합니다.

  ![](https://user-images.githubusercontent.com/40125372/179642712-025a20fe-cb19-4409-83f3-274b05b022f2.PNG)

* Elastic IP를 할당하고 생성한 인스턴스에 연결합니다.

  ![](https://user-images.githubusercontent.com/40125372/179642932-68bb9744-58ea-45e4-8f08-e8a5b2dad007.PNG)

* NestJS 프로젝트를 생성합니다.

* Nginx, NestJS를 구축하기 위한 Dockerfile을 작성합니다. Proxy 서버에는 80 포트를 매핑하고, 백엔드 서버에서는 3000 포트를 expose 합니다.

* Dockerfile

  ```dockerfile
  FROM node:16-alpine3.11
  
  WORKDIR /deploy-app/
  
  RUN apk update
  RUN apk upgrade
  
  COPY ./package.json /deploy-app/
  COPY ./yarn.lock /deploy-app/
  
  RUN yarn install
  
  COPY . /deploy-app/
  
  CMD yarn start:dev
  ```

  

* docker-compose.yml

  ```dockerfile
  version: '3.8'
  
  services:
    proxy:
      image: nginx:latest
      container_name: proxy
      ports:
        - "80:80"  # 80번 포트를 host와 container 맵핑
      volumes:
        - ./proxy/nginx.conf:/etc/nginx/nginx.conf  # nginx 설정 파일 volume 맵핑
      restart: 'unless-stopped'  # 내부에서 에러로 인해 container가 죽을 경우 restart
    
    backend-server:
      build:
        context: .
        dockerfile: Dockerfile
      container_name: backend-server
      expose:
        - "3000"  # 다른 컨테이너에게 3000번 포트 오픈
      volumes:
        - ./env/.env:/deploy-app/env/.env
        - ./src:/deploy-app/src
      restart: "unless-stopped"
  ```

  

* proxy/nginx.conf 생성하고 nginx 설정 파일을 작성합니다.

* Nginx에 80포트를 열어두고 백엔드 서버로 포워딩합니다.

  ```
  user  nginx;
  worker_processes  1;
  
  error_log  /var/log/nginx/error.log warn;
  pid        /var/run/nginx.pid;
  
  events {                     
      worker_connections  1024;
  }                            
  
  http {
      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;
      
      # backend-server 라는 이름의 upstream을 정의
      # docker-compose.yml에서 backend-server 컨테이너 이름
      upstream backend-server { 
          server backend-server:3000;
      }
  
      # 클라이언트가 nginx / 경로로 들어올 경우
      # 정의한 backend-server upstream으로 포워딩
      server {
          listen 80;
          server_name localhost;
  
          location / {
  		proxy_http_version 1.1;
              	proxy_pass         http://backend-server;
          }
  
      }
  
      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
  
      access_log  /var/log/nginx/access.log  main;
                                                  
      sendfile        on;                                                                         
      keepalive_timeout  65;                                                                      
      include /etc/nginx/conf.d/*.conf;           
  }
  ```

  

* EC2 인스턴스에 접속하여 해당 프로젝트 clone 후 docker-compsoe를 이용해서 배포합니다.

  ```
  $ git clone https://github.com/ymink716/04-DeployAPP-E.git
  $ cd 04-DeployAPP-E
  $ docker-compose build
  $ docker-compose up
  ```

* 결과 화면

  ![](https://user-images.githubusercontent.com/40125372/179643059-518a6bb3-ae02-45c0-ad14-54923eded4eb.PNG)

  

