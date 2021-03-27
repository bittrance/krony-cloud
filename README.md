# Krony Cloud - learning Terraform and Kubernetes

This is my attempt to learn how to use Terraform to set up a simple cloud service on Kubernetes. The goal is to turn [dkron](https://github.com/distribworks/dkron) into a simple cloud service. dkron is a distributed service which can be instructed via REST API to perform HTTP calls periodically.

The end result should have
- dkron cluster that can be scaled without downtime,
- simple authentication,
- HTTPS with automatical certificate renewal,
- automatic registeration of REST endpoints and domain names, 
- no single point of faiulre, and
- gitops with staging and production environments

## In this repo

- **global/**: Terraform module with global control plane
- **enviornment/**: Terraform module for one environment, i.e. instantiated for staging and production. It defines a Kubernetes cluster and supporting services.
- **krony-app/**: Terraform module for the actual cloud service.
- **webhook-receiver/**: Microservice used as target for Dkron callbacks, see below.

### Webhook receiver

This tool is used to give Dkron something to call during load and acceptance testing. It has three endpoints:

- `PUT /log/:token`: adds an entry to the log. Each entry is a list of RFC3339 timestamps when calls where received for that particular token.
- `GET /logs`: Returns a mapping of tokens to timestamps, see below for example.
- `DELETE /logs`: Clears the entire mapping and starts from scratch.

A returned mapping might look like so:
```json
{
    "bar": [
        "2021-03-27T18:59:30.072822641+01:00",
    ],
    "foo": [
        "2021-03-27T18:59:30.071508593+01:00",
        "2021-03-27T18:59:30.072207055+01:00",
    ],
}
```

## Testing the service

dkron provides cluster health:
```
$ curl http://api.staging.krony.cloud/v1/
{"agent":{"name":"dkron-545bf86ffc-flfm4","version":"3.1.5"},"serf":{"coordinate_resets":"0","encrypted":"false","event_queue":"0","event_time":"1","failed":"2","health_score":"0","intent_queue":"0","left":"0","member_time":"7","members":"5","query_queue":"0","query_time":"1"},"tags":{"dc":"dc1","expect":"2","port":"6868","region":"global","role":"dkron","rpc_addr":"10.244.0.29:6868","server":"true","version":"3.1.5"}}
```

## Third-party software

Azure Kubernetes Service - managed Kubernetes
dkron - distributed job scheduler
external-dns - Azure DNS auto-registration
Traefik - ingress controller