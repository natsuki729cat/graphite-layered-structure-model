// ============================================================
// Lithium intercalation part for the Graphite Layered Structure model
// グラファイトへのリチウム吸蔵（インターカレーション）可視化パーツ
//
// Print this part in a different filament colour (e.g. red/orange)
// together with graphite.stl — e.g. as a second object in the same
// 3MF on an AMS / multi-material printer.
//
// Chemistry (schematic):
//   stage = 1 -> LiC6 : Li in BOTH interlayer gaps
//   stage = 2 -> LiC12: Li in ONE gap only (staging phenomenon)
// Li ions sit at the hollow sites (hexagon centres) of the layer
// below, in the (sqrt3 x sqrt3) pattern of LiC6 — one Li per six
// carbons. Each Li sphere carries a short vertical strut up to the
// carbon atom directly above it, which anchors the part for printing.
// Note: real LiC6 rearranges the carbon stacking from AB to AA;
// this model keeps the AB host so the two states can be compared.
//
// Parameters must match graphite.scad.
// Export: openscad -D stage=1 -o lithium_stage1.stl lithium.scad
//         openscad -D stage=2 -o lithium_stage2.stl lithium.scad
// ============================================================

stage = 1;           // 1 = LiC6 (both gaps), 2 = LiC12 (first gap only)

/* [Dimensions — same as graphite.scad] */
bond_len = 12;
li_r     = 3.4;      // lithium sphere radius (mm)
strut_r  = 1.1;      // anchoring strut radius (mm)
clip_r   = 46;
base_h   = 4;
post_h   = 20;

$fn = 20;

/* [Derived] */
layer_gap = bond_len * 3.35 / 1.42;
sqrt3     = sqrt(3);
a1        = [sqrt3 * bond_len, 0];
a2        = [sqrt3 * bond_len / 2, 1.5 * bond_len];
boff      = [0, bond_len];
cbase     = [sqrt3 * bond_len / 2, bond_len / 2];   // hexagon-centre offset

function z_of(k) = base_h + post_h + k * layer_gap;
function shift_of(k) = (k % 2 == 0) ? [0, 0] : boff;

// Atom centres of one layer within radius rmax (wide set for site checks)
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

// Li sites for the gap whose lower layer is layer k:
// hexagon centres of the lower layer with all 6 carbons present,
// occupied in the (i - j) mod 3 == 0 pattern (LiC6 stoichiometry)
function li_sites(k) =
    let (shift = shift_of(k),
         wide  = layer_atoms_r(shift, clip_r + 25),
         rng   = [-7 : 7])
    [ for (i = rng, j = rng)
        let (c = [i * a1[0] + j * a2[0] + shift[0] + cbase[0],
                  i * a1[1] + j * a2[1] + shift[1] + cbase[1]],
             neighbours = len([ for (p = wide) if (abs(norm(p - c) - bond_len) < 0.05) 1 ]))
        if (norm(c) <= clip_r && neighbours >= 6 && ((i - j) % 3 + 3) % 3 == 0) c ];

module rod(p1, p2, r) {
    v = p2 - p1;
    translate(p1)
        rotate([0, acos(v[2] / norm(v)), atan2(v[1], v[0])])
            cylinder(h = norm(v), r = r);
}

// Lithium in gap k (between layer k and layer k+1)
module lithium_gap(k) {
    zmid = z_of(k) + layer_gap / 2;
    for (c = li_sites(k)) {
        translate([c[0], c[1], zmid]) sphere(r = li_r);
        // strut up to the carbon atom directly above the hollow site
        rod([c[0], c[1], zmid], [c[0], c[1], z_of(k + 1)], strut_r);
    }
}

if (stage == 1) {
    lithium_gap(0);
    lithium_gap(1);
} else {
    lithium_gap(0);
}
