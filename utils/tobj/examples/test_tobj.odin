package tobj_example

// Packages
import "core:fmt"

// Local packages
import tobj "./.."

main :: proc() {
	models, materials, err := tobj.load_obj("./obj/cube_textured.obj")
	if err != nil {
		tobj.print_error(err)
		return
	}
	defer tobj.destroy(models, materials)

	fmt.printfln("Number of models: %d", len(models))
	fmt.printfln("%#v", models)
	fmt.println()
	fmt.printfln("Number of materials: %d", len(models))
	fmt.printfln("%#v", materials)
}
