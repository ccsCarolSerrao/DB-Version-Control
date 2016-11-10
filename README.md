# DB-Version-Control
Simple DataBase Versioning Control - PowerShell

*I did it to myself so it's very very simple!*

Contains a configuration file (.xml) where the database connection and the path scripts files are set and a powsershell file that makes sure the script files haven't already been installed in the database and installs them.


## How to Use

Before the file name you have to put the version number and the run order split by "." (To install at DataBase).


**Example**

**File:** 01.05.File5.sql
 - Version Number: 1
 - Run Order: 5
 - File Name: File1
 
**File:** 02.30.FileTest.sql
 - Version Number: 2
 - Run Order: 30
 - File Name: FileTest
