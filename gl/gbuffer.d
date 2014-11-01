module ws.gl.gbuffer;

import
	std.string,
	ws.gl.gl;


string error(GLuint i){
	string[GLuint] ERRORS = [
		GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: "invalid attachment(s)",
	//	GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS: "invalid dimensions",
		GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: "no attachments",
		GL_FRAMEBUFFER_UNSUPPORTED: "this framebuffer configuration is not supported"
	];
	return ERRORS[i];
}



class GBuffer {

	private {
		GLuint fbo;
		GLuint textures[NUM];
		GLuint depth;
		GLuint result;
	}

	this(int w, int h){

		// Create the FBO
		glGenFramebuffers(1, &fbo); 
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	
		// Create the gbuffer textures
		glGenTextures(textures.length, textures.ptr);
		for(uint i = 0; i < textures.length; i++){
			glBindTexture(GL_TEXTURE_2D, textures[i]);
			if(i == LIGHT)
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, null);
			else
        		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, w, h, 0, GL_RGB, GL_FLOAT, null);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	        glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + i, GL_TEXTURE_2D, textures[i], 0);
		}
		// depth & stencil
		glGenTextures(1, &depth);
		glBindTexture(GL_TEXTURE_2D, depth);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH32F_STENCIL8, w, h, 0, GL_DEPTH_STENCIL, GL_FLOAT_32_UNSIGNED_INT_24_8_REV, null);
		glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, depth, 0);
		GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
		if(status != GL_FRAMEBUFFER_COMPLETE)
			throw new Exception("FB error: %s".format(error(status)));

		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	void destroy(){
		if(fbo)
			glDeleteFramebuffers(1, &fbo);
		if(textures[0])
			glDeleteTextures(textures.length, textures.ptr);
		if(depth)
			glDeleteRenderbuffers(1, &depth);
	}


	void startFrame(){
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
		glDrawBuffer(GL_COLOR_ATTACHMENT0+LIGHT);
		glClearColor(0.1,0.1,0.1,1);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

	void bindGeom(){
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
		GLenum[] buffers;
		for(int i=0; i<NUM; i++)
			buffers ~= GL_COLOR_ATTACHMENT0 + i;
		glDrawBuffers(cast(uint)buffers.length, buffers.ptr);
	}

	void bindStencil(){
		glDrawBuffer(GL_NONE);
	}

	void bindTextures(){
		for(int i=0 ; i < LIGHT; i++){
			glActiveTexture(GL_TEXTURE0 + i);
			glBindTexture(GL_TEXTURE_2D, textures[i]);
		}
	}

	void bindDepth(int where){
		glActiveTexture(GL_TEXTURE0 + where);
		glBindTexture(GL_TEXTURE_2D, depth);
	}

	void bindLight(){
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		glDrawBuffer(GL_COLOR_ATTACHMENT0+LIGHT);
		bindTextures;
	}

	void bindRead(int which){
		glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
		glReadBuffer(GL_COLOR_ATTACHMENT0+which);
	}

	enum: int { DIFFUSE, TEXCOORD, NORMAL, LIGHT, NUM };

}
