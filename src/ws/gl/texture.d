module ws.gl.texture;

import
	ws.log,
	ws.file.freeimage,
	ws.string,
	ws.gl.gl,
	ws.gui.point,
	ws.file.tga,
	ws.exception,
	ws.io;

__gshared:

class Texture {

	private static Texture[string] textures;

	uint id;
	string path;
	Point size;

	void destroy(){
		glDeleteTextures(1, &id);
	}

	this(){}

	this(uint id){
		this.id = id;
	}

	int bind(int where){
		glActiveTexture(GL_TEXTURE0 + where);
		glBindTexture(GL_TEXTURE_2D, id);
		return where;
	}

	static Texture load(string path){
		if(path in textures)
			return textures[path];
		try {
			//auto file = new TGA("materials/" ~ path);
			auto file = new FIImage("materials/" ~ path);
			auto t = new Texture;
			t.path = path;
			t.id = 0;
			t.size = Point(cast(int)file.width, cast(int)file.height);
			textures[path] = t;
			if(file.width >= GL_MAX_TEXTURE_SIZE)
				Log.warning("Image width too large (" ~ tostring(file.width) ~ " of " ~ tostring(GL_MAX_TEXTURE_SIZE) ~ "): " ~ path);
			if(file.height >= GL_MAX_TEXTURE_SIZE)
				Log.warning("Image height too large (" ~ tostring(file.height) ~ " of " ~ tostring(GL_MAX_TEXTURE_SIZE) ~ "): " ~ path);
			glGenTextures(1, &t.id);
			glBindTexture(GL_TEXTURE_2D, t.id);
			glTexImage2D(
					GL_TEXTURE_2D,
					0,
					cast(uint)(file.colors == 4 ? GL_RGBA : (file.colors == 3 ? GL_RGB : 0x1909)),
					cast(int)file.width,
					cast(int)file.height,
					0,
					file.colors == 4 ? GL_RGBA : (file.colors == 3 ? GL_RGB : 0x1909),
					GL_UNSIGNED_BYTE,
					file.data.ptr
			);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_NEAREST);
			glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
			glGenerateMipmap(GL_TEXTURE_2D);
			float aniso = 0.0f;
			glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &aniso);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, aniso);
			return t;
		}catch(Exception e)
			exception("Failed to load texture \"" ~ path ~ "\"", e);
		return null;
	}

}
