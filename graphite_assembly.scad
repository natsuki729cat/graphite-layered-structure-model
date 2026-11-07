// ============================================================
// Graphite Layered Structure — ASSEMBLY version (差し込み式)
// 一体印刷版 graphite.scad と同じ構造を、3枚の層シートに分割した版
//
// Each graphene layer is one sheet (atoms + bond rods). Three legs
// under each sheet land on the collar pads of the sheet below (or
// on the base), with a peg-and-hole locator at every interface, so
// the stack is assembled by simply dropping the sheets on in order.
// Leg positions sit in the atom-free channels of the AB bilayer
// projection (6.8 mm from the nearest carbon in every layer,
// verified numerically), at radius 28, 120 degrees apart.
// The lithium parts (lithium_stage1/2.stl) have the same geometry
// as the one-piece model, so they can be laid into the gaps while
// stacking (loose, trapped once the next sheet is on).
//
//   part = "base"   hexagonal base with 3 locating pegs
//   part = "layer1".."layer3"  sheets, bottom to top
//   part = "all"    assembled stack (preview / single print)
// Export: openscad -D part="layer1" -o asm_layer1.stl graphite_assembly.scad
//
// Author: Yuki AnimaLab (model design) — generated with Muse
// License: CC BY 4.0 (see README)
// ============================================================

part = "all";

/* [Dimensions — same lattice as graphite.scad] */
bond_len = 12;
atom_r   = 4.2;
rod_r    = 1.8;
clip_r   = 46;
base_h   = 4;
base_r   = 56;

$fn = 16;           // export STLs use -D '$fn=12'

/* [Derived] */
layer_gap = bond_len * 3.35 / 1.42;         // 28.31
sqrt3     = sqrt(3);
a1        = [sqrt3 * bond_len, 0];
a2        = [sqrt3 * bond_len / 2, 1.5 * bond_len];
boff      = [0, bond_len];
legs      = [[28, 0], [-14, 24.2], [-14, -24.2]];
leg_r     = 3.0;
collar_r  = 4.6;
peg_r     = 1.5;
hole_r    = 1.75;

function shift_of(k) = (k % 2 == 0) ? [0, 0] : boff;

function layer_atoms(shift) =
    let (rng = [-6 : 6])
    concat(
        [ for (i = rng, j = rng)
            let (p = [i * a1[0] + j * a2[0] + shift[0],
                      i * a1[1] + j * a2[1] + shift[1]])
            if (norm(p) <= clip_r) p ],
        [ for (i = rng, j = rng)
            let (p = [i * a1[0] + j * a2[0] + shift[0] + boff[0],
                      i * a1[1] + j * a2[1] + shift[1] + boff[1]])
            if (norm(p) <= clip_r) p ]
    );

module rod(p1, p2, r) {
    v = p2 - p1;
    translate(p1)
        rotate([0, acos(v[2] / norm(v)), atan2(v[1], v[0])])
            cylinder(h = norm(v), r = r);
}

// Graphene net of layer k in the z=0 plane
module net(k) {
    pts = layer_atoms(shift_of(k));
    for (p = pts) translate([p[0], p[1], 0]) sphere(r = atom_r);
    for (p = pts)
        for (q = pts)
            if (abs(norm(q - p) - bond_len) < 0.05 &&
                (q[0] > p[0] || (q[0] == p[0] && q[1] > p[1])))
                rod([p[0], p[1], 0], [q[0], q[1], 0], rod_r);
}

// One sheet: net at z = leg_len, legs below it.
// leg_len = 20 for layer 1 (stands on the base), layer_gap - 1.2 above.
module sheet(k, leg_len, is_top) {
    pts = layer_atoms(shift_of(k));
    difference() {
        union() {
            translate([0, 0, leg_len]) net(k);
            for (lp = legs) {
                // leg with chamfered foot
                translate([lp[0], lp[1], 0]) cylinder(h = 1.2, r1 = 2.3, r2 = leg_r);
                translate([lp[0], lp[1], 0]) cylinder(h = leg_len + 1.2, r = leg_r);
                // collar pad at the sheet plane
                translate([lp[0], lp[1], leg_len - 1.2]) cylinder(h = 2.4, r = collar_r);
                // locating peg on top (except the top sheet)
                if (!is_top)
                    translate([lp[0], lp[1], leg_len + 1.2]) cylinder(h = 1.8, r = peg_r);
                // spoke to the nearest atom (guarantees the leg joins the net)
                let (ds = [for (p = pts) norm(p - lp)],
                     near = pts[search(min(ds), ds)[0]])
                    rod([lp[0], lp[1], leg_len], [near[0], near[1], leg_len], 1.2);
            }
        }
        // locating holes in the leg feet
        for (lp = legs)
            translate([lp[0], lp[1], -0.1]) cylinder(h = 2.1, r = hole_r);
    }
}

module base() {
    linear_extrude(height = base_h) circle(r = base_r, $fn = 6);
    translate([0, -47.5, base_h - 0.4])
        linear_extrude(height = 1.2)
            text("GRAPHITE", size = 7, halign = "center", valign = "center",
                 font = "DejaVu Sans:style=Bold");
    for (lp = legs)
        translate([lp[0], lp[1], base_h]) cylinder(h = 1.8, r = peg_r);
}

// ---- Build ----
if (part == "base") base();
else if (part == "layer1") sheet(0, 20, false);
else if (part == "layer2") sheet(1, layer_gap - 1.2, false);
else if (part == "layer3") sheet(2, layer_gap - 1.2, true);
else if (part == "all") {
    base();
    translate([0, 0, base_h]) sheet(0, 20, false);
    translate([0, 0, base_h + 20 + 1.2]) sheet(1, layer_gap - 1.2, false);
    translate([0, 0, base_h + 20 + layer_gap + 1.2]) sheet(2, layer_gap - 1.2, true);
}
