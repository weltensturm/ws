
module ws.gl.font;

import
    file = std.file,
    std.process,
    std.traits,
    std.conv,
    std.algorithm,
    std.math,

    derelict.freetype.ft,
    derelict.util.exception,

    //ws.bindings.xlib,
    ws.log,
    ws.string,
    ws.gl.gl,
    ws.gl.context,
    ws.gl.batch;


version(Posix){
    import std.path;
    import ws.bindings.xlib:
        FcPattern,
        FcResult,
        FcNameParse,
        FcConfigSubstitute,
        FcDefaultSubstitute,
        FcPatternGetString,
        FcPatternGetInteger,
        FcMatchPattern,
        FcFontMatch,
        FcChar8,
        FcPatternDestroy;
}



private __gshared FT_Library ftLib;


shared static this(){
    DerelictFT.missingSymbolCallback = (name){
        //if(name == "FT_Gzip_Uncompress")
            return ShouldThrow.No;
        //return ShouldThrow.Yes;
    };
    DerelictFT.load();
    FT_Error r = FT_Init_FreeType(&ftLib);
    if(r)
        throw new Exception("Failed to initialize FreeType 2 [" ~ tostring(r) ~ "]");
    FT_Library_SetLcdFilter(ftLib, FT_LCD_FILTER_DEFAULT);
}

shared static ~this(){
    FT_Done_FreeType(ftLib);
}

struct SelectedFont {
    string path;
    int index;
}


byte applyGamma(ubyte b){
    return cast(ubyte)(((b/255.0)^^0.45)*255);
}

version(Posix){
    SelectedFont findFont(string name, int size){
        FcPattern *match;
        FcResult result;
        char *file;
        int index;
        name ~= "-" ~ size.to!string;
        auto pat = FcNameParse(cast(ubyte*)name.toStringz);
        FcConfigSubstitute(null, pat, FcMatchPattern);
        FcDefaultSubstitute(pat);
        match = FcFontMatch(null, pat, &result);

        FcPatternGetString(match, "file", 0, cast(FcChar8 **) &file);
        FcPatternGetInteger(match, "index", 0, &index);

        SelectedFont selected;
        selected.path = file.to!string;
        selected.index = index;

        FcPatternDestroy(match);
        FcPatternDestroy(pat);

        return selected;
    }
}

version(Windows){
    import ws.wm.win32.api;
    auto winDir(){
        WCHAR[MAX_PATH] winDir;
        auto winDirLength = GetWindowsDirectory(winDir.ptr, MAX_PATH);
        return winDir[0..winDirLength].to!string;
    }
    auto iterateRegistryKey(string key){
        struct Iterator {
            int opApply(int delegate(string, void[]) dg){
                int delegateResult = 0;
                enum fontRegistryPath = "Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts";
                HKEY hKey;
                LONG result;
                result = RegOpenKeyEx(HKEY_LOCAL_MACHINE, fontRegistryPath, 0, KEY_READ, &hKey);
                if(result != ERROR_SUCCESS){
                    return delegateResult;
                }
                DWORD maxKeySize, maxDataSize;
                result = RegQueryInfoKey(hKey, null, null, null, null, null, null, null, &maxKeySize, &maxDataSize, null, null);
                if(result != ERROR_SUCCESS){
                    return delegateResult;
                }
                DWORD valueIndex = 0;
                auto valueName = new BYTE[maxKeySize];
                auto value = new BYTE[maxDataSize];
                DWORD keySize, valueSize, valueType;
                do {
                    valueSize = maxDataSize;
                    keySize = maxKeySize;
                    result = RegEnumValue(hKey, valueIndex, cast(WCHAR*)valueName.ptr, &keySize, null, &valueType, value.ptr, &valueSize);
                    valueIndex++;
                    if(result != ERROR_SUCCESS || valueType != REG_SZ) {
                        continue;
                    }
                    auto keyNice = (cast(wchar*)(valueName[0..keySize])).to!string;
                    auto valueNice = value[0..valueSize];
                    delegateResult = dg(keyNice, valueNice);
                    if(delegateResult)
                        break;
                }while(result != ERROR_NO_MORE_ITEMS);
                RegCloseKey(hKey);
                return delegateResult;
            }
        }
        return Iterator();
    }

    SelectedFont findFont(string name, int size){
        foreach(key, valueBytes; iterateRegistryKey("Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts")){
            auto value = (cast(wchar*)valueBytes.ptr).to!string;
            if(name == key || (name ~ " (TrueType)") == key){
                return SelectedFont(winDir ~ "\\Fonts\\" ~ value, 0);
            }
        }
        return SelectedFont("", 0);
    }
}


