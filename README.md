# Performance_Framework
----------------------
### Appendix 
[Preconfiguration](https://github.com/youketero/Performance_Framework#preconfigurationoptional-but-preferable)  
[Installing](https://github.com/youketero/Performance_Framework#installing)  
[Framework architecture](https://github.com/youketero/Performance_Framework#framework-architecture)   
[How to load Flask app](https://github.com/youketero/Performance_Framework#how-to-load-flask-app)   

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
4. Navigate to jenkins(Login: admin, Password: admin, **localhost:8080**).
+ If you want to use github(by default basic scipts download from github repository) add credentials by this path **options->credentials**
By default in jenkins you can see one job - gatling. It is gatling tests based on **Gradle builder + gatling**
Job used pipeline script(Type of pipeline: scripted). 
+ Change you github credentials. Click on gatling job. Choose **Configure**.
+ After that choose **Pipeline syntax**. 
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/Pipeline_syntax.jpg "Pipeline syntax")
+ Choose in dropdown **git** and fill all needed info. 
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/Git_hub.jpg "Git Hub config")
+ Add your credentials
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/Credentials.jpg "Credentials")
+ **Generate** and copy code.
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/Export_cred.jpg "Export credentials")
+ Paste into pipeline script.
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/pipeline_script.jpg "Pipeline script")
+ If you want to know more about pipeline scripting you may read more [here][4]
5. Navigate to kibana(**localhost:5601**).
+ You need to add dashboard. 
+ Open **Settings**. 
+ Open **Saved objects**.  
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/Management_kibana.jpg "Management") 
+ Click **import** and choose file in path(framework_path/kibana/gatling.ndjson or framework_path/kibana/jmeter.ndjson)  
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/Import_kibana.jpg "Import") 
+ After that check that you have all indices.
+ Select index management. And check that you have **gatling** or **jmeter** index  
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/Index_kibana.jpg "Index kibana") 
6. Run performance script to check that the framework works.


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

### Architecture structure of framework with gatling
------------------

![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/framework_architecture.jpg "Framework architecture gatling")

### Architecture structure of framework with jmeter
------------------

![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/architecture_jmeter.jpg "Framework architecture jmeter")


## How to load Flask app
----------
1. Open command line and write command  
```
ipconfig
```
2. Copy IP address and add port 5000. The final address is: YOUR_IP:5000
3. Add to your jmeter or gatling this address.
4. Done

## Jenkins jmeter test run
-----------  
  
How to run jmeter test. 
You can run test with parameters: THREAD - number of paralel users, LOOP - number of repeats, DURATION - duration of test(you can create perf test depends on loop or duration parameter. By default uses LOOP parameter).  
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/jenkins_jmeter.gif "Jenkins job")  
Also you can add your own parameters to pipeline and performance script and customize this job or create another.  

## Kibana dashboard for jmeter tests
-----------
For performance monitoring to kibana dashboad added.
Here some screenshots of vizualizations.
![alt-текст](https://github.com/youketero/Performance_Framework/blob/main/img/kibana_dashboard_jmeter.gif "Kibana dashboard for jmeter")

-----------
On the .gif you can see some dashboards
- Jmeter_controls. Filters to choose **Transaction name**, **Response code**, **CSV_File**
- Jmeter_average. Average response time of all transactions. If you choose in jmeter-controls **Transaction name** the average response will filter for choosen transaction.
- Jmeter_percentiles. Percentiles of response time.
- Jmeter_Errors_Num. Show number of errors in the performance test. 
- Jmeter_Data_Table. Show aggregate table metrics for each transactions.
- Jmeter_Response_Codes. Show response codes for all transactions.
- Jmeter_Response_Codes_Series. Show count of response codes depends on time.
- Jmeter_Response_Time_Percentiles. Show response percentiles.
- Jmeter_Count_vs_Average. Average response time distribution for each transaction.
- Jmeter_Response_Active_Threads. Average response time with number of active threads.
- Jmeter_Throughput. Number of transactions per time metric.
- Jmeter_Bytes. Number of received bytes.
-----------
You can add another visualizations to dashboard or create your own based on **jmeter** index.


[2]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[3]: https://github.com/youketero/Performance_Framework
[4]: https://www.jenkins.io/doc/book/pipeline/syntax/ 
