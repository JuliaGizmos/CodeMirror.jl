module CodeMirror

using WebIO
using JSExpr
using AssetRegistry

export codemirror

const CMPATH = joinpath((@__DIR__), "..", "assets", "node_modules", "codemirror")

function codemirror(code;
                    jsmodpath=CMPATH,
                    theme="default",
                    mode="julia",
                    kwargs...)

    key = AssetRegistry.register(CMPATH)
    imports=Any["./lib/codemirror"=>"$jsmodpath/lib/codemirror.js",]

    modename = mode isa Dict ? mode["name"] : mode

    # see https://stackoverflow.com/questions/41753509/with-systemjs-how-do-i-map-urls-between-cdn-libraries-codemirror
    sys_opts = Dict( # I think having to do this is bullshit, but life.
        :map => Dict(
            "codemirror" => key
        ),
        :packages=> Dict(
            "codemirror"=> Dict(
                :map=> Dict("./lib/codemirror"=>  "$key/lib/codemirror.js")
            )
        )
    )

    push!(imports, "$jsmodpath/mode/$modename/$modename.js")

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
    @show vcat(imports, css_imports)
    s = Scope(imports=vcat(imports, css_imports))
    s.systemjs_options = sys_opts
    s.dom = node(:div,
                 node(:style, ".CodeMirror { height: auto; }"),
                 node(:div, id="codemirror-root")
            )
    onimport(s, ondeps)
    s
end

end # module
