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
    if name := doc_format.from_string(header, param.name); len(name) > 0 {
        fmt.printf("<span class='param-name'>%s</span>: ", name)
    }

    fmt.printf("<span class='type'>")
    defer fmt.printf("</span>")
    #partial switch type.kind {
        case .Basic: {
            fmt.printf("%s", doc_format.from_string(header, type.name))
            if init_string := doc_format.from_string(header, param.init_string); len(init_string) > 0 {
                if init_string[0] == '"' {
                    fmt.printf(" = %s", init_string[1:len(init_string)-1])
                } else {
                    fmt.printf(" = %v", init_string)
                }
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
    fmt.println("<!doctype html>")
    fmt.println("<html>")
    defer fmt.println("</html>")

    fmt.println("<head>")
    fmt.println("<meta charset=utf8>")
    defer fmt.println(`<link rel="stylesheet" href="main.css?v=1">`)
    fmt.println("</head>")

    fmt.println("<body>")
    defer fmt.println(`<script src="main.js?v=1"></script>`)
    defer fmt.println("</body>")

    // generate this file by calling:
    // $ odin doc examples/all/all_main.odin -all-packages -doc-format
    data :: #load("odindoc.odin-doc")
    header, err := doc_format.read_from_bytes(data)
    if err != nil {
        panic(fmt.tprintln(err))
    }

    files := doc_format.from_array(header, header.files);
    entities := doc_format.from_array(header, header.entities);
    types := doc_format.from_array(header, header.types);

    // TOC
    // TODO: deduplicate
    fmt.println("<header>")
    fmt.println("<a href='https://odin-lang.org' target=_blank>")
    fmt.println("<img height=30 src='https://odin-lang.org/logo.svg'>")
    fmt.println("</a>")
    fmt.println("<span class='subheader'>:: <a href='#pkgs'>docs</a></span>")
    fmt.println("<form>")
    fmt.println("<input class='search-input' placeholder='search' >")
    fmt.println("</form>")
    fmt.println("</header>")

    fmt.println("<main>")
    defer fmt.println("</main>")

    fmt.println("<div id='pkgs'>")
    fmt.println("<h1>Packages</h1>")
    for pkg in doc_format.from_array(header, header.pkgs) {
        pkg_name := doc_format.from_string(header, pkg.name)
        switch pkg_name {
        case "", "c", "main": continue
        }
        fmt.printf("<a href='#%s'>%s</a>\n", pkg_name, pkg_name)
    }
    fmt.println("</div>")

    for pkg in doc_format.from_array(header, header.pkgs) {
        pkg_name := doc_format.from_string(header, pkg.name)
        switch pkg_name {
        case "", "c", "main": continue
        }

        fmt.printf("<div class='pkg' id='%s'>\n", pkg_name)
        fmt.printf("<h2>Package: <span class='pkg-name'>%s</span></h2>\n", pkg_name)

        for entity_index in doc_format.from_array(header, pkg.entities) {
            entity := entities[entity_index]
            if entity.kind == .Procedure {
                proc_name := doc_format.from_string(header, entity.name)

                fmt.printf("<div class='proc' id='%s.%s' data-pkg='%s'>", pkg_name, proc_name, pkg_name)
                defer fmt.println("</div>")

                // Name
                fmt.printf(
                    "<span class='proc-name'>%s.%s</span>",
                    pkg_name,
                    proc_name,
                )

                // Source location
                base_url :: "https://github.com/odin-lang/Odin/tree/master"
                file := doc_format.from_string(header, files[entity.pos.file].name)[len(ODIN_ROOT):]
                line := entity.pos.line

                // Link
                fmt.printf(" <a href='#%s.%s' class='proc-link'>::</a>", pkg_name, proc_name)

                fmt.printf(
                    " <a href='%s/%s#L%d' target=_blank class='keyword'>proc</a>(",
                    base_url,
                    file,
                    line,
                )

                // Type
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
                    fmt.printf("<p class='.docs'>%s</p>", docs)
                }
            }
        }
        fmt.print("</div>") // .pkg
    }
}