version(Windows){
    enum FALLBACK_FONT = "Tahoma";
}
version(Posix){
    enum FALLBACK_FONT = "sans";
}


class Font {

    const string name;
    const int size;
    const int height;
    const int verticalOffset;
    const int em;
    GlContext context;

    this(GlContext context, string name, int size){
        this.context = context;
        if(name.split("-")[$-1].isNumeric)
            size = name.split("-")[$-1].to!int;
        this.name = name;
        this.size = size;

        bool found = false;
        auto selected = findFont(name, size);
        if(!selected.path.length){
            Log.warning("Could not find font \"%s\"".format(name));
            selected = findFont(FALLBACK_FONT, size);
            if(!selected.path.length)
                throw new Exception("Failed to find fallback font \"%s\", no usable font available".format(FALLBACK_FONT));
        }
        FT_Face face;
        FT_Error r = FT_New_Face(ftLib, selected.path.toStringz(), selected.index, &face);
        if(r)
            throw new Exception("Failed to load font \"" ~ name ~ "\": " ~ tostring(r));
        else {
            FT_Set_Char_Size(face, size*64, size*64, 96, 96);
            ftFace = face;
            auto scale = face.size.metrics.x_scale;
            height = cast(int)FT_MulFix(face.height, scale)/64;
            em = cast(int)FT_MulFix(face.units_per_EM, scale)/64;
            verticalOffset = -cast(int)FT_MulFix(face.descender, scale)/64;
        }
    }

    protected {
        Glyph[dchar] glyphs;
        FT_Face ftFace;
    }

    static class Glyph {
        uint tex;
        Batch vao;
        long advance;
        private this(){}
    }

    Glyph opIndex(dchar c){
        if(c in glyphs)
            return glyphs[c];
        auto g = new Glyph;
        FT_Error e = FT_Load_Glyph(ftFace, FT_Get_Char_Index(ftFace, c), FT_LOAD_FORCE_AUTOHINT);
        if(e)
            throw new Exception("FT_Load_Glyph failed (" ~ tostring(e) ~ ")");
        FT_Glyph glyph;
        e = FT_Get_Glyph(ftFace.glyph, &glyph);
        if(e)
            throw new Exception("FT_Get_Glyph failed (" ~ tostring(e) ~ ")");
        FT_Glyph_To_Bitmap(&glyph, FT_RENDER_MODE_LCD, null, 1);
        FT_Bitmap bitmap = (cast(FT_BitmapGlyph)glyph).bitmap;
        int width = bitmap.width/3;
        int pad = bitmap.pitch-bitmap.width;
        int height = bitmap.rows;
        auto textureData = new GLubyte[width * height * 4];
        for(int y=0; y < height; y++){
            for(int x=0; x < width; x++){
                auto pixel = &textureData[(x + y*width)*4];
                pixel[0..3] = bitmap.buffer[(x + y*width)*3+y*pad .. (x + y*width)*3+y*pad+3];
                pixel[3] = 1;
                /+
                pixel[0..3] = bitmap.buffer[(x + y*width)*3+y*pad .. (x + y*width)*3+y*pad+3];
                pixel[3] = pixel[0..3].maxElement;
                foreach(ref b; pixel[0..4])
                    b = b.applyGamma;
                //pixel[3] = 255;
                +/
            }
        }
        context.genTextures(1, &g.tex);
        context.bindTexture(GL_TEXTURE_2D, g.tex);
        context.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        context.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        context.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        context.texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        context.pixelStorei(GL_UNPACK_ALIGNMENT, 1);
        context.texImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData.ptr);
        long x = ftFace.glyph.metrics.horiBearingX/64;
        long y = ftFace.glyph.metrics.horiBearingY/64 + verticalOffset;
        g.advance = ftFace.glyph.metrics.horiAdvance/64;
        g.vao = new Batch(context, gl.triangleFan, Batch.vert3 ~ Batch.tex2, [
            x, y, 0, 0, 0,
            x, y-height, 0, 0, 1,
            x+width, y-height, 0, 1, 1,
            x+width, y, 0, 1, 0
        ]);
        glyphs[c] = g;
        return g;
    }

};
