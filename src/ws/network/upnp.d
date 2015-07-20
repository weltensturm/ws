module ws.network.upnp;

import
	ws.exception,
	ws.string,
	ws.io,
	ws.sys.library,
	ws.time,
	std.socket,
	std.c.windows.winsock;

//pragma(lib, "miniupnpc");

__gshared:


class upnp {

	enum: long {
		tcp = 1,
		udp = 1<<1
	}

	static UPNPUrls urls;
	static IGDdatas data;
	static UPNPDev* devlist;
	static string addrInternal;
	static string addrExternal;

	version(Windows)
		static bool wsaInitialized;

	static void init(){
		
		version(Windows)
			if(!wsaInitialized){
				WSADATA wd;
				int val = WSAStartup(0x2020, &wd);
				wsaInitialized = true;
				if(val)
					exception("Unable to initialize socket library " ~ tostring(val));
			}
		
		FreeUPNPUrls(&urls);
		
		char[64] lanaddr;
		int r;
		int error = 0;
		devlist = upnpDiscover(2000, null, null, 0/*sameport*/, 0, &error);
		if(!devlist)
			exception("upnpDiscover() error: " ~ error.tostring());
		r = UPNP_GetValidIGD(devlist, &urls, &data, lanaddr.ptr, lanaddr.sizeof);
		if(!r || r != 1)
			exception(tostring("Could not find valid Internet Gateway Device (Error %)", r));
		addrInternal = lanaddr.tostring();
		char[40] externalIPAddress;

		UPNP_GetExternalIPAddress(urls.controlURL, data.first.servicetype.ptr, externalIPAddress.ptr);
		if(!externalIPAddress[0])
			throw new Exception("GetExternalIPAddress failed.");
		addrExternal = externalIPAddress.tostring();
	}


	static class forward {
		long external;
		long protocol;

		double timeout;

		@property bool valid(){
			return timeout > time.now();
		}
		
		this(long portIntern, long portExtern, long p){
			if(p & tcp) addPortMapping("TCP", portIntern, portExtern);
			if(p & udp) addPortMapping("UDP", portIntern, portExtern);
			timeout = time.now() + 7200;
		}
		
		void disable(){
			if(protocol & tcp) removeMapping("TCP", external);
			if(protocol & udp) removeMapping("UDP", external);
		}
		
	}


	static ~this(){
		FreeUPNPUrls(&urls);
	}
	

	private:
	
		static void removeMapping(string pr, long e){
			int r = UPNP_DeletePortMapping(urls.controlURL, data.first.servicetype.ptr, tostring(e).toStringz(), pr.toStringz(), null);
			writeln("UPNP_DeletePortMapping() returned : %", r);
		}
	
		static void addPortMapping(string pr, long i, long e, bool updated = false){
			char[40] intClient;
			char[6] intPort;
			char[16] duration;
			int r = UPNP_AddPortMapping(
				urls.controlURL, data.first.servicetype.ptr,
				tostring(e).toStringz(), tostring(i).toStringz(), addrInternal.toStringz(),
				null, pr.toStringz(), null, "7200"
			);
			if(r != UPNPCOMMAND_SUCCESS){
				if(updated){
					throw new Exception(tostring("AddPortMapping failed: % (%)", r, strupnperror(r)));
				}else{
					init();
					addPortMapping(pr, i, e, true);
				}
			}
			/+
			r = UPNP_GetSpecificPortMappingEntry(
				urls.controlURL, data.first.servicetype.ptr, tostring(e).toStringz,
				tostring(i).toStringz, intClient.ptr, intPort.ptr, null/*desc*/, null/*enabled*/, duration.ptr
			);
			if(r != UPNPCOMMAND_SUCCESS)
				//throw new Exception(tostring("GetSpecificPortMappingEntry failed: % (%)", r, strupnperror(r)));
				writeln("GetSpecificPortMappingEntry failed: % (%)", r, strupnperror(r));
			+/
		}

}


extern(C):

	const static auto MINIUPNPC_URL_MAXSIZE = 128;
	const static auto UPNPCOMMAND_SUCCESS = 0;

	struct UPNPUrls {
		char* controlURL;
		char* ipcondescURL;
		char* controlURL_CIF;
		char* controlURL_6FC;
		char* rootdescURL;
	}
	
	struct IGDdatas_service {
		char[MINIUPNPC_URL_MAXSIZE] controlurl;
		char[MINIUPNPC_URL_MAXSIZE] eventsuburl;
		char[MINIUPNPC_URL_MAXSIZE] scpdurl;
		char[MINIUPNPC_URL_MAXSIZE] servicetype;
	}
		
	struct IGDdatas {
		char[MINIUPNPC_URL_MAXSIZE] cureltname;
		char[MINIUPNPC_URL_MAXSIZE] urlbase;
		char[MINIUPNPC_URL_MAXSIZE] presentationurl;
		int level;
		IGDdatas_service CIF;
		IGDdatas_service first;
		IGDdatas_service second;
		IGDdatas_service IPv6FC;
		IGDdatas_service tmp;
	}
	
	struct UPNPDev {
		UPNPDev* pNext;
		char * descURL;
		char * st;
		uint scope_id;
		char[2] buffer;
	}
	
	
	mixin library!(
		"miniupnpc", "miniupnpc",
		"strupnperror",
			"const(char*) function(int)",
		"upnpDiscover",
			"UPNPDev* function(int, const char*, const char*, int, int, int*)",
		"UPNP_GetValidIGD",
			"int function(UPNPDev*, UPNPUrls*, IGDdatas*, char*, int)",
		"UPNP_GetExternalIPAddress",
			"int function(const char*, const char*, char*)",
		"UPNP_AddPortMapping",
			"int function(const char*, const char*, const char*, const char*, const char*, const char*, const char*, const char*, const char*)",
		"UPNP_GetSpecificPortMappingEntry",
			"int function(const char*, const char*, const char*, const char*, char*, char*, char*, char*, char*)",
		"UPNP_DeletePortMapping",
			"int function(const char*, const char*, const char*, const char*, const char*)",
		"FreeUPNPUrls",
			"void function(UPNPUrls*)"
		
	);
