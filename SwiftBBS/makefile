# Makefile for Perfect Server

TARGET = SwiftBBS
OS = $(shell uname)
MODULE_SRC = $(shell ls -b SwiftBBS\ Server/*.swift)
PERFECT_ROOT = ../Perfect/PerfectLib
MYSQL_ROOT = ../Perfect/Connectors/MySQL
SWIFTC = swift
SWIFTC_FLAGS = -frontend -c -module-cache-path $(MODULE_CACHE_PATH) -emit-module -I /usr/local/lib \
 -I $(PERFECT_ROOT)/linked/LibEvent -I $(PERFECT_ROOT)/linked/OpenSSL_Linux -I $(PERFECT_ROOT)/linked/ICU -I $(PERFECT_ROOT)/linked/SQLite3 -I $(PERFECT_ROOT)/linked/cURL_Linux -I $(PERFECT_ROOT)/linked/LinuxBridge \
 -I $(MYSQL_ROOT)/linked/libmysqlclient
MODULE_CACHE_PATH = /tmp/modulecache
Linux_SHLIB_PATH = $(shell dirname $(shell dirname $(shell which swiftc)))/lib/swift/linux
SHLIB_PATH = -L$($(OS)_SHLIB_PATH)
LFLAGS = $(SHLIB_PATH) -luuid -lswiftCore -lswiftGlibc /usr/local/lib/MySQL.so /usr/local/lib/PerfectLib.so -Xlinker -rpath -Xlinker $($(OS)_SHLIB_PATH) -shared

all: $(TARGET)

install:
	@mkdir -p `pwd`/SwiftBBS\ Server/PerfectLibraries
	ln -sf `pwd`/$(TARGET).so `pwd`/SwiftBBS\ Server/PerfectLibraries

modulecache:
	@mkdir -p $(MODULE_CACHE_PATH)

$(TARGET): modulecache
	$(SWIFTC) $(SWIFTC_FLAGS) $(MODULE_SRC) -o $@.o -module-name $@ -emit-module-path $@.swiftmodule
	clang++ $(LFLAGS) $@.o -o $@.so

clean:
	@rm -f *.o

