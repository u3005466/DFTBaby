from DFTB import XYZ

if __name__ == "__main__":
    unitcell = [
     (30, (0.0, 0.0, 0.0)),
     (6, (-8.028166947895373, -1.2771174521903907, 0.0)),
     (6, (-5.3861172327157245, -2.048001689505741, 0.0)),
     (7, (-3.8394538008568095, 0.0, 0.0)),
     (6, (-5.3861172327157245, 2.048001689505741, 0.0)),
     (6, (-8.028166947895373, 1.2771174521903907, 0.0)),
     (6, (-4.599570001544039, -4.565820629223612, 0.0)),
     (6, (-2.1291669324959965, -5.45655922558379, 0.0)),
     (7, (0.0, -3.991635891360855, 0.0)),
     (6, (2.1291669324959965, -5.45655922558379, 0.0)),
     (6, (1.2922388505784004, -8.02789615016121, 0.0)),
     (6, (-1.2922388505784004, -8.02789615016121, 0.0)),
     (6, (4.599570001544039, -4.565820629223612, 0.0)),
     (6, (5.3861172327157245, -2.048001689505741, 0.0)),
     (7, (3.8394538008568095, 0.0, 0.0)),
     (6, (5.3861172327157245, 2.048001689505741, 0.0)),
     (6, (8.028166947895373, 1.2771174521903907, 0.0)),
     (6, (8.028166947895373, -1.2771174521903907, 0.0)),
     (6, (4.599570001544039, 4.565820629223612, 0.0)),
     (6, (2.1291669324959965, 5.45655922558379, 0.0)),
     (6, (1.2922388505784004, 8.02789615016121, 0.0)),
     (6, (-1.2922388505784004, 8.02789615016121, 0.0)),
     (6, (-2.1291669324959965, 5.45655922558379, 0.0)),
     (7, (0.0, 3.991635891360855, 0.0)),
     (6, (-4.599570001544039, 4.565820629223612, 0.0))]
    hydrogens = [
     (1, (9.629285479731577, 2.541273462797718, 0.0)),
     (1, (9.629285479731577, -2.541273462797718, 0.0)),
     (1, (2.535509798532552, -9.642392052270562, 0.0)),
     (1, (-2.535509798532552, -9.642392052270562, 0.0)),
     (1, (-9.629285479731577, -2.541273462797718, 0.0)),
     (1, (-9.629285479731577, 2.541273462797718, 0.0)),
     (1, (-2.535509798532552, 9.642392052270562, 0.0)),
     (1, (2.535509798532552, 9.642392052270562, 0.0)),
     (1, (6.064552484190416, 5.994616748914692, 0.0)),
     (1, (6.064552484190416, -5.994616748914692, 0.0)),
     (1, (-6.064552484190416, -5.994616748914692, 0.0)),
     (1, (-6.064552484190416, 5.994616748914692, 0.0))]
    porphyrin = unitcell + hydrogens
    
    XYZ.write_xyz("/tmp/porphyrin.xyz", [porphyrin])
