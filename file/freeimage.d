module ws.file.freeimage;

pragma(lib, "DerelictFI");


import
	std.string,
	std.file,
	ws.exception,
	ws.testing,
	derelict.freeimage.freeimage;


shared static this(){
	DerelictFI.load();
}


class FIImage {

	FREE_IMAGE_FORMAT type;
	FIBITMAP* dib;
	int width, height;
	int colors, depth;
	FREE_IMAGE_COLOR_TYPE format;
	byte[] data;

	this(string path){
		if(!exists(path))
			exception(path ~ " does not exist");
		type = FreeImage_GetFileType(path.toStringz);
		dib = FreeImage_Load(type, path.toStringz);
		assert(dib, path ~ " not a valid image file");
		format = FreeImage_GetColorType(dib);
		assert(format == FIC_RGB || format == FIC_RGBALPHA);
		colors = (format == FIC_RGB ? 3 : 4);
		depth = FreeImage_GetBPP(dib)/colors;
		width = FreeImage_GetWidth(dib);
		height = FreeImage_GetHeight(dib);

		assert(depth == 8);

 		int bytespp = FreeImage_GetLine(dib) / width;
 		for(int y = 0; y < height; y++) {
 			BYTE *bits = FreeImage_GetScanLine(dib, y);
 			for(int x = 0; x < width; x++) {
				data ~= bits[FI_RGBA_RED];
				data ~= bits[FI_RGBA_GREEN];
				data ~= bits[FI_RGBA_BLUE];
				if(colors == 4)
					data ~= bits[FI_RGBA_ALPHA];
				bits += bytespp;
			}
		}

	}

	~this(){
		FreeImage_Unload(dib);
	}

}
