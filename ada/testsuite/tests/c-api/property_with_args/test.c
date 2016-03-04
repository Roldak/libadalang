#include <stdio.h>
#include <stdlib.h>
#include "libadalang.h"

#include "langkit_text.h"
#include "utils.h"

static void
dump_identifier(ada_base_node id)
{
    const ada_text kind = ada_kind_name(ada_node_kind(id));
    ada_token name;

    printf("  ");
    fprint_text(stdout, kind, 0);
    printf(": ");

    if (!ada_single_tok_node_f_tok(id, &name))
      error("Could not the the name of an Identifier");
    fprint_text(stdout, ada_token_text(name), 0);
    printf("\n");
}

static const char *
bool_image(int b)
{
  return b ? "True" : "False";
}

int
main(void)
{
    ada_analysis_context ctx;
    ada_analysis_unit unit;

    ada_base_node foo, i;
    ada_base_node tmp;
    int boolean;

    libadalang_initialize();
    ctx = ada_create_analysis_context("iso-8859-1");
    if (ctx == NULL)
        error("Could not create the analysis context");

    unit = ada_get_analysis_unit_from_file(ctx, "foo.adb", NULL, 0);
    if (unit == NULL)
        error("Could not create the analysis unit from foo.adb");


    tmp = ada_unit_root(unit);
    if (ada_node_kind (tmp) != ada_compilation_unit)
      error("Unit root is not a CompilationUnit");

    tmp = ada_unit_root(unit);
    if (!ada_compilation_unit_f_bodies(tmp, &tmp))
        error("Could not get CompilationUnit -> Bodies");
    if (!ada_node_child(tmp, 0, &tmp))
        error("Could not get CompilationUnit -> Bodies[0]");
    if (!ada_library_item_f_item(tmp, &tmp))
        error("Could not get CompilationUnit -> Bodies[0] -> Item");
    if (!ada_subprogram_body_f_subp_spec(tmp, &tmp))
        error("Could not get CompilationUnit -> Bodies[0] -> Item ->"
	      " SubprogramSpec");

    if (!ada_subprogram_spec_f_name(tmp, &foo))
        error("Could not get CompilationUnit -> Bodies[0] -> Item ->"
	      " SubprogramSpec -> Name");

    if (!ada_subprogram_spec_f_params(tmp, &tmp))
        error("Could not get CompilationUnit -> Bodies[0] -> Item ->"
	      " SubprogramSpec -> Params");
    if (!ada_node_child(tmp, 0, &tmp))
        error("Could not get CompilationUnit -> Bodies[0] -> Item ->"
	      " SubprogramSpec -> Params[0]");
    if (!ada_parameter_profile_f_ids(tmp, &tmp))
        error("Could not get CompilationUnit -> Bodies[0] -> Item ->"
	      " SubprogramSpec -> Params[0] -> Ids");
    if (!ada_node_child(tmp, 0, &i))
        error("Could not get CompilationUnit -> Bodies[0] -> Item ->"
	      " SubprogramSpec -> Params[0] -> Ids[0]");

    printf("This should be Foo:\n");
    dump_identifier(foo);

    printf("This should be I:\n");
    dump_identifier(i);

    if (!ada_single_tok_node_p_matches(foo, foo, &boolean))
      error ("Call to Foo.p_matches(Foo) failed");
    printf("Foo.p_matches(Foo) = %s\n", bool_image (boolean));

    if (!ada_single_tok_node_p_matches(foo, i, &boolean))
      error ("Call to Foo.p_matches(I) failed");
    printf("Foo.p_matches(I) = %s\n", bool_image (boolean));

    ada_destroy_analysis_context(ctx);
    puts("Done.");
    return 0;
}
