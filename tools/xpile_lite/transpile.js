#!/usr/bin/env node
// xpile-lite：宇宙银河机甲 网页版 JS（ES5 子集）-> UrhoX Lua（运行库 scripts/jsrt/JS.lua）
// 约定（与原转换器生成的 CosmicData.lua / CosmicRun.lua 一致）：
//   · 每个函数第一个参数是 _this；方法调用 a.b(x) -> a:b(x)；普通函数调用 f(x) -> f(nil, x)
//   · 第一个顶层 IIFE 是“模块”：其中的 var / function 变成 S.xxx（界面层通过 S 访问战斗状态）
//   · 数组 0 起始 + length 字段（smt(..., AMT)）；空对象 {} 与模块级常量表用有序对象（JS.dict / JS.odict）
//   · window / document / setTimeout 等由宿主 HOST 提供；Math.xxx -> Math_xxx
// 用法：node transpile.js 输入1.js [输入2.js ...] -o 输出.lua [--name 模块说明]
'use strict';
const fs = require('fs');
let acorn;
try { acorn = require('acorn'); } catch (e) {
  try { acorn = require('internal/deps/acorn/acorn/dist/acorn'); } catch (e2) {
    console.error('需要 acorn：npm i acorn，或用 node --expose-internals 运行（使用 Node 自带的 acorn）'); process.exit(2);
  }
}

const LUA_KW = new Set('and break do else elseif end false for function goto if in local nil not or repeat return then true until while'.split(' '));
const RESERVED = new Set([...LUA_KW, 'S', 'G', 'T', 'OR', 'AND', 'S2', 'LEN', 'MOD', 'typeof', 'tonum', 'smt', 'AMT', 'JS', 'HOST', 'bor', 'band', 'bxor', 'shl', 'shr', 'ushr',
  'type', 'next', 'pairs', 'ipairs', 'error', 'pcall', 'select', 'tostring', 'tonumber', 'string', 'table', 'math', 'utf8', 'require', 'print', 'setmetatable', 'getmetatable',
  'rawget', 'rawset', 'rawequal', 'unpack', 'os', 'io', 'debug', 'coroutine', 'load', 'assert', '_this', '_t', '_ok', '_f', '_v', '_G', '_ENV']);
const MATH_FN = ['abs', 'min', 'max', 'floor', 'ceil', 'round', 'sqrt', 'sin', 'cos', 'tan', 'asin', 'atan2', 'exp', 'hypot', 'pow', 'random', 'sign', 'imul'];
const HOST_OBJ = { window: 'HOST.window', document: 'HOST.document', localStorage: 'HOST.localStorage', console: 'HOST.console', performance: 'HOST.performance', navigator: 'HOST.navigator' };
const HOST_FN = new Set(['setTimeout', 'setInterval', 'clearTimeout', 'clearInterval', 'requestAnimationFrame', 'btoa', 'atob', 'encodeURIComponent', 'decodeURIComponent', 'escape', 'unescape']);
const G_OBJ = new Set(['JSON', 'Object', 'Array', 'Date']);
const G_FN = new Set(['String', 'Number', 'Boolean', 'parseInt', 'parseFloat', 'isNaN', 'isFinite', 'Error']);
const STR_METHODS = new Set(['toFixed', 'join', 'toString', 'toUpperCase', 'toLowerCase', 'trim', 'charAt', 'padStart', 'toLocaleString', 'substr', 'substring', 'replace']);
const NUM_METHODS = new Set(['indexOf', 'lastIndexOf', 'charCodeAt', 'push', 'unshift']);
const BOOL_METHODS = new Set(['some', 'every', 'includes']);
const isIdent = s => /^[A-Za-z_][A-Za-z0-9_]*$/.test(s) && !LUA_KW.has(s);

function luaStr(s) {
  let o = '"';
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === '"') o += '\\"'; else if (ch === '\\') o += '\\\\'; else if (ch === '\n') o += '\\n'; else if (ch === '\r') o += '\\r'; else if (ch === '\t') o += '\\t';
    else if (c < 32 || c === 127) o += '\\' + String(c).padStart(3, '0'); else o += ch;
  }
  return o + '"';
}

class Scope {
  constructor(kind, parent) { this.kind = kind; this.parent = parent; this.names = new Map(); }
  declare(name) {
    if (this.names.has(name)) return this.names.get(name);
    let ln;
    if (this.kind === 'module') ln = isIdent(name) ? 'S.' + name : 'S[' + luaStr(name) + ']';
    else { ln = name; while (RESERVED.has(ln) || !isIdent(ln) || /^_[ok]\d+$/.test(ln)) ln = ln.replace(/[^A-Za-z0-9_]/g, '_') + '_'; }
    this.names.set(name, ln); return ln;
  }
  lookup(name) { for (let s = this; s; s = s.parent) if (s.names.has(name)) return s.names.get(name); return null; }
}

