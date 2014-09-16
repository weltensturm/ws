module ws.gl.shader;


import
	file = std.file,
	std.string,
	ws.string,
	ws.math.vector,
	ws.math.matrix,
	ws.log,
	ws.exception,
	ws.thread.loader,
	ws.gl.gl;


__gshared:


class Shader: Loadable {
	protected:
		this(){};
		~this(){};
		
	public:
	

		static Shader load(Args...)(Args args){
			string id = args[0] ~ tostring(args[1..$]);
			auto shader = prepare(id);
			shader.start(args[0]);
			shader.addAttribute(args[1..$]);
			shader.finish();
			return shader;
		}


		static Shader prepare(string id){
			if(id in shaderContainer)
				return shaderContainer[id];
			auto shader = new Shader;
			shaderContainer[id] = shader;
			return shader;
		}
		

		Uniform opIndex(string name){
			if(name in uniforms)
				return uniforms[name];
			uniforms[name] = new Uniform(name, this);
			return uniforms[name];
		}
		

		void applyUniform(Args...)(Args args){
			static if(args.length){
				opIndex(args[0]).set(args[1]);
				//gl.check(args[0]);
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
			try {
				if(failed) return;
				this.name = name;
				shaderVertex = new gl.Shader(gl.shaderVertex, vertex);
				shaderFragment = new gl.Shader(gl.shaderFragment, fragment);
				program = new gl.Program;
				program.attach(shaderVertex);
				program.attach(shaderFragment);
			}catch(Exception e){
				exception("Failed to load shader \"" ~ name ~ "\"", e);
			}
		}


		override void finish(){
			assert(gl.active());
			if(failed)
				return;
			program.link();
			valid = true;
			foreach(Uniform u; uniforms)
				u.update();
		}


		void addAttribute(Args...)(uint id, string name, Args args){
			glBindAttribLocation(program.program, id, name.toStringz());
			static if(args.length > 0)
				addAttribute(args);
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
					throw new Exception("%s not an accepted uniform type".format(typeid(T)));
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

