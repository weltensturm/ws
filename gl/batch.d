module ws.gl.batch;

import ws.gl.gl, ws.exception, ws.io;

__gshared:


class Batch {
	
	alias float[2] tex;
	alias float[3] vec;
	alias float[4] color;
	
	void begin(int verts, uint type = GL_TRIANGLES){
		assert(gl.active());
		verticeCount = verts;
		currentVert = 0;
		this.type = type;
		glGenVertexArrays(1, cast(uint*)&vao);
		glBindVertexArray(vao);
	}
	
	void finish(){
		assert(!done);
		foreach(array; arrays){
			glBindBuffer(GL_ARRAY_BUFFER, array.globj);
			glUnmapBuffer(GL_ARRAY_BUFFER);
		}

		glBindVertexArray(vao);

		foreach(array; arrays){
			glBindBuffer(GL_ARRAY_BUFFER, array.globj);
			glEnableVertexAttribArray(array.attributeId),
			glVertexAttribPointer(array.attributeId, array.size, GL_FLOAT, GL_FALSE, 0, null);
		}

		done = true;
		glBindVertexArray(0);
	}
	
	void draw(){
		if(!done)
			return;
		glBindVertexArray(vao);
		glDrawArrays(type, 0, verticeCount);
		//glBindVertexArray(0);
	}

	void add(vec pos){
		addVertex(pos);
		currentVert++;
	}

	void addPoint(vec pos, color col){
		addVertex(pos);
		addColor(col);
		currentVert++;
	}

	void addPoint(vec pos, vec normal){
		addVertex(pos);
		addNormal(normal);
		currentVert++;
	}

	void addPoint(vec pos, vec normal, color col){
		addVertex(pos);
		addNormal(normal);
		addColor(col);
		currentVert++;
	}

	void addPoint(vec pos, tex t){
		addVertex(pos);
		addTex(t);
		currentVert++;
	}

	void addPoint(vec pos, vec normal, tex t){
		addVertex(pos);
		addNormal(normal);
		addTex(t);
		currentVert++;
	}

	/*~this(){
		glDeleteVertexArrays(1, &vao);
	}*/
	
	void updateVertices(float[] data, size_t pos = 0, size_t length = 1){
		glBindBuffer(GL_ARRAY_BUFFER, vertices.globj);
		glBufferSubData(GL_ARRAY_BUFFER, pos*3*float.sizeof, length*3*float.sizeof, data.ptr);
	} 
	
	protected:
		
		uint vao;
		uint type;
		
		bool done = false;
		int verticeCount = 0;
		int currentVert = 0;
		
		class Array {
			this(int size, uint attributeId){
				assert(!done);
				assert(vao);
				this.size = size;
				this.attributeId = attributeId;
				glGenBuffers(1, cast(uint*)&globj);
				glBindBuffer(GL_ARRAY_BUFFER, globj);
				glBufferData(GL_ARRAY_BUFFER, float.sizeof*size*verticeCount, null, GL_DYNAMIC_DRAW);
				glBindBuffer(GL_ARRAY_BUFFER, globj);
				array = cast(float*)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
				arrays ~= this;
				//gl.check();
				if(!array)
					exception("Failed to create array buffer");
			}
			float* array = null;
			uint globj = 0;
			uint size;
			uint attributeId;
			/*~this(){
				glDeleteBuffers(1, &globj);
			}*/
		}
		
		Array vertices;
		Array normals;
		Array colors;
		Array texCoords;
		Array[] arrays;
	
		void addVertex(vec v){
			if(!vertices)
				vertices = new Array(3, gl.attributeVertex);
			float* o = vertices.array+currentVert*3;
			o[0] = v[0];
			o[1] = v[1];
			o[2] = v[2];
		}

		void addNormal(vec v){
			if(!normals)
				normals = new Array(3, gl.attributeNormal);
			float* o = normals.array+currentVert*3;
			o[0] = v[0];
			o[1] = v[1];
			o[2] = v[2];
		}

		void addColor(color c){
			if(!colors)
				colors = new Array(4, gl.attributeColor);
			float* o = colors.array+currentVert*4;
			o[0] = c[0];
			o[1] = c[1];
			o[2] = c[2];
			o[3] = c[3];
		}

		void addTex(tex t){
			if(!texCoords)
				texCoords = new Array(2, gl.attributeTexture);
			texCoords.array[currentVert*2] = t[0];
			texCoords.array[currentVert*2+1] = t[1];
		}

}
