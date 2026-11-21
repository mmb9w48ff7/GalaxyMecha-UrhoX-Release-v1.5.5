/* 技能模块图标：按形态的 8x8 像素图案，用模块自身颜色绘制 */
(function () {
  var C = window.Cosmic;
  var P = {
    homing: ['...aa...', '..abba..', '..abba..', '..abba..', '.aabbaa.', '.a.aa.a.', '...bb...', '..b..b..'],
    orbit: ['..aaaa..', '.a....a.', 'a..bb..a', 'a.b..b.a', 'a.b..b.a', 'a..bb..a', '.a....a.', '..aaaa..'],
    nova: ['a..a..a.', '.a.a.a..', '..aaa...', 'aaabaaa.', '..aaa...', '.a.a.a..', 'a..a..a.', '........'],
    strike: ['....aa..', '...aa...', '..aa....', '.aaaaa..', '...aa...', '..aa....', '.aa.....', 'aa......'],
    beam: ['........', 'b.......', '.aaaaaaa', 'abbbbbbb', '.aaaaaaa', 'b.......', '........', '........'],
    fan: ['a.....a.', '.a...a..', '..a.a...', '...b....', '..a.a...', '.a...a..', 'a.....a.', '........'],
    mine: ['...a....', '.aaaaa..', '.abbba..', 'aabbbaa.', '.abbba..', '.aaaaa..', '...a....', '........'],
    boomerang: ['aaaa....', 'abba....', 'aab.....', 'aa.b....', '....b...', '.....b..', '......aa', '......aa']
  };
  C.modIcon = function (m) {
    var px = '', fm = C.modForm(m.form), pat = P[(fm && fm.b) || m.form] || P[m.form] || P.homing;
    pat.forEach(function (r) { for (var i = 0; i < r.length; i++) px += r[i] === '.' ? '.' : (r[i] === 'a' ? '0' : '1'); });
    return { w: 8, h: 8, pal: [m.color, '#FFFFFF'], px: px };
  };
})();

