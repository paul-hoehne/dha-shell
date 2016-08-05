# Shell Application

This is a simple shell application to help you get started.  It uses
ml-gradle [documentation](https://github.com/rjrudin/ml-gradle/wiki)
is available on line.  [Documentation](https://docs.gradle.org/current/userguide/userguide.html)
for gradle is also available on line.

## Prerequisites

The prequisites are that you have the JDK installed on your 
desktop and Gradle.  Downloand and install the JDK (not JRE) from 
[Oracle](http://www.oracle.com).  Gradle can be obtained from
[Gradle.org](https://gradle.org/gradle-download/).  Select the 
"Complete distribution" option.

Run the JDK installer to install the Java development tools.  They 
should automatically add the path to the Java tools into your 
environment variables.  You should be able to open a command prompt
on windows and type <code>java -version</code> and get the current
version of the installed JDK.

From the gradle download unpack the files and copy them to your 
user directory (<code>C:\\Users\\[username]</code>) as gradle.  
The full path should be <code>C:\\users\\[username]\\gradle</code>.
If there is a version number in the name of the gradle folder 
(for your own sanity) just remove it.

From the Cortanasearch located in the taskbar, search for "Environment". 
One of the options should be to edit your system environment variables.
Select that and you are presented with a dialog box that has a button
"Environment Variables".  Select that and on the lower section edit 
your "path" variable.  Add <code>C:\\Users\\[username]\\gradle\\bin</code>.
Hit "Ok" or "Apply" until you close that dialog.


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

<code>gradlew importExampleOnto</code>

<code>gradlew importData</code>

from the command line.  You can now either log into the query console, which
is on port 8000 on the server, or you can use a REST endpoint such as:

<code>http://\[server name]:\[port]/v1/documents?uri=/visits/visit1.xml</code>

To view the document.  (Note there is an Explore button int he query console,
which allows you to browse documents.)  When you are prompted for credentials, 
try using the user credentials defined in src/main/ml-config/security/users.

## Step 4 - Import the Workspace

Log in to the query console <code>http://[server]:8000/</code> and on the right
you'll see a dropdown called "Workspace".  Select the drop down and import Workspace
option.  That will open a file upload box.  Navigate to the "DHA-VCE.xml" file
and upload it.  You now have an example workspace.

## What You Have

At this point you have a working system that can ingest data, has a couple of
example triggers defined, and will operate as a REST server.  If you make a
change to the source code (the xquery files), you can push your changes with

<code>gradlew mlLoadModules</code>

If you make a change in the database settings, you will need to use the 
mlDeploy command.

## Higlights

1. The ontology demonstrates very basic inferencing.  If you select "Anything
Head", you can run  query that searches for injuries on someone's head.  The
data is only marked up with eye, ear, nose, etc., but the ontology allows the 
query to generalize to the the concept of "head."

2. Examples of triggers to perform enrichment.  The files 
<code>/src/main/ml-modules/ext/triggers/create-xxx-triples.xqy</code> 
are examples of taking the data an enriching it with semantic triples during
ingest.

3. An example of using a transform to enrich data.  The file 
<code>/src/main/ml-modules/ext/triggers/transform-encounter.xml</code>
demonstrates enriching a document using an ingest tansform called from
the MLCP ingest.  (See the <code>importEncounter</code> in build.gradle).

4. The enrichment does a poor man's entity extraction, running a series of
reverse queries against the doctor's soap notes to extract information from
the text.  In cases where you have an ICD code, you might not wan to use 
this approach, but maybe this is useful when you don't have the 
information that would correctly classify the encounter.

5. An example of a custom rest end point under 
<code>/src/main/ml-modules/services/notes.xqy</code>.  This service searches just
the doctor's soap notes (*not* web service SOAP).  This includes snippeting and 
can be accessed at: <code>http://localhost:8700/v1/resources/notes?rs:q=bleeding AND face&rs:format=json</code>
You can change the query text (rs:q parameter) to include expressions.  You can
also specify a format for xml or json.

## Cleaning Up

If you want to delete the application or start over, simply run 

<code>gradlew mlUndeploy</code>

from the command line.