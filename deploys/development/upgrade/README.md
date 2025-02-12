# Upgrade from DBPTK 2.X to DBPTK 3

This guide outlines the steps required to upgrade DBPTK from version 2.X to version 3. 
Before starting the new version of DBPTK follow these steps.

## Add Your Machine's IP Address to DBPTK Whitelist

If CAS authentication is not enabled, you can skip this step.

### Prerequisites:
- These scripts can only be executed by users with an administrator role.
- To run them, you must first modify the DBPTK configuration file (`dbvtk-viewer.properties`).

### Instructions:

1. Open the `dbvtk-viewer.properties` file.
2. Ensure the following property is set to `true`:
    ```
    ui.filter.onOff.protectedResourcesAllowAllIPs=true
    ```
3. Add the following lines to the same file:
    ```
    ui.filter.onOff.protectedResourcesWhitelistedIP[].ip=<ip_address>
    ui.filter.onOff.protectedResourcesWhitelistedIP[].username=admin
    ```
    Replace `<ip_address>` with the IP address of the machine where you will be running the scripts.

4. After updating the file, you may need to restart DBPTK for the changes to take effect.

## Update Database Schemas

Before shutting down DBPTK 2 and its services, update the database schemas by running:

```bash
./scripts/01-database-model-migration.sh <dbptk_home> <host>
```
Replace `<dbptk_home>` with the DBPTK home directory path and `<host>` with the DBPTK host.

## Shutdown DBPTK and Migrate H2 Database

Shutdown DBPTK and its services. Before upgrading, the H2 database must be migrated from version 1 to 2 in order 
to be compatible with the new DBPTK version. Run the following script:

```bash
./scripts/02-h2-migration.sh <dbptk_home>
```

Replace `<dbptk_home>` with the DBPTK home directory path.

## Upgrade Solr from Version 8 to 9

DBPTK 3 requires Solr 9. To update Solr's configurations run:
```bash
./scripts/03-solr-upgrade.sh <dbptk_compose_path>
```

Replace `<dbptk_compose_path>` with the path of the docker compose file with the DBPTK services.

## Start DBPTK and Reindex Old Jobs

Start DBPTK and its services. Then reindex old jobs by running:

```bash
./scripts/04-old-jobs-reindex.sh <host>
```

Replace `<host>` with the DBPTK host.

##  Reindex databases

Reindex databases by running:

```bash
./scripts/05-databases-reindex.sh <host>
```

Replace `<host>` with the DBPTK host.

## Migrate Collections

Finally, reindex the collections and re-apply any existing transformations using:

```bash
./scripts/06-collection-migration.sh <dbptk_home> <host>
```

Replace `<dbptk_home>` with the DBPTK home directory path and `<host>` with the DBPTK host.