class Gen {
  constructor() { this.uid = 0; this.warn = new Set(); }
  id(p) { return p + (++this.uid); }

  // ---------------------------------------------------------------- 声明收集（var / function / catch 参数，不进入嵌套函数）
  collect(body, scope, fnDecls) {
    const visit = (n) => {
      if (!n || typeof n !== 'object') return;
      if (Array.isArray(n)) { n.forEach(visit); return; }
      switch (n.type) {
        case 'FunctionDeclaration': scope.declare(n.id.name); fnDecls.push(n); return;
        case 'FunctionExpression': return;
        case 'VariableDeclaration': n.declarations.forEach(d => { scope.declare(d.id.name); visit(d.init); }); return;
        case 'CatchClause': scope.declare(n.param.name); visit(n.body); return;
        default: for (const k in n) if (k !== 'loc' && k !== 'start' && k !== 'end' && n[k] && typeof n[k] === 'object') visit(n[k]);
      }
    };
    visit(body);
  }

  // ---------------------------------------------------------------- 函数
  fn(node, scope, nameForSelf) {
    const sc = new Scope('function', scope);
    if (node.type === 'FunctionExpression' && node.id) sc.declare(node.id.name);
    const params = node.params.map(p => sc.declare(p.name));
    const before = new Set(sc.names.values());
    const decls = []; this.collect(node.body.body, sc, decls);
    const locals = [...sc.names.values()].filter(v => !before.has(v) && !params.includes(v));
    const saved = this.ctx; this.ctx = { scope: sc, tryDepth: 0, loops: [] };
    const out = [];
    if (locals.length) out.push('local ' + locals.join(', ') + ';');
    for (const d of decls) out.push(sc.lookup(d.id.name) + ' = ' + this.fn(d, sc) + ';');
    for (const st of node.body.body) this.stmt(st, out);
    this.ctx = saved;
    const head = 'function(' + ['_this', ...params].join(', ') + ')';
    let code = head + '\n' + out.join('\n') + (out.length ? '\n' : '') + 'end';
    if (node.type === 'FunctionExpression' && node.id) {
      // 具名函数表达式：在闭包里绑定自身名字
      const self = sc.lookup(node.id.name);
      code = '(function() local ' + self + '; ' + self + ' = ' + code + '; return ' + self + ' end)()';
    }
    return code;
  }

