### Collec-science multi-instance config [CS-MI]

A working collec-science should be running on the system prior to creating a collec instance. For further information see the collec science [install guide][] and the [installation procedure][].

[install guide]: https://github.com/Irstea/collec/blob/hotfix-2.0.2/database/documentation/collec_installation_configuration.pdf
[installation procedure]: https://github.com/Irstea/collec/blob/hotfix-2.0.2/install/deploy_new_instance.sh

#### Create multi-instance tree structure

##### CS-MI tree example

	/
	|-- var
	|   |-- www
	|   |   |-- collec-science
	+   |   |   |-- collec ( -> /path/to/collec-lastver)
	    +   |   |
	        +   |-- bin* ( -> collec)
	            |
	            |-- first-instance
	            |   |-- bin* ( -> ../bin)
	            |   \-- param.ini
	            |
	            \-- second-instance
	                |-- bin* ( -> ../bin)
	                \-- param.ini
	    
	( -> <symbolic link>)

Create the structure

`cd /path/to/collec-science`  
`sudo ln -s collec bin`  
`sudo mkdir first-instance`  _this is the instance folder (see the tree example)_  
`sudo ln -s bin first-instance/bin` 

#### Extract keys and values

##### ini file structure
Comments should be prefixed with semicolon character  
<sup>info @ [php.net](http://php.net/manual/en/function.parse-ini-file.php#refsect1-function.parse-ini-file-changelog)</sup>

Here below there are 4 variables. The value of #var is 222. Strings containing non-aplhanumeric characters should be enclosed with double-quotes _`""`_.
``` ini
;this is a comment
var = 1
#var = 222 ;https://en.wikipedia.org/wiki/INI_file#Comments_2  
string = this works
string_special = "that's special ;"
```

A typical minimal CS-MI param.ini file should contain

``` ini
APPLI_titre = First Instance
; Database management
BDD_login = username
BDD_passwd = password
BDD_dsn = "pgsql:host=localhost;dbname=dbname"

; Rights management, logins and log records database
GACL_dblogin = username
GACL_dbpasswd = password
GACL_dsn = "pgsql:host=localhost;dbname=dbname"
```

Use the default **`param.inc.php.dist`** or already configured **`param.inc.php`** file for the new instance. The _Minimal configuration **(A)**_ option below will create the **`param.ini`** file. Choose the _optional configuration **(B)**_ for more complex instance configuration.

* _Minimal configuration requirements **(A)**_  
`sed -e 's/^\$//' -e 's/;$//' -ne '/titre =\|login =\|passwd =\|dsn =/p' -e '1i ; First instance config' collec/param/param.inc.php.dist > first-instance/param.ini`

  - `'s/^\$//'`					_create keys - remove leading `$` characters_
  - `'s/;$//'`					_remove ending semicolons `;`_
  - `-n '/titre =\|login =\|passwd =\|dsn =/p'`	_keep the keys `titre`, `login`, `passwd`, `dsn`_
  - `'1i ; First instance config'`		_add header_

> * Including all variables in scope _( optional and instance specific configuration ) **(B)**_  
 `sed -e 's/^[^$].*$/;&/' -e 's/\$//g' -e 's/;$//' -e 's/^\(paramI\|SMARTY\)/;&/' collec/param/param.inc.php.dist > second-instance/param.ini`  
   - `'s/^[^$].\+$/;&/'` _or_ `'s/^[^$].*$/;&/'`	_add ini comments_
   - `'s/\$//g'`					_remove _'$'_ character from variable names_  
   - `'s/;$//'`						_remove semicolons at the end of lines_  
   - `'s/^\(paramI\|SMARTY\)/;&/'`			_comment param.ini and smarty variables_  

> * Removing php comments - for complete clean-up run  
   `sed -e 's/^[\*/<>? ][\*/<>? ]*/;/' -e 's/\$//g' -e 's/;$//' -e 's/^\(paramI\|SMARTY\)/;&/' collec/param/param.inc.php.dist > second-instance/param.ini`  
   - `-r 's/^[\*/><? ]+/;/'`	_extended regular expressions version_ _or shorter_ `'s/^[\*/><? ]\+/;/'`  

### Configure databases and credentials

Modify the connection details in the created **`param.ini`** file to match the configuration in **`pg_hba.conf`** and enable the DB access.
> 

#### Start from scratch
To start a fresh instance create a new database using the collec-science [init script]<sup id="n1">[(1)](#f1)</sup>. Don't forget to chose a database name suiting the new instance and to configure its access in the postgresql pg_hba.conf

<sup id="f1">(1) https://github.com/Irstea/collec/blob/03dc3942bb46ddf5c37f114210dbffc641ff22e1/install/deploy_new_instance.sh#L40</sup>

[init script]: https://github.com/Irstea/collec/blob/hotfix-2.0.2/install/init_by_psql.sql

#### Duplicate existing database

If the database contains data which can be used in the new instance :

`sudo -u postgres pg_dump myhotdb > path/to/hotDBexport.sql` _export the existing DB_  
`sudo -u postgres psql -c "CREATE DATABASE newinstancedb OWNER collec;"` _create a new empty DB_ <sup id="n1">[(2)](#f2)</sup>
> <sup>make sure the _OWNER_ has been previously created</sup>

`sudo -u postgres psql newinstancedb < path/to/hotDBimport.sql` _and reimport the exported DB_

<sup id="f2">(2)</sup>_At the present time the username of the database [has to be identic](https://github.com/Irstea/collec/issues/194) to the username of the exported DB._ [↩](#n2)

Consider reading the chapters about upgrading database if version of the new instance is newer from the currently installed collec-science on your system.

