# 生成“UrhoX 观感预览”网页：在网页引擎里模拟 UrhoX 的 LDR + gamma 空间渲染、叠加混合特效与光晕，用来对比特效方案
import sys
src = open('/home/claude/gm/宇宙银河机甲_测试版_25.html', encoding='utf-8').read()
def sub(old, new):
    global src
    assert src.count(old) == 1, (src.count(old), old[:80]); src = src.replace(old, new)
sub("'uniform sampler2D uShadow; uniform float uShadowOn, uShadowTexel; uniform vec4 uTint;',",
    "'uniform sampler2D uShadow; uniform float uShadowOn, uShadowTexel; uniform vec4 uTint; uniform float uUrho; uniform vec4 uAdd;',\n    'vec3 fin(vec3 c){ return uUrho>0.5 ? pow(clamp(c,0.0,1.0), vec3(1.0/2.2)) : c; }',")
sub("'void main(){ vec3 N=normalize(vNor); float metal=vMat.x, rough=vMat.y, emi=vMat.z; vec3 vCol = mix(vCol0, uTint.rgb, uTint.a);',",
    "'void main(){ if(uAdd.a>0.5){ o=vec4(uAdd.rgb,1.0); return; } vec3 N=normalize(vNor); float metal=vMat.x, rough=vMat.y, emi=vMat.z; vec3 vCol = mix(vCol0, uTint.rgb, uTint.a);',\n    ' if(uUrho>0.5){ float lu=dot(vCol,vec3(0.2126,0.7152,0.0722)); vCol=max(vec3(lu)+(vCol-vec3(lu))*1.35, 0.0); }',")
sub("' if(emi<-1.5){ o=vec4(vCol*0.8,1.0); return; }\\n if(emi<-0.5){ o=vec4(vCol*1.6,1.0); return; }',",
    "' if(emi<-1.5){ o=vec4(fin(vCol*0.8),1.0); return; }\\n if(emi<-0.5){ o=vec4(fin(vCol*1.6),1.0); return; }',")
sub("' o=vec4(col,1.0); }'].join('\\n');", "' o=vec4(fin(col),1.0); }'].join('\\n');")
sub("var BRIGHT_FS = 'in vec2 vUv; out vec4 o; uniform sampler2D uTex; uniform float uThr; void main(){ vec3 c=texture(uTex,vUv).rgb;",
    "var BRIGHT_FS = 'in vec2 vUv; out vec4 o; uniform sampler2D uTex; uniform float uThr, uUrho; void main(){ vec3 c=texture(uTex,vUv).rgb; if(uUrho>0.5){ o=vec4(max(c-vec3(uThr),0.0),1.0); return; }")
sub("var COMP_FS = 'in vec2 vUv; out vec4 o; uniform sampler2D uTex, uBloom; uniform float uMix;' +",
    "var COMP_FS = 'in vec2 vUv; out vec4 o; uniform sampler2D uTex, uBloom; uniform float uMix, uUrho;' +")
sub("' void main(){ vec3 c=texture(uTex,vUv).rgb + texture(uBloom,vUv).rgb*uMix; c=aces(c*1.05);' +",
    "' void main(){ vec3 c=texture(uTex,vUv).rgb + texture(uBloom,vUv).rgb*uMix; if(uUrho>0.5){ c=clamp(c,0.0,1.0); vec2 dd=vUv-0.5; c*=1.0-dot(dd,dd)*0.55; o=vec4(c,1.0); return; } c=aces(c*1.05);' +")
