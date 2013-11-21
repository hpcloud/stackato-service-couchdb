#!/usr/bin/env bash

APP_NAME_1=todo-list-1
APP_NAME_2=todo-list-2
TEST_SERVICE_NAME=task-db-extra

cd $(dirname $0)

echo "Please enter cloud controller api url (api.stackato.local): "
read CCURL

stackato target $CCURL
stackato login
stackato services
read -p "Press any key to continue..."

# Create a temporary couchdb service - this won't be used by the app.
stackato create-service couchdb $TEST_SERVICE_NAME

git clone https://github.com/jhou2/tasks
pushd tasks
	stackato push -n $APP_NAME_1 && sleep 2
	stackato push -n $APP_NAME_2 && sleep 2

	# Binds an extra service to both applications.
	stackato bind-service $TEST_SERVICE_NAME $APP_NAME_1 && sleep 2
	stackato bind-service $TEST_SERVICE_NAME $APP_NAME_2 && sleep 2

	# Echo the VCAP_SERVICES env variable. Credentials for connecting to the 2 databases will be shown.
	echo "==================VCAP_SERVICES FOR $APP_NAME_1=================="
	stackato ssh $APP_NAME_1 'echo $VCAP_SERVICES | json'
	read -p "Press any key to continue..."
	
	echo "==================VCAP_SERVICES FOR $APP_NAME_2=================="
	stackato ssh $APP_NAME_2 'echo $VCAP_SERVICES | json'
	read -p "Press any key to continue..."

	read -p "Do you want to open the deployed applications? (y/n)? "
	if [ $REPLY == "y" ]; then
		stackato open $APP_NAME_1
		stackato open $APP_NAME_2
		read -p "Press any key to continue..."
	fi

	echo "Deleting apps. Stackato Client may prompt for service deletion."
	stackato delete $APP_NAME_1 -n
	stackato delete $APP_NAME_2 -n
	stackato delete-service $APP_NAME_1-db
	stackato delete-service $APP_NAME_2-db
popd
rm -rf tasks



