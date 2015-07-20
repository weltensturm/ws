
module ws.file.tga;

import
	std.file,
	std.string,
	std.c.string,
	std.zlib,
	ws.string,
	ws.exception;

class TGA {
	
	this(string s){
		load(s);
	}
	
	void load(string path){
		try {
			const(void)[] file;
			if(exists(path ~ ".gz")){
				auto uc = new UnCompress(HeaderFormat.gzip);
				file = uc.uncompress(read(path ~ ".gz"));
				file ~= uc.flush();
			}else
				file = read(path);
			size_t cursor = 18;
			TGAHEADER header;
			memcpy(&header, file.ptr, cursor);

			width = header.width;
			height = header.height;
			depth = header.bits / 8;
			origin = header.ystart > 0 ? 1 : 0;

			if(header.bits != 8 && header.bits != 24 && header.bits != 32)
				exception("Could not load TGA(\""~path~"\"): not 8, 24 or 32 bits ("~tostring(header.bits)~")");

			if(header.identsize)
				cursor += header.identsize/8;

			if(data.length < cursor + width * height * depth)
				exception("%s is too small".format(path));

			data = cast(byte[])file[cursor..cast(uint)(cursor + width * height * depth)];
		}catch(FileException e){
			exception("Failed to open file \"" ~ path ~ "\"");
		}
	};
	
	//void save(string path);

	long width;
	long height;
	long origin; // 0: top left, 1: bottom left
	long depth;

	byte[] data;
	
	struct TGAHEADER {
		align(1):
		byte identsize;					// Size of ID field that follows header (0)
		byte colorMapType;				// 0 = None, 1 = paletted
		byte imageType;					// 0 = none, 1 = indexed, 2 = rgb, 3 = grey, +8=rle
		ushort	colorMapStart;			// First colour map entry
		ushort	colorMapLength;			// Number of colors
		byte 	colorMapBits;			// bits per palette entry
		ushort	xstart;					// image x origin
		ushort	ystart;					// image y origin
		ushort	width;					// width in pixels
		ushort	height;					// height in pixels
		byte bits;						// bits per pixel (8 16, 24, 32)
		byte descriptor;				// image descriptor
	}
}