# 主绘制循环：UrhoX 模式下按规则把发光特效改为叠加混合 + 光晕
sub("""    for (i = 0; i < draws.length; i++) {
      var tn = draws[i].tint; if (tn) gl.uniform4f(u.uTint, tn[0], tn[1], tn[2], 1); else if (draws[i - 1] && draws[i - 1].tint) gl.uniform4f(u.uTint, 0, 0, 0, 0);
      gl.uniformMatrix4fv(u.uModel, false, draws[i].m); gl.uniform1f(u.uScale, draws[i].s);
      gl.bindVertexArray(draws[i].mesh.vao); gl.drawArrays(gl.TRIANGLES, 0, draws[i].mesh.count);
    }""", """    var UR = window.__urho, addL = [];
    gl.uniform1f(u.uUrho, UR ? 1 : 0); gl.uniform4f(u.uAdd, 0, 0, 0, 0);
    for (i = 0; i < draws.length; i++) {
      if (UR) { var rule = window.__urhoRule(draws[i]); if (rule) { addL.push([draws[i], rule]); continue; } }
      var tn = draws[i].tint; if (tn) gl.uniform4f(u.uTint, tn[0], tn[1], tn[2], 1); else gl.uniform4f(u.uTint, 0, 0, 0, 0);
      gl.uniformMatrix4fv(u.uModel, false, draws[i].m); gl.uniform1f(u.uScale, draws[i].s);
      gl.bindVertexArray(draws[i].mesh.vao); gl.drawArrays(gl.TRIANGLES, 0, draws[i].mesh.count);
    }
    if (addL.length) {
      gl.enable(gl.BLEND); gl.blendFunc(gl.ONE, gl.ONE); gl.depthMask(false); var halos = 0;
      for (i = 0; i < addL.length; i++) {
        var dw = addL[i][0], rl = addL[i][1], mm = dw.m;
        if (rl.sc && rl.sc !== 1) mm = window.__m4local(dw.m, 0, rl.sc);
        gl.uniform4f(u.uAdd, rl.col[0], rl.col[1], rl.col[2], 1); gl.uniformMatrix4fv(u.uModel, false, mm); gl.uniform1f(u.uScale, dw.s);
        gl.bindVertexArray(dw.mesh.vao); gl.drawArrays(gl.TRIANGLES, 0, dw.mesh.count);
        if (rl.halo && halos < (window.__haloMax || 90)) { halos++;
          gl.uniform4f(u.uAdd, rl.halo.col[0], rl.halo.col[1], rl.halo.col[2], 1); gl.uniformMatrix4fv(u.uModel, false, window.__m4local(dw.m, rl.halo.rot, rl.halo.scale * (rl.sc || 1)));
          gl.drawArrays(gl.TRIANGLES, 0, dw.mesh.count); }
        if (rl.halos) for (var hj = 0; hj < rl.halos.length && halos < (window.__haloMax || 90); hj++) { var hh = rl.halos[hj]; halos++;
          gl.uniform4f(u.uAdd, hh.col[0], hh.col[1], hh.col[2], 1); gl.uniformMatrix4fv(u.uModel, false, window.__m4local(dw.m, hh.rot, hh.s));
          gl.drawArrays(gl.TRIANGLES, 0, dw.mesh.count); }
      }
      gl.disable(gl.BLEND); gl.depthMask(true); gl.uniform4f(u.uAdd, 0, 0, 0, 0);
    }""")
sub("gl.uniform1i(progBright.u.uTex, 0); gl.uniform1f(progBright.u.uThr, 1.0 + env.bloom.threshold * 0.6); drawFS();",
    "gl.uniform1i(progBright.u.uTex, 0); gl.uniform1f(progBright.u.uThr, window.__urho ? window.__urhoBloom(env).thr : 1.0 + env.bloom.threshold * 0.6); gl.uniform1f(progBright.u.uUrho, window.__urho ? 1 : 0); drawFS();")
sub("gl.uniform1f(progComp.u.uMix, env.bloom.mix); drawFS();",
    "gl.uniform1f(progComp.u.uMix, window.__urho ? window.__urhoBloom(env).mix : env.bloom.mix); gl.uniform1f(progComp.u.uUrho, window.__urho ? 1 : 0); drawFS();")
sub("' vec3 col = diff + sc*sp*uKeyCol*sh + vCol*emi;',", "' float em2 = emi; if(uUrho>0.5 && window_capEm>0.5) em2 = min(emi, 0.75/max(max(vCol.r,vCol.g),max(vCol.b,0.001)));', ' vec3 col = diff + sc*sp*uKeyCol*sh + vCol*em2;',")
src = src.replace("uniform float uUrho; uniform vec4 uAdd;'", "uniform float uUrho; uniform vec4 uAdd; uniform float window_capEm;'")
src = src.replace("gl.uniform1f(u.uUrho, UR ? 1 : 0); gl.uniform4f(u.uAdd, 0, 0, 0, 0);", "gl.uniform1f(u.uUrho, UR ? 1 : 0); gl.uniform4f(u.uAdd, 0, 0, 0, 0); gl.uniform1f(u.window_capEm, window.__capEm ? 1 : 0);")
# 柔光贴片（模拟 UrhoX 的 BillboardSet + 径向渐变贴图 + 叠加混合）
sub("  var progMain = compile(MAIN_VS, MAIN_FS),", """  var SPR_VS = 'layout(location=0) in vec3 aPos; layout(location=1) in vec2 aUv; layout(location=2) in vec3 aCol; uniform mat4 uVP; out vec2 vUv; out vec3 vCol; void main(){ vUv=aUv; vCol=aCol; gl_Position=uVP*vec4(aPos,1.0); }';
  var SPR_FS = 'in vec2 vUv; in vec3 vCol; out vec4 o; uniform float uLine; void main(){ vec2 p=vUv*2.0-1.0; float f; if(uLine>0.5){ float x=abs(p.x); f=exp(-x*x*3.0)*clamp(1.0-x*x,0.0,1.0)*(1.0-smoothstep(0.65,1.0,abs(p.y))); } else { float r=length(p); f=exp(-r*r*3.0)*clamp(1.0-r*r,0.0,1.0); } o=vec4(vCol*f,1.0); }';
  var progSpr = compile(SPR_VS, SPR_FS), sprVAO = gl.createVertexArray(), sprBuf = gl.createBuffer();
  gl.bindVertexArray(sprVAO); gl.bindBuffer(gl.ARRAY_BUFFER, sprBuf);
  gl.enableVertexAttribArray(0); gl.vertexAttribPointer(0, 3, gl.FLOAT, false, 32, 0); gl.enableVertexAttribArray(1); gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 32, 12); gl.enableVertexAttribArray(2); gl.vertexAttribPointer(2, 3, gl.FLOAT, false, 32, 20); gl.bindVertexArray(null);
  var progMain = compile(MAIN_VS, MAIN_FS),""")
