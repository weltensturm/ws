module ws.cache;


class CachedFactory(T){

    T[size_t] cache;

    T get(Args...)(Args args){
        size_t hash;
        foreach(arg; args){
            hash = hashOf(arg, hash);
        }
        auto a = hash in cache;
        if(a)
            return *a;
        else {
            auto b = new T(args);
            cache[hash] = b;
            return b;
        }
    }

}