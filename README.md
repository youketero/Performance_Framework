# Performance_Framework
## Preconfiguration(optional but preferable)
---------------
You need this items for performance framework
- Install docker [Docker install website][1]
- Install WSL 2(optional)[WSL2 install guide][2]
- Install Java(8 version or higher) 
## Installing
---------------
For installing and building framework you need to:
- Download repository: [here][3]
- For quick install navigate to repository dir and choose framework load tool(jmeter or gatling).
- ```docker-compose up -d```
- If you want to install separate container
```docker compose up -d elasticsearch
  docker compose up -d kibana 
  docker compose up -d logstash
  docker compose up -d filebeat
  docker compose up -d metricbeat
  docker compose up -d portainer
  docker compose up -d web
  docker compose up -d jenkins```


[1]: https://docs.docker.com/engine/install/
[2]: https://docs.microsoft.com/en-us/windows/wsl/install-win10
[3]: https://github.com/youketero/Performance_Framework