# Source

This is the source directory.  Under this directory there's a 
ml-config directory and ml-modules directory.  These are the only
two that are important right now.

## ml-config

This directory contains the configuration for an application.  The
ml-gradle tool stores the database and server configuration in a
series of JSON files.

### databases
 
#### content-database.json

This defines the content database, or where you will put the actual
documents.  

#### schemas-database.json

If we use XML schemas to enforce a document structure (which I 
would not do unless you had a very, very compelling reason), it will
live in the schemas database

#### tiggers-database.json

The triggers database contains the database where the trigger 
definitions are stored.

### security

The security in MarkLogic is role based.  This defines a couple of
simple roles and users.  You can use these users when logging
in to your own system.

#### roles

Defines a role.  The role has a name, optional description and 
then a list of roles from which it inherits.  A document has 
permissions for each role.  If a document isn't given any 
permissions, it is only readable/updatable by the admin.  Since
roles are at the document level, they are normally assigned 
when the document is ingested into the database.

#### users

Defines some standard users.  Note that is isn't necessary in 
MarkLogic to have a user for each person accessing the system. 
Authentication can happen with a collection of roles without a
specific user, meaning you can still have role based security
without creating a user for each person accessing the application.

### triggers

These are trigger definitions.  The definition tells the database
when to apply a given trigger.  In this case there are two triggers
that fire when patients or visits are imported.  They are post-
commit triggers, meaning that they fire once the document has 
been written to the database.  

## ml-modules

This is where the XQuery application code would reside.  The 
general pattern is to put extension code int "ext".  

### ext

This contains the application specific code.  It is not required
that you use "ext."  It is just practice.

#### triggers

This contains a couple of example triggers.  The first enriches
patient documents as they are ingested.  The second enriches 
visits, which then use the already ingeted patient data in their
enrichment.  