  // ---------------------------------------------------------------- 语句
  stmt(n, out) {
    const ctx = this.ctx;
    switch (n.type) {
      case 'EmptyStatement': return;
      case 'FunctionDeclaration': return;          // 已提升
      case 'ExpressionStatement': {
        if (n.directive) return;
        this.exprStmt(n.expression, out); return;
      }
      case 'VariableDeclaration': {
        const parts = [];
        for (const d of n.declarations) if (d.init) {
          const name = ctx.scope.lookup(d.id.name);
          const v = this.expr(d.init, { moduleConst: ctx.scope.kind === 'module' });
          parts.push(name + ' = ' + v.c + ';');
        }
        if (parts.length) out.push(parts.join(' '));
        return;
      }
      case 'ReturnStatement': {
        const v = n.argument ? this.expr(n.argument).c : null;
        if (ctx.tryDepth > 0) out.push('do return "R"' + (v ? ', ' + v : '') + ' end;');
        else out.push('do return' + (v ? ' ' + v : '') + ' end;');
        return;
      }
      case 'IfStatement': {
        let cur = n, first = true;
        while (true) {
          out.push((first ? 'if ' : 'elseif ') + this.cond(cur.test) + ' then');
          this.block(cur.consequent, out);
          first = false;
          if (cur.alternate && cur.alternate.type === 'IfStatement') { cur = cur.alternate; continue; }
          if (cur.alternate) { out.push('else'); this.block(cur.alternate, out); }
          break;
        }
        out.push('end;'); return;
      }
      case 'BlockStatement': { out.push('do'); this.block(n, out); out.push('end;'); return; }
      case 'ForStatement': {
        const loop = { label: this.id('cont'), used: false, kind: 'for' };
        out.push('do');
        if (n.init) { if (n.init.type === 'VariableDeclaration') this.stmt(n.init, out); else this.exprStmt(n.init, out); }
        out.push('while ' + (n.test ? this.cond(n.test) : 'true') + ' do');
        const body = []; ctx.loops.push(loop); this.block(n.body, body); ctx.loops.pop();
        if (loop.used) { out.push('do'); out.push(...body); out.push('end'); out.push('::' + loop.label + '::'); } else out.push(...body);
        if (n.update) this.exprStmt(n.update, out);
        out.push('end'); out.push('end;'); return;
      }
      case 'WhileStatement': {
        const loop = { label: this.id('cont'), used: false };
        out.push('while ' + this.cond(n.test) + ' do');
        const body = []; ctx.loops.push(loop); this.block(n.body, body); ctx.loops.pop();
        if (loop.used) { out.push('do'); out.push(...body); out.push('end'); out.push('::' + loop.label + '::'); } else out.push(...body);
        out.push('end;'); return;
      }
      case 'DoWhileStatement': {
        const loop = { label: this.id('cont'), used: false };
        out.push('repeat');
        const body = []; ctx.loops.push(loop); this.block(n.body, body); ctx.loops.pop();
        if (loop.used) { out.push('do'); out.push(...body); out.push('end'); out.push('::' + loop.label + '::'); } else out.push(...body);
        out.push('until not ' + this.cond(n.test) + ';'); return;
      }
      case 'ForInStatement': {
        const loop = { label: this.id('cont'), used: false };
        const k = this.id('_k');
        let target;
        if (n.left.type === 'VariableDeclaration') target = ctx.scope.lookup(n.left.declarations[0].id.name); else target = this.lhs(n.left).c;
        out.push('for _, ' + k + ' in ipairs(JS.keys(' + this.expr(n.right).c + ')) do ' + target + ' = ' + k);
        const body = []; ctx.loops.push(loop); this.block(n.body, body); ctx.loops.pop();
        if (loop.used) { out.push('do'); out.push(...body); out.push('end'); out.push('::' + loop.label + '::'); } else out.push(...body);
        out.push('end;'); return;
      }
      case 'BreakStatement': if (n.label) throw new Error('不支持带标签的 break'); out.push('do break end;'); return;
      case 'ContinueStatement': {
        if (n.label) throw new Error('不支持带标签的 continue');
        const loop = ctx.loops[ctx.loops.length - 1]; if (!loop) throw new Error('continue 不在循环内');
        loop.used = true; out.push('goto ' + loop.label + ';'); return;
      }
      case 'ThrowStatement': out.push('error(' + this.expr(n.argument).c + ');'); return;
      case 'TryStatement': {
        if (n.finalizer) throw new Error('不支持 finally');
        const body = []; ctx.tryDepth++; const loops = ctx.loops; ctx.loops = []; this.block(n.block, body); ctx.loops = loops; ctx.tryDepth--;
        out.push('do local _ok, _f, _v = pcall(function()'); out.push(...body); out.push('end)');
        const h = [];
        if (n.handler) { this.block(n.handler.body, h); }
        const pname = n.handler && n.handler.param ? ctx.scope.lookup(n.handler.param.name) : null;
        const ret = ctx.tryDepth > 0 ? 'do return "R", _v end' : 'do return _v end';
        out.push('if not _ok then ' + (pname ? pname + ' = _f' : ''));
        out.push(...h);
        out.push('elseif _f == "R" then ' + ret + ' end end;');
        return;
      }
      default: throw new Error('不支持的语句 ' + n.type + ' @' + (n.loc && n.loc.start.line));
    }
  }
  block(n, out) { if (n.type === 'BlockStatement') n.body.forEach(s => this.stmt(s, out)); else this.stmt(n, out); }
  push(out, code) { out.push((code[0] === '(' ? ';' : '') + code); }

  exprStmt(e, out) {
    switch (e.type) {
      case 'AssignmentExpression': this.assign(e, out); return;
      case 'UpdateExpression': this.update(e, out); return;
      case 'SequenceExpression': e.expressions.forEach(x => this.exprStmt(x, out)); return;
      case 'LogicalExpression': {
        const body = []; this.exprStmt(e.right, body);
        out.push('if ' + (e.operator === '&&' ? this.cond(e.left) : '(not ' + this.cond(e.left) + ')') + ' then'); out.push(...body); out.push('end;'); return;
      }
      case 'ConditionalExpression': {
        const a = [], b = []; this.exprStmt(e.consequent, a); this.exprStmt(e.alternate, b);
        out.push('if ' + this.cond(e.test) + ' then'); out.push(...a); if (b.length) { out.push('else'); out.push(...b); } out.push('end;'); return;
      }
      case 'CallExpression': case 'NewExpression': this.push(out, this.expr(e).c + ';'); return;
      case 'UnaryExpression': if (e.operator === 'void' || e.operator === '!') { this.exprStmt(e.argument, out); return; } // fallthrough
      default: { const v = this.expr(e); out.push('do local _ = ' + v.c + ' end;'); }
    }
  }

