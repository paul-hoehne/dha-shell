# Shell Application

This is a simple shell application to help you get started.  It uses
ml-gradle [documentation](https://github.com/rjrudin/ml-gradle/wiki)
is available on line.  [Documentation](https://docs.gradle.org/current/userguide/userguide.html)
for gradle is also available on line.

## Prerequisites

The only pre-requisite is that you have the JDK installed on your 
desktop.  The gradlew.bat script will take care of downloading a
version of groovy and gradle to use for deploying the application.
It does not use an installer.  It just downloads jars for your use.

## Step 1 - Database Settings

Open the file gradle.properties in a text editor.  

1. mlHost=localhost
1. mlAppName=dha-shell
1. mlRestPort=8700
1. mlTestRestPort=8701
1. mlUsername=phoehne
1. mlPassword=password
1. mlContentForestsPerHost=4

Change the mlHost, mlAppName, mlRestPort, mlTestRestPort to something
reasonable for your server.  For example, if your server is ml-dev.mydept.mil,
set mlHost=ml-dev.mydept.mil.  The rest port and test rest port should be 
something reasonable.  I've used 8700, but feel free to change it to any port
you like.  

The username and password should be the username and password for a user with
admin privileges.  For developers, on the developer database, it's normal to
give them admin privileges so they can push database configuration changes.

In your specific case, I would have each developer pick a port and a slightly
different app name for now.  So Joe migh have joe-shell and use ports 8710 
and 8711.  Rao might have rao-shell and ports 8720 and 8721, etc.  This will
allow you to "play" with the system without making life unpleasant for 
anyone else.

## Step 2 - Deploying the Application

Run the command:

<code>gradlew mlDeploy</code>

from a command line.  It will take a few seconds to a couple of minutes to 
deploy the initial application.  

## Step 3 - Deploy the Data

Run the commands:

<code>gradlew importPatients</code>

<code>gradlew importVisits</code>

from the command line.  You can now either log into the query console, which
is on port 8000 on the server, or you can use a REST endpoint such as:

<code>http://\[server name]:\[port]/v1/documents?uri=/visits/visit1.xml</code>

To view the document.  (Note there is an Explore button int he query console,
which allows you to browse documents.)  When you are prompted for credentials, 
try using the user credentials defined in src/main/ml-config/security/users.

## What You Have

At this point you have a working system that can ingest data, has a couple of
example triggers defined, and will operate as a REST server.  If you make a
change to the source code (the xquery files), you can push your changes with

<code>gradlew mlLoadModules</code>

If you make a change in the database settings, you will need to use the 
mlDeploy command.

## Cleaning Up

If you want to delete the application or start over, simply run 

<code>gradlew mlUndeploy</code>

from the command line.