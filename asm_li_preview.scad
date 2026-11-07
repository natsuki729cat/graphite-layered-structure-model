use <asm_lithium.scad>
color([0.45, 0.45, 0.48]) import("asm_base.stl");
color([0.35, 0.35, 0.38]) translate([0,0,4]) import("asm_layer1.stl");
color([0.35, 0.35, 0.38]) translate([0,0,25.2]) import("asm_layer2.stl");
color([0.35, 0.35, 0.38]) translate([0,0,53.51]) import("asm_layer3.stl");
color([0.95, 0.35, 0.1]) {
    for (c = li_xy()) {
        translate([c[0], c[1], 24]) li_piece();
        translate([c[0], c[1], 52.31]) li_piece();
    }
}