  // 赋值目标
  lhs(n) {
    if (n.type === 'Identifier') { const nm = this.ctx.scope.lookup(n.name); if (!nm) { this.warn.add('赋值给未声明的全局变量 ' + n.name); return { c: 'HOST.window.' + n.name, pure: true }; } return { c: nm, pure: true }; }
    if (n.type === 'MemberExpression') {
      const o = this.obj(n.object);
      if (!n.computed) { const p = n.property.name; return { c: isIdent(p) ? o.c + '.' + p : o.c + '[' + luaStr(p) + ']', o: o.c, k: luaStr(p), pure: this.pure(n.object), prop: p }; }
      const k = this.expr(n.property);
      return { c: o.c + '[' + k.c + ']', o: o.c, k: k.c, pure: this.pure(n.object) && this.pure(n.property) };
    }
    throw new Error('不支持的赋值目标 ' + n.type);
  }
  binop(op, a, b, nodeB) {
    // a、b：{c,t}；op 为 JS 运算符（+ - * / % | & ^ << >> >>>）
    switch (op) {
      case '+': if (a.t === 'string' || b.t === 'string') return { c: '(' + (a.t === 'string' ? a.c : 'S2(' + a.c + ')') + ' .. ' + (b.t === 'string' ? b.c : 'S2(' + b.c + ')') + ')', t: 'string' };
        return { c: '(' + a.c + ' + ' + b.c + ')', t: a.t === 'number' && b.t === 'number' ? 'number' : 'any' };
      case '-': case '*': case '/': return { c: '(' + a.c + ' ' + op + ' ' + b.c + ')', t: 'number' };
      case '%': return { c: 'MOD(' + a.c + ',' + b.c + ')', t: 'number' };
      case '|': return { c: 'bor(' + a.c + ',' + b.c + ')', t: 'number' };
      case '&': return { c: 'band(' + a.c + ',' + b.c + ')', t: 'number' };
      case '^': return { c: 'bxor(' + a.c + ',' + b.c + ')', t: 'number' };
      case '<<': return { c: 'shl(' + a.c + ',' + b.c + ')', t: 'number' };
      case '>>': return { c: 'shr(' + a.c + ',' + b.c + ')', t: 'number' };
      case '>>>': return { c: 'ushr(' + a.c + ',' + b.c + ')', t: 'number' };
    }
    throw new Error('不支持的运算符 ' + op);
  }
  assign(e, out) {
    if (e.operator === '=') {
      if (e.right.type === 'AssignmentExpression' && e.right.operator === '=') {
        // 连等：a = b = v -> b = v; a = b
        this.assign(e.right, out);
        const inner = this.lhs(e.right.left), t = this.lhs(e.left);
        if (t.prop === 'length') out.push('JS.setlen(' + t.o + ', ' + inner.c + ');'); else out.push(t.c + ' = ' + inner.c + ';');
        return;
      }
      const t = this.lhs(e.left), v = this.expr(e.right);
      if (t.prop === 'length') { out.push('JS.setlen(' + t.o + ', ' + v.c + ');'); return; }
      out.push(t.c + ' = ' + v.c + ';'); return;
    }
    const op = e.operator.slice(0, -1), t = this.lhs(e.left), v = this.expr(e.right);
    if (t.o === undefined || t.pure) { const r = this.binop(op, { c: t.c, t: 'any' }, v); out.push(t.c + ' = ' + r.c + ';'); return; }
    const o = this.id('_o'), k = this.id('_k');
    const r = this.binop(op, { c: o + '[' + k + ']', t: 'any' }, v);
    out.push('do local ' + o + ', ' + k + ' = ' + t.o + ', ' + t.k + '; ' + o + '[' + k + '] = ' + r.c + ' end;');
  }
  update(e, out) {
    const t = this.lhs(e.argument), op = e.operator === '++' ? '+' : '-';
    if (t.o === undefined || t.pure) { out.push(t.c + ' = ' + t.c + ' ' + op + ' 1;'); return; }
    const o = this.id('_o'), k = this.id('_k');
    out.push('do local ' + o + ', ' + k + ' = ' + t.o + ', ' + t.k + '; ' + o + '[' + k + '] = ' + o + '[' + k + '] ' + op + ' 1 end;');
  }

