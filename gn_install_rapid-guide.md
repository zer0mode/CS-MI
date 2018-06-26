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

To enable ssl edit **`server.xml`** in _/etc/tomcat8/_. Copy uncomment & configure the __\<Connector\>__ ( port 8443 ).

    <Connector port="8443" protocol="org.apache.coyote.http11.Http11AprProtocol"
               maxThreads="150" SSLEnabled="true" >
        <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
        <SSLHostConfig>
            <Certificate certificateKeyFile="/path/to/keyfile.key"
                         certificateFile="/path/to/certfile.crt"
                         certificateChainFile="/path/to/CAfile.crt"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>

<sup>more @ [tomcatdocs](http://tomcat.apache.org/tomcat-8.5-doc/ssl-howto.html)</sup>

> _View the [errors & solutions](#appendix---tomcat-errors--solutions) appendix_.

Allocate the resources  
`sudo sh -c "cat > /usr/share/tomcat8/bin/setenv.sh"`

> CATALINA\_OPTS="$CATALINA_OPTS -Xms256m -Xmx2048m"  
> <kbd>Ctrl-D</kbd>

If the geonetwork data folder should be externalized add its path  
> CATALINA\_OPTS="$CATALINA\_OPTS -Xms256m -Xmx2048m -Dgeonetwork.dir=/usr/share/tomcat8/gn\_data\_externalized"  
> <kbd>Ctrl-D</kbd>

_Tomcat needs permission to write on that location. See [detailed info][di] about setting-up the data folder and writing permissions._

[di]: https://github.com/zer0mode/GNdplyi#data-directory

Make executable  
`sudo chmod +x /usr/share/tomcat8/bin/setenv.sh`

Apply modifications by restarting the service  
`sudo service tomcat8 restart`  

Check if _"It works !"_ - run **localhost:8080** in browser.

Geonetwork-Apache configuration is not required. This step is optional, but eventually handy for URL _"beautification"_.  
> `sudo cp -a /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/geonetwork.conf`
>
> Edit **`geonetwork.conf`** - add in \<Virtualhost\> section  
> ```
> ProxyPass /geonetwork/ http://localhost:8080/geonetwork/  
> ProxyPassReverse /geonetwork/ http://localhost:8080/geonetwork/  
> ```  
<sup>more @ stackoverflow [(I)](https://stackoverflow.com/questions/13550121/apache-tomcat-proxypass-and-proxypassreverse#27746392) & [(II)](https://stackoverflow.com/questions/31534188/redirect-apache-to-tomcat-8-with-mod-proxy)</sup>

Put the conig in action  
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

Configure the user access  
`sudo nano /etc/postgresql/10/main/pg_hba.conf`

Add the user in section _"local" is for Unix domain socket connections only_
```
# "local" is for Unix domain socket connections only  
#local   all             all                                     peer  
#local   all             all                                     md5  
local   hotdb           hotuser                                 md5
```

Reload postgresql  
`sudo service postgresql reload`

Now create the spatial extension if needed  
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

Backup **`jdbc.properties`**  
`sudo cp -a /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-db/jdbc.properties /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-db/jdbc.properties.orig`

Config jdbc with appropriate credentials  
`sudo nano /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-db/jdbc.properties`

Choose node ( activate postgresql database )  
`sudo nano /var/lib/tomcat8/webapps/geonetwork/WEB-INF/config-node/srv.xml`

- `<import resource="../config-db/h2.xml"/>` _enabled by default_
- `<import resource="../config-db/postgres.xml"/>` _uncomment for postgres db_
- `<import resource="../config-db/postgres-postgis.xml"/>` _uncomment for postgres db with spatial extension - postGIS_

Init geonetwork - run **localhost:8080/geonetwork** in browser.

If geonetwork is rendering blank pages, that must be the cache issue. Try to remove __`wro4j-cache*`__ files in _/var/lib/tomcat8/webapps/geonetwork/WEB-INF/data/_ or another location if the data folder has been externalized. **Carefully !**

`sudo rm -r /geonetwork/data/location/wro4j-cache*`

Finaly, clearing cache in the admin interface should solve the problem. See recommended steps in the ["Contribute" pages not displaying in GeoNetwork 3.0.2][cpndig] post.

[cpndig]: http://osgeo-org.1560.x6.nabble.com/Contribute-pages-not-displaying-in-GeoNetwork-3-0-2-tp5324713p5327628.html

Certain configuration details are explained in my [previous installation guide][pig].

[pig]: https://github.com/zer0mode/GNdplyi

---

###### Appendix - tomcat errors & solutions

__Error parsing HTTP request header__
> INFOS [http-nio-8080-exec-5] org.apache.coyote.http11.Http11Processor.service Error parsing HTTP request header  
>     Note: further occurrences of HTTP header parsing errors will be logged at DEBUG level.  
>     java.lang.IllegalArgumentException: Invalid character found in method name. HTTP method names must be tokens  

* - add `maxHttpHeaderSize="8192"` in the _\<Connector\>_  
<sup>https://stackoverflow.com/questions/26504212/error-parsing-http-request-header#47257892</sup>

  - or minimise `maxKeepAliveRequests`  
Review all the posts in [this thread](https://stackoverflow.com/questions/18819180/tomcat-7-0-43-info-error-parsing-http-request-header).

  - [Configuring ssl](https://stackoverflow.com/questions/38891866/when-spring-boot-startup-throw-out-the-method-names-must-be-tokens-exception#41728777) might help

- Verify and eliminate [another possible cause][apc]
  - *`URIEncoding="UTF-8"`*
  - or by [allowing forbiden characters][afc]  

  <sup>more @ [wiki](https://wiki.apache.org/tomcat/FAQ/CharacterEncoding#How)</sup>

[apc]: https://stackoverflow.com/questions/41053653/tomcat-8-is-not-able-to-handle-get-request-with-in-query-parameters/44005213#46053161
[afc]: https://stackoverflow.com/questions/41053653/tomcat-8-is-not-able-to-handle-get-request-with-in-query-parameters/44005213#44005213

__Problem with directory__ issue

> WARNING [main] org.apache.catalina.startup.ClassLoaderFactory.validateFile Problem with directory [/var/lib/tomcat8/common/classes], exists: [false], isDirectory: [false], canRead: [false]

[symbolic links solution][sls] ?

[sls]: https://stackoverflow.com/questions/27337674/folder-issues-with-tomcat-7-on-ubuntu#41043514

__Rigged installation__

If tomcat server does not start-up and restarting the service throws a `status=1/FAILURE`, [purge and reinstall tomcat][part].

[part]: https://stackoverflow.com/questions/36259907/service-tomcat8-failed-to-start-by-using-service-tomcat8-start/50987693#50987693
