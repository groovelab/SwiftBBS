# SwiftBBS

SwiftBBS is BBS with [Swift](https://github.com/apple/swift), MySQL and [PerfectLib](https://github.com/PerfectlySoft/Perfect) on Linux (Ubuntu 15.10)

## Install ImageMagick

```
$ sudo apt-get install -y imagemagick
```

## Install Swift

See [swift.org](https://swift.org/getting-started/#installing-swift) or [gist](https://gist.github.com/groovelab/dc2a434e2db0b27320ac#swift%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)

## Clone repository

```
$ git clone https://github.com/groovelab/SwiftBBS.git
$ cd SwiftBBS
$ git submodule init
$ git submodule update
$ git submodule foreach 'git pull origin master'
```

## Install PerfectLib

ref. [PerfectLib README](https://github.com/PerfectlySoft/Perfect/tree/master/PerfectLib#perfectlib) or [gist](https://gist.github.com/groovelab/dc2a434e2db0b27320ac#perfectlib-%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)

```
$ sudo apt-get -y install libssl-dev libevent-dev libsqlite3-dev make make-guile
$ cd Perfect/PerfectLib
$ sudo make
$ sudo make install
$ ll /usr/local/lib/*Perfect*
/usr/local/lib/PerfectLib.so -> (your_home)/SwiftBBS/Perfect/PerfectLib/PerfectLib.so
/usr/local/lib/PerfectLib.swiftdoc -> (your_home)/SwiftBBS/Perfect/PerfectLib/PerfectLib.swiftdoc
/usr/local/lib/PerfectLib.swiftmodule -> (your_home)/SwiftBBS/Perfect/PerfectLib/PerfectLib.swiftmodule
$ cd ../../ 
```

## Install Perfect Server FastCGI

You can run SwiftBBS on PerfectServerHttp or Apache2(mod_perfect)

ref. [PerfectServer README](https://github.com/PerfectlySoft/Perfect/tree/master/PerfectServer#perfect-server) or [gist](https://gist.github.com/groovelab/dc2a434e2db0b27320ac#perfectserver%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)

```
$ cd Perfect/PerfectServer
$ sudo make
$ sudo ln -sf "$(pwd)/perfectserverfcgi" /usr/local/bin/
$ ll /usr/local/bin/perfect*
/usr/local/bin/perfectserverfcgi -> (your_home)/SwiftBBS/Perfect/PerfectServer/perfectserverfcgi
$ cd ../../
```

## Install MySQL Connect

```
$ sudo apt-get -y install mysql-server libmysqlclient-dev
$ cd Perfect/Connectors/MySQL
$ sudo make
$ sudo ln -sf "$(pwd)/MySQL.so" /usr/local/lib/
$ sudo ln -sf "$(pwd)/MySQL.swiftmodule" /usr/local/lib/
```

create database

```
$ mysql -u root
mysql> CREATE DATABASE SwiftBBS DEFAULT CHARACTER SET utf8mb4;
```

## Deploy SwiftBBS

```
$ cd SwiftBBS
$ sudo make
$ sudo make install
$ cd ../
```

if you need to configure database setting

```
$ vi SwiftBBS\ Server/Config.swift
```

## Run Perfect Server FastCGI

```
$ SwiftBBS/SwiftBBS\ Server/perfectServerFcgi.sh start
```

## Configure nginx

```
$ sudo apt-get install nginx
$ sudo vi /etc/nginx/sites-available/default
$ sudo service nginx start
```

See [/etc/nginx/sites-available/default](https://gist.github.com/groovelab/fae744207b96133ebd4a#file-your-domain-com)

you must change ```$perfect_root``` and ```$root``` like below

```
set $perfect_root "(your_home)/SwiftBBS/SwiftBBS/SwiftBBS Server";
set $root "${perfect_root}/webroot";
```
## After

access http://your.domain.com/


