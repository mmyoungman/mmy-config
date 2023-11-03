#!/bin/bash

rsync -av --progress /tmp/explore-education-statistics /tmp/

xfce4-terminal \
	--title="db" --working-directory=/tmp/explore-education-statistics -e "bash -c 'trap: INT; docker-compose up db; exec bash'" \
	--tab -T "storage" --working-directory=/tmp/explore-education-statistics -e "bash -c 'trap : INT; docker-compose up data-storage; exec bash'" \
	--tab -T "idp" --working-directory=/tmp/explore-education-statistics -e "bash -c 'trap : INT; docker-compose up idp; exec bash'" \
	--tab -T "admin" --working-directory=/tmp/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Admin -e "bash -c 'export IdpConfig=Keycloak; dotnet clean; dotnet build; trap : INT; dotnet run; cat ~/dfe.sh | grep admin; exec bash'" \
	--tab -T "content" --working-directory=/tmp/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Content.Api -e "bash -c 'dotnet clean; dotnet build; trap : INT; dotnet run; exec bash'" \
	--tab -T "data" --working-directory=/tmp/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Data.Api -e "bash -c 'dotnet clean; dotnet build; trap : INT; dotnet run; exec bash'" \
	--tab -T "frontend" --working-directory=/tmp/explore-education-statistics/src/explore-education-statistics-frontend -e "bash -c 'source /home/mark/.bashrc; trap : INT; pnpm run dev; exec bash'" \
	--tab -T "data-processor" --working-directory=/tmp/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Data.Processor -e "bash -c 'source /home/mark/.bashrc; dotnet clean; dotnet build; trap : INT; func host start --port 7071 --pause-on-error; cat ~/dfe.sh | grep data-pro; exec bash'" \
	--tab -T "publisher" --working-directory=/tmp/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Publisher -e "bash -c 'source /home/mark/.bashrc; dotnet clean; dotnet build; trap : INT; func host start --port 7072 --pause-on-error; cat ~/dfe.sh | grep publish; exec bash'" \
	--tab -T "bash" --working-directory=/tmp/explore-education-statistics/ -e "bash -c 'exec bash'"
	#--tab -T "notify" --working-directory=/tmp/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Notifier -e "bash -c 'source /home/mark/.bashrc; dotnet clean; dotnet build; trap : INT; func host start --port 7073 --pause-on-error; exec bash'" \

