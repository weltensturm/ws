
module ws.gl.font;

import
	file = std.file,
	std.process,
	std.traits,

	derelict.freetype.ft,
	derelict.util.exception,

	ws.io,
	ws.string,
	ws.gl.gl,ws.gl.batch;


version(Posix)
	import std.path;


class Font {

	const string name;
	const long size;

	protected {
		this(string name, long size){
			this.name = name;
			this.size = size;
		}

		/*static ~this(){
		FT_Done_FreeType(ftLib);
		}*/

		Glyph[dchar] glyphs;
		bool reference;
		FT_Face ftFace;

		static bool initialized = false;

		static FT_Library ftLib;
		static Font[string] fonts;

		static string[] searchPaths;
		static string[] searchExtensions = ["", ".otf", ".ttf"];
	}

	static Font load(string name, int size = 12){
		if(!initialized){
			DerelictFT.missingSymbolCallback = (name){
				if(name == "FT_Gzip_Uncompress")
					return ShouldThrow.No;
				return ShouldThrow.Yes;
			};
			DerelictFT.load();
			searchPaths ~= "fonts/";
			version(Windows)
				searchPaths ~= "C:/Windows/Fonts/";
			version(Posix){
				searchPaths ~= "/usr/share/fonts/TTF/";
				searchPaths ~= "~/.fonts/".expandTilde;
			}
			FT_Error r = FT_Init_FreeType(&ftLib);
			if(r)
				throw new Exception("Failed to initialize FreeType 2 [" ~ tostring(r) ~ "]");
			initialized = true;
		}

		if(tostring(name, "::", size) in fonts)
			return fonts[name ~ "::" ~ tostring(size)];
		string wholeName;
		bool found = false;
		foreach(folder; searchPaths){
			foreach(string ext; searchExtensions){
				if(file.exists(folder ~ name ~ ext)){
					wholeName = folder ~ name ~ ext;
					found = true;
				}
			}
		}
		if(!found){
			writeln("Failed to find font file \"" ~ name ~ "\"");
			if(name == "sans"){
				throw new Exception("Failed to find fallback font \"sans\", no usable font available");
			} else {
				Font f = load("sans", size);
				f.reference = true;
				fonts[name ~ "::" ~ tostring(size)] = f;
				return f;
			}
		}
		FT_Face face;
		FT_Error r = FT_New_Face(ftLib, wholeName.toStringz(), 0, &face);
		if(r)
			throw new Exception("Failed to load font \"" ~ name ~ "\": " ~ tostring(r));
		else{
			auto f = new Font(name, size);
			FT_Set_Char_Size(face, size << 6, size << 6, 96, 96);
			f.ftFace = face;
			f.reference = false;
			fonts[name ~ "::" ~ tostring(size)] = f;
			return f;
		}
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
		if(c == ' '){
			g.tex = 0;
			g.advance = cast(long)(size*0.9);
		}
		FT_Error e = FT_Load_Glyph(ftFace, FT_Get_Char_Index(ftFace, c), FT_LOAD_FORCE_AUTOHINT);
		if(e)
			throw new Exception("FT_Load_Glyph failed (" ~ tostring(e) ~ ")");
		FT_Glyph glyph;
		e = FT_Get_Glyph(ftFace.glyph, &glyph);
		if(e)
			throw new Exception("FT_Get_Glyph failed (" ~ tostring(e) ~ ")");
		FT_Glyph_To_Bitmap(&glyph, FT_RENDER_MODE_NORMAL, null, 1);
		FT_Bitmap bitmap = (cast(FT_BitmapGlyph)glyph).bitmap;
		int width = bitmap.width;
		int height = bitmap.rows;
		auto expandedData = new GLubyte[width * height * 4];
		for(int y=0; y < height; y++){
			for(int x=0; x < width; x++){
				auto pixel = &expandedData[(x + y*width)*4];
				pixel[0] = pixel[1] = pixel[2] =
					(x>=width || y>=bitmap.rows || bitmap.buffer[x + y*width]) ? 255 : 0;
				pixel[3] = (x>=width || y>=bitmap.rows) ? 0 : bitmap.buffer[x + y*width];
			}
		}
		glGenTextures(1, &g.tex);
		glBindTexture(GL_TEXTURE_2D, g.tex);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, expandedData.ptr);
		long x = ftFace.glyph.metrics.horiBearingX >> 6;
		long y = ftFace.glyph.metrics.horiBearingY >> 6;
		g.advance = ftFace.glyph.metrics.horiAdvance >> 6;
		g.vao = new Batch;
		g.vao.begin(4, GL_TRIANGLE_FAN);
		g.vao.addPoint([x, y, 0], [0, 0]);
		g.vao.addPoint([x, y-height, 0], [0, 1]);
		g.vao.addPoint([x+width, y-height, 0], [1, 1]);
		g.vao.addPoint([x+width, y, 0], [1, 0]);
		g.vao.finish();
		glyphs[c] = g;
		return g;
	}

};

