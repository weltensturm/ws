
module ws.gl.gl;

public import derelict.opengl3.gl3;

import
	std.regex,
	derelict.opengl3.wgl,
	derelict.opengl3.glx,
	ws.sys.library;

/+
pragma(lib, "DerelictGL3");
pragma(lib, "DerelictUtil");
version(linux) pragma(lib, "dl");
+/

import std.string, ws.string, ws.exception;

import
	ws.io,
	std.conv,
	ws.math.vector,
	ws.math.matrix;

__gshared:

class gl {
	const static int lines = GL_LINES;
	const static int triangles = GL_TRIANGLES;
	const static int triangleFan = GL_TRIANGLE_FAN;
	
	const static int arrayBuffer = GL_ARRAY_BUFFER;
	
	const static int compileStatus = GL_COMPILE_STATUS;
	const static int linkStatus = GL_LINK_STATUS;
	const static int shaderVertex = GL_VERTEX_SHADER;
	const static int shaderFragment = GL_FRAGMENT_SHADER;
	
	const static int attributeVertex = 0;
	const static int attributeNormal = 1;
	const static int attributeColor = 2;
	const static int attributeTexture = 3;
	
	static bool active(){
		version(Windows)
			return wglGetCurrentContext() != null;
		version(Posix)
			return glXGetCurrentContext() != null;
	}


	/++
		Checks for OpenGL errors.
		
		Resource-intensive, only call once each frame.
	+/
	static void check(T = string)(T info = T.init, string file = __FILE__, size_t line = __LINE__){
		while(true){
			GLenum error = glGetError();
			if(!error) break;
			exception("GL error, " ~ to!string(info) ~ ": " ~ to!string(cast(char*)gluErrorString(error)), null, file, line);
		}
	}

	static bool matrixTranspose = false;
	
	static class Shader {

		uint shader;

		this(uint type, string text){
			assert(gl.active());
			shader = glCreateShader(type);
			char *tempPtr[1];
			tempPtr[0] = cast(char*)(text.toStringz());
			glShaderSource(shader, 1, cast(const char**)tempPtr, null);
			glCompileShader(shader);
			int r;
			glGetShaderiv(shader, compileStatus, &r);
			if(!r){
				string msg;
				auto log = getLog();
				foreach(i, line; text.splitLines){
					auto m = match(log, regex(r"[0-9]\(%s\) :".format(i+1)));
					if(m)
						msg ~= "!\t%s\t%s\n".format(i+1, line);
					else
						msg ~= "\t%s\t%s\n".format(i+1, line);
				}
				msg ~= (log ~ '\n');
				exception("Failed to compile shader\n" ~ msg);
			}
		}
		
		string getLog(){
			char log[1024];
			GLsizei length;
			glGetShaderInfoLog(shader, 1024, &length, log.ptr);
			string ret;
			foreach(char c; log)
				if(c != 255)
					ret ~= c;
				else
					break;
			return ret;
		}
		
		~this(){
			//glDeleteShader(shader);
		}
	}

	static class Program {
		uint program;

		this(){
			assert(gl.active());
			program = glCreateProgram();
		}

		~this(){
			//glDeleteProgram(program);
		}

		void attach(Shader s){
			glAttachShader(program, s.shader);
		}

		string getLog(){
			char log[1024];
			GLsizei length;
			glGetProgramInfoLog(program, 1024, &length, log.ptr);
			string ret;
			foreach(char c; log)
				if(c != 255)
					ret ~= c;
				else
					break;
			return ret;
		}

		void link(){
			glLinkProgram(program);
			int r;
			glGetProgramiv(program, linkStatus, &r);
			if(!r)
				exception("Failed to link shader: " ~ getLog());
		}

		void use(){
			glUseProgram(program);
		}

		void bindAttrib(uint idx, string name){
			glBindAttribLocation(program, idx, name.toStringz());
		}

		int getUniform(string n){
			return glGetUniformLocation(program, n.toStringz());
		}
		
		void uniform(const int pos, const int i){
			glUniform1i(pos, i);
		}

		void uniform(const int pos, const float f){
			glUniform1f(pos, f);
		}
		
		void uniform(const int pos, const float[3] f){
			glUniform3fv(pos, 1, f.ptr);
		}
		
		void uniform(const int pos, const float[4] f){
			glUniform4fv(pos, 1, f.ptr);
		}
		
		void uniform(const int pos, const float[3][3] m){
			glUniformMatrix3fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m[0].ptr);
		} 
		
		void uniform(const int pos, const float[4][4] m){
			glUniformMatrix4fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m[0].ptr);
		}
		
		void uniform(const int pos, Vector!3 v){
			glUniform3fv(pos, 1, v.data.ptr);
		}
		
		void uniform(const int pos, Matrix!(3,3) m){
			glUniformMatrix3fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m.data.ptr);
		}
		
		void uniform(const int pos, Matrix!(4,4) m){
			glUniformMatrix4fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m.data.ptr);
		}
		
	}

}


version(Windows)
	const string LIB_FILE = "GLU32";
version(Posix)
	const string LIB_FILE = "GLU";

extern(C)
	mixin library!(
		"OpenGL_Library", LIB_FILE,
		"gluErrorString", const(GLubyte*) function(GLenum)
	);
