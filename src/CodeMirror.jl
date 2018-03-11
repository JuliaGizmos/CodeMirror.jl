module CodeMirror

using WebIO
using JSExpr

export codemirror

function codemirror(code;
                    jsmodpath="/pkg/CodeMirror/node_modules/codemirror",
                    theme="default",
                    mode="julia",
                    kwargs...)
    imports=Any["./lib/codemirror"=>"codemirror/lib/codemirror.js",]

    modename = mode isa Dict ? mode["name"] : mode

    # see https://stackoverflow.com/questions/41753509/with-systemjs-how-do-i-map-urls-between-cdn-libraries-codemirror
    sys_opts = Dict( # I think having to do this is bullshit, but life.
        :map => Dict(
            "codemirror" => jsmodpath
        ),
        :packages=> Dict(
            "codemirror"=> Dict(
                :map=> Dict("./lib/codemirror"=>  "./lib/codemirror.js")
            )
        )
    )

    push!(imports, "codemirror/mode/$modename/$modename.js")

    options = Dict(
        "value" => code,
        "mode" => mode,
        "theme" => theme,
    )

    merge!(options, Dict(kwargs))

    ondeps = @js function (CM)
        @var cm = CM(this.dom.querySelector("#codemirror-root"), $options)
        console.log(cm)
        nothing
    end

    css_imports = ["$jsmodpath/lib/codemirror.css"]
    if theme != "default"
        push!(css_imports, "$jsmodpath/theme/$theme.css")
    end
    s = Scope(imports=[imports, css_imports])
    s.systemjs_options = sys_opts
    s.dom = Node(:div,
                 Node(:style, ".CodeMirror { height: auto; }"),
                 Node(:div, id="codemirror-root")
            )
    onimport(s, ondeps)
    s
end

end # module
