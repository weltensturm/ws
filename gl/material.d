
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


class Material: Loadable {

	/++ Shader + Uniforms
		Params:
			name = unique name
			vp = array of vertex shader parts + the shader functions that should be called
			fp = array of fragment shader parts + the shader functions that should be called
			attr = attribute bindings
		Example:
			---
			auto m = new Material(
				"model.materialName",
				["vertexPart1.vp": "vertexMain1", ...],
				["fragmentPart1.fp": "fragmentMain1", ...],
				["vertex": gl.attributeVertex, "normal": gl.attributeNormal, ...]
			);
			loader.finish(m);
			---
		You can then add uniform bindings and more shader parts.
	+/
	this(string name, string[string] vp, string[string] fp, int[string] attr){
		this.name = name;
		shader = new MaterialShader;
		foreach(n,f; vp)
			shader.partsVertex[n] = f;
		foreach(n,f; fp)
			shader.partsFragment[n] = f;
		foreach(n,i; attr)
			shader.attributes[n] = i;
	}


	/++
		Activates a material for immediate use.
		args: string name, T value, ...
		Example:
		---
		mat.use(
			"matrixProjection", someMatrix,
			"worldColor", someVector,
			...
		);
		---
	+/
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


	void linkFragment(string path, string fn){
		shader.partsFragment[path] = fn;
	}


	//int[string] attributes;


	override void finish(){
		if(loadState != Idle)
			exception("Already finished");
		try {
			loadState = Loadable.Loading;
			string name;
			foreach(part, f; shader.partsVertex)
				name ~= part ~ ".vp;";
			foreach(part, n; shader.partsFragment)
				name ~= part ~ ".fp;";
			name ~= '[';
			foreach(n,i; shader.attributes)
				name ~= tostring("%:%, ", n, i);
			name ~= ']';
			if(name in shaders)
				shader = shaders[name];
			else {
				shader.name = name;
				shader.finish();
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
		return
			name ~ ' ' ~ to!string(shader.partsVertex) ~ ' ' ~ to!string(shader.partsFragment);
	}

	protected:

		string name;

		void delegate()[] onFinish;

		//string[string] partsVertex;
		//string[string] partsFragment;

		MaterialShader shader;
		MaterialUniform[string] globals;

		static MaterialShader[string] shaders;


		static class MaterialShader: Shader {

			void attach(uint type, string path){
				try
					program.attach(new gl.Shader(type, cast(string)read("shaders/"~path)));
				catch(Exception e)
					writeln("Failed to compile shader part \"" ~ path ~ "\":\n", e);
			}

			override void finish(){
				try {
					program = new gl.Program;

					foreach(part, f; partsVertex)
						attach(gl.shaderVertex, part ~ ".vp");
					program.attach(new gl.Shader(gl.shaderVertex, buildVertex()));

					foreach(part, f; partsFragment)
						attach(gl.shaderFragment, part ~ ".fp");
					program.attach(new gl.Shader(gl.shaderFragment, buildFragment()));

					foreach(s,i; attributes)
						addAttribute(i,s);
					super.finish();
				}catch(Exception e)
					exception("Failed to finish material \"" ~ name ~ "\"", e);
			}

			string buildVertex(){
				const string vertex =
						"#version 130\n"
						"in vec4 vertex;\n"
						"uniform mat4 matMVP;\n"
						//"uniform float far;\n"
						//"out float logz;\n"
						"%s"
						"void main(){\n"
						"	%s"
						"	gl_Position = matMVP*vertex;\n"
						//"	gl_Position.z = log2(max(1e-6, 1.0 + gl_Position.w)) * (2.0 / log2(far + 1.0)) - 1.0;\n"
						//"	gl_Position.z *= gl_Position.w;\n"
						//"	logz = log2(1.0 + gl_Position.w) / log2(far + 1);"
						"}";
				string dec;
				foreach(_, f; partsVertex)
					dec ~= "void " ~ f ~ "();\n";
				string call;
				foreach(_, f; partsVertex)
					call ~= '\t' ~ f ~ "();\n";
				return vertex.format(dec, call);
			}

			string buildFragment(){
				const string fragment = 
						"#version 130\n"
						"out vec4 fragColor;\n"
						//"in float logz;\n"
						"%s"
						"void main(){\n"
						//"	gl_FragDepth = logz;"
						"	fragColor = vec4(1,1,1,1);\n"
							"%s"
						"	if(fragColor.a < 0) discard;\n"
						"}";
				string dec;
				foreach(_, f; partsFragment)
					dec ~= "vec4 " ~ f ~ "();\n";
				string call;
				foreach(_, f; partsFragment)
					call ~= "\tfragColor *= " ~ f ~ "();\n";
				return fragment.format(dec, call);
			}

			int[string] attributes;
			string[string] partsVertex;
			string[string] partsFragment;
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

