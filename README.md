# SwiftBBS
## under construction

OS : Ubuntu 15.10

## install Swift

ref. https://gist.github.com/groovelab/dc2a434e2db0b27320ac#swift%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB

## git clone

```
$ git clone https://github.com/groovelab/SwiftBBS.git
$ cd SwiftBBS
$ git submodule init
$ git submodule update
$ git submodule foreach 'git pull origin master'
```

## install PerfectLib

ref. https://gist.github.com/groovelab/dc2a434e2db0b27320ac#perfectlib-%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB

```
$ sudo apt-get -y install libssl-dev libevent-dev libsqlite3-dev make make-guile
$ cd Perfect/PerfectLib
$ sudo make
$ sudo make install
$ ls -al /usr/local/lib/*Perfect*
$ cd ../../ 
```

## install Perfect Server FastCGI

ref. https://gist.github.com/groovelab/dc2a434e2db0b27320ac#perfectserver%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB

```
$ cd Perfect/PerfectServer
$ sudo make
$ sudo ln -sf perfectserverfcgi /usr/local/lib/
$ ls -al /usr/local/bin/perfect*
$ cd ../../
```

## deploy SwiftBBS

```
$ cd SwiftBBS
$ sudo make
$ sudo make install
$ cd ../
```

## run Perfect Server FastCGI

```
$ SwiftBBS/SwiftBBS\ Server/perfectServerFcgi.sh start
```

## configure nginx

ref. https://gist.github.com/groovelab/fae744207b96133ebd4a

```
$ sudo apt-get install nginx
$ sudo vi /etc/nginx/sites-available/default (ref. https://gist.github.com/groovelab/fae744207b96133ebd4a#file-your-domain-com)
$ $ sudo service nginx start
```

access http://your.domain.com/


