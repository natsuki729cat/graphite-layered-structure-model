// ============================================================
// Plug-in lithium parts for the ASSEMBLY graphite model
// 組み立て版グラファイト用・差し込み式リチウムパーツ
//
// Each Li piece has a plug that drops into a hexagon hole
// (hollow site) of the graphene sheet below, so the piece
// registers and stays in place while you stack the next sheet.
//   stage = 1 -> LiC6 : 12 pieces (6 per gap x 2 gaps)
//   stage = 2 -> LiC12:  6 pieces (lower gap only)
// The STL exports arrange the pieces on a print plate
// (plug down, no supports needed).
// Site pattern matches lithium.scad (sqrt3 x sqrt3, LiC6).
//
// Export: openscad -D stage=1 -o asm_lithium_stage1.stl asm_lithium.scad
//         openscad -D stage=2 -o asm_lithium_stage2.stl asm_lithium.scad
// ============================================================

stage = 1;

bond_len = 12;
clip_r   = 46;
li_r     = 3.6;      // lithium sphere radius (mm)
plug_r   = 6.0;      // plug radius (hexagon hole free radius is ~8)
stem_r   = 2.2;
$fn = 20;

layer_gap = bond_len * 3.35 / 1.42;
sqrt3     = sqrt(3);
a1        = [sqrt3 * bond_len, 0];
a2        = [sqrt3 * bond_len / 2, 1.5 * bond_len];
boff      = [0, bond_len];
cbase     = [sqrt3 * bond_len / 2, bond_len / 2];

function layer_atoms_r(shift, rmax) =
    let (rng = [-7 : 7])
    concat(
        [ for (i = rng, j = rng)
            let (p = [i * a1[0] + j * a2[0] + shift[0],
                      i * a1[1] + j * a2[1] + shift[1]])
            if (norm(p) <= rmax) p ],
        [ for (i = rng, j = rng)
            let (p = [i * a1[0] + j * a2[0] + shift[0] + boff[0],
                      i * a1[1] + j * a2[1] + shift[1] + boff[1]])
            if (norm(p) <= rmax) p ]
    );

// Hollow sites of layer A (both gaps share these xy positions)
function li_xy() =
    let (wide = layer_atoms_r([0, 0], clip_r + 25), rng = [-7 : 7])
    [ for (i = rng, j = rng)
        let (c = [i * a1[0] + j * a2[0] + cbase[0],
                  i * a1[1] + j * a2[1] + cbase[1]],
             neighbours = len([ for (p = wide) if (abs(norm(p - c) - bond_len) < 0.05) 1 ]))
        if (norm(c) <= clip_r && neighbours >= 6 && ((i - j) % 3 + 3) % 3 == 0) c ];

// One plug-in Li piece. Origin at the sheet plane (socket centre),
// z = 0 at the plane of the sheet it plugs into; plug goes down
// through the hexagon hole, ball floats at mid-gap height.
module li_piece() {
    zmid = layer_gap / 2;
    // plug through the hole, with a tapered tip
    translate([0, 0, -3.5]) cylinder(h = 7, r = plug_r);
    translate([0, 0, -5.1]) cylinder(h = 1.6, r1 = plug_r - 1.6, r2 = plug_r);
    // stem from plug to ball
    translate([0, 0, 3.0]) cylinder(h = zmid, r = stem_r);
    // the Li ion
    translate([0, 0, zmid]) sphere(r = li_r);
}

// Pieces laid out on a print plate, plug tip at z = 0
module plate(n) {
    sites = li_xy();
    for (idx = [0 : n - 1]) {
        gx = (idx % 4) * 21 - 31.5;
        gy = floor(idx / 4) * 21 - 10.5;
        translate([gx, gy, 5.1]) li_piece();
    }
}

if (stage == 1) plate(12);
else plate(6);
