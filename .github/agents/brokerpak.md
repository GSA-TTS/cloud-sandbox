---
sources: 
  - https://github.com/cloudfoundry/cloud-service-broker/blob/main/docs/brokerpak-dissection.md
  - https://github.com/cloudfoundry/cloud-service-broker/blob/main/docs/configuration.md
  - https://github.com/cloudfoundry/cloud-service-broker/blob/main/docs/brokerpak-specification.md
---

# Dissecting a Brokerpak

So you want to build a brokerpak from scratch? As long as you can write some code based on OpenTofu to control whatever
resource you're interested in controlling, and the lifecycle can be mapped into the
[OSBAPI API](https://www.openservicebrokerapi.org/), you should be able to write a brokerpak to fulfill your needs.

Hopefully this document helps familiarize you enough with layout and details of the brokerpak specification to help you
along the way.

> Note: OpenTofu replaced Terraform in the CSB starting with version 1.0.0.
> There may still be some references to Terraform in the codebase.

## Requirements

### Talent

* familiarity with [yaml](https://yaml.org/spec/1.2/spec.html) - yaml glues all the pieces together.
* knowledge of [OpenTofu](https://opentofu.org/) - OpenTofu language scripts do the heavy lifting of managing resource
  lifecycle.

## References

* [Brokerpak Introduction](./brokerpak-intro.md)
* [Brokerpak Specification](./brokerpak-specification.md)

## The Azure Brokerpak

Browse the brokerpak contents [here](https://github.com/cloudfoundry/cloud-service-broker/tree/master/azure-brokerpak)

Have a look at the Azure brokerpak, starting with
*[manifest.yml](https://github.com/cloudfoundry/csb-brokerpak-azure/blob/master/manifest.yml)*

The file should resemble:

```yaml
packversion: 1
name: azure-services
version: 0.1.0
metadata:
  author: VMware
platforms:
- os: linux
  arch: amd64
- os: darwin
  arch: amd64
terraform_binaries:
- name: tofu
  version: 1.6.1
  source: https://github.com/opentofu/opentofu/archive/refs/tags/v1.6.1.zip
- name: terraform-provider-azurerm
  version: 2.20.0
  source: https://github.com/terraform-providers/terraform-provider-azurerm/archive/v2.20.0.zip
- name: terraform-provider-random
  version: 2.2.1
  source: https://releases.hashicorp.com/terraform-provider-random/2.2.1/terraform-provider-random_2.2.1_linux_amd64.zip
- name: terraform-provider-mysql
  version: 1.9.0
  source: https://releases.hashicorp.com/terraform-provider-mysql/1.9.0/terraform-provider-mysql_1.9.0_linux_amd64.zip 
- name: terraform-provider-null
  version: 2.1.2
  source: https://releases.hashicorp.com/terraform-provider-null/2.1.2/terraform-provider-null_2.1.2_linux_amd64.zip
- name: psqlcmd
  version: 0.1.0
  source: https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
  url_template: ../build/${name}_${version}_${os}_${arch}.zip
- name: sqlfailover
  version: 0.1.0
  source: https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
  url_template: ../build/${name}_${version}_${os}_${arch}.zip  
- name: terraform-provider-postgresql
  version: 1.5.0
  source: https://github.com/terraform-providers/terraform-provider-postgresql/archive/v1.5.0.zip
env_config_mapping:
  ARM_SUBSCRIPTION_ID: azure.subscription_id
  ARM_TENANT_ID: azure.tenant_id
  ARM_CLIENT_ID: azure.client_id
  ARM_CLIENT_SECRET: azure.client_secret
service_definitions:
- azure-redis.yml
- azure-mysql.yml
- azure-mssql.yml
- azure-mssql-failover.yml
- azure-mongodb.yml
- azure-eventhubs.yml
- azure-mssql-db.yml
- azure-mssql-server.yml
- azure-mssql-db-failover.yml
- azure-mssql-fog-run-failover.yml
- azure-resource-group.yml
- azure-postgres.yml
- azure-storage-account.yml
- azure-cosmosdb-sql.yml
```

Let's break it down.

### Header

```yaml
packversion: 1
name: azure-services
version: 0.1.0
metadata:
  author: VMware
```

Metadata about the brokerpak.

| Field       | Value                              |
|-------------|------------------------------------|
| packversion | should always be 1                 |
| name        | name of brokerpak                  |
| version     | version of brokerpak               |
| metadata    | a map of metadata to add to broker |

Besides *packversion* (which should always be 1), these values are left to the brokerpak author to describe the
brokerpak.

### Platforms

```yaml
platforms:
- os: linux
  arch: amd64
- os: darwin
  arch: amd64
```

Describes which platforms the brokerpak should support. Typically, *os: linux* is the minimum required for `cf push`ing
the broker into CloudFoundry. For local development on OSX, adding *os: darwin* allows the broker to run locally.

### Binaries

```yaml
terraform_binaries:
- name: tofu
  version: 1.6.1
  source: https://github.com/opentofu/opentofu/archive/refs/tags/v1.6.1.zip
- name: terraform-provider-azurerm
  version: 2.20.0
  source: https://github.com/terraform-providers/terraform-provider-azurerm/archive/v2.20.0.zip
- name: terraform-provider-random
  version: 2.2.1
  source: https://releases.hashicorp.com/terraform-provider-random/2.2.1/terraform-provider-random_2.2.1_linux_amd64.zip
- name: terraform-provider-mysql
  version: 1.9.0
  source: https://releases.hashicorp.com/terraform-provider-mysql/1.9.0/terraform-provider-mysql_1.9.0_linux_amd64.zip 
- name: terraform-provider-null
  version: 2.1.2
  source: https://releases.hashicorp.com/terraform-provider-null/2.1.2/terraform-provider-null_2.1.2_linux_amd64.zip
- name: psqlcmd
  version: 0.1.0
  source: https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
  url_template: ../build/${name}_${version}_${os}_${arch}.zip
- name: sqlfailover
  version: 0.1.0
  source: https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
  url_template: ../build/${name}_${version}_${os}_${arch}.zip  
- name: terraform-provider-postgresql
  version: 1.5.0
  source: https://github.com/terraform-providers/terraform-provider-postgresql/archive/v1.5.0.zip
  ```

This section defines all the binaries and OpenTofu providers that will be bundled into the brokerpak when its built.
The *os* and *arch* parameters are substituted from the platforms section above.

| Field        | Value                                                                                                                                           |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| name         | name of artifact                                                                                                                                |
| version      | version of artifact                                                                                                                             |
| source       | URL for source code archive of artifact, which can optionally be included in the brokerpak.                                                     |
| url_template | non-standard location to copy artifact from (default: *https://releases.hashicorp.com/${name}/${version}/${name}_${version}_${os}_${arch}.zip*) |

### Environment Config Mapping

The broker can be supplied runtime configuration through environment variables and/or a configuration file. Those values
can be made available for use in the brokerpak (see [here](brokerpak-specification.md#functions))
via `config("config.key")`

To map values supplied as environment variables (often when `cf push`ing the broker) into config keys that may be
referenced in the brokerpak, add them to the *environment_config_mapping* section of the manifest:

```yaml
env_config_mapping:
  ARM_SUBSCRIPTION_ID: azure.subscription_id
  ARM_TENANT_ID: azure.tenant_id
  ARM_CLIENT_ID: azure.client_id
  ARM_CLIENT_SECRET: azure.client_secret
  ```

These make the runtime environment variables *ARM_SUBSCRIPTION_ID*, *ARM_TENANT_ID*, *ARM_CLIENT_ID* and
*ARM_CLIENT_SECRET* available as config values *azure.subscription_id*, *azure.tenant_id*, *azure.client_id*, and
*azure.client_secret* respectively.

### Service Definitions

The final section references the yml files that describe the services that will be supported by the brokerpak.

```yaml
service_definitions:
- azure-redis.yml
- azure-mysql.yml
- azure-mssql.yml
- azure-mssql-failover.yml
- azure-mongodb.yml
- azure-eventhubs.yml
- azure-mssql-db.yml
- azure-mssql-server.yml
- azure-mssql-db-failover.yml
- azure-mssql-fog-run-failover.yml
- azure-resource-group.yml
- azure-postgres.yml
- azure-storage-account.yml
- azure-cosmosdb-sql.yml
```

Each of these service yml files and their requisite OpenTofu language will be bundled into the brokerpak.

## A Service Definition

Now lets dive into one of the service yaml files,
*[azure-mssql-db.yml](https://github.com/cloudfoundry/csb-brokerpak-azure/blob/master/azure-mssql-db.yml)*

```yaml
version: 1
name: csb-azure-mssql-db
id: 6663f9f1-33c1-4f7d-839c-d4b7682d88cc
description: Manage Azure SQL Databases on pre-provisioned database servers
display_name: Azure SQL Database
provider_display_name: Company Name
image_url: https://msdnshared.blob.core.windows.net/media/2017/03/azuresqlsquaretransparent1.png
documentation_url: https://docs.microsoft.com/en-us/azure/sql-database/
support_url: https://docs.microsoft.com/en-us/azure/sql-database/
tags: [azure, mssql, sqlserver, preview]
plan_updateable: true
plans:
- name: small
  id: fd07d12b-94f8-4f69-bd5b-e2c4e84fafc1
  description: 'SQL Server latest version. Instance properties: General Purpose - Serverless ; 0.5 - 2 cores ; Max Memory: 6gb ; 50 GB storage ; auto-pause enabled after 1 hour of inactivity'
  display_name: "Small"
  properties:
    subsume: false
- name: medium
  id: 3ee14bce-33e8-4d02-9850-023a66bfe120
  description: 'SQL Server latest version. Instance properties: General Purpose - Provisioned ; Provisioned Capacity ; 8 cores ; 200 GB storage'
  display_name: "Medium"
  properties:
    cores: 8
    max_storage_gb: 200
    subsume: false
- name: large
  id: 8f1c9c7b-80b2-49c3-9365-a3a059df9907
  description: 'SQL Server latest version. Instance properties: Business Critical ; Provisioned Capacity ; 32 cores ; 500 GB storage'
  display_name: "Large"
  properties:
    cores: 32
    max_storage_gb: 500
    subsume: false
- name: extra-large
  id: 09096759-58a8-41d0-96bf-39b02a0e4104
  description: 'SQL Server latest version. Instance properties: Business Critical ; Provisioned Capacity ; 80 cores ; 1 TB storage'
  display_name: "Extra Large"
  properties:
    cores: 80
    max_storage_gb: 1024
    subsume: false
- name: subsume
  id: 7781fa41-f486-447a-942c-ded8cccb8299
  description: 'Subsume control of an existing SQL Database'
  display_name: "Subsume"
  properties:
    subsume: true
provision:
  import_inputs:
  - field_name: azure_db_id
    type: string
    details: Azure resource id for database to subsume
    tf_resource: azurerm_mssql_database.azure_sql_db
  import_parameter_mappings:
  - tf_variable: sku_name
    parameter_name: local.sku_name
  - tf_variable: max_size_gb
    parameter_name: var.max_storage_gb 
  - tf_variable: tags
    parameter_name: var.labels
  - tf_variable: retention_days
    parameter_name: var.short_term_retention_days
  import_parameters_to_delete: [ "azurerm_mssql_database.azure_sql_db.id", 
                                 "azurerm_mssql_database.azure_sql_db.min_capacity",
                                 "azurerm_mssql_database.azure_sql_db.long_term_retention_policy",
                                 "azurerm_mssql_database.azure_sql_db.extended_auditing_policy"]
  plan_inputs:
  - field_name: subsume
    type: boolean
    details: Subsume existing DB
  user_inputs:
  - field_name: cores
    type: number
    default: 2
    details: Number vcores for the instance (upto the maximum allowed for the service tier)
    constraints:
      maximum: 80
      minimum: 1
      multipleOf: 2
  - field_name: max_storage_gb
    type: number
    default: 5
    details: Maximum storage allocated to the database instance in GB      
  - field_name: db_name
    type: string
    details: Name for your database
    default: csb-db-${request.instance_id}
    constraints:
      maxLength: 64
  - field_name: server
    type: string
    details: Name of server from server_credentials to create database upon
    required: true
  - field_name: server_credentials
    type: object
    details: 'JSON has of server credentials. { "name1":{"server_name":"...", "server_resource_group":"...", "admin_username":"...", "admin_password":"..."},"name2":{...}...}'
    required: true
  - field_name: azure_tenant_id
    type: string
    details: Azure Tenant to create resource in
    default: ${config("azure.tenant_id")}      
  - field_name: azure_subscription_id
    type: string
    details: Azure Subscription to create resource in
    default: ${config("azure.subscription_id")}      
  - field_name: azure_client_id
    type: string
    details: Client ID of Azure principal 
    default: ${config("azure.client_id")}      
  - field_name: azure_client_secret
    type: string
    details: Client secret for Azure principal
    default: ${config("azure.client_secret")}
  - field_name: skip_provider_registration
    type: boolean
    details: Skip automatic Azure provider registration, set to true if service principal being used does not have rights to register providers
    default: false    
  - field_name: sku_name
    type: string
    details: Azure sku (typically, tier [GP_S,GP,BC,HS] + family [Gen4,Gen5] + cores, e.g. GP_S_Gen4_1, GP_Gen5_8) Will be computed from cores if empty.
    default: ""       
  - field_name: short_term_retention_days
    type: number
    details: Retention period in days for short term retention (Point in Time Restore) policy
    default: 7
    constraints:
      maximum: 35
  template_refs:
    outputs: terraform/azure-mssql-db/mssql-db-outputs.tf
    provider: terraform/azure-mssql-db/azure-provider.tf
    variables: terraform/azure-mssql-db/mssql-db-variables.tf
    main: terraform/azure-mssql-db/mssql-db-main.tf
    data: terraform/azure-mssql-db/mssql-db-data.tf
  computed_inputs:
  - name: labels
    default: ${json.marshal(request.default_labels)}
    overwrite: true
    type: object
  outputs:
  - field_name: sqlServerName
    type: string
    details: Hostname of the Azure SQL Server
  - field_name: sqldbName
    type: string
    details: The name of the database.    
  - field_name: sqlServerFullyQualifiedDomainName
    type: string
    details: The fully qualifief domain name (FQDN) of the Azure SQL Server
  - field_name: hostname
    type: string
    details: Hostname of the Azure SQL Server
  - field_name: port
    type: integer
    details: The port number to connect to the database on
  - field_name: name
    type: string
    details: The name of the database.
  - field_name: username
    type: string
    details: The username to authenticate to the database server.
  - field_name: password
    type: string
    details: The password to authenticate to the database server.
bind:
  plan_inputs: []
  user_inputs: []
  computed_inputs:
  - name: mssql_db_name
    type: string
    default: ${instance.details["name"]}
    overwrite: true
  - name: mssql_hostname
    type: string
    default: ${instance.details["hostname"]}
    overwrite: true
  - name: mssql_port
    type: integer
    default: ${instance.details["port"]}
    overwrite: true
  - name: admin_username
    type: string
    default: ${instance.details["username"]}
    overwrite: true
  - name: admin_password
    type: string
    default: ${instance.details["password"]}
    overwrite: true
  template_ref: terraform/azure-mssql/bind-mssql.tf
  outputs:
  - field_name: username
    type: string
    details: The username to authenticate to the database instance.
  - field_name: password
    type: string
    details: The password to authenticate to the database instance.  
  - field_name: uri
    type: string
    details: The uri to connect to the database instance and database.
  - field_name: jdbcUrl
    type: string
    details: The jdbc url to connect to the database instance and database.    
  - field_name: jdbcUrlForAuditingEnabled
    type: string
    details: The audit enabled JDBC URL to connect to the database server and database.    
  - field_name: databaseLogin
    type: string
    details: The username to authenticate to the database server.
  - field_name: databaseLoginPassword
    type: string
    details: The password to authenticate to the database server. 
```

Time to break it all down.

### Header

```yaml
version: 1
name: csb-azure-mssql-db
id: 6663f9f1-33c1-4f7d-839c-d4b7682d88cc
description: Manage Azure SQL Databases on pre-provisioned database servers
display_name: Azure SQL Database
provider_display_name: Company Name
image_url: https://msdnshared.blob.core.windows.net/media/2017/03/azuresqlsquaretransparent1.png
documentation_url: https://docs.microsoft.com/en-us/azure/sql-database/
support_url: https://docs.microsoft.com/en-us/azure/sql-database/
tags: [azure, mssql, sqlserver, preview]
plan_updateable: true
```

Metadata about the service.

| Field                 | Value                                                                |
|-----------------------|----------------------------------------------------------------------|
| version               | should always be 1                                                   |
| name                  | name of service                                                      |
| id                    | a unique guid                                                        |
| description           | human readable description of service                                |
| display_name          | human readable name of the service                                   |
| provider_display_name | name of the provider of this service                                 |
| image_url             | a link to an image that may be included in documentation             |
| documentation_url     | link to external documentation that may be included in documentation |
| support_url           | link to external support site that may be included in documentation  |
| tags                  | list of tags that will be provided in service bindings               |
| plan_updateable       | indicates if service support `cf update-service -p`                  |

Besides *version* (which should always be 1) these values are left to the brokerpak author to describe the service.

### Plans

Next is a list of plans that will be provided as defaults by the service.

```yaml
plans:
- name: small
  id: fd07d12b-94f8-4f69-bd5b-e2c4e84fafc1
  description: 'SQL Server latest version. Instance properties: General Purpose - Serverless ; 0.5 - 2 cores ; Max Memory: 6gb ; 50 GB storage ; auto-pause enabled after 1 hour of inactivity'
  display_name: "Small"
  properties:
    subsume: false
- name: medium
  ...
```

There may be zero or more plan entries.

| Field        | Value                                                                                                    |
|--------------|----------------------------------------------------------------------------------------------------------|
| name         | name of plan                                                                                             |
| id           | a unique guid                                                                                            |
| description  | human readable description of plan                                                                       |
| display_name | human readable plan name                                                                                 |
| properties   | list of property values for plan settings, property names must be defined in plan_inputs and user_inputs | 

### Provision and Bind

The *provision* and *bind* sections contain the inputs, outputs and OpenTofu code for the provision and bind
operation for the service. They are identical in form, the following sections apply to both.

```yaml
provision:
  plan_inputs:
    ...
  user_inputs:
    ...
  ...
bind:
  user_inputs:
    ...
  ...   
```

### Plan Inputs

Configuration parameters that can only be set as part of plan description. Users may not set these parameters through `cf create-service ... -c {...}` or `cf update-service ... -c {...}`

```yaml
  plan_inputs:
  - field_name: subsume
    type: boolean
    details: Subsume existing DB
```

| Field      | Value                               |
|------------|-------------------------------------|
| field_name | name of plan variable               |
| type       | field type                          |
| details    | human readable description of field |

> The plan input *subsume* has special meaning. It is used to designate a plan for `tf import` to take over an existing resource. When *subsume* is true, all *import_parameter_mappings* values must be provided through `cf create-service ... -c {...}` and `cf update-service ... -p subsume` is prohibited.

> input fields must be declared as OpenTofu *variables*. Failure to do so will result in failures to build brokerpak.

### User Inputs

Configuration parameters that my be set as part of a plan or set by the user through `cf create-service ... -c {...}` or `cf update-service ... -c {...}`

```yaml
  user_inputs:
  - field_name: cores
    type: number
    default: 2
    details: Number vcores for the instance (upto the maximum allowed for the service tier)
    constraints:
      maximum: 80
      minimum: 1
      multipleOf: 2
```

| Field       | Value                                                                                                         |
|-------------|---------------------------------------------------------------------------------------------------------------|
| field_name  | name of user variable                                                                                         |
| type        | field type                                                                                                    |
| details     | human readable description of field                                                                           |
| default     | (optional) default value for field                                                                            |
| constraints | (optional) Holds additional JSONSchema validation for the field. Feature flag `enable-catalog-schemas`        |
|             | controls whether to serve Json schemas in catalog. The following keys are supported:                          |
|             | `examples`, `const`, `multipleOf`, `minimum`, `maximum`, `exclusiveMaximum`, `exclusiveMinimum`, `maxLength`, |
|             | `minLength`, `pattern`, `maxItems`, `minItems`, `maxProperties`, `minProperties`, and `propertyNames`.        |

> input fields must be declared as OpenTofu *variables*. Failure to do so will result in failures to build brokerpak.

### Import Inputs

In order to support `tofu import` to subsume control of existing resources (instead of creating new resources) parameters
that represent native resources and the OpenTofu resources they apply to are described in the *import_inputs* section.

```yaml
  import_inputs:
  - field_name: azure_db_id
    type: string
    details: Azure resource id for database to subsume
    tf_resource: azurerm_mssql_database.azure_sql_db
```

| Field       | Value                                            |
|-------------|--------------------------------------------------|
| field_name  | name of user variable                            |
| type        | field type                                       |
| details     | human readable description of field              |
| tf_resource | resource.instance of OpenTofu resource to import |

A user will provide the values through `cf create-service ... -c {...}` and the broker will use them during
the `tf import` phase.

### Import Parameter Mapping

Once `tofu import` is run to generate matching OpenTofu for the resource, some values may need to be parameterized so
that the user may modify them later through `cf update-service`  The

```yaml
  import_parameter_mappings:
  - tf_variable: max_size_gb
    parameter_name: var.max_storage_gb 
```

This will cause instances of *max_size_gb = ...* in the resulting imported code to be replaced with
*max_size_gb = var.max_storage_gb* so that it may be updated by the user with `cf update-service ...`

### Import Parameters to Delete

`tofu import` will return all current values for a resource, including those that are readonly and my not be set
during `tofu apply`. List those resource values in *import_parameters_to_delete,* and they will be removed
between `tofu import` and `tofu apply`

```yaml
  import_parameters_to_delete: [ "azurerm_mssql_database.azure_sql_db.id", 
                                 "azurerm_mssql_database.azure_sql_db.min_capacity",
                                 "azurerm_mssql_database.azure_sql_db.long_term_retention_policy",
                                 "azurerm_mssql_database.azure_sql_db.extended_auditing_policy"]
```

### OpenTofu Template References

The OpenTofu language that will be executed for provision or bind is referenced in *template_refs*

```yaml
  template_refs:
    outputs: terraform/azure-mssql-db/mssql-db-outputs.tf
    provider: terraform/azure-mssql-db/azure-provider.tf
    variables: terraform/azure-mssql-db/mssql-db-variables.tf
    main: terraform/azure-mssql-db/mssql-db-main.tf
    data: terraform/azure-mssql-db/mssql-db-data.tf
```

See [here](./brokerpak-specification.md#template-references) for details.

### Outputs

Outputs from OpenTofu will be collected into binding credentials.

```yaml
  outputs:
  - field_name: username
    type: string
    details: The username to authenticate to the database instance.
```

| Field      | Value                                      |
|------------|--------------------------------------------|
| field_name | name of output field                       |
| type       | field type                                 |
| details    | Human readable description of output field |

> output fields *must* be declared as *output* variables in OpenTofu language. Failure to do so will result in failures
> creating brokerpak

> binding credentials will contain all output variables from both the *provision* and *bind* portions of the service
> yaml.

> there is a special output parameter called *status* that may be declared in OpenTofu language, it does not need to be
> declared in the service manifest yaml. The *status* output value will be returned as the status message for the OSBAPI
> provision call and will be displayed to the user as the *message* portion of a `cf service <service name>` command. It
> is recommended that resource ID's and other information that may help a user identify the managed resource.


# Broker Configuration
The broker can be configured though environment variables or configuration files or a combo of both.

## Configuration File
A configuration file can be provided at run time to the broker.
```bash
cloud-service-broker serve --config <config file name>
```

A configuration file can be YAML or JSON. Config file values that are `.` delimited represent hierarchy in the config file.

Example:
```
db:
  host: hostname
```
represents a config file value of `db.host`

## Database Configuration Properties

Connection details for the backing database for the service broker.

You can configure the following values:

| Environment Variable | Config File Value | Type    | Description                                                                                                                                   |
|----------------------|------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| <tt>DB_HOST</tt> <b>*</b> | db.host | string  | <p>Database host </p>                                                                                                                         |
| <tt>DB_USERNAME</tt> | db.user | string  | <p>Database username </p>                                                                                                                     |
| <tt>DB_PASSWORD</tt> | db.password | secret  | <p>Database password </p>                                                                                                                     |
| <tt>DB_PORT</tt> <b>*</b> | db.port | string  | <p>Database port (defaults to 3306)  Default: <code>3306</code></p>                                                                           |
| <tt>DB_NAME</tt> <b>*</b> | db.name | string  | <p>Database name  Default: <code>servicebroker</code></p>                                                                                     |
| <tt>DB_TLS</tt> <b>*</b>      | db.tls   | string  | <p>Enforce TLS on connection to Database. Allowed values:<code>true</code>,<code>false</code>,<code>skip-verify</code>,<code>custom</code></p> |
| <tt>CUSTOM_CERT_TLS_SKIP_VERIFY</tt> <b>*</b>      | db.custom_certs.tls_skip_verify   | bool    | <p>Skip TLS verification when using custom certificates. Default: <code>true</code></p> |
| <tt>CA_CERT</tt> | db.ca.cert | text    | <p>Server CA cert </p>                                                                                                                        |
| <tt>CLIENT_CERT</tt> | db.client.cert | text    | <p>Client cert </p>                                                                                                                           |
| <tt>CLIENT_KEY</tt> | db.client.key | text    | <p>Client key </p>                                                                                                                            |
| <tt>ENCRYPTION_ENABLED</tt> | db.encryption.enabled | Boolean | <p>Enable encryption of sensitive data in the database </p>                                                                                   |
| <tt>ENCRYPTION_PASSWORDS</tt> | db.encryption.passwords | text    | <p>JSON collection of passwords </p>                                                                                                          |

Example:
```
db:
  host: hostname
  encryption:
    enabled: true
    passwords: "[{\"label\":\"first-password\",{\"password\":{\"secret\": \"veryStrongSecurePassword\"}},\"primary\": true}]"
```

Example Encryption Passwords JSON object: 
```
[
  {
    "label": "first-password",
    "password": {
      "secret": "veryStrongSecurePassword"
    },
    "primary": true
  }
]
```

### Enabling first time encryption
1. Set `encryption.enabled` to `true` and add a password to the collection of passwords and mark it as primary.
1. Restart the CSB app.

### Rotating encryption keys

1. Add a new password to the collection of passwords and mark it as primary. The previous primary password should still be provided and 
no longer marked as primary.
1. Restart the CSB app.
1. Once the app has successfully started, the old password(s) can be removed from the configuration.

### Disabling encryption (after it was enabled)
1. Set `encryption.enabled` to `false`. The previous primary password should still be provided and no longer marked as primary.
1. Restart the CSB app.
1. Once the app has successfully started, the old password(s) can be removed from the configuration.

## Broker Service Configuration

Broker service configuration values:

| Environment Variable | Config File Value | Type | Description |
|----------------------|------|-------------|------------------|
| <tt>SECURITY_USER_NAME</tt> <b>*</b> | api.user | string | <p>Broker authentication username</p>|
| <tt>SECURITY_USER_PASSWORD</tt> <b>*</b> | api.password | string | <p>Broker authentication password</p>|
| <tt>PORT</tt> | api.port | string | <p>Port to bind broker to</p>|
| <tt>TLS_CERT</tt> | api.tlsCert | string | <p>File path to a pem encoded certificate</p>|
| <tt>TLS_PRIVATE_KEY</tt> | api.tlsKey | string | <p>File path to a pem encoded private key</p>|


## Debugging
Values for debugging:

| Environment Variable                   | Config File Value         | Type | Description                                                                                     |
|----------------------------------------|---------------------------|------|-------------------------------------------------------------------------------------------------|
| <tt>CSB_DEBUG_LEAVE_WORKSPACE_DIR</tt> | debug.leave_workspace_dir | bool | Disables the cleanup of workspace directories, so you can inspect the files and run tf commands |
| <tt>CSB_LOG_LEVEL</tt> | (none) | string | Sets the logging level to the specified value, which can be one of `debug`, `info`, `error`, `fatal` |
| <tt>GSB_DEBUG</tt> | (none) | bool | If set to any value, the log level is set to `debug`. Overrides `CSB_LOG_LEVEL` |

## Feature flags Configuration

Feature flags can be toggled through the following configuration values. See also [source code occurences of "toggles.Features.Toggle"](https://github.com/cloudfoundry/cloud-service-broker/search?q=toggles.Features.Toggle&type=code)

| Environment Variable | Config File Value | Type | Description | Default |
|----------------------|------|-------------|------------------|----------|
| <tt>GSB_COMPATIBILITY_ENABLE_BUILTIN_BROKERPAKS</tt> <b>*</b> | compatibility.enable_builtin_brokerpaks | Boolean | <p>Load brokerpaks that are built-in to the software.</p>| "true" |
| <tt>GSB_COMPATIBILITY_ENABLE_CATALOG_SCHEMAS</tt> <b>*</b> | compatibility.enable_catalog_schemas | Boolean | <p>Enable generating JSONSchema for the service catalog.</p>| "false" |
| <tt>GSB_COMPATIBILITY_ENABLE_CF_SHARING</tt> <b>*</b> | compatibility.enable_cf_sharing | Boolean | <p>Set all services to have the Sharable flag so they can be shared</p>| "false" |
| <tt>GSB_COMPATIBILITY_ENABLE_EOL_SERVICES</tt> <b>*</b> | compatibility.enable_eol_services | Boolean | <p>Enable broker services that are end of life.</p>| "false" |
| <tt>GSB_COMPATIBILITY_ENABLE_BETA_SERVICES</tt> <b>*</b> | compatibility.enable_beta_services | Boolean | <p>Enable services that are in Beta. These have no SLA or support</p>| "false" |
| <tt>GSB_COMPATIBILITY_ENABLE_GCP_DEPRECATED_SERVICES</tt> <b>*</b> | compatibility.enable_gcp_deprecated_services | Boolean | <p>Enable services that use deprecated GCP components.</p>| "false" |
| <tt>GSB_COMPATIBILITY_ENABLE_PREVIEW_SERVICES</tt> <b>*</b> | compatibility.enable_preview_services | Boolean | <p>Enable services that are new to the broker this release.</p>| "true" |
| <tt>GSB_COMPATIBILITY_ENABLE_TERRAFORM_SERVICES</tt> <b>*</b> | compatibility.enable_terraform_services | Boolean | <p>Enable services that use the experimental, unstable, Terraform back-end.</p>| "false" |
| <tt>GSB_COMPATIBILITY_ENABLE_UNMAINTAINED_SERVICES</tt> <b>*</b> | compatibility.enable_unmaintained_services | Boolean | <p>Enable broker services that are unmaintained.</p>| "false" |
| <tt>TERRAFORM_UPGRADES_ENABLED</tt> <b>*</b> | brokerpak.terraform.upgrades.enabled | Boolean | <p>Enables terraform version upgrades when brokerpak specifies an upgrade path and an upgrade is requested for an instance.</p>| "false" |
| <tt>BROKERPAK_UPDATES_ENABLED</tt> <b>*</b> | brokerpak.updates.enabled | Boolean | <p>Enable update of HCL of existing instances on update. When false, any update will be executed with the same HCL the instance was created with. If true, updates will be executed with newest specification in the brokerpak.</p>| "false" |

## Credhub Configuration
The broker supports passing credentials to apps via [credhub references](https://github.com/cloudfoundry-incubator/credhub/blob/master/docs/secure-service-credentials.md#service-brokers), thus keeping them private to the application (they won't show up in `cf env app_name` output.)

| Environment Variable | Config File Value | Type | Description |
|----------------------|------|-------------|------------------|
| CH_CRED_HUB_URL           |credhub.url    | URL | credhub service URL - usually `https://credhub.service.cf.internal:8844`|
| CH_UAA_URL                |credhub.uaa_url | URL | uaa service URL - usually `https://uaa.service.cf.internal:8443`|
| CH_UAA_CLIENT_NAME        |credhub.uaa_client_name| string | uaa username - usually `credhub_admin_client`|
| CH_UAA_CLIENT_SECRET      |credhub.uaa_client_secret| string | uaa client secret - "*Credhub Admin Client Credentials*" from *Operations Manager > PAS > Credentials* tab. |
| CH_SKIP_SSL_VALIDATION    |credhub.skip_ssl_validation| boolean | skip SSL validation if true | 
| CH_CA_CERT                |credhub.ca_cert| string | CA cert |
### Credhub Config Example (Azure) 
```
azure:
  subscription_id: your subscription id
  tenant_id: your tenant id
  client_id: your client id
  client_secret: your client secret
db:
  host: your mysql host
  password: your mysql password
  user: your mysql username
api:
  user: someusername
  password: somepassword
credhub:
  url: ...
  uaa_url: ...
  uaa_client_name: ...
  uaa_client_secret: ...
 ```

## Brokerpak Configuration

Brokerpak configuration values:
| Environment Variable | Config File Value | Type | Description |
|----------------------|------|-------------|------------------|
| <tt>GSB_BROKERPAK_BUILTIN_PATH</tt> | brokerpak.builtin.path | string | <p>Path to search for .brokerpak files, default: <code>./</code></p>|
|<tt>GSB_BROKERPAK_CONFIG</tt>|brokerpak.config| string | JSON global config for broker pak services|
|<tt>GSB_PROVISION_DEFAULTS</tt>|provision.defaults| string | JSON global provision defaults|
|<tt>GSB_SERVICE_*SERVICE_NAME*_PROVISION_DEFAULTS</tt>|service.*service-name*.provision.defaults| string | JSON provision defaults override for *service-name*|
|<tt>GSB_SERVICE_*SERVICE_NAME*_PLANS</tt>|service.*service-name*.plans| string | JSON plan collection to augment plans for *service-name*|


## CLI Configuration

The `cloud-service-broker pak` command supports the following configuration values:

| Environment Variable | Config File Value | Type | Description |
| - | - | - | - |
| <tt>PAK_BUILD_CACHE_PATH</tt> | pak.cache_path | string | Set to a non-empty file system path to use a cache when `csb pak build` downloads binaries |
\


# Brokerpak V1 specification

This document will explain how a brokerpak is structured, and the schema it follows.

> Note: OpenTofu replaced Terraform in the CSB starting with version 1.0.0.
> There may still be some references to Terraform in the codebase.

A brokerpak consists of a versioned OpenTofu binary and providers for one
or more platform, a manifest, one or more service definitions, and source code.
Here are the contents of an example brokerpak:

```
.
├── bin
│   └── linux
│       └── amd64
│           ├── 1.6.1
│           │   ├── CHANGELOG.md
│           │   ├── LICENSE
│           │   ├── README.md
│           │   └── tofu
│           ├── LICENSE
│           ├── README.md
│           ├── terraform-provider-aws_v5.42.0_x5
│           ├── terraform-provider-csbdynamodbns_v1.0.0
│           ├── terraform-provider-csbmajorengineversion_v1.0.0
│           ├── terraform-provider-csbmysql_v1.2.27
│           ├── terraform-provider-csbpg_v1.2.21
│           ├── terraform-provider-csbsqlserver_v1.0.12
│           └── terraform-provider-random_v3.6.0_x5
├── definitions
│   ├── service0-csb-aws-mysql.yml
│   ├── service1-csb-aws-redis.yml
│   ├── service2-csb-aws-postgresql.yml
│   ├── service3-csb-aws-s3-bucket.yml
│   ├── service4-csb-aws-dynamodb-table.yml
│   ├── service5-csb-aws-dynamodb-namespace.yml
│   ├── service6-csb-aws-aurora-postgresql.yml
│   ├── service7-csb-aws-aurora-mysql.yml
│   ├── service8-csb-aws-mssql.yml
│   └── service9-csb-aws-sqs.yml
├── file.txt
└── manifest.yml
```

You can create, inspect, validate, document and test brokerpaks using the `pak` sub-command.
Run the command `cloud-service-broker pak help` for more information about creating a pak.

## Manifest

Each brokerpak has a manifest file named `manifest.yml`. This file determines
which architectures your brokerpak will work on, which plugins it will use,
and which services it will provide.

### Schema

#### Manifest YAML file

| Field                                 | Type                           | Description                                                                                                                                                                                                                                                                                   |
|---------------------------------------|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| packversion*                          | int                            | The version of the schema the manifest adheres to. This MUST be set to `1` to be compatible with the brokerpak specification v1.                                                                                                                                                              |
| version*                              | string                         | The version of this brokerpak. It's RECOMMENDED you follow [semantic versioning](https://semver.org/) for your brokerpaks.                                                                                                                                                                    |
| name*                                 | string                         | The name of this brokerpak. It's RECOMMENDED that this be lower-case and include only alphanumeric characters, dashes, and underscores.                                                                                                                                                       |
| metadata                              | object                         | A free-form field for key/value pairs of additional information about this brokerpak. This could include the authors, creation date, source code repository, etc.                                                                                                                             |
| platforms*                            | array of platform              | The platforms this brokerpak will be executed on.                                                                                                                                                                                                                                             |
| terraform_binaries*                   | array of OpenTofu resource     | The list of OpenTofu providers and OpenTofu binaries that'll be bundled with the brokerpak. |
| service_definitions*                  | array of string                | Each entry points to a file relative to the manifest that defines a service as part of the brokerpak.                                                                                                                                                                                         |
| parameters                            | array of parameter             | These values are set as environment variables when OpenTofu is executed.                                                                                                                                                                                                                      |
| required_env_variables                | array of string                | These are the required environment variables that will be passed through to the OpenTofu execution environment. Use these to make OpenTofu platform plugin auth credentials available for OpenTofu execution.                                                                               |
| env_config_mapping                    | map[string]string              | List of mappings of environment variables into config keys, see [functions](#functions) for more information on how to use these                                                                                                                                                              |
| terraform_upgrade_path                | array of OpenTofu Upgrade Path | List of OpenTofu version steps when performing upgrade in ascending order                                                                                                                                                                                                                     |
| terraform_state_provider_replacements | map of OpenTofu provider names | Map of OpenTofu providers, where the key represents the old name of the provider and the value represents the new name of the provider. Can be used to replace the provider in the terraform state file when switching providers. |
Fields marked with `*` are required, others are optional.

#### Platform object

The platform OS and architecture follow Go's naming scheme. Combinations of OS and architecture for which there is an [OpenTofu release](https://github.com/opentofu/opentofu/releases) are valid.

| Field | Type   | Description                           | Valid Values                                                   |
|-------|--------|---------------------------------------|----------------------------------------------------------------|
| os*   | string | The operating system of the platform. | `darwin`, `freebsd`, `linux`, `openbsd`, `solaris`, `windows`  |
| arch* | string | The architecture of the platform.     | `386`, `amd64`, `arm`, `arm64`                                 |
Fields marked with `*` are required, others are optional.

#### OpenTofu resource object

This structure holds information about a specific OpenTofu version or Resource.

| Field        | Type    | Description                                                                                                                                                                                                                           |
|--------------|---------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name*        | string  | The name of this resource. e.g. `terraform-provider-google-beta`.                                                                                                                                                                     |
| version*     | string  | The version of the resource e.g. 1.19.0.                                                                                                                                                                                              |
| source       | string  | (optional) The URL to a zip of the source code for the resource.                                                                                                                                                                      |
| url_template | string  | (optional) A custom URL template to get the release of the given tool. Available parameters are ${name}, ${version}, ${os}, and ${arch}. If unspecified, the default Hashicorp Terraform download server is used for providers and the Opentofu URL for the tofu binary. Can be a local file. |
| provider     | string  | (optional) The provider in the form of `namespace/type` (e.g `cyrilgdn/postgresql`). This is required if the provider is not provided by Hashicorp. This should match the source of the provider in terraform.required_providers.     |
| default      | boolean | (optional) Where there is more than one version of OpenTofu, this nominates the default version.                                                                                                                                      |
Fields marked with `*` are required, others are optional.

##### Example


```yaml
terraform_binaries:
- name: tofu
  version: 1.6.1
  source: https://github.com/opentofu/opentofu/archive/refs/tags/v1.6.1.zip
  url_template: https://github.com/opentofu/opentofu/releases/download/v${version}/tofu_${version}_${os}_${arch}.zip
  default: true
- name: terraform-provider-google
  version: 1.19.0
  source: https://github.com/terraform-providers/terraform-provider-google/archive/v1.19.0.zip  
- name: terraform-provider-csbmajorengineversion
  version: 1.0.0
  provider: cloudfoundry.org/cloud-service-broker/csbmajorengineversion
  url_template: ./providers/build/cloudfoundry.org/cloud-service-broker/csbmajorengineversion/${version}/${os}_${arch}/${name}_v${version}  
...
```

#### Parameter object

This structure holds information about an environment variable that the user can set on the OpenTofu instance.
These variables are first resolved from the configuration of the brokerpak then against a global set of values.

| Field        | Type   | Description                                                       |
|--------------|--------|-------------------------------------------------------------------|
| name*        | string | The environment variable that will be injected e.g. `PROJECT_ID`. |
| description* | string | A human readable description of what the variable represents.     |
Fields marked with `*` are required, others are optional.

#### Upgrade Path object

This structure holds information about a step in the OpenTofu upgrade process

| Field    | Type   | Description                          |
|----------|--------|--------------------------------------|
| version* | semver | The OpenTofu version to step through |
Fields marked with `*` are required, others are optional.

**Note:** OpenTofu does not recommend making HCL changes at the same time that performing a OpenTofu upgrade.
Hence, ideally these changes should be included in a separate release of your brokerpak and all existing instances should be upgraded before installing a subsequent release.

**Note:** For upgrades to be carried over by the broker when requested, the feature flags `BROKERPAK_UPDATES_ENABLED` and `TERRAFORM_UPGRADES_ENABLED` must be set to `true`. The default is `false`.
To trigger the upgrade of an instance, a request to `update` the instance without any parameters must be made or a `cf upgrade-service <instance_name>` has to be executed.


### Example

```yaml
packversion: 1
name: my-custom-services
version: 1.0.0
metadata:
  author: someone@my-company.com
platforms:
- os: linux
  arch: "386"
- os: linux
  arch: amd64
terraform_binaries:
- name: tofu
  version: 1.6.1
  source: https://github.com/opentofu/opentofu/archive/refs/tags/v1.6.1.zip
- name: terraform-provider-google
  version: 1.19.0
  source: https://github.com/terraform-providers/terraform-provider-google/archive/v1.19.0.zip  
service_definitions:
- custom-cloud-storage.yml
- custom-redis.yml
- service-mesh.yml
parameters:
- name: TF_VAR_redis_version
  description: Set this to override the Redis version globally via injected Terraform variable.
required_env_variables:
- ENV_VARIABLE1
- ENV_VARIABLE2
env_config_mapping:
  ENV_CONFIG_VAL: env.config_val
terraform_upgrade_path:
- version: 1.6.0
- version: 1.6.1
terraform_state_provider_replacements:
  registry.terraform.io/-/random: "registry.terraform.io/hashicorp/random"
```

## Services

### Schemas

#### Service YAML files

| Field                 | Type                                  | Description                                                                                                                                                                                                                                                                                                     |
|-----------------------|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| version*              | int                                   | The version of the schema the service definition adheres to. This MUST be set to `1` to be compatible with the brokerpak specification v1.                                                                                                                                                                      |
| name*                 | string                                | A CLI-friendly name of the service. MUST only contain alphanumeric characters, periods, and hyphens (no spaces). MUST be unique across all service objects returned in this response. MUST be a non-empty string.                                                                                               |
| id*                   | string                                | A UUID used to correlate this service in future requests to the Service Broker. This MUST be globally unique such that Platforms (and their users) MUST be able to assume that seeing the same value (no matter what Service Broker uses it) will always refer to this service.                                 |
| description*          | string                                | A short description of the service. MUST be a non-empty string.                                                                                                                                                                                                                                                 |
| tags                  | array of strings                      | Tags provide a flexible mechanism to expose a classification, attribute, or base technology of a service, enabling equivalent services to be swapped out without changes to dependent logic in applications, buildpacks, or other services. E.g. mysql, relational, redis, key-value, caching, messaging, amqp. |
| display_name*         | string                                | The name of the service to be displayed in graphical clients.                                                                                                                                                                                                                                                   |
| provider_display_name | string                                | The name of the provider for this service to be displayed in graphical clients.                                                                                                                                                                                                                                 |
| image_url*            | string                                | The URL to an image or a data URL containing an image. A local file can also be referenced with `file://<path-to-image>`. This image will be base64 encoded when the Brokerpak is built.                                                                                                                        |
| documentation_url*    | string                                | Link to documentation page for the service.                                                                                                                                                                                                                                                                     |
| support_url*          | string                                | Link to support page for the service.                                                                                                                                                                                                                                                                           |
| plan_updateable       | boolean                               | Set to `true` if service supports `cf update-service`                                                                                                                                                                                                                                                           |
| plans*                | array of [plan objects](#plan-object) | A list of plans for this service, schema is defined below. MUST contain at least one plan.                                                                                                                                                                                                                      |
| provision*            | [action object](#action-object)       | Contains configuration for the provision operation, schema is defined below.                                                                                                                                                                                                                                    |
| bind*                 | [action object](#action-object)       | Contains configuration for the bind operation, schema is defined below.                                                                                                                                                                                                                                         |
| examples*             | [example object](#example)            | Contains examples for the service, used in documentation and testing.  MUST contain at least one example.                                                                                                                                                                                                       |
Fields marked with `*` are required, others are optional.

#### Plan object

A service plan in a human-friendly format that can be converted into an OSB compatible plan.

| Field               | Type               | Description                                                                                                                                                                                                                       |
|---------------------|--------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name*               | string             | The CLI-friendly name of the plan. MUST only contain alphanumeric characters, periods, and hyphens (no spaces). MUST be unique within the service. MUST be a non-empty string.                                                    |
| id*                 | string             | A GUID for this plan in UUID format. This MUST be globally unique such that Platforms (and their users) MUST be able to assume that seeing the same value (no matter what Service Broker uses it) will always refer to this plan. |
| description*        | string             | A short description of the plan. MUST be a non-empty string.                                                                                                                                                                      |
| display_name*       | string             | The name of the plan to be displayed in graphical clients.                                                                                                                                                                        |
| bullets             | array of string    | Features of this plan, to be displayed in a bulleted-list.                                                                                                                                                                        |
| free                | boolean            | When false, Service Instances of this plan have a cost. The default is false.                                                                                                                                                     |
| properties*         | map of string:any  | Constant values for the provision and bind calls. They take precedent over any other definition of the same field.                                                                                                                |
| provision_overrides | map of string:any  | Constant values to be overwritten for the provision calls.                                                                                                                                                                        |
| bind_overrides      | map of string:aany | Constant values to be overwritten for the bind calls.                                                                                                                                                                             |
Fields marked with `*` are required, others are optional.

#### Action object

The Action object contains a OpenTofu template to execute as part of a
provision or bind action, and the inputs and outputs to that template.

| Field                       | Type                                                                   | Description                                                                                                                                                                                                           |
|-----------------------------|------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| import_inputs               | array of [import-input](#import-input-object)                          | Defines the variables that will be passed to tf import command                                                                                                                                                        |
| import_parameter_mappings   | array of [import-parameter-mappings](#import-parameter-mapping-object) | Defines how tf resource variables will be replaced with broker variables between `tf import` and `tf apply`                                                                                                           |
| import_parameters_to_delete | array of string                                                        | list of `tf import` discovered values to remove before `tf apply`. `tf import` will return read-only values that cannot be set during `tf apply` so they should be listed here to be removed between import and apply |
| import_parameters_to_add    | array of [import-parameter-mappings](#import-parameter-mapping-object) | Defines tf resource variables to add between `tf import` and `tf apply`                                                                                                                                               |
| plan_inputs                 | array of [variable](#variable-object)                                  | Defines constraints and settings for the variables plans provide in their properties map. It is used to validate [plan objects](#plan-object) properties field.                                                       |
| user_inputs                 | array of [variable](#variable-object)                                  | Defines constraints and defaults for the variables users provide as part of their request.                                                                                                                            |
| computed_inputs             | array of [computed variable](#computed-variable-object)                | Defines default values or overrides that are executed before the template is run.                                                                                                                                     |
| template                    | string                                                                 | The complete OpenTofu language to execute.                                                                                                                                                                            |
| template_ref                | string                                                                 | A path to OpenTofu language template to execute. If present, this will be used to populate the `template` field.                                                                                                      |
| templates                   | map                                                                    | The complete OpenTofu language templates to execute.                                                                                                                                                                  |
| template_refs               | map                                                                    | standard OpenTofu file [snippet list](#template-references)                                                                                                                                                           |
| outputs                     | array of [variable](#variable-object)                                  | Defines constraints and settings for the outputs of the OpenTofu language template. This MUST match the OpenTofu outputs and the constraints WILL be used as part of integration testing.                             |
Fields marked with `*` are required, others are optional.

#### Import Input object

The import input object defines the mapping of an input parameter to a OpenTofu resource on the `tofu import` command.
The presence of any import input values will trigger a `tofu import` before `tofu apply` upon `cf create-service`

| Field       | Type   | Description                                                                     |
|-------------|--------|---------------------------------------------------------------------------------|
| field_name  | string | the name of the user input variable to use                                      |
| type        | string | The JSON type of the field. This MUST be a valid JSONSchema type excepting null |
| details     | string | A description of what this field is                                             |
| tf_resource | string | The tf resource to import given this value.                                     |
Fields marked with `*` are required, others are optional.

Given:
```yaml
  import_inputs:
  - field_name: azure_db_id
    type: string
    details: Azure resource id for database to subsume
    tf_resource: azurerm_mssql_database.azure_sql_db
```

A create service call:
```bash
cf create-service my-service my-plan my-instance -c '{"azure_db_id":"some-id"}'
```

Will result in OpenTofu import:

```bash
tofu import azurerm_mssql_database.azure_sql_db some-id
```

#### Import Parameter Mapping object

The import parameter mapping object defines the tf variable to input variable mapping that will occur between `tf import` and `tf apply`

`tf import` will return current values for all variables for the service instance. In order to allow user configuration of these values to support `cf update-service`, it is necessary to enumerate the terraform resource variables that should be parameterized with broker input variables.

| Field          | Type   | Description                          |
|----------------|--------|--------------------------------------|
| tf_variable    | string | the OpenTofu resource variable name |
| parameter_name | string | the broker input variable name       |
Fields marked with `*` are required, others are optional.

Given:
```yaml
  - tf_variable: requested_service_objective_name
    parameter_name: var.service_objective 
```

Will convert the resulting `tofu import`:
```tf
resource "azurerm_mssql_database" "azure_sql_db" {
    requested_service_objective_name = S0
}
```

Into:
```tf
resource "azurerm_mssql_database" "azure_sql_db" {
    requested_service_objective_name = var.service_objective
}
```
Between running `tofu import` and `tofu apply`

So that:
```bash
cf update-service my-instance -c '{"service_objective":"S1"}'
```

Will successfully update the `requested_service_objective_name` for the instance.

#### Removing TF Values

`tofu import` will often return read only values that cannot be set during `tofu apply`.
The *import_parameters_to_delete* field is used to specify which values to remove before `tofu apply` is run.

Given:

```yaml
import_parameters_to_delete: [ "azurerm_mssql_database.azure_sql_db.id" ]
```

Will convert the resulting `tofu import`

```tf
resource "azurerm_mssql_database" "azure_sql_db" {
    id = "/subscriptions/899bf076-632b-4143-b015-43da8179e53f/resourceGroups/broker-cf-test/providers/Microsoft.Sql/servers/masb-subsume-test-server"
    requested_service_objective_name = S0
}
```

into

```tf
resource "azurerm_mssql_database" "azure_sql_db" {
    requested_service_objective_name = S0
}
```

So that `tofu apply` will not fail trying to set the read-only field *id*

#### Template References

It is possible to break OpenTofu code into sections to aid reusability and better readability.
It is also required to support `tofu import` as main.tf is a special case during import.

Given:
```yaml
  template_refs:
    outputs: terraform/subsume-masb-mssql-db/mssql-db-outputs.tf
    provider: terraform/subsume-masb-mssql-db/azure-provider.tf
    variables: terraform/subsume-masb-mssql-db/mssql-db-variables.tf
    main: terraform/subsume-masb-mssql-db/mssql-db-main.tf
    data: terraform/subsume-masb-mssql-db/mssql-db-data.tf
```

Will result is a OpenTofu workspace with the following structure:
* outputs.tf gets contents of *terraform/subsume-masb-mssql-db/mssql-db-outputs.tf*
* provider.tf gets contents of *terraform/subsume-masb-mssql-db/azure-provider.tf*
* variables.tf gets contents of *terraform/subsume-masb-mssql-db/mssql-db-variables.tf*
* main.tf gets contents of *terraform/subsume-masb-mssql-db/mssql-db-main.tf*
* data.tf gets contents of *terraform/subsume-masb-mssql-db/mssql-db-data.tf*

> If there are [import inputs](#import-input-object), a `tofu import` will be run for each import input value before
> `tofu apply` is run. Once all the import calls are complete, `tofu show` is run to generate a new *main.tf*.
> So it is important not to put anything into *main.tf* that needs to be preserved. Put them in one of the other tf files.

#### Variable object

The variable object describes a particular input or output variable. The
structure is turned into a JSONSchema to validate the inputs or outputs.
Outputs are _only_ validated on integration tests.

| Field             | Type              | Description                                                                                                                                                                                                                                                                                                                                                                                           |
|-------------------|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| required          | boolean           | Should the user request fail if this variable isn't provided?                                                                                                                                                                                                                                                                                                                                         |
| field_name*       | string            | The name of the JSON field this variable serializes/deserializes to.                                                                                                                                                                                                                                                                                                                                  |
| type*             | string            | The JSON type of the field. This MUST be a valid JSONSchema type excepting `null`.                                                                                                                                                                                                                                                                                                                    |
| nullable          | boolean           | Whether the field can be set to `null`. For example, if the type is `string`, this will allow the field to also be set to `null`, which is valid in HCL. This allows for differentiation between `null` and (say) an empty string.                                                                                                                                                                    |
| details*          | string            | Provides explanation about the purpose of the variable.                                                                                                                                                                                                                                                                                                                                               |
| default           | any               | The default value for this field. If `null`, the field MUST be marked as required. If a string, it will be executed as a HIL expression and cast to the appropriate type described in the `type` field. See the [Expression language reference](#expression-language-reference) section for more information about what's available.                                                                  |
| enum              | map of any:string | Valid values for the field and their human-readable descriptions suitable for displaying in a drop-down list.                                                                                                                                                                                                                                                                                         |
| constraints       | map of string:any | Holds additional JSONSchema validation for the field. Feature flag `enable-catalog-schemas` controls whether to serve Json schemas in catalog. The following keys are supported: `examples`, `const`, `multipleOf`, `minimum`, `maximum`, `exclusiveMaximum`, `exclusiveMinimum`, `maxLength`, `minLength`, `pattern`, `maxItems`, `minItems`, `maxProperties`, `minProperties`, and `propertyNames`. |
| tf_attribute      | string            | The tf resource attribute from which the value of this field can be extracted from (e.g. `azurerm_mssql_database.azure_sql_db.name`). To be specified for subsume use cases only.                                                                                                                                                                                                                     |
| tf_attribute_skip | string            | A reference to another field, which if true, the reading of `tf_attribute` should be skipped. To be specified only for subsume use cases where a resource may optionally not exist.                                                                                                                                                                                                                   |
| prohibit_update   | boolean           | Defines if the field value can be updated on update operation.                                                                                                                                                                                                                                                                                                                                        |
Fields marked with `*` are required, others are optional.

#### Computed Variable Object

Computed variables allow you to evaluate arbitrary HIL expressions against
variables or metadata about the provision or bind call.

| Field     | Type    | Description                                                                                                                                                                                                                              |
|-----------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name*     | string  | The name of the variable.                                                                                                                                                                                                                |
| default*  | any     | The value to set the variable to. If it's a string, it will be evaluated by the expression engine and cast to the provided type afterwards. See the "Expression language reference" section for more information about what's available. |
| overwrite | boolean | If a variable already exists with the same name, should this one replace it?                                                                                                                                                             |
| type      | string  | The JSON type of the field it will be cast to if evaluated as an expression. If defined, this MUST be a valid JSONSchema type excepting `null`.                                                                                          |
Fields marked with `*` are required, others are optional.

### Example

```yaml
version: 1
name: example-service
id: 00000000-0000-0000-0000-000000000000
description: a longer service description
display_name: Example Service
provider_display_name: Example company name
image_url: https://example.com/icon.jpg
documentation_url: https://example.com
support_url: https://example.com/support.html
tags: [gcp, example, service]
plans:
- name: example-email-plan
  id: 00000000-0000-0000-0000-000000000001
  description: Builds emails for example.com.
  display_name: example.com email builder
  bullets:
  - information point 1
  - information point 2
  - some caveat here
  properties:
    domain: example.com
provision:
  plan_inputs:
  - required: true
    field_name: domain
    type: string
    details: The domain name
  user_inputs:
  - required: true
    field_name: username
    type: string
    details: The username to create
    tf_attribute: resourceType.resourceName.user
  computed_inputs: []
  template: |-
    variable domain {type = string}
    variable username {type = string}
    output email {value = "${var.username}@${var.domain}"}

  outputs:
  - required: true
    field_name: email
    type: string
    details: The combined email address
bind:
  plan_inputs: []
  user_inputs: []
  computed_inputs:
  - name: address
    default: ${instance.details["email"]}
    overwrite: true
  template: |-
    resource "random_string" "password" {
      length = 16
      special = true
      override_special = "/@\" "
    }

    output uri {value = "smtp://${var.address}:${random_string.password.result}@smtp.mycompany.com"}

  outputs:
  - required: true
    field_name: uri
    type: string
    details: The uri to use to connect to this service
examples:
- name: Example
  description: Examples are used for documenting your service AND as integration tests.
  plan_id: 00000000-0000-0000-0000-000000000001
  provision_params:
    username: my-account
  bind_params: {}

```

## Expression language reference

The broker uses the [HIL expression language](https://github.com/hashicorp/hil) with a limited set of built-in functions.

### Functions

The following string interpolation functions are available for use:

* `assert(condition_bool, message_string) -> bool`
  * If the condition is false, then an error will be raised to the user containing `message_string`.
  * Avoid using this function. Instead, try to make it so your users can't get into a bad state to begin with. See the "design guidelines" section.  
  * In the words of [PEP-20](https://www.python.org/dev/peps/pep-0020/):
    * If the implementation is hard to explain, it's a bad idea.
    * If the implementation is easy to explain, it may be a good idea.
* `time.nano() -> string`
  * This function returns the current time as a Unix time, the number of nanoseconds elapsed since January 1, 1970 UTC, as a decimal string.
  * The result is undefined if the Unix time in nanoseconds cannot be represented by an int64 (a date before the year 1678 or after 2262).
* `regexp.matches(regex_string, string) -> bool`
  * Checks if the string matches the given regex.
* `str.truncate(count, string) -> string`
  * Trims the given string to be at most `count` characters long.
  * If the string is already shorter, nothing is changed.
* `counter.next() -> int`
  * Provides a counter that increments once per call within the same call context.
  * The counter is reset on restart of the application.
* `rand.base64(count) -> string`
  * Generates `count` bytes of cryptographically secure randomness and converts it to [URL Encoded Base64](https://tools.ietf.org/html/rfc4648).
  * The randomness makes it suitable for using as passwords.
* `json.marshal(type) -> string`
  * Returns a JSON marshaled string of the given type.
* `map.flatten(keyValueSeparator, tupleSeparator, map)`
  * Converts a map into a string with each key/value pair separated by `keyValueSeparator` and each entry separated by `tupleSeparator`.
  * The output is deterministic.
  * Example: if `labels = {"key1":"val1", "key2":"val2"}` then `map.flatten(":", ";", labels)` produces `key1:val1;key2:val2`.
* `env("ENV_VAR_NAME")`
  * Returns value for environment variable `ENV_VAR_NAME`
* `config("config.key")`
  * Returns value for config key `config.key`. These will come from the config file or be mapped from environment variables by the *env_config_mapping* section of the root *manifest.yml*.

### Variables

The broker makes additional variables available to be used during provision and bind calls.

#### Resolution

The order of combining all plan properties before invoking OpenTofu is as follows:
1. Operator default variables loaded from the environment.
   * `GSB_PROVISION_DEFAULTS` values first and then `GSB_SERVICE_*SERVICE_NAME*_PROVISION_DEFAULTS`. 
1. User defined variables provided during provision/bind call.
   * The variable constraints are defined in `service_definitions.provision.user_inputs` or `service_definitions.bind.user_inputs` 
   * These values overwrite the above values if set.
1. (If the operation is an update) User defined variables provided during update call.
   * The variable constraints are defined in `service_definitions.provision.user_inputs` or `service_definitions.bind.user_inputs`
   * These values overwrite the above values if set.
1. Default variables and values as configured in `service_definitions.plans[0].provision_overrides`. 
   * These values overwrite the above values if set.
1. Default properties and values for any variables that is defined in `service_definitions.provision.user_input` and the user has not provided. 
   * These values do not override user defined params if they are already set by step 2 or 3.
1. Constant properties and values for any field that is defined in `service_definitions.plans[0].properties`. 
   * These values overwrite the above values if set.
1. Computed fields that are defined in `service_definitions.provision.computed_inputs`.
   * The service definition for `computed_inputs` specifies if these values will overwrite previous steps.

#### Provision/Deprovision

* `request.service_id` - _string_ The GUID of the requested service.
* `request.plan_id` - _string_ The ID of the requested plan. Plan IDs are unique within an instance.
* `request.instance_id` - _string_ The ID of the requested instance. Instance IDs are unique within a service.
* `request.default_labels` - _map[string]string_ A map of labels that should be applied to the created infrastructure for billing/accounting/tracking purposes. 
   * `request.default_labels.pcf-organization-guid` - _string_ Mapped from [cloudfoundry context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#cloud-foundry-context-object) `organization_guid` (provision only).
   * `request.default_labels.pcf-space-guid` - _string_ Mapped from [cloudfoundry context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#cloud-foundry-context-object) `space_guid` (provision only).
   * `request.default_labels.pcf-instance-id` - _string_ Mapped from the ID of the requested instance.
* `request.context` - _map[string]any_ Mapped from [cloudfoundry context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#cloud-foundry-context-object) (provision only).
* `request.x_broker_api_originating_identity` - _map[string]any_ Mapped from [cloudfoundry `x_broker_api_originating_identity` header](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#originating-identity-header)
   
#### Bind/Unbind

* `request.binding_id` - _string_ The ID of the new binding.
* `request.instance_id` - _string_ The ID of the existing instance to bind to.
* `request.service_id` - _string_ The GUID of the service this binding is for.
* `request.plan_id` - _string_ The ID of plan the instance was created with.
* `request.plan_properties` - _map[string]string_ A map of properties set in the service's plan.
* `request.app_guid` - _string_ The ID of the application this binding is for. (bind only)
* `instance.name` - _string_ The name of the instance.
* `instance.details` - _map[string]any_ Output variables of the instance as specified by ProvisionOutputVariables.
* `request.context` - _map[string]any_ Mapped from [cloudfoundry context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#cloud-foundry-context-object) (bind only).
* `request.x_broker_api_originating_identity` - _map[string]any_ Mapped from [cloudfoundry `x_broker_api_originating_identity` header](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#originating-identity-header)

## File format

The brokerpak itself is a zip file with the extension `.brokerpak`.
In the root is the `manifest.yml` file, which will specify the version of the pak.

There are three directories in the pak's root:

* `src/` an unstructured directory that holds source code for the bundled binaries, this is for complying with 3rd party licenses.
* `bin/` contains binaries under `bin/{os}/{arch}` sub-directories for each supported platform.
* `definitions/` contain the service definition YAML files.

## OpenTofu lifecycle meta-argument `prevent_destroy`
OpenTofu supports a [lifecycle meta-argument called `prevent_destroy`](https://opentofu.org/docs/language/meta-arguments/lifecycle/)
that stops resources from being accidentally destroyed. For example:
```hcl
resource "database" "mydatabase" {
  name = var.database_name
  lifecycle {
    prevent_destroy = true
  }
}
```
It might be that changing the database name would cause the OpenTofu to delete the
database and create a new one with the correct name. This can be prevented by adding
the lifecycle meta-argument `prevent_destroy`. During the deletion of a service instance,
Cloud Service Broker will set the `prevent_destroy` property to be `false` so that
the service instance can be deleted.