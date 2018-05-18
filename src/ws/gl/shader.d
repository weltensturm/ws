module ws.gl.shader;


import
	file = std.file,
	std.string,
	std.conv,
	std.stdio,
	ws.string,
	ws.math.vector,
	ws.math.matrix,
	ws.log,
	ws.exception,
	ws.thread.loader,
	ws.gl.gl,
	ws.gl.context;


__gshared:


class Shader: Loadable {
	protected:
		~this(){};
		GlContext context;

	public:
	
		this(GlContext context){
			this.context = context;
		}

		this(GlContext context, string dir, string[uint] attributes, string[uint] fragmentBindings=null){
			this(context);
			start(dir);
			bindAttr(attributes);
			if(fragmentBindings)
				bindFrag(fragmentBindings);
			finish;
		};

		this(GlContext context, string name, string[uint] attr, string[uint] frag, string vertex, string fragment){
			this(context);
			start(name, vertex, fragment);
			bindAttr(attr);
			if(frag)
				bindFrag(frag);
			finish;
		}

		Uniform opIndex(string name){
			if(name in uniforms)
				return uniforms[name];
			uniforms[name] = new Uniform(name, this);
			return uniforms[name];
		}
		
		void opIndexAssign(T)(T value, string key){
			auto uniform = this[key];
			uniform.set(value);
		}

		void applyUniform(Args...)(Args args){
			static if(args.length){
				opIndex(args[0]).set(args[1]);
				applyUniform(args[2..$]);
			}
		}


		void use(Args...)(Args args){
			if(!valid || failed)
				exception("Trying to use unfinished shader " ~ name);
			program.use();
			try {
				applyUniform(args);
			}catch(Exception e){
				Log.error("Failed to activate shader: %s".format(e));
			}
		}


		void start(string folder){
			start(
				folder,
				cast(string)file.read("shaders/" ~ folder ~ "/vertex.vp"),
				cast(string)file.read("shaders/" ~ folder ~ "/fragment.fp")
			);
		}


		void start(string name, string vertex, string fragment){
			assert(!valid);
			try {
				if(failed) return;
				this.name = name;
				shaderVertex = new gl.Shader(context, gl.shaderVertex, vertex);
				shaderFragment = new gl.Shader(context, gl.shaderFragment, fragment);
				program = new gl.Program(context);
				program.attach(shaderVertex);
				program.attach(shaderFragment);
			}catch(Exception e){
				throw new Exception("Failed to load shader \"" ~ name ~ "\"\n" ~ e.to!string);
			}
		}


		override void finish(){
			if(failed)
				return;
			program.link();
			valid = true;
			foreach(Uniform u; uniforms)
				u.update();
		}


		void bindAttr(string[uint] attrs){
			foreach(i, name; attrs)
				context.bindAttribLocation(program.program, i, name.toStringz);
		}


		void bindFrag(string[uint] frags){
			foreach(i, name; frags)
				context.bindFragDataLocation(program.program, i, name.toStringz);
		}


		gl.Program program;

		gl.Shader shaderVertex;
		gl.Shader shaderGeometry;
		gl.Shader shaderFragment;

		bool valid = false;
		bool failed = false;

		string name;

		Uniform[string] uniforms;

		static Shader[string] shaderContainer;


		static class Uniform {

			this(string n, Shader s){
				if(!s)
					exception("Shader is null");
				name = n;
				shader = s;
				s.uniforms[n] = this;
				if(s.valid && !s.failed)
					update();
				else
					valid = false;
			};

			/*~this(){
				shader.uniforms.remove(name);
			}*/

			void set(T)(T r){
				if(valid && shader && shader.valid && !shader.failed){
					if(gltype!T() == type)
						shader.program.uniform(location, r);
					else
						throw new Exception("Wrong uniform type for %s: %s (%s), expected %s)"
							.format(name, gltype!T(), typeid(T).toString(), type));
				}
			}

			protected:

				template Tuple(E...){
					alias Tuple = E;
				}

				alias UniformTypes = Tuple!(
					GL_FLOAT, float,
					GL_FLOAT_VEC2, float[2],
					GL_FLOAT_VEC3, float[3],
					GL_FLOAT_VEC4, float[4],
					GL_FLOAT_VEC2, Vector!2,
					GL_FLOAT_VEC3, Vector!3,
					GL_FLOAT_VEC4, Vector!4,
					//GL_INT, GLint,
					//GL_INT_VEC2, GLint[2],
					//GL_INT_VEC3, GLint[3],
					//GL_INT_VEC4, GLint[4],
					GL_BOOL, GLboolean,
					GL_FLOAT_MAT3, Matrix!(3,3),
					GL_FLOAT_MAT4, Matrix!(4,4),
					//GL_BOOL_VEC2, GLboolean[2],
					//GL_BOOL_VEC3, GLboolean[3],
					//GL_BOOL_VEC4, GLboolean[4],
					GL_SAMPLER_2D, GLint
					//GL_FLOAT_MAT2, GL_FLOAT_MAT3, GL_FLOAT_MAT4,
					//GL_SAMPLER_2D, GL_SAMPLER_CUBE
				);

				GLenum gltype(T)(){
					foreach(i, u; UniformTypes)
						static if(is(u == T))
							return UniformTypes[i-1];
					assert(false, "%s not an accepted uniform type".format(typeid(T).stringof));
				}

				int location;
				string name;
				Shader shader;
				GLenum type;
				bool valid;

				void update(bool dead = false){
					if(!dead && shader.valid){
						location = shader.program.getUniform(name);
						if(location < 0){
							dead = true;
							Log.warning("Shader \"" ~ shader.name ~ "\": could not find uniform \"" ~ name ~ "\" (optimized out?)");
						}else{
							char[256] name;
							GLsizei length;
							GLint size;
							glGetActiveUniform(
								shader.program.program, location, 256,
								&length, &size, &type, name.ptr
							);
						}
					}
					valid = !dead;
				}
		}

}