  // ---------------------------------------------------------------- 表达式
  pure(n) {
    if (!n) return true;
    switch (n.type) {
      case 'Identifier': case 'ThisExpression': case 'Literal': return true;
      case 'MemberExpression': return this.pure(n.object) && (!n.computed || this.pure(n.property));
    }
    return false;
  }
  // 条件上下文：返回 Lua 布尔表达式
  cond(n) {
    if (n.type === 'LogicalExpression') return '(' + this.cond(n.left) + (n.operator === '&&' ? ' and ' : ' or ') + this.cond(n.right) + ')';
    if (n.type === 'UnaryExpression' && n.operator === '!') return '(not ' + this.cond(n.argument) + ')';
    if (n.type === 'Literal' && typeof n.value === 'boolean') return String(n.value);
    const v = this.expr(n);
    return v.t === 'boolean' ? v.c : 'T(' + v.c + ')';
  }
  // 能直接放在 a:b() 前面的写法
  obj(n) {
    const v = this.expr(n);
    if (/^[A-Za-z_][A-Za-z0-9_.]*$/.test(v.c) || /^[A-Za-z_][\w.]*(\[[^\[\]]*\]|\.\w+)*$/.test(v.c)) return v;
    return { c: '(' + v.c + ')', t: v.t };
  }
  args(list) {
    const a = list.map(x => this.expr(x).c);
    if (a.length && list[list.length - 1].type === 'CallExpression') a[a.length - 1] = '(' + a[a.length - 1] + ')';   // 只取一个返回值
    return a;
  }
  truthyLit(n) { return (n.type === 'Literal' && n.value !== null && n.value !== false) || n.type === 'ArrayExpression' || n.type === 'ObjectExpression' || n.type === 'FunctionExpression'; }

