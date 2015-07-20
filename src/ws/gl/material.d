
module ws.gl.material;

import
	derelict.opengl3.gl3,
	std.file,
	std.utf,
	std.conv,

	ws.io,
	ws.string,
	ws.exception,
	ws.decode,
	ws.gl.gl,
	ws.gl.shader,
	ws.gl.texture,
	ws.thread.loader,
	ws.math.vector,
	ws.file.obj;


__gshared:


const string VERTEX_BASE = "
#version 130

uniform mat4 mvp;
uniform mat4 world;

in vec4 vertex;

//uniform float far;
//out float logz;

%s

void main(){
	%s
	gl_Position = mvp*vertex;
	//gl_Position.z = log2(max(1e-6, 1.0 + gl_Position.w)) * (2.0 / log2(far + 1.0)) - 1.0;
	//gl_Position.z *= gl_Position.w;
	//logz = log2(1.0 + gl_Position.w) / log2(far + 1);
}";


const string FRAGMENT_BASE = "
#version 130

out vec4 outDiffuse;
out vec4 outNormal;
out vec4 outLightData;

//in float logz;

vec4 calcNormal();
vec4 calcDiffuse();
vec4 calcLightData();

void main(){
	outDiffuse = calcDiffuse();
	if(outDiffuse.a < 0)
		discard;
	outNormal = calcNormal();
	outLightData = calcLightData();
	//gl_FragDepth = logz;
}";


class DeferredMaterial: Loadable {

	enum {
		diffuse,
		normal,
		lightInfo
	}

	enum targetTextures = [
		diffuse,
		normal,
		lightInfo
	];

	this(string name, string[string] vp=null, string[] fp=null, int[string] attr=null){
		this.name = name;
		shader = new MaterialShader;
		if(!vp)
			vp = vp.init;
		if(!fp)
			fp = fp.init;
		foreach(n,f; vp)
			shader.partsVertex[n] = f;
		shader.partsFragment = fp.dup;
		if(!attr)
			attr = [
					"vertex": gl.attributeVertex, 
					"normal": gl.attributeNormal,
					"texCoord": gl.attributeTexture
					];
		this.output = output.dup;
		foreach(n,i; attr)
			shader.attributes[n] = i;
	}


	void use(Args...)(Args args){
		if(!loaded)
			exception("Trying to use unfinished material \"" ~ name ~ "\"");
		if(shader.failed)
			exception("Material \"" ~ name ~ "\": trying to use failed shader " ~ shader.name);
		shader.use(args);
		int curtex = 0;
		foreach(u; globals){
			final switch(u.type){
				case MaterialUniform.Type.vec:
					u.set(u.data.vec);
				break;
				case MaterialUniform.Type.number:
					u.set(u.data.number);
				break;
				case MaterialUniform.Type.vec4:
					u.set(u.data.vec4);
				break;
				case MaterialUniform.Type.tex:
					glActiveTexture(GL_TEXTURE0 + curtex);
					glBindTexture(GL_TEXTURE_2D, u.data.tex.id);
					u.set(curtex++);
				break;
			}
		}
	}


	void addTexture(string id, string path){
		if(loadState != Loaded)
			onFinish ~= {
				globals[id] = new MaterialUniform(shader, id, Texture.load(path));
				//gl.check(id);
			};
		else {
			globals[id] = new MaterialUniform(shader, id, Texture.load(path));
			//gl.check(id);
		}
	}


	void addUniform(T)(string id, T u){
		if(!shader)
			onFinish ~= {
				globals[id] = new MaterialUniform(shader, id, u);
				//gl.check(id);
			};
		else {
			globals[id] = new MaterialUniform(shader, id, u);
			//gl.check(id);
		}
	}


	void linkVertex(string path, string fn){
		shader.partsVertex[path] = fn;
	}


	void linkFragment(string part){
		shader.partsFragment ~= part;
	}

	override void finish(){
		if(loadState != Idle)
			exception("Already finished");
		try {
			loadState = Loadable.Loading;
			string name = 
				to!string(shader.partsVertex)
				~ to!string(shader.partsFragment) 
				~ to!string(shader.attributes);
			if(name in shaders)
				shader = shaders[name];
			else {
				shader.name = name;
				shader.finish();
				shader.bindFrag([diffuse: "outDiffuse", normal: "outNormal", lightInfo: "outLightData"]);
				shaders[name] = shader;
			}
			foreach(f; onFinish)
				f();
			loadState = Loadable.Loaded;
		}catch(Exception e){
			loadState = Loadable.Error;
			exception("Failed to finish material \"" ~ name ~ "\"", e);
		}
	}

	override string toString(){
		return name ~ ':'
				~ to!string(shader.partsVertex)
				~ to!string(shader.partsFragment) 
				~ to!string(shader.attributes);
	}

	void activateTextures(){
		int curtex = 0;
		foreach(u; globals){
			if(u.type == MaterialUniform.Type.tex){
				glActiveTexture(GL_TEXTURE0 + curtex);
				glBindTexture(GL_TEXTURE_2D, u.data.tex.id);
			}
		}
	}

	protected:

		string name;

		void delegate()[] onFinish;

		string[int] output;
		MaterialShader shader;
		MaterialUniform[string] globals;

		static MaterialShader[string] shaders;


		static class MaterialShader: Shader {

			void attach(uint type, string path){
				try
					program.attach(new gl.Shader(type, cast(string)read("shaders/parts/"~path)));
				catch(Exception e)
					writeln("Failed to compile shader part \"" ~ path ~ "\":\n", e);
			}

			override void finish(){
				try {
					program = new gl.Program;
					foreach(part, f; partsVertex)
						attach(gl.shaderVertex, part ~ ".vp");
					program.attach(new gl.Shader(gl.shaderVertex, buildVertex()));
					foreach(part; partsFragment)
						attach(gl.shaderFragment, part ~ ".fp");
					program.attach(new gl.Shader(gl.shaderFragment, FRAGMENT_BASE));
					foreach(s,i; attributes)
						bindAttr([i: s]);
					super.finish();
				}catch(Exception e)
					exception("Failed to finish material \"" ~ name ~ "\"", e);
			}

			string buildVertex(){
				string dec;
				foreach(_, f; partsVertex)
					dec ~= "void " ~ f ~ "();\n";
				string call;
				foreach(_, f; partsVertex)
					call ~= '\t' ~ f ~ "();\n";
				return VERTEX_BASE.format(dec, call);
			}

			int[string] attributes;
			string[string] partsVertex;
			string[] partsFragment;
		}


		static class MaterialUniform: Shader.Uniform {

			string name;
			Data data;
			Type type;

			private this(MaterialShader m, string name){
				this.name = name;
				super(name, m);
			}
			this(MaterialShader m, string name, const double n){
				this(m, name);
				this.type = Type.number;
				data.number = cast(int)n;
			}
			this(MaterialShader m, string name, const float[3] v){
				this(m, name);
				this.type = Type.vec;
				data.vec = v;
			}
			this(MaterialShader m, string name, const float[4] v){
				this(m, name);
				this.type = Type.vec4;
				data.vec4 = v;
			}
			this(MaterialShader m, string name, Texture t){
				this(m, name);
				type = Type.tex;
				data.tex = t;
			}

			union Data {
				float[3] vec;
				float[4] vec4;
				int number;
				Texture tex;
			}

			enum Type {
				vec,
				number,
				vec4,
				tex
			};

		}

}

