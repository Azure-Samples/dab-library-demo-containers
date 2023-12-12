##############################################################################
# Build your APIs with DAB using containers
#
#   1- Create docker network
#   2- SQL Container
#   3- DAB Container
#   4- Testing DAB health
#   5- Testing DAB API
##############################################################################

# 1- Create docker network
docker network create library-network

# 2- SQL Container
# When running Docker on an ARM chip-based machine, ensure to include the --platform linux/amd64 option in your docker run command.
docker run \
    --name SQL-Library \
    --hostname SQL-Library \
    --env 'ACCEPT_EULA=Y' \
    --env 'MSSQL_SA_PASSWORD=P@ssw0rd!' \
    --publish 1401:1433 \
    --network library-network \
    --detach mcr.microsoft.com/mssql/server:2022-latest

# SQLCMD env variable - SA password
export SQLCMDPASSWORD=P@ssw0rd! 

# Create database and tables
sqlcmd -S localhost,1401 -U SA -d master -e -i ./Scripts/library.azure-sql.sql -C

# 3- DAB Container
# When running Docker on an ARM chip-based machine, ensure to include the --platform linux/amd64 option in your docker run command.
docker run \
    --name DAB-Library \
    --volume "./DAB-Config:/App/configs" \
    --publish 5001:5000 \
    --env-file "./DAB-Config/.env" \
    --network library-network \
    --detach mcr.microsoft.com/azure-databases/data-api-builder:latest \
    --ConfigFileName /App/configs/dab-config.json

# Checking image env variables
docker exec DAB-Library env

# 4- Testing DAB health
curl -v http://localhost:5001/

# 5- Testing DAB API
curl -s http://localhost:5001/api/Book | jq
curl -s http://localhost:5001/api/Author | jq

# Testing DAB API with jq
curl -s 'http://localhost:5001/api/Book?$first=2' | jq '.value[] | {id, title}'
curl -s http://localhost:5001/api/Author | jq '.value[1] | {id, first_name, last_name}'

# Testing DAB API with jq and filter
# From brower
http://localhost:5001/api/Book?$first=2&$orderby=id
http://localhost:5001/api/Book?$first=2&$orderby=id desc

# From command line
curl -s 'http://localhost:5001/api/Book?$first=2&$orderby=id' | jq
curl -s 'http://localhost:5001/api/Book?$first=2&$orderby=id' | jq

# Testing DAB API with GraphQL
curl -X POST \ -H "Content-Type: application/json" \ 
    -d '{"query": "{ books(first: 2, orderBy: {id: ASC}) { items { id title } } }"}' \ 
    http://localhost:5001/graphql | jq