# Run a parsing operation and generate a more readable and concise
# HTML format of the resulting log.

using XML
using XML: Document, Element, Text, Comment, CData, escape
using Logging
using Test: TestLogger

export debug_parsing


PARSER_DEBUG_CSS = """
body {
     font-family: sans-serif;
}
div.input-text {
    font-family: monospace;
    border: solid 3px;
    margin-top: 1ex;
    margin-bottom: 2ex;
}div.level {
    margin-left: 1em;
    margin-top: 1ex;
    margin-bottom: none;
    border-left: solid 1px;
    border-top: solid 1px;
    border-bottom: solid 1px;
    border-right: none;
}
span.log-index {
    font-weight: bold;
}
span.input-index {
}
span.node-pretty {
    font-size: 60%;
}
.result {
    font-family: monospace;
    font-size: 60%;
}
"""

PARSER_DEBUG_SCRIPT = """
function toggle_visibility(element) {
    if (element.style.display == "none") {
        element.style.display = "block";
    } else {
        element.style.display = "none";
    }
    // console.log("toggled ", element, "to", element.style.display);
}

function log_index_click_handler(event) {
    if (event instanceof PointerEvent) {
        if (event.target.classList.contains("log-index")) {
            event.target.closest(".level").querySelectorAll(":scope > .level").forEach((element, index) => {
                toggle_visibility(element);
            });
        }
    }
}

document.addEventListener('DOMContentLoaded', (event) => {
    // console.log('DOM fully loaded and parsed');
    document.querySelector("body").addEventListener("click", (event) => {
            log_index_click_handler(event);
        });
});
"""

function debug_parsing(grammar::Symbol, rulename::AbstractString,
                       input::AbstractString; keyargs...)
    debug_parsing(AllGrammars[grammar], rulename, input; keyargs...)
end


"""
    debug_parsing(grammar::BNFGrammar, rulename::AbstractString, input::AbstractString; index = 1, finish = length(input), context=nothing, report_file::AbstractString)

Run the parser specified by `grammar` and `rulename` to parse `input`
from `index` to `finish` with the specified `context` object.  The
parsing log is written to `report_file` as HTML.  That file presents a
hierarchichal view of how the parse progressed.
"""
function debug_parsing(grammar::BNFGrammar, rulename::AbstractString,
                       input::AbstractString;
                       index = 1, finish = length(input), context=nothing,
                       report_file::AbstractString)
    logger = TestLogger()
    parser = Parser()
    let                      # set DEBUG_BNFNODES
        debug_uids = Set()
        for rule in values(grammar.derivations)
            walk_nodes(rule) do node
                # Done enable logging for tedious nodes:
                if node isa Alternatives && all(n -> n isa CharacterLiteral, node.alternatives)
                    # ignore
                elseif node isa CharacterLiteral
                    #ignore
                else
                    push!(debug_uids, node.uid)
                end
            end
        end
        saved_debug = AnotherParser.DEBUG_BNFNODES
        AnotherParser.DEBUG_BNFNODES = collect(debug_uids)
        try
            with_logger(logger) do
                AnotherParser.recognize1(parser, grammar[rulename], input;
                                         index = index, finish = finish,
                                         context = context)
            end
        finally
            process_and_report_parser_debug_log(grammar, rulename, input, logger, report_file)
            AnotherParser.DEBUG_BNFNODES = saved_debug
        end
    end
end


function process_and_report_parser_debug_log(grammar, rulename, input, logger, report_file)
    report_file = abspath(report_file)
    is_parse_start(log_entry) =
        haskey(log_entry.kwargs, :trying)
    is_cache_hit(log_entry) =
        haskey(log_entry.kwargs, :cacheed_result)
    is_recursion(log_entry) =
        get(log_entry.kwargs, :infinite_recursion, false)
    is_match(log_entry) =
        haskey(log_entry.kwargs, :matched)
    is_parse_end(log_entry) = is_cache_hit(log_entry) || is_match(log_entry) || is_recursion(log_entry)
    # Match logging records by call_counter and infer hierarchy:
    log_index_stack = []
    log_entry_children = Dict{Int64, Vector{Int64}}()  # log entry index => [ log entry index ]
    for index in 1 : length(logger.logs)
        log_entry = logger.logs[index]
        if is_parse_start(log_entry)
            @assert !haskey(log_entry_children, index)
            log_entry_children[index] = []
            if !isempty(log_index_stack)
                push!(log_entry_children[last(log_index_stack)], index)
            end
            push!(log_index_stack, index)
        elseif is_parse_end(log_entry)
            @assert logger.logs[last(log_index_stack)].kwargs[:call_counter] ==
                log_entry.kwargs[:call_counter]
            push!(log_entry_children[last(log_index_stack)], index)
            pop!(log_index_stack)
        end
    end
    # global LOG_ENTRY_CHILDREN = log_entry_children
    # Write the HTML file:
    function log_tree(log_index)
        log_entry = logger.logs[log_index]
        Element("div",
                Element("span",
                        Text(escape(*("[$log_index]")));
                        title="log entry index",
                        class="log-index"),
                Element("span",
                        Text(escape("@$(log_entry.kwargs[:index])"));
                        # title="index into input",
                        # Show the remaining text instead:
                        title = escape(SubString(input, log_entry.kwargs[:index], length(input))),
                        class="input-index"),
                Element("span",
                        Text(escape("$(log_entry.kwargs[:node])"));
                        title= "node description",
                        class="node-pretty"),
                if is_parse_start(log_entry)
                    []
                elseif is_cache_hit(log_entry)
                    [ Element("div",
                              Text(escape("cahched result: $(log_entry.kwargs[:cacheed_result])"));
                              class="result")
                      ]
                elseif is_recursion(log_entry)
                    [ Element("div",
                              Text(escape("RECURSION!")))
                      ]
                elseif is_match(log_entry)
                    if log_entry.kwargs[:matched]
                        [ Element("div",
                                  Text(escape("result: $(log_entry.kwargs[:v])"));
                                  class="result")
                          ]
                    else
                        [ Element("div",
                                  Text("NO MATCH");
                                  class="result")
                          ]
                    end
                else
                    error("unhandled log entry $log_entry")
                end...,
                map(get(log_entry_children, log_index, [])) do child_index
                    if child_index == log_index
                        Comment("starting log entry")
                    else
                        log_tree(child_index)
                    end
                end...;
                id = "index-$log_index",
                class="level")
    end
    # global LOG_ENTRIES = logger.logs
    doc = Document(
        Element("head",
                Element("style",
                        PARSER_DEBUG_CSS),
                Element("script",
                        PARSER_DEBUG_SCRIPT)),
        Element("body",
                Element("h1",
                        Text(grammar.name), Text(" "), Text(escape(rulename))),
                Text("Parsing:"),
                Element("div", Text(escape(input));
                        class="input-text"),
                log_tree(minimum(keys(log_entry_children)))))
    open(report_file, "w") do io
        XML.write(io, doc)
    end
    println("Wrote $report_file")
end

