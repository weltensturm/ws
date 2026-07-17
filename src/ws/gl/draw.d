module ws.gl.draw;

import
    std.conv,
    std.algorithm,
    std.random,
    std.range,
    ws.exception,
    ws.draw,
    ws.cache,
    ws.gl.gl,
    ws.gl.context,
    ws.gl.batch,
    ws.gl.shader,
    ws.gl.font,
    ws.bindings.harfbuzz,
    ws.gui.point;


class GlDraw: DrawInterface {

    GlContext context;

    this(GlContext context){
        this.context = context;
        batchRectTexture = new Batch(context, gl.triangleFan, Batch.vert3 ~ Batch.tex2, [
            0, 0, 0, 0, 0,
            1, 0, 0, 1, 0,
            1, 1, 0, 1, 1,
            0, 1, 0, 0, 1
        ]);
        shaderRectTexture = new Shader(
                context,
                "2d_texture",
                [gl.attributeVertex: "vVertex", gl.attributeTexture: "vTexture0"],
                null,
                TextureShader.vertex,
                TextureShader.fragment
        );
        batchRect = new Batch(context, gl.triangleFan, Batch.vert3, [
            0, 0, 0,
            1, 0, 0,
            1, 1, 0,
            0, 1, 0
        ]);
        shaderRect = new Shader(
                context,
                "2d_rect",
                [gl.attributeVertex: "vVertex"],
                null,
                RectShader.vertex,
                RectShader.fragment
        );
        batchLine = new Batch(context, gl.lines, Batch.vert3, [0, 0, 0, 0, 10, 0]);
        shaderLine = new Shader(
                context,
                "2d_rect",
                [gl.attributeVertex: "vVertex"],
                null,
                RectShader.vertex,
                RectShader.fragment
        );
        shaderText = new Shader(
                context,
                "2d_text",
                [gl.attributeVertex: "vVertex", gl.attributeTexture: "vTexture0"],
                null,
                TextShader.vertex,
                TextShader.fragment
        );
        fonts = new CachedFactory!(ws.gl.font.Font);
    }

    override void resize(int[2] size){
        context.viewport(0,0,size.w,size.h);
        screen = size.to!(float[2]) ~ 1;
    }


    override void setColor(float[3] rgb){
        color = rgb ~ 1;
    }


    override void setColor(float[4] rgba){
        color = rgba;
    }


    override void setFont(string f, int size){
        font = fonts.get(context, f, size);
    }

    override int fontHeight(){
        return font.height.to!int;
    }

    /+
    override void setFont(Font f){
        font = f;
    }
    +/

    override void rect(int[2] pos, int[2] size){
        auto s = activateShader(type.rect);
        float[3] offset = [pos.x, pos.y, 1];
        float[3] scale = [size.w, size.h, 1];
        s["Screen"] = screen;
        s["Color"] = color;
        s["Offset"] = offset;
        s["Scale"] = scale;
        s["Clip"] = clipStack.length ? clipStack[$-1] : [0, 0, screen.w, screen.h];
        batchRect.draw();
    }

    override void rectOutline(int[2] pos, int[2] size){
        line(pos, pos.a + [size.w,0]);
        line(pos, pos.a + [0,size.h]);
        line(pos.a + [0,size.h], pos.a + size);
        line(pos.a + [size.w,0], pos.a + size);
    }

    override void clip(int[2] pos, int[2] size){
        if(clipStack.length){
            auto clipPos = clipStack[$-1][0..2].to!(int[2]);
            auto clipSize = clipStack[$-1][2..4].to!(int[2]);
            pos = [pos.x.max(clipPos.x), pos.y.max(clipPos.y)];
            size = [size.w.min(clipSize.w - (pos.x-clipPos.x)), size.h.min(clipSize.h - (pos.y-clipPos.y))];
        }
        clipStack ~= [pos.x, pos.y, size.w, size.h];
    }

    override void noclip(){
        clipStack = clipStack[0..$-1];
    }

