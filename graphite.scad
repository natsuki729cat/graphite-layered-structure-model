// ============================================================
// Graphite Layered Structure — 3D-printable model
// グラファイト（黒鉛）の層状構造モデル / Bernal (AB) stacking, 3 layers
//
// Author: Yuki AnimaLab (model design) — generated with Muse
// License: CC BY 4.0 (see README)
//
// Real graphite data (scaled):
//   in-plane C-C bond  1.42 A  -> bond_len (mm)
//   layer spacing      3.35 A  -> layer_gap = bond_len * 3.35 / 1.42
// Carbon atoms are spheres, in-plane bonds are rods.
// Atoms that sit directly above/below each other in AB stacking
// are joined by thin vertical rods (they also hold the model together).
// The bottom layer stands on 6 posts over a hexagonal base plate.
// ============================================================

/* [Dimensions] */
bond_len   = 12;     // in-plane C-C bond length (mm)
atom_r     = 4.2;    // carbon atom radius (mm)
bond_r     = 2.0;    // in-plane bond rod radius (mm)
vrod_r     = 1.6;    // vertical interlayer rod radius (mm)
post_r     = 2.2;    // base post radius (mm)
clip_r     = 46;     // flake radius: atoms kept within this distance (mm)
n_layers   = 3;      // number of graphene layers (ABA = Bernal graphite)
base_h     = 4;      // base plate thickness (mm)
base_r     = 56;     // base plate hexagon circumradius (mm)
post_h     = 20;     // height of posts under the bottom layer (mm)
with_text  = true;   // "GRAPHITE" label on the base plate

/* [Quality] */
$fn = 20;            // sphere/cylinder resolution for export (raise to 32+ for final)

/* [Derived] */
layer_gap  = bond_len * 3.35 / 1.42;   // real graphite layer spacing, scaled
sqrt3      = sqrt(3);
a1         = [sqrt3 * bond_len, 0];
a2         = [sqrt3 * bond_len / 2, 1.5 * bond_len];
boff       = [0, bond_len];            // B-sublattice offset within a layer

function z_of(k) = base_h + post_h + k * layer_gap;

// Atom centres (2D) of one graphene layer, shifted by `shift`.
// Two triangular sublattices: A at i*a1 + j*a2, B = A + boff.
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

// Rod (cylinder) between two 3D points
module rod(p1, p2, r) {
    v = p2 - p1;
    translate(p1)
        rotate([0, acos(v[2] / norm(v)), atan2(v[1], v[0])])
            cylinder(h = norm(v), r = r);
}

// One graphene layer at height z: atoms + in-plane bonds
module graphene_layer(shift, z) {
    atoms = layer_atoms(shift);
    for (p = atoms)
        translate([p[0], p[1], z]) sphere(r = atom_r);
    for (i = [0 : len(atoms) - 2])
        for (j = [i + 1 : len(atoms) - 1])
            if (abs(norm(atoms[i] - atoms[j]) - bond_len) < 0.01)
                rod([atoms[i][0], atoms[i][1], z],
                    [atoms[j][0], atoms[j][1], z], bond_r);
}

// Positions where atoms of adjacent layers align vertically (AB stacking)
function aligned_positions() =
    let (a = layer_atoms([0, 0]), b = layer_atoms(boff))
    [ for (p = a) if (min([for (q = b) norm(p - q)]) < 0.01) p ];

// ---- Build ----
aligned = aligned_positions();

// Base plate (hexagon, flat sides facing front/back)
translate([0, 0, 0])
    linear_extrude(height = base_h)
        circle(r = base_r, $fn = 6);

// Label on the base plate
if (with_text)
    translate([0, -43.5, base_h - 0.4])
        linear_extrude(height = 1.2)
            text("GRAPHITE", size = 6.5, halign = "center", valign = "center",
                 font = "DejaVu Sans:style=Bold");

// Posts under the bottom layer (at aligned positions near the centre)
for (p = aligned)
    if (norm(p) <= 30)
        rod([p[0], p[1], base_h - 2], [p[0], p[1], z_of(0)], post_r);

// Graphene layers (even layers unshifted, odd layers shifted = ABAB...)
for (k = [0 : n_layers - 1])
    graphene_layer(k % 2 == 0 ? [0, 0] : boff, z_of(k));

// Vertical rods between aligned atoms of adjacent layers
for (k = [0 : n_layers - 2])
    for (p = aligned)
        rod([p[0], p[1], z_of(k)], [p[0], p[1], z_of(k + 1)], vrod_r);
