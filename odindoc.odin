package main

import "core:fmt"
import doc_format "core:odin/doc-format"

print_params :: proc(header: ^doc_format.Header, params_indices: []doc_format.Entity_Index) {
    entities := doc_format.from_array(header, header.entities);

    for param_index, i in params_indices {
        param := &entities[param_index]
        print_param(header, param)

        if len(params_indices) > 30 {
            fmt.printf(",\n")
        } else {
            // Skip trailing coma when printing all args in 1 line
            if i < len(params_indices) - 1 {
                fmt.printf(", ")
            }
        }
    }
}

print_param :: proc(header: ^doc_format.Header, param: ^doc_format.Entity) {
    entities := doc_format.from_array(header, header.entities);
    files := doc_format.from_array(header, header.files);
    types := doc_format.from_array(header, header.types);
    pkgs := doc_format.from_array(header, header.pkgs);

    type := types[param.type]
    fmt.printf("%s: ", doc_format.from_string(header, param.name))
    #partial switch type.kind {
        case .Basic: {
            fmt.printf("%s", doc_format.from_string(header, type.name))
            if init_string := doc_format.from_string(header, param.init_string); len(init_string) > 0 {
                fmt.printf("!!!!! = %s", init_string)
            }
        }
        case .Slice: {
            slice_type := types[doc_format.from_array(header, type.types)[0]]
            fmt.printf("%s", doc_format.from_string(header, slice_type.name),)
        }
        case .Pointer: {
            pointer_type := types[doc_format.from_array(header, type.types)[0]]
            fmt.printf("%s", doc_format.from_string(header, pointer_type.name),)
        }
        case .Named: {
            base_type := types[doc_format.from_array(header, type.types)[0]]
            entity := entities[doc_format.from_array(header, type.entities)[0]]
            file := files[entity.pos.file]
            pkg := pkgs[file.pkg]
            fmt.printf(
                "%v.%s",
                doc_format.from_string(header, pkg.name),
                doc_format.from_string(header, entity.name),
            )
        }
        case: {
            fmt.printf("<<%s>>", type.kind)
        }
    }
}



main :: proc() {
    // generate this file by calling:
    // $ odin doc odindoc.odin -all-packages -doc-format
    data :: #load("odindoc.odin-doc")
    header, err := doc_format.read_from_bytes(data)
    if err != nil {
        panic(fmt.tprintln(err))
    }

    files := doc_format.from_array(header, header.files);
    entities := doc_format.from_array(header, header.entities);
    types := doc_format.from_array(header, header.types);

    for pkg in doc_format.from_array(header, header.pkgs) {
        pkg_name := doc_format.from_string(header, pkg.name)
        switch pkg_name {
        case "", "c", "main": continue
        }

        fmt.printf("* Package: %s\n", pkg_name)

        if false {
            fmt.printf(" :FILE: %s\n", doc_format.from_string(header, pkg.fullpath))
        }

        for entity_index in doc_format.from_array(header, pkg.entities) {
            entity := entities[entity_index]
            if entity.kind == .Procedure {
                proc_name := doc_format.from_string(header, entity.name)

                fmt.printf("** ")

                // Name & Source location
                use_github_as_location :: true
                if use_github_as_location {
                    base_url :: "https://github.com/odin-lang/Odin/tree/master"
                    file := doc_format.from_string(header, files[entity.pos.file].name)[len(ODIN_ROOT):]
                    line := entity.pos.line
                    fmt.printf("[[%s/%s#L%d][~%s.%s~]]", base_url, file, line, pkg_name, proc_name)
                } else {
                    file := doc_format.from_string(header, files[entity.pos.file].name)
                    line := entity.pos.line
                    column := entity.pos.column
                    fmt.printf("[[%s:%d:%d][%s.%s]]", file, line, column, pkg_name, proc_name)
                }

                fmt.printf(" :: proc(")


                proc_type := types[entity.type]
                proc_params_and_results := doc_format.from_array(header, proc_type.types)

                proc_params := types[proc_params_and_results[0]]

                // Input params
                params := doc_format.from_array(header, proc_params.entities);
                print_params(header, params)

                fmt.printf(")")
                if len(params) > 0 {
                    fmt.printf(" -> ")

                    // Results
                    results := doc_format.from_array(header, proc_params.entities);
                    if len(results) > 1 {
                        fmt.printf("(")
                        print_params(header, results)
                        fmt.printf(")")
                    } else {
                        print_params(header, results)
                    }
                }

                fmt.printf("\n")

                // Docs
                if docs := doc_format.from_string(header, entity.docs); len(docs) > 0 {
                    fmt.printf("%s", docs)
                }
            }
        }
    }
}
