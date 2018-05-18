
module ws.gl.gl;

public import derelict.opengl3.gl3;

import
    std.regex,
    std.traits,
    derelict.opengl3.wgl,
    derelict.opengl3.glx,
    ws.gl.context,
    ws.wm,
    ws.sys.library;

version(Windows){
	import ws.wm.win32.api;
}

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
    
    static GraphicsContext context(){
        version(Windows)
            return derelict.opengl3.wgl.wglGetCurrentContext();
        version(Posix)
            return glXGetCurrentContext();
    }

    static bool active(){
        return context != null;
    }

    static void check(T = string)(T info = T.init, string file = __FILE__, size_t line = __LINE__){
        while(true){
            GLenum error = glGetError();
            if(!error) break;
            throw new Exception("OpenGL error @" ~ info ~ ": " ~ to!string(cast(char*)gluErrorString(error)), null, file, line);
        }
    }

    static bool matrixTranspose = false;
    
    static class Shader {

        uint shader;
        GlContext context;

        this(GlContext context, uint type, string text){
            this.context = context;
            shader = context.createShader(type);
            char*[1] tempPtr;
            tempPtr[0] = cast(char*)(text.toStringz());
            context.shaderSource(shader, 1, cast(const char**)tempPtr, null);
            context.compileShader(shader);
            int r;
            context.getShaderiv(shader, compileStatus, &r);
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
            char[1024] log;
            GLsizei length;
            context.getShaderInfoLog(shader, 1024, &length, log.ptr);
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
        GlContext context;

        this(GlContext context){
            this.context = context;
            program = context.createProgram();
        }

        ~this(){
            //glDeleteProgram(program);
        }

        void attach(Shader s){
            context.attachShader(program, s.shader);
        }

        string getLog(){
            char[1024] log;
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
            context.linkProgram(program);
            int r;
            context.getProgramiv(program, linkStatus, &r);
            if(!r)
                exception("Failed to link shader: " ~ getLog());
        }

        void use(){
            context.useProgram(program);
        }

        void bindAttrib(uint idx, string name){
            context.bindAttribLocation(program, idx, name.toStringz());
        }

        int getUniform(string n){
            return context.getUniformLocation(program, n.toStringz());
        }
        
        void uniform(const int pos, const int i){
            context.uniform1i(pos, i);
        }

        void uniform(const int pos, const float f){
            context.uniform1f(pos, f);
        }
        
        void uniform(const int pos, const float[3] f){
            context.uniform3fv(pos, 1, f.ptr);
        }
        
        void uniform(const int pos, const float[4] f){
            context.uniform4fv(pos, 1, f.ptr);
        }
        
        void uniform(const int pos, const float[3][3] m){
            context.uniformMatrix3fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m[0].ptr);
        } 
        
        void uniform(const int pos, const float[4][4] m){
            context.uniformMatrix4fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m[0].ptr);
        }
        
        void uniform(const int pos, Vector!3 v){
            context.uniform3fv(pos, 1, v.data.ptr);
        }
        
        void uniform(const int pos, Matrix!(3,3) m){
            context.uniformMatrix3fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m.data.ptr);
        }
        
        void uniform(const int pos, Matrix!(4,4) m){
            context.uniformMatrix4fv(pos, 1, matrixTranspose ? GL_TRUE : GL_FALSE, m.data.ptr);
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