    /+
    override void texturedRect(Point pos, Point size){
        if(!texture)
            exception("No texture active");
        auto s = activateShader(type.texture);
        float[3] offset = [pos.x, pos.y, 0];
        float[3] scale = [size.x, size.y, 0];
        s["Screen"] = screen;
        s["Color"] = color;
        s["Offset"] = offset;
        s["Scale"] = scale;
        s["Image"] = 0;
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture.id);
        batchRectTexture.draw();
    }
    +/

    override void line(int[2] start, int[2] end){
        auto s = activateShader(type.line);
        float[3] offset = [start.x+0.25,start.y+0.25,0];
        float[3] scale = [1,1,0];
        s["Screen"] = screen;
        s["Color"] = color;
        s["Offset"] = offset;
        s["Scale"] = scale;
        s["Clip"] = clipStack.length ? clipStack[$-1] : [0, 0, screen.w, screen.h];
        batchLine.updateVertices([end.x-start.x+0.25, end.y-start.y+0.25, 0], 1);
        batchLine.draw();
    }

    struct GlyphShape {
        dchar origChar;
        uint glyphIndex;
        float x_offset;
        float y_offset;
        float x_advance;
        float y_advance;
    }
    
    GlyphShape[] shape(string text){
        hb_buffer_t* buf = hb_buffer_create();
        scope(exit) hb_buffer_destroy(buf);
        hb_buffer_add_utf8(buf, text.ptr, cast(int)text.length, 0, cast(int)text.length);
        hb_buffer_guess_segment_properties(buf);

        hb_shape(font.hb, buf, null, 0);

        uint count;
        auto infos = hb_buffer_get_glyph_infos(buf, &count);
        auto pos = hb_buffer_get_glyph_positions(buf, &count);

        GlyphShape[] shape;
        shape.length = count;
        foreach(i; 0 .. count){
            shape[i] = GlyphShape(
                origChar: text[infos[i].cluster],
                glyphIndex: infos[i].codepoint,
                x_offset: pos[i].x_offset,
                y_offset: pos[i].y_offset,
                x_advance: pos[i].x_advance,
                y_advance: pos[i].y_advance
            );
        }
        return shape;
    }

    // override int width(string text) => this.width(this.shape(text.dtext));
    override int width(string text) => this.width(this.shape(text));

    int width(GlyphShape[] shape){
        return shape
            .map!(a => a.x_advance / 64)
            .sum
            .to!int;
    }

    override int text(int[2] pos, string text_utf8, double offset=-0.2){
        if(!font)
            exception("no font active");
        auto text = text_utf8; //.dtext;
        auto shape = this.shape(text);
        auto width = this.width(shape);
        context.enable(GL_BLEND);
        context.blendFunc(GL_SRC1_COLOR, GL_ONE_MINUS_SRC1_COLOR);
        auto offsetRight = max(0.0,-offset)*fontHeight;
        auto offsetLeft = max(0.0,offset-1)*fontHeight;
        float x = pos.x - offset.min(1).max(0)*width + offsetRight - offsetLeft;
        auto s = activateShader(type.text);
        float[3] scale = [1,1,0];
        s["Screen"] = screen;
        s["Image"] = 0;
        s["Color"] = color;
        s["Scale"] = scale;
        s["Clip"] = clipStack.length ? clipStack[$-1] : [0, 0, screen.w, screen.h];
        float y = pos.y;
        context.activeTexture(GL_TEXTURE0);
        foreach(i, c; shape){
            if(c.origChar == '\n'){
                x = pos.x;
                y -= font.height;
                continue;
            }
            auto g = font[c.glyphIndex];
            context.bindTexture(GL_TEXTURE_2D, g.tex);
            float[3] p = [
                cast(int)(x + c.x_offset / 64f),
                cast(int)(y + c.y_offset / 64f),
                0
            ];
            s["Offset"] = p;
            g.vao.draw();
            // import std.stdio;
            // writeln("CHR ", c, " bitmap_left ", g.bitmap_left,
                    // " OFF ", shape[i].x_offset, "ADV ", shape[i].x_advance);
            x += c.x_advance / 64f;
            import std.stdio;
        }
        context.blendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        return width;
    }

    override int text(int[2] pos, int h, string text, double offset=-0.2){
        pos[1] += cast(int)((h-font.height)/2.0);
        return this.text(pos, text, offset);
    }

    override void clear(){
        glClearColor(0,0,0,0);
        glClear(GL_COLOR_BUFFER_BIT);
    }

    override void finishFrame(){
        context.swapBuffers;
    }

    alias Clip = float[4];
    Clip[] clipStack;
    float[3] screen = [10,10,1];
    float[4] color = [1,1,1,1];

    private:

        CachedFactory!(ws.gl.font.Font) fonts;
        ws.gl.font.Font font;
        enum type {
            rect = 1,
            line,
            text,
            texture
        }

        Shader activateShader(type t){
            Shader shader;
            final switch(t){
                case type.texture:
                    shader = shaderRectTexture;
                    break;
                case type.rect:
                    shader = shaderRect;
                    break;
                case type.line:
                    shader = shaderLine;
                    break;
                case type.text:
                    shader = shaderText;
                    break;
            }
            shader.use();
            return shader;
        }

        Batch batchRect;
        Shader shaderRect;
        Batch batchRectTexture;
        Shader shaderRectTexture;
        Batch batchLine;
        Shader shaderLine;
        Shader shaderText;

}