  expr(n, opt) {
    opt = opt || {};
    const sc = this.ctx.scope;
    switch (n.type) {
      case 'Literal': {
        if (n.regex) throw new Error('不支持正则 @' + n.loc.start.line);
        if (typeof n.value === 'string') return { c: luaStr(n.value), t: 'string' };
        if (typeof n.value === 'number') { let r = n.raw; if (r[0] === '.') r = '0' + r; if (/^0[0-7]+$/.test(r)) r = String(n.value); return { c: r, t: 'number' }; }
        if (typeof n.value === 'boolean') return { c: String(n.value), t: 'boolean' };
        return { c: 'nil', t: 'nil' };
      }
      case 'Identifier': {
        if (n.name === 'undefined') return { c: 'nil', t: 'nil' };
        if (n.name === 'NaN') return { c: '(0/0)', t: 'number' };
        if (n.name === 'Infinity') return { c: 'math.huge', t: 'number' };
        const nm = sc.lookup(n.name);
        if (nm) return { c: nm, t: 'any' };
        if (HOST_OBJ[n.name]) return { c: HOST_OBJ[n.name], t: 'object' };
        if (HOST_FN.has(n.name)) return { c: 'HOST.' + n.name, t: 'object' };
        if (G_OBJ.has(n.name) || G_FN.has(n.name)) return { c: 'G.' + n.name, t: 'object' };
        if (n.name === 'Math') return { c: 'G.Math', t: 'object' };
        this.warn.add('未知全局变量 ' + n.name + '（按 window.' + n.name + ' 处理）');
        return { c: 'HOST.window.' + n.name, t: 'any' };
      }
      case 'ThisExpression': return { c: '_this', t: 'any' };
      case 'ArrayExpression': {
        if (!n.elements.length) return { c: 'smt({length=0},AMT)', t: 'object' };
        const els = n.elements.map(x => x ? this.expr(x, { moduleConst: false }).c : 'nil');
        if (n.elements[n.elements.length - 1] && n.elements[n.elements.length - 1].type === 'CallExpression') els[els.length - 1] = '(' + els[els.length - 1] + ')';
        return { c: 'smt({[0]=' + els.join(',') + ',length=' + els.length + '},AMT)', t: 'object' };
      }
      case 'ObjectExpression': {
        if (!n.properties.length) return { c: 'JS.dict()', t: 'object' };
        const parts = [], keys = [];
        for (const p of n.properties) {
          if (p.kind !== 'init' || p.computed) throw new Error('不支持的对象属性 @' + p.loc.start.line);
          const key = p.key.type === 'Identifier' ? p.key.name : String(p.key.value);
          const v = this.expr(p.value, { moduleConst: opt.moduleConst && p.value.type === 'ObjectExpression' });
          if (p.key.type === 'Literal' && typeof p.key.value === 'number') parts.push('[' + p.key.raw + ']=' + v.c);
          else parts.push((isIdent(key) ? key : '[' + luaStr(key) + ']') + '=' + v.c);
          keys.push(luaStr(key));
        }
        if (opt.moduleConst) return { c: 'JS.odict({' + parts.join(',') + '},{' + keys.join(',') + '})', t: 'object' };
        return { c: '{' + parts.join(',') + '}', t: 'object' };
      }
      case 'FunctionExpression': return { c: this.fn(n, sc), t: 'object' };
      case 'MemberExpression': {
        if (!n.computed && n.object.type === 'Identifier' && n.object.name === 'Math' && !sc.lookup('Math')) {
          if (n.property.name === 'PI') return { c: 'Math_PI', t: 'number' };
          return { c: 'JS.Math_' + n.property.name, t: 'object' };
        }
        const o = this.obj(n.object);
        if (!n.computed) {
          const p = n.property.name;
          if (p === 'length') return { c: 'LEN(' + o.c + ')', t: 'number' };
          return { c: isIdent(p) ? o.c + '.' + p : o.c + '[' + luaStr(p) + ']', t: 'any' };
        }
        return { c: o.c + '[' + this.expr(n.property).c + ']', t: 'any' };
      }
      case 'CallExpression': return this.call(n);
      case 'NewExpression': {
        const nm = n.callee.name;
        if (nm === 'Date' || nm === 'Uint8Array' || nm === 'Error') return { c: (nm === 'Error' ? 'G.Error(nil, ' : 'G.new_' + nm + '(') + this.args(n.arguments).join(', ') + ')', t: 'object' };
        this.warn.add('不支持的 new（第 ' + n.loc.start.line + ' 行），运行到这里会报错；网页版里只在宿主替换掉的代码（如音频）里出现时可以忽略');
        return { c: 'error("xpile: 不支持的 new @' + n.loc.start.line + '")', t: 'any' };
      }
      case 'UnaryExpression': {
        const op = n.operator;
        if (op === '!') return { c: '(not ' + this.cond(n.argument) + ')', t: 'boolean' };
        if (op === 'typeof') {
          if (n.argument.type === 'Identifier' && !sc.lookup(n.argument.name) && !HOST_OBJ[n.argument.name] && !G_OBJ.has(n.argument.name) && !G_FN.has(n.argument.name) && !HOST_FN.has(n.argument.name) && n.argument.name !== 'Math')
            return { c: 'typeof(HOST.window.' + n.argument.name + ')', t: 'string' };
          return { c: 'typeof(' + this.expr(n.argument).c + ')', t: 'string' };
        }
        const a = this.expr(n.argument);
        if (op === '-') return { c: '(-' + a.c + ')', t: 'number' };
        if (op === '+') return { c: 'tonum(' + a.c + ')', t: 'number' };
        if (op === '~') return { c: 'bxor(' + a.c + ',-1)', t: 'number' };
        if (op === 'void') return { c: 'nil', t: 'nil' };
        throw new Error('不支持的一元运算 ' + op);
      }
      case 'BinaryExpression': {
        const op = n.operator;
        if (op === 'in') return { c: '(' + this.expr(n.right).c + '[' + this.expr(n.left).c + '] ~= nil)', t: 'boolean' };
        const a = this.expr(n.left), b = this.expr(n.right);
        if (op === '===' || op === '==') return { c: '(' + a.c + ' == ' + b.c + ')', t: 'boolean' };
        if (op === '!==' || op === '!=') return { c: '(' + a.c + ' ~= ' + b.c + ')', t: 'boolean' };
        if (op === '<' || op === '>' || op === '<=' || op === '>=') return { c: '(' + a.c + ' ' + op + ' ' + b.c + ')', t: 'boolean' };
        return this.binop(op, a, b);
      }
      case 'LogicalExpression': {
        const a = this.expr(n.left), b = this.expr(n.right);
        if (a.t === 'boolean' && b.t === 'boolean') return { c: '(' + a.c + (n.operator === '&&' ? ' and ' : ' or ') + b.c + ')', t: 'boolean' };
        const t = a.t === b.t ? a.t : 'any';
        if (n.operator === '||') {
          if (a.t === 'boolean') return { c: '(' + a.c + ' or ' + b.c + ')', t };
          if (this.pure(n.left)) return { c: '(' + (a.t === 'boolean' ? a.c : 'T(' + a.c + ')') + ' and ' + a.c + ' or ' + b.c + ')', t };
          return { c: '(function() local _t = ' + a.c + '; if T(_t) then return _t end; return ' + b.c + ' end)()', t };
        }
        if (a.t === 'boolean') return { c: '(' + a.c + ' and ' + b.c + ')', t };
        if (this.pure(n.left) && b.t === 'boolean') return { c: '(T(' + a.c + ') and ' + b.c + ')', t: 'boolean' };
        if (this.pure(n.left) && this.truthyLit(n.right)) return { c: '(T(' + a.c + ') and ' + b.c + ' or ' + a.c + ')', t };
        return { c: '(function() local _t = ' + a.c + '; if not T(_t) then return _t end; return ' + b.c + ' end)()', t };
      }
      case 'ConditionalExpression': {
        const c = this.cond(n.test), a = this.expr(n.consequent), b = this.expr(n.alternate);
        const t = a.t === b.t ? a.t : (a.t === 'nil' ? b.t : b.t === 'nil' ? a.t : 'any');
        if (this.truthyLit(n.consequent)) return { c: '(' + c + ' and ' + a.c + ' or ' + b.c + ')', t };
        return { c: '(function() if ' + c + ' then return ' + a.c + ' else return ' + b.c + ' end end)()', t };
      }
      case 'AssignmentExpression': {
        const body = []; this.assign(n, body); const t = this.lhs(n.left);
        const v = n.operator === '=' ? this.expr(n.right) : { t: 'any' };
        return { c: '(function() ' + body.join(' ') + ' return ' + (t.prop === 'length' ? 'LEN(' + t.o + ')' : t.c) + ' end)()', t: v.t };
      }
      case 'UpdateExpression': {
        const t = this.lhs(n.argument), op = n.operator === '++' ? '+' : '-';
        if (n.prefix) return { c: '(function() ' + t.c + ' = ' + t.c + ' ' + op + ' 1; return ' + t.c + ' end)()', t: 'number' };
        return { c: '(function() local _v = ' + t.c + '; ' + t.c + ' = _v ' + op + ' 1; return _v end)()', t: 'number' };
      }
      case 'SequenceExpression': {
        const body = []; for (let i = 0; i < n.expressions.length - 1; i++) this.exprStmt(n.expressions[i], body);
        return { c: '(function() ' + body.join(' ') + ' return ' + this.expr(n.expressions[n.expressions.length - 1]).c + ' end)()', t: 'any' };
      }
      default: throw new Error('不支持的表达式 ' + n.type + ' @' + (n.loc && n.loc.start.line));
    }
  }

