module ws.bindings.fontconfig;

version(Posix):

import x11.Xlib;

extern(C):

	enum FC_CHARSET = "charset";
	enum FC_SCALABLE = "scalable";

	alias FcChar8 = char;
	alias FcChar32 = long;
	struct FcPattern {}
	struct FcCharSet{}
	
	enum FcResult {
	    FcResultMatch, FcResultNoMatch, FcResultTypeMismatch, FcResultNoId,
	    FcResultOutOfMemory
    }
	
	alias FcMatchKind = int;

	enum: FcMatchKind {
	    FcMatchPattern, FcMatchFont, FcMatchScan
	}
	
	Bool FcPatternAddBool(FcPattern*, const(char)*, Bool b);
	Bool FcPatternAddCharSet(FcPattern*, const(char)*, const(FcCharSet)*);
    Bool FcConfigSubstitute(void*, FcPattern*, FcMatchKind);
    FcCharSet* FcCharSetCreate();
    Bool FcCharSetAddChar(FcCharSet*, FcChar32);
	FcPattern* FcNameParse(const(char)* name);
	FcPattern* FcPatternDuplicate(FcPattern*);
	void FcDefaultSubstitute(FcPattern*);
	void FcPatternDestroy(FcPattern*);
	void FcCharSetDestroy(FcCharSet*);
	void FcPatternPrint(const FcPattern *p);
	FcPattern * FcFontMatch(FcConfig *config, FcPattern *p, FcResult *result);
	FcResult FcPatternGetInteger(FcPattern *p, const char *object, int n, int *i);
	FcResult FcPatternGetString(FcPattern *p, const char *object, int n, FcChar8 **s);
	alias FcConfig = void*;