enum TextShader {
    vertex = "
        #version 330

        in vec4 vVertex;
        in vec2 vTexture0;

        uniform vec3 Screen;
        uniform vec3 Offset;
        uniform vec3 Scale;

        smooth out vec2 vVaryingTexCoord;

        void main(void){
            vVaryingTexCoord = vTexture0.st;
            vec4 t = vVertex;
            t.x = (vVertex.x*Scale.x + Offset.x) / Screen.x * 2 - 1;
            t.y = (vVertex.y*Scale.y + Offset.y) / Screen.y * 2 - 1;
            gl_Position = t;
        }
    ",
    fragment = "
        #version 330

        uniform sampler2D Image;
        uniform vec4 Color;
        uniform vec4 Clip;
        uniform vec3 Screen;
        uniform vec3 Offset;
        uniform vec3 Scale;

        smooth in vec2 vVaryingTexCoord;

        layout(location = 0, index = 0) out vec4 color;
        layout(location = 0, index = 1) out vec4 colorMask;

        void main(void){
            vec2 screenPos = gl_FragCoord.xy;
            if(gl_FragCoord.x < Clip.x || gl_FragCoord.y < Clip.y
               || gl_FragCoord.x > Clip.x+Clip.z || gl_FragCoord.y > Clip.y+Clip.w)
                discard;
            vec4 pixel = texture(Image, vVaryingTexCoord);
            if(pixel.r+pixel.g+pixel.b < 0.001)
                discard;
            color = Color;
            colorMask = Color.a*pixel;
        }
    "
}


enum TextureShader {
    vertex = "
        #version 130

        in vec4 vVertex;
        in vec2 vTexture0;

        uniform vec3 Screen;
        uniform vec3 Offset;
        uniform vec3 Scale;

        smooth out vec2 vVaryingTexCoord;

        void main(void){
            vVaryingTexCoord = vTexture0.st;
            vec4 t = vVertex;
            t.x = (vVertex.x*Scale.x + Offset.x) / Screen.x * 2 - 1;
            t.y = (vVertex.y*Scale.y + Offset.y) / Screen.y * 2 - 1;
            gl_Position = t;
        }
    ",
    fragment = "
        #version 130

        uniform sampler2D Image;
        uniform vec4 Color;
        uniform vec4 Clip;
        uniform vec3 Screen;
        uniform vec3 Offset;
        uniform vec3 Scale;

        smooth in vec2 vVaryingTexCoord;

        out vec4 vFragColor;

        void main(void){
            vec2 screenPos = gl_FragCoord.xy;
            if(gl_FragCoord.x < Clip.x || gl_FragCoord.y < Clip.y
               || gl_FragCoord.x > Clip.x+Clip.z || gl_FragCoord.y > Clip.y+Clip.w)
                discard;
            vec4 color = texture(Image, vVaryingTexCoord);
            if(color.a < 0.001)
                discard;
            vFragColor = color * Color;
        }
    "
}


enum RectShader {
    vertex = "
        #version 130

        in vec4 vVertex;

        uniform vec3 Screen;
        uniform vec3 Offset;
        uniform vec3 Scale;

        void main(void){
            vec4 t = vVertex;
            t.x = (vVertex.x*Scale.x + Offset.x) / Screen.x * 2 - 1;
            t.y = (vVertex.y*Scale.y + Offset.y) / Screen.y * 2 - 1;
            gl_Position = t;
        }
    ",
    fragment = "
        #version 130

        uniform vec4 Color;
        uniform vec4 Clip;
        uniform vec3 Screen;
        uniform vec3 Offset;
        uniform vec3 Scale;

        out vec4 vFragColor;

        void main(void){
            if(gl_FragCoord.x < Clip.x || gl_FragCoord.y < Clip.y
               || gl_FragCoord.x > Clip.x+Clip.z || gl_FragCoord.y > Clip.y+Clip.w)
                discard;
            if(Color.a < 0.001)
                discard;
            vFragColor = Color;
        }
    "
}