  call(n) {
    const cal = n.callee, sc = this.ctx.scope, A = this.args(n.arguments);
    if (cal.type === 'MemberExpression' && !cal.computed) {
      const p = cal.property.name, ob = cal.object;
      if (ob.type === 'Identifier' && !sc.lookup(ob.name)) {
        if (ob.name === 'Math') {
          if (!MATH_FN.includes(p)) throw new Error('不支持 Math.' + p);
          return { c: 'Math_' + p + '(' + A.join(',') + ')', t: 'number' };
        }
        if (G_OBJ.has(ob.name)) return { c: 'G.' + ob.name + ':' + p + '(' + A.join(',') + ')', t: p === 'stringify' ? 'string' : p === 'isArray' ? 'boolean' : p === 'now' ? 'number' : 'any' };
      }
      const o = this.obj(ob);
      const t = STR_METHODS.has(p) && (p !== 'toString' || true) ? 'string' : NUM_METHODS.has(p) ? 'number' : BOOL_METHODS.has(p) ? 'boolean' : 'any';
      if (!isIdent(p)) return { c: 'JS.callk(' + o.c + ', ' + luaStr(p) + (A.length ? ', ' + A.join(', ') : '') + ')', t };
      return { c: o.c + ':' + p + '(' + A.join(',') + ')', t };
    }
    if (cal.type === 'MemberExpression' && cal.computed) {
      const o = this.expr(cal.object), k = this.expr(cal.property);
      return { c: 'JS.callk(' + o.c + ', ' + k.c + (A.length ? ', ' + A.join(', ') : '') + ')', t: 'any' };
    }
    if (cal.type === 'Identifier' && !sc.lookup(cal.name)) {
      if (G_FN.has(cal.name)) return { c: 'G.' + cal.name + '(' + ['nil', ...A].join(',') + ')', t: cal.name === 'String' ? 'string' : cal.name === 'Number' || cal.name === 'parseInt' || cal.name === 'parseFloat' ? 'number' : cal.name === 'isNaN' || cal.name === 'isFinite' || cal.name === 'Boolean' ? 'boolean' : 'any' };
      if (HOST_FN.has(cal.name)) return { c: 'HOST.' + cal.name + '(' + ['nil', ...A].join(',') + ')', t: 'any' };
    }
    const f = this.expr(cal);
    const fc = cal.type === 'Identifier' || cal.type === 'MemberExpression' ? f.c : '(' + f.c + ')';
    return { c: fc + '(' + ['nil', ...A].join(',') + ')', t: 'any' };
  }