sub("""      gl.disable(gl.BLEND); gl.depthMask(true); gl.uniform4f(u.uAdd, 0, 0, 0, 0);
    }""", """      gl.disable(gl.BLEND); gl.depthMask(true); gl.uniform4f(u.uAdd, 0, 0, 0, 0);
      var sp = []; for (i = 0; i < addL.length; i++) if (addL[i][1].sprites) { var mm2 = addL[i][0].m; addL[i][1].sprites.forEach(function (q) { sp.push([mm2[12], mm2[13], mm2[14], q]); }); }
      if (sp.length) {
        var fw = [f.target[0] - f.eye[0], f.target[1] - f.eye[1], f.target[2] - f.eye[2]], fl0 = Math.hypot(fw[0], fw[1], fw[2]); fw = fw.map(function (v) { return v / fl0; });
        var rt = [fw[2], 0, -fw[0]], rl0 = Math.hypot(rt[0], rt[2]) || 1; rt = [rt[0] / rl0, 0, rt[2] / rl0]; var up = [fw[1] * rt[2] - fw[2] * rt[1], fw[2] * rt[0] - fw[0] * rt[2], fw[0] * rt[1] - fw[1] * rt[0]];
        var data = new Float32Array(sp.length * 6 * 8), w2 = 0, nSpr = Math.min(sp.length, window.__sprMax || 400);
        for (i = 0; i < nSpr; i++) { var c0 = sp[i], q = c0[3], ax, sd, hw, hl;
          if (q.dir) { var dl = Math.hypot(q.dir[0], q.dir[1], q.dir[2]) || 1; ax = [q.dir[0] / dl, q.dir[1] / dl, q.dir[2] / dl]; var vd = [c0[0] - f.eye[0], c0[1] - f.eye[1], c0[2] - f.eye[2]];
            sd = [ax[1] * vd[2] - ax[2] * vd[1], ax[2] * vd[0] - ax[0] * vd[2], ax[0] * vd[1] - ax[1] * vd[0]]; var sl = Math.hypot(sd[0], sd[1], sd[2]) || 1; sd = sd.map(function (v) { return v / sl; }); hw = q.w / 2; hl = q.l / 2; }
          else { ax = up; sd = rt; hw = q.w / 2; hl = q.w / 2; }
          var cs = [[-1, -1, 0, 0], [1, -1, 1, 0], [1, 1, 1, 1], [-1, -1, 0, 0], [1, 1, 1, 1], [-1, 1, 0, 1]];
          for (var cc = 0; cc < 6; cc++) { var e = cs[cc]; data[w2++] = c0[0] + sd[0] * hw * e[0] + ax[0] * hl * e[1]; data[w2++] = c0[1] + sd[1] * hw * e[0] + ax[1] * hl * e[1]; data[w2++] = c0[2] + sd[2] * hw * e[0] + ax[2] * hl * e[1];
            data[w2++] = e[2]; data[w2++] = e[3]; data[w2++] = q.col[0]; data[w2++] = q.col[1]; data[w2++] = q.col[2]; } }
        gl.useProgram(progSpr.p); gl.uniformMatrix4fv(progSpr.u.uVP, false, VP); gl.enable(gl.BLEND); gl.blendFunc(gl.ONE, gl.ONE); gl.depthMask(false);
        gl.bindVertexArray(sprVAO); gl.bindBuffer(gl.ARRAY_BUFFER, sprBuf); gl.bufferData(gl.ARRAY_BUFFER, data.subarray(0, w2), gl.DYNAMIC_DRAW); for (var pass = 0; pass < 2; pass++) { gl.uniform1f(progSpr.u.uLine, pass); var st0 = -1; for (var qi = 0; qi < nSpr; qi++) { var isDir = !!sp[qi][3].dir; if (isDir === (pass === 1)) gl.drawArrays(gl.TRIANGLES, qi * 6, 6); } }
        gl.disable(gl.BLEND); gl.depthMask(true); gl.useProgram(progMain.p);
      }
    }""")
open('/home/claude/gm/urho_preview.html', 'w', encoding='utf-8').write(src); print('preview built')
