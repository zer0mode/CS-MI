### GeoNetwork - rapid install

##### system specifics

> <kbd>::</kbd> Debian GNU/Linux 9 (stretch) <kbd>::</kbd> Apache/2.4.25 (Debian) <kbd>::</kbd> Apache Tomcat/8.5.14 (Debian) <kbd>::</kbd> Java(TM) SE Runtime Environment (build 1.8.0_171-b11) <kbd>::</kbd> PostgreSQL 9.6.7 <kbd>::</kbd> GeoNetwork v3.4.2 <kbd>::</kbd>

---

Check if java is present  
`java -version`  
> java version "1.8.0_171"  
> Java(TM) SE Runtime Environment (build 1.8.0_171-b11)  
> Java HotSpot(TM) 64-Bit Server VM (build 25.171-b11, mixed mode)

If not install with  
> `sudo apt-get install openjdk-{VERSION}-jre-headless`  
> <sup>stretch latest recommended java {VERSION} is 8 or 9</sup>

#### Tomcat install & config

Install tomcat  
`sudo apt-get install tomcat8`

Check if it's running  
`sudo /usr/share/tomcat8/bin/version.sh`

To enable ssl edit **`server.xml`** in _/etc/tomcat8/_. Copy uncomment & configure the Connector with port 8443.

    <Connector port="8443" protocol="org.apache.coyote.http11.Http11AprProtocol"  
       maxThreads="150"  
       maxHttpHeaderSize="8192"  
       minSpareThreads="25"  
       maxSpareThreads="75"  
       enableLookups="false"  
       SSLEnabled="true" >  
       <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />  
       <SSLHostConfig>  
           <Certificate certificateKeyFile="/etc/ssl/certs/keyfile.key"  
               certificateFile="/etc/ssl/certs/certfile.crt"  
               certificateChainFile="/etc/ssl/certs/CAfile.crt"  
               type="RSA" />  
       </SSLHostConfig>  
    </Connector>

Allocate the resources  
`sudo sh -c "cat > /usr/share/tomcat8/bin/setenv.sh"`

> CATALINA\_OPTS="$CATALINA_OPTS -Xms256m -Xmx2048m"  
> <kbd>Ctrl-D</kbd>

If the geonetwork data folder should be externalized add its path  
> CATALINA\_OPTS="$CATALINA\_OPTS -Xms256m -Xmx2048m -Dgeonetwork.dir=/usr/share/tomcat8/gn\_data\_externalized"  
> <kbd>Ctrl-D</kbd>

_Tomcat needs permission to write in that location. Detailed info about setting-up the data folder and writing permissions can be found [here](https://github.com/zer0mode/GNdplyi#data-directory)._

Make executable  
`sudo chmod +x /usr/share/tomcat8/bin/setenv.sh`

Apply modifications by restarting the service  
`sudo service tomcat8 restart`  

Check if _"It works !"_ - run **localhost:8080** in browser.

Geonetwork-Apache configuration is not required. This step is optional, but eventually handy for _"beautification"_ of the catalog URL.  
> `sudo cp -a /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/geonetwork.conf`
>
> Edit **`geonetwork.conf`** - add in \<Virtualhost\> section  
> ```
> ProxyPass /geonetwork/ http://localhost:8080/geonetwork/  
> ProxyPassReverse /geonetwork/ http://localhost:8080/geonetwork/  
> ```  
<sup>more @[stackoverflow](https://stackoverflow.com/questions/13550121/apache-tomcat-proxypass-and-proxypassreverse#27746392)</sup>

`sudo service apache2 reload`

#### Configure postgresql

`sudo -u postgres psql`  
> <sup>psql (9.6.7)</sup>

`postgres=# CREATE DATABASE hotdb ;`  
> <sup>CREATE DATABASE</sup>

`postgres=# CREATE USER hotuser WITH PASSWORD 'hottestpass' ;`  
> <sup>CREATE ROLE</sup>

`postgres=# ALTER DATABASE hotdb OWNER TO hotuser;`  
> <sup>ALTER DATABASE</sup>

`postgres=# \l`  
`postgres=# \q`

Config the user access  
`sudo nano /etc/postgresql/10/main/pg_hba.conf`

Add the user in the section _"local"_
```
# "local" is for Unix domain socket connections only  
#local   all             all                                     peer  
#local   all             all                                     md5  
local   hotdb           hotuser                                 md5
```

Reload postgresql  
`sudo service postgresql reload`

Now you can create the spatial extension if needed  
`psql hotdb hotuser`  
`hotdb=# CREATE EXTENSION postgis_topology ;`  
> <sup>CREATE EXTENSION</sup>

`hotdb=# \dx`  
`hotdb=# \q`

#### GeoNetwork configuration

Download geonetwork  
`cd /var/lib/tomcat8/webapps`  
`sudo wget https://sourceforge.net/projects/geonetwork/files/GeoNetwork_opensource/v3.4.2/geonetwork.war`

Wait a few moments for tomcat to deploy the file.

Backup jdbc.properties  
`sudo cp -a /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-db/jdbc.properties /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-db/jdbc.properties.orig`

Config jdbc with appropriate credentials  
`sudo nano /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-db/jdbc.properties`

Choose node ( activate postgresql database )  
`sudo nano /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-node/srv.xml`

- `<import resource="../config-db/h2.xml"/>` _enabled by default_
- `<import resource="../config-db/postgres.xml"/>` _uncomment for postgres db_
- `<import resource="../config-db/postgres-postgis.xml"/>` _uncomment for postgres db with spatial extension - postGIS_

Init geonetwork - run **localhost:8080/geonetwork** in browser.

If geonetwork is rendering blank pages, that's a cache issue. Try to remove __`wro4j-cache*`__ files in _/var/lib/tomcat8/webapps/geonetwork/WEB-INF/data/_ or another location if the data folder has been externalized.

Finaly, clearing cache in the admin interface should solve the problem. See recommended steps in the ["Contribute" pages not displaying in GeoNetwork 3.0.2][] post.
["Contribute" pages not displaying in GeoNetwork 3.0.2]: http://osgeo-org.1560.x6.nabble.com/Contribute-pages-not-displaying-in-GeoNetwork-3-0-2-tp5324713p5327628.html

Certain configuration details are explained in my [previous installation guide](https://github.com/zer0mode/GNdplyi).
