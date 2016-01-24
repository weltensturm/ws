module ws.inotify;


import
    core.sys.linux.sys.inotify,
    core.sys.posix.sys.time,
    core.sys.posix.unistd,
    core.sys.posix.sys.select,
    std.string,
    std.stdio,
    std.algorithm,
    std.conv,
    ws.event;


class Inotify {

    enum EVENT_BUFFER_LENGTH = (inotify_event.sizeof + 16) * 1024;

    WatchStruct*[int] watchers;
    int mLastWatchID;
    int inotify;
    timeval timeOut;
    fd_set descriptorSet;

    enum Action {
        Add,
        Remove,
        Modify
    }

    struct WatchStruct {
        int id;
        string directory;
        Event!(string, string) add;
        Event!(string, string) remove;
        Event!(string, string) change;
    };


    this(){
        inotify = inotify_init();
        if(inotify < 0)
            writeln("Error");
        timeOut.tv_sec = 0;
        timeOut.tv_usec = 0;
        FD_ZERO(&descriptorSet);
    }


    void destroy(){
    }


    WatchStruct* addWatch(string directory, bool recursive){
        int wd = inotify_add_watch(inotify, directory.toStringz, IN_CLOSE_WRITE | IN_MOVED_TO | IN_CREATE | IN_MOVED_FROM | IN_DELETE);
        if(wd < 0){
            throw new Exception("inotify error in ", directory);
        }
        auto watcher = new WatchStruct;
        watcher.id = wd;
        watcher.directory = directory;
        watcher.add = new Event!(string, string);
        watcher.remove = new Event!(string, string);
        watcher.change = new Event!(string, string);
        watchers[wd] = watcher;
        return watcher;
    }


    void removeWatch(string directory){
        foreach(id, watch; watchers)
            if(watch.directory == directory)
                removeWatch(watch);
    }


    void removeWatch(WatchStruct* watcher){
        foreach(id, watch; watchers)
            if(watch == watcher)
                watchers.remove(id);
        inotify_rm_watch(inotify, watcher.id);
    }


    void update(){
        FD_SET(inotify, &descriptorSet);
        int ret = select(inotify + 1, &descriptorSet, null, null, &timeOut);
        if(ret < 0){
            perror("select");
        }else if(FD_ISSET(inotify, &descriptorSet)){
            ssize_t len, i = 0;
            byte[EVENT_BUFFER_LENGTH] buff = 0;
            len = read(inotify, buff.ptr, buff.length);
            while(i < len){
                auto pevent = cast(inotify_event*)&buff[i];
                WatchStruct* watch = watchers[pevent.wd];
                handleAction(watch, (cast(char*)&pevent.name).to!string, pevent.mask);
                i += inotify_event.sizeof + pevent.len;
            }
        }
    }


    void handleAction(WatchStruct* watch, string filename, ulong action){
        if(IN_CLOSE_WRITE & action)
            watch.change(watch.directory, filename);
        if(IN_MOVED_TO & action || IN_CREATE & action)
            watch.add(watch.directory, filename);
        if(IN_MOVED_FROM & action || IN_DELETE & action)
            watch.remove(watch.directory, filename);
    }


}