  // ---------------------------------------------------------------- 程序：第一个顶层 IIFE 为模块
  program(asts, header) {
    const out = [];
    const ms = new Scope('module', null);
    let first = true;
    const tail = [];
    this.ctx = { scope: ms, tryDepth: 0, loops: [] };
    for (const ast of asts) for (const st of ast.body) {
      const iife = st.type === 'ExpressionStatement' && st.expression.type === 'CallExpression' && st.expression.callee.type === 'FunctionExpression' && st.expression.arguments.length === 0;
      if (iife && first) {
        first = false;
        const body = st.expression.callee.body.body, decls = [];
        this.collect(body, ms, decls);
        for (const d of decls) out.push(ms.lookup(d.id.name) + ' = ' + this.fn(d, ms) + ';');
        const stm = []; for (const s of body) this.stmt(s, stm);
        const hasRet = body.some(s => this.topReturn(s));
        if (hasRet) { out.push(';(function()'); out.push(...stm); out.push('end)();'); } else out.push(...stm);
      } else {
        // 其它顶层语句（第二个起的 IIFE 等）：普通代码
        const stm = []; this.stmt(st, stm); tail.push(...stm);
      }
    }
    out.push(...tail);
    const lines = out.join('\n').split('\n').map(l => (l[0] === '(' ? ';' + l : l));
    return header + 'return function(HOST)\nlocal S = {}\n' + lines.join('\n') + '\nreturn S\nend\n';
  }
  topReturn(s) {
    // 模块顶层（不在嵌套函数里）的 return
    let found = false;
    const visit = (n) => { if (!n || typeof n !== 'object' || found) return; if (Array.isArray(n)) { n.forEach(visit); return; }
      if (n.type === 'FunctionExpression' || n.type === 'FunctionDeclaration') return; if (n.type === 'ReturnStatement') { found = true; return; }
      for (const k in n) if (k !== 'loc' && n[k] && typeof n[k] === 'object') visit(n[k]); };
    visit(s); return found;
  }
}

function indent(code) {
  // 简单缩进，便于阅读（不影响语义；字符串里的换行都已转义）
  const lines = code.split('\n'); let d = 0; const o = [];
  for (const raw of lines) {
    const l = raw.trim();
    if (!l) continue;
    if (/^(end\b|else\b|elseif\b|until\b|end\)|end;|end end)/.test(l)) d = Math.max(0, d - 1);
    o.push('  '.repeat(Math.min(d, 40)) + l);
    const opens = (l.match(/\bfunction\b|\bdo\b(?!\s*return\b)(?!\s*break\b)|\bthen\b|\brepeat\b/g) || []).length - (l.match(/\bdo return\b|\bdo break\b/g) || []).length * 0;
    const closes = (l.match(/\bend\b|\buntil\b/g) || []).length;
    const elses = /^(else\b|elseif\b)/.test(l) ? 1 : 0;
    d = Math.max(0, d + opens - closes + elses + (/^(end\b|else\b|elseif\b|until\b|end\)|end;|end end)/.test(l) ? 1 : 0) - (/^(elseif\b)/.test(l) ? 1 : 0));
  }
  return o.join('\n') + '\n';
}

function main() {
  const argv = process.argv.slice(2), inputs = []; let outFile = null, name = null, pretty = false;
  for (let i = 0; i < argv.length; i++) { if (argv[i] === '-o') outFile = argv[++i]; else if (argv[i] === '--name') name = argv[++i]; else if (argv[i] === '--pretty') pretty = true; else inputs.push(argv[i]); }
  const asts = inputs.map(f => acorn.parse(fs.readFileSync(f, 'utf8'), { ecmaVersion: 5, locations: true }));
  const g = new Gen();
  const header = '-- 由 xpile-lite（tools/xpile_lite/transpile.js）从 ' + (name || inputs.map(f => require('path').basename(f)).join(' + ')) + ' 自动生成，请勿手改。\n' +
    '-- 运行库见 jsrt/JS.lua。改玩法请改网页版 JS 后重新转换。\n' +
    'local JS = require("jsrt.JS")\n' +
    'local G, T, OR, AND, S2, LEN, MOD, typeof, tonum, smt, AMT = JS.G, JS.T, JS.OR, JS.AND, JS.S, JS.len, JS.mod, JS.typeof, JS.tonum, setmetatable, JS.AMT\n' +
    'local bor, band, bxor, shl, shr, ushr = JS.bor, JS.band, JS.bxor, JS.shl, JS.shr, JS.ushr\n' +
    'local ' + MATH_FN.map(f => 'Math_' + f).join(', ') + ', Math_PI = ' + MATH_FN.map(f => 'JS.Math_' + f).join(', ') + ', math.pi\n';
  let lua = g.program(asts, header);
  if (pretty) lua = indent(lua);
  if (outFile) fs.writeFileSync(outFile, lua); else process.stdout.write(lua);
  for (const w of g.warn) console.error('提示：' + w);
}
if (require.main === module) main();
module.exports = { Gen };
