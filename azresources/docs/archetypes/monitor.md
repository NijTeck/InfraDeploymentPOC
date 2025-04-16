# Monitor Configuration

By default, this configuration group will create a resource group, an action group, multiple activity alerts and a service alerts.
All configuration files are the same except for four parameters

## Short Location Name
- Azure Commercial: east (Default Value)

## Network Name
- Either Subscription Name
  or
- If applicable, remove "sub-" from subscription name (default)

## serviceHealth\condition
Default Configuration.   Additional sites can be added.
### Azure Commercial:
                            "containsAny": [
                                "Global",
                                "central us"
                            ]


## serviceHealth\webhookProperties\serviceClass
- "serviceClass": "Non-Production" or "serviceClass": "Production"

# Maintainer
* Leonard Esere - [leonard.esere@flyfrontier.com](mailto:leonard.esere@flyfrontier.com)
