# Performance_Framework
## Preconfiguration(optional but preferable)
---------------
You need this items for performance framework
- Install docker [Docker install website](https://docs.docker.com/engine/install/)
- Install WSL 2 (optional)[WSL2 install guide][2]
- Install Java (8 version or higher) 
## Installing
---------------
For installing and building framework you need to:
1. Download repository: [here][3]
2. For quick install navigate to repository dir and choose framework load tool(jmeter or gatling).
 ```docker-compose up -d```
3. If you want to install separate container
```docker compose up -d elasticsearch
  docker compose up -d kibana 
  docker compose up -d logstash
  docker compose up -d filebeat
  docker compose up -d metricbeat
  docker compose up -d portainer
  docker compose up -d web
  docker compose up -d jenkins
  ```
If you want only build container use this command.
```
docker-compose build -d
```
After building and creating containers services have such adresses and ports:
- Jenkins: localhost:8080
- Kibana: localhost:5601
- Portainer: localhost:9000
- Flask app: localhost:5000
4. Navigate to jenkins(Login: admin, Password: admin).
+ If you want to use github(by default basic scipts download from github repository) add credentials by this path **options->credentials**
By default in jenkins you can see one job - gatling. It is gatling tests based on **Gradle builder + gatling**
Job used pipeline script(Type of pipeline: scripted). 
+ Change you github credentials. Choose **Configure**. After that choose **Pipeline script**. Choose in dropdown **git** and fill all needed info. **Generate** and paste into script in image below.
+ If you want to know more about pipeline scripting you may read more [here][4]
5. Navigate to kibana.
+ You need to add dashboard. Open **Settings**. Open **Saved objects**. Click **import** and choose file in path(framework_path/kibana/gatling.ndjson)
+ After that check that you have all indices. Select index management. And check that you have **gatling** index

## Framework architecture
------------------
Framework consist of such aplications:
- Elasticsearch. Need to store all data and creating templates based on data.
- Kibana. Visualization of data. 
- Filebeat. Need to read data from load machine and send to logstash.
- Logstash. Modify data to common format and send to elasticsearch.
- Metricbeat. Get server metrics from docker containers and from host.
- Jenkins. Automate performance process.Need to run gatling and jmeter jobs.
- Portainer. Managing all docker containers.
- Flask app. Simple application with blog. Store data in SQLite3
------------------
###Architecture structure of framework with gatling


![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/framework_architecture.jpg "Framework architecture")


###Architecture structure of framework with jmeter




[2]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[3]: https://github.com/youketero/Performance_Framework
[4]: https://www.jenkins.io/doc/book/pipeline/syntax/ 
