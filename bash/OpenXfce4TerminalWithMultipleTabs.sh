#!/bin/bash

xfce4-terminal \
	--title="db" --working-directory=/home/mark/projects/explore-education-statistics/src -e "bash -c 'docker-compose up db; exec bash'" \
	--tab -T "storage" --working-directory=/home/mark/projects/explore-education-statistics/src -e "bash -c 'docker-compose up data-storage; exec bash'" \
	--tab -T "admin" --working-directory=/home/mark/projects/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Admin -e "bash -c 'dotnet clean; dotnet build; dotnet run; exec bash'" \
	--tab -T "content" --working-directory=/home/mark/projects/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Content.Api -e "bash -c 'dotnet clean; dotnet build; dotnet run; exec bash'" \
	--tab -T "data" --working-directory=/home/mark/projects/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Data.Api -e "bash -c 'dotnet clean; dotnet build; dotnet run; exec bash'" \
	--tab -T "frontend" --working-directory=/home/mark/projects/explore-education-statistics/src/explore-education-statistics-frontend -e "bash -c 'source /home/mark/.bashrc; npm run start:local; exec bash'" \
	--tab -T "data-processor" --working-directory=/home/mark/projects/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Data.Processor -e "bash -c 'source /home/mark/.bashrc; dotnet clean; dotnet build; func host start --port 7071 --pause-on-error; exec bash'" \
	--tab -T "publisher" --working-directory=/home/mark/projects/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Publisher -e "bash -c 'source /home/mark/.bashrc; dotnet clean; dotnet build; func host start --port 7072 --pause-on-error; exec bash'" \
	--tab -T "notify" --working-directory=/home/mark/projects/explore-education-statistics/src/GovUk.Education.ExploreEducationStatistics.Notifier -e "bash -c 'source /home/mark/.bashrc; dotnet clean; dotnet build; func host start --port 7073 --pause-on-error; exec bash'" \
	--tab -T "bash" --working-directory=/home/mark/projects/explore-education-statistics/ -e "bash -c 'exec bash'"
	
