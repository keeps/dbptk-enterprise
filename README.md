[![Deploy](https://github.com/keeps/dbptk-enterprise/actions/workflows/deploy.yml/badge.svg)](https://github.com/keeps/dbptk-enterprise/actions/workflows/deploy.yml)

# Install DBPTK Enterprise via Docker

Docker deployment of the [DBPTK User Interface](https://github.com/keeps/dbptk-ui) as a Web application.

### Deploy (by default the CAS authentication is disabled)
We suggest you use docker on Linux. Docker on Windows will require you to edit the docker-compose.yaml and transform config path `./config/dbvtk-viewer.properties` to Windows path style.

Pre-requisites:
1. Install [docker](https://docs.docker.com/install/)
2. Install [docker compose](https://docs.docker.com/compose/install/)
3. Download and unzip this [project](https://github.com/keeps/dbptk-enterprise/archive/master.zip).
4. Open a terminal within `deploys/development` folder
5. Run `docker-compose up`
6. Application should be available at [http://localhost:8080](http://localhost:8080)

### To add more databases to DBPTK Enterprise via REST API
1. Update dbvtk-viewer.properties file and set *manage.upload.basePath* property with a path to the SIARD folder (reload the docker-compose to apply the changes)
2. Replace the `<siardFilename>` with the name of the SIARD then run: ``curl -X POST "http://localhost:8080/api/v1/database" -H "accept: text/plain" -H "Content-Type: application/json" -d "<siardFilename>"``

### To add more databases to DBPTK Enterprise Interface

1. Open DBPTK Enterprise, click on the "LOAD SIARD FILE" button
2. Browse to the SIARD files or drag and drop in the demarcated area
3. Wait for upload process
4. When upload is complete, click the "OPEN SIARD" button

### To stop the server

Use CTRL+C to stop the server.

### Run as a daemon

Run `docker-compose up -d` at deploys/development folder.

### Shutdown daemon and cleanup

Run `docker-compose down` at deploys/development folder.


## More information

Configuration options are detailed in the [DBPTK UI Wiki](https://github.com/keeps/dbptk-ui/wiki).

DBPTK logos can be downloaded [here](https://github.com/keeps/dbptk-developer/wiki/Logos).

More information about these tools can be found at [database-preservation.com](https://database-preservation.com).

## To report a problem or make a suggestion

Create a new issue on [DBPTK Enterprise GitHub Issues](https://github.com/keeps/dbptk-enterprise/issues/new).

## Information & Commercial support

For more information or commercial support, contact [KEEP SOLUTIONS](http://www.keep.pt/contactos/?lang=en).

## License

Database Visualization Toolkit licence is [LGPLv3](LICENSE)
