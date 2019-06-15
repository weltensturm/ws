module ws.inotify;


import
    core.sys.linux.sys.inotify,
    core.sys.posix.sys.time,
    core.sys.posix.unistd,
    core.sys.posix.sys.select,
    core.stdc.errno,
    std.string,
    std.stdio,
    std.algorithm,
    std.conv,
    std.file,
    ws.event;


version(Posix):

__gshared:


class Inotify {

    enum EVENT_BUFFER_LENGTH = (inotify_event.sizeof + 16) * 1024;

    static int inotify = -1;
    static timeval timeOut;
    static fd_set descriptorSet;

    static Watcher[int] staticWatchers;

    enum {
        Add,
        Remove,
        Modify
    }


    shared static this(){
        if(inotify >= 0)
            return;
        inotify = inotify_init;
        if(inotify < 0)
                throw new Exception("Failed to initialize inotify: %s".format(errno));
            timeOut.tv_sec = 1;
            timeOut.tv_usec = 0;
            FD_ZERO(&descriptorSet);
    }


    static class Watcher {
        this(){
            event = new Event!(string, string, int);
        }
        string directory;
        Event!(string, string, int) event;
    }


    static void watch(string path, void delegate(string, string, int) event){
        assert(inotify >= 0);
        if(!path.isDir)
            throw new Exception("\"" ~ path ~ "\" is not a directory. Please don't watch single files, they need to be \"re-watched\" in almost all cases on change");
        foreach(wd, watcher; staticWatchers){
            if(watcher.directory == path){
                watcher.event ~= event;
                return;
            }
        }
        if(staticWatchers.values.find!(a => a.directory == path).length){
            return;
        }
        int wd = inotify_add_watch(inotify, path.toStringz,
                IN_CLOSE_WRITE
                | IN_MOVED_FROM
                | IN_MOVED_TO
                | IN_CREATE
                | IN_DELETE
                | IN_MASK_ADD);
        if(wd < 0)
            throw new Exception("inotify error in %s: %s".format(path, errno));
        auto watcher = new Watcher;
        watcher.directory = path;
        watcher.event ~= event;
        staticWatchers[wd] = watcher;
    }

    static void update(){
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
                auto watcher = staticWatchers[pevent.wd];
                watcher.event(
                    watcher.directory,
                    (cast(char*)&pevent.name).to!string,
                    pevent.mask & IN_CLOSE_WRITE ? Modify
                        : pevent.mask & (IN_MOVED_TO | IN_CREATE) ? Add
                        : pevent.mask & (IN_MOVED_FROM | IN_DELETE) ? Remove
                        : -1);
                i += inotify_event.sizeof + pevent.len;
            }
        }

    }

}

